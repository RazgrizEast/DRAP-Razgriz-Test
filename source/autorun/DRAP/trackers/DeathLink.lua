-- DRAP/trackers/DeathLink.lua
-- Tracks player death via PlayerVitalController
-- and provides a DeathLink-compatible "kill player" trigger

local Shared = require("DRAP/Shared")
local PlayerReady = require("DRAP/PlayerReady")

local M = Shared.create_module("DeathLink")
M:set_throttle(0.25)  -- CHECK_INTERVAL_FRAMES = 15 at 60fps ≈ 0.25s

------------------------------------------------------------
-- Singleton Managers
------------------------------------------------------------

local psm_mgr = M:add_singleton("psm", "app.solid.PlayerStatusManager")
local gm_mgr  = M:add_singleton("gm", "app.solid.gamemastering.GameManager")

------------------------------------------------------------
-- Internal State
------------------------------------------------------------

-- Last InGameFlowManagerBase seen, kept only to notice when it changes.
--
-- It is NOT a cache any more. get_MainInstance can hand back a different
-- object without GameManager itself being replaced -- a log of two Psycho
-- runs 40s apart showed no GameManager transition at all -- and a call on a
-- stale one neither throws nor does anything: pcall returns true, the log
-- says "playerDead() invoked", and nobody dies. Re-reading it costs one
-- managed call, which is nothing next to a death that silently does not
-- happen.
local igfm_cached = nil
local last_is_dead = nil
local has_announced_death_this_life = false

-- A DeathLink from another world waits until Frank is on foot, out of
-- cutscenes and past any load screen. One is enough: dying once answers any
-- number of them.
local held_death = nil

-- Why the next death is not to be sent out, or nil. A received DeathLink
-- must not echo back, and the Psycho ending's scripted death (the trigger for
-- the Special Forces capture) must not kill the rest of the multiworld at
-- the moment the run is won. Nothing stopped either before: every death sent.
local quiet_death = nil

------------------------------------------------------------
-- Public Callbacks
------------------------------------------------------------

M.on_death_detected = nil
M.on_revive_detected = nil

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function get_vital_controller()
    local psm = psm_mgr:get()
    if not psm then return nil end

    -- Try backing field first
    local vc = Shared.get_field_value(psm, {"<PlayerVitalController>k__BackingField"})
    if vc then return vc end

    -- Try accessor method
    if psm.get_PlayerVitalController then
        local ok, v = pcall(psm.get_PlayerVitalController, psm)
        if ok then return v end
    end

    return nil
end

local function vital_is_dead(vc)
    if not vc then return nil end
    if vc.get_IsDead then
        local ok, v = pcall(vc.get_IsDead, vc)
        if ok then return v end
    end
    return nil
end

local function get_ingame_flow_manager()
    local gm = gm_mgr:get()
    if not gm then
        M.log("get_ingame_flow_manager: GameManager singleton is nil")
        return nil
    end

    local ok, v = pcall(function()
        return gm:call("get_MainInstance")
    end)

    if ok and v then
        if igfm_cached ~= nil and igfm_cached ~= v then
            M.log("InGameFlowManagerBase replaced -- the old one would have"
                .. " swallowed playerDead() silently")
        end
        igfm_cached = v
        return v
    end

    igfm_cached = nil
    M.log("get_ingame_flow_manager: gm:call(get_MainInstance) failed")
    return nil
end

------------------------------------------------------------
-- Public API
------------------------------------------------------------

--- Kills the player (for receiving DeathLink)
--- @param reason string|nil The reason for death
--- @return boolean True if successful
function M.kill_player(reason)
    -- Avoid spamming if already dead
    local vc = get_vital_controller()
    if vc then
        local is_dead = vital_is_dead(vc)
        if is_dead == true then
            M.log("kill_player: already dead; ignoring. reason=" .. tostring(reason))
            return false
        end
    end

    local igfm = get_ingame_flow_manager()
    if not igfm then
        M.log("kill_player: InGameFlowManagerBase not available yet. reason=" .. tostring(reason))
        return false
    end

    if not igfm.playerDead then
        igfm_cached = nil
        M.log("kill_player: playerDead() not bound; cache cleared.")
        return false
    end

    local ok = pcall(igfm.playerDead, igfm)
    if ok then
        M.log("kill_player: playerDead() invoked. reason=" .. tostring(reason))
        return true
    end

    igfm_cached = nil
    M.log("kill_player: playerDead() call failed; cache cleared.")
    return false
end

local function kill_quietly(reason, why)
    quiet_death = why
    local ok = M.kill_player(reason)
    if not ok then quiet_death = nil end
    return ok
end

--- A death that is not sent as a DeathLink: the Psycho ending's.
function M.kill_without_sending(reason)
    return kill_quietly(reason, tostring(reason))
end

--- A DeathLink from another player. Kills now if Frank is ready, else holds
--- it for the frame loop. Lethal DamageLink uses kill_player and is not held.
local function kill_from_link(reason)
    return kill_quietly(reason, "a received DeathLink")
end

function M.receive(reason)
    if not held_death and PlayerReady.ready() then
        return kill_from_link(reason)
    end
    if not held_death then
        M.log(string.format("DeathLink held (%s): %s", PlayerReady.blocked_by(), tostring(reason)))
    end
    held_death = reason
    return false
end

------------------------------------------------------------
-- Death Polling
------------------------------------------------------------

local function poll_death_state()
    local vc = get_vital_controller()
    if not vc then return end

    local is_dead = vital_is_dead(vc)

    -- First read: initialize state
    if last_is_dead == nil and is_dead ~= nil then
        last_is_dead = is_dead
        has_announced_death_this_life = (is_dead == true)
        return
    end

    -- Revive detection
    if last_is_dead == true and is_dead == false then
        has_announced_death_this_life = false
        quiet_death = nil
        if M.on_revive_detected then
            pcall(M.on_revive_detected)
        end
    end

    -- Death detection
    if (last_is_dead == false or last_is_dead == nil) and is_dead == true then
        if not has_announced_death_this_life then
            has_announced_death_this_life = true
            if quiet_death then
                M.log("Detected player death -- " .. quiet_death .. ", not sent.")
                quiet_death = nil
            else
                M.log("Detected player death.")
                if M.on_death_detected then
                    pcall(M.on_death_detected)
                end
            end
        end
    end

    last_is_dead = is_dead
end

------------------------------------------------------------
-- Per-frame Update
------------------------------------------------------------

function M.on_frame()
    if not M:should_run() then return end
    poll_death_state()
    if held_death and PlayerReady.ready() then
        local reason = held_death
        held_death = nil
        M.log("releasing a held DeathLink")
        kill_from_link(reason)
    end
end

--- Receive a DeathLink through the real path, holding and all, to test the
--- deferral offline.
_G.drap_deathlink_receive = function()
    M.receive("DeathLink: console test")
end

return M