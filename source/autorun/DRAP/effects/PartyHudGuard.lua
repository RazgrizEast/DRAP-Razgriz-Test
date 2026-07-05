-- DRAP/effects/PartyHudGuard.lua
-- Fixes the crash when 10+ party members are left in another zone.
--
-- BattleHudUI.updateOtherMapNpcHp renders HP for party NPCs in other maps
-- through a widget pool sized for the vanilla 8-survivor party; large DRAP
-- parties overflow it and the game null-derefs on the first HUD update
-- after a transition.
--
-- Guard: while more than show_n party members lack live controllers, the
-- excess members' mLiveState is flipped JOIN->FOUND for the duration of
-- the one updateOtherMapNpcHp call and restored in the post-hook, so the
-- widget renders show_n entries and ignores the rest. The mutation window
-- is a single main-thread HUD call; nothing else observes it. show_n = 0
-- skips the update entirely (also the fallback if the cap path errors).
--
-- Console: drap_party_hud_guard_status() / _enabled(bool) / _show(n)

local Shared = require("DRAP/Shared")

local M = Shared.create_module("PartyHudGuard")
M:set_throttle(0.5)

------------------------------------------------------------
-- Configuration / State
------------------------------------------------------------

local HUD_TYPE = "app.solid.gui.BattleHudUI"
local NPC_TYPE = "app.solid.gamemastering.NpcManager"

local JOIN, FOUND = 2, 1

-- Max other-map members the widget is allowed to see. 8 = vanilla max
-- party, guaranteed inside the asset's widget pool.
local show_n = 8

local enabled = true
local guard_active = false      -- stranded exceeds safe count (updated every 0.5s)
local stranded_count = 0
local caps_this_session = 0     -- calls where members were hidden
local skips_this_session = 0    -- calls fully skipped (fallback/show_n=0)
local hook_installed = false

local npc_mgr = M:add_singleton("npc", NPC_TYPE)

-- Members hidden for the current call: array of NpcBaseInfo to restore.
local flipped = {}

------------------------------------------------------------
-- Census helpers
------------------------------------------------------------

-- Collect JOIN members without a live controller, in stable list order.
-- Returns the array (possibly empty), or nil on any read failure.
local function collect_stranded()
    local mgr = npc_mgr:get()
    if not mgr then return nil end
    local list_field = npc_mgr:get_field("NpcInfoList")
    if not list_field then return nil end
    local list = Shared.safe_get_field(mgr, list_field)
    if not list then return nil end

    local out = {}
    for _, info in Shared.iter_collection(list) do
        if info then
            local state = nil
            pcall(function() state = Shared.to_int(info:get_field("mLiveState")) end)
            if state == JOIN then
                local stype = nil
                pcall(function()
                    stype = Shared.to_int(info:get_field("<Name>k__BackingField"))
                end)
                if stype then
                    local ctrl = nil
                    local ok = pcall(function()
                        ctrl = mgr:call("searchNpc", stype)
                    end)
                    if not ok then return nil end
                    if ctrl == nil then table.insert(out, info) end
                end
            end
        end
    end
    return out
end

------------------------------------------------------------
-- Hook: cap or skip updateOtherMapNpcHp
------------------------------------------------------------

-- Hide members beyond show_n for the duration of the call. Returns true
-- on success; false means the caller must fall back to skipping.
local function hide_excess()
    local stranded = collect_stranded()
    if not stranded then return false end
    if #stranded <= show_n then return true end  -- nothing to hide

    for i = show_n + 1, #stranded do
        local info = stranded[i]
        local ok = pcall(function() info:set_field("mLiveState", FOUND) end)
        if not ok then
            return false  -- caller restores whatever was flipped, then skips
        end
        table.insert(flipped, info)
    end
    return true
end

local function restore_flipped()
    for i = #flipped, 1, -1 do
        pcall(function() flipped[i]:set_field("mLiveState", JOIN) end)
        flipped[i] = nil
    end
end

local function install_hook()
    if hook_installed then return true end
    local td = sdk.find_type_definition(HUD_TYPE)
    if not td then return false end
    local m = td:get_method("updateOtherMapNpcHp")
    if not m then
        M.log("WARNING: BattleHudUI.updateOtherMapNpcHp not found; guard inactive")
        return false
    end

    local ok = pcall(sdk.hook, m,
        function(args)
            if not (enabled and guard_active) then return end

            if show_n > 0 then
                local ok_hide = false
                local ok_call, err = pcall(function() ok_hide = hide_excess() end)
                if ok_call and ok_hide then
                    if #flipped > 0 then
                        caps_this_session = caps_this_session + 1
                    end
                    return  -- run original with excess members hidden
                end
                -- Cap path failed: restore and fall through to full skip.
                restore_flipped()
            end
            skips_this_session = skips_this_session + 1
            return sdk.PreHookResult.SKIP_ORIGINAL
        end,
        function(retval)
            if #flipped > 0 then
                restore_flipped()
            end
            return retval
        end)

    hook_installed = ok == true
    if hook_installed then
        M.log(string.format("updateOtherMapNpcHp guard installed (show up to %d)", show_n))
    end
    return hook_installed
end

------------------------------------------------------------
-- Per-frame Update
------------------------------------------------------------

function M.on_frame()
    if not hook_installed then
        install_hook()
        if not hook_installed then return end
    end
    if not M:should_run() then return end
    if not Shared.is_in_game() then
        guard_active = false
        return
    end

    local stranded = collect_stranded()
    stranded_count = stranded and #stranded or 0
    -- Cap mode engages once there is anything to hide; full-skip mode
    -- (show_n=0) engages at the field-proven-safe vanilla count.
    local should_guard
    if show_n == 0 then
        should_guard = stranded_count >= 8
    else
        should_guard = stranded_count > show_n
    end
    if should_guard ~= guard_active then
        guard_active = should_guard
        if guard_active then
            M.log(string.format(
                "party HUD guard ENGAGED: %d members without controllers "
                .. "(showing up to %d in the other-map HP widget)",
                stranded_count, show_n))
        else
            M.log("party HUD guard disengaged -- other-map HP widget back to normal")
        end
    end
end

------------------------------------------------------------
-- Public API / Console Commands
------------------------------------------------------------

function M.get_status()
    return {
        enabled = enabled,
        active = guard_active,
        stranded = stranded_count,
        show_n = show_n,
        caps = caps_this_session,
        skips = skips_this_session,
        hook_installed = hook_installed,
    }
end

function M.set_enabled(v)
    enabled = (v == true)
    M.log("party HUD guard enabled: " .. tostring(enabled))
end

function M.set_show(n)
    n = tonumber(n)
    if n and n >= 0 and n <= 8 then
        show_n = math.floor(n)
        M.log("party HUD guard: showing up to " .. show_n
            .. (show_n == 0 and " (full skip mode)" or " other-map members"))
    else
        M.log("show must be 0..8 (8 = vanilla widget pool size)")
    end
end

_G.drap_party_hud_guard_status = function()
    local s = M.get_status()
    M.log(string.format(
        "enabled=%s active=%s stranded=%d show=%d capped_calls=%d skipped_calls=%d hook=%s",
        tostring(s.enabled), tostring(s.active), s.stranded, s.show_n,
        s.caps, s.skips, tostring(s.hook_installed)))
end

_G.drap_party_hud_guard_enabled = function(v) M.set_enabled(v) end
_G.drap_party_hud_guard_show = function(n) M.set_show(n) end

return M
