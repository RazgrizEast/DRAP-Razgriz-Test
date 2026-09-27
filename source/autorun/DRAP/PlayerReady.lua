-- DRAP/PlayerReady.lua
-- Whether Frank is free to take something another world sends him.
--
-- A knockback or a death that lands mid-cutscene, mid-load or behind the
-- wheel does the wrong thing or nothing at all, so those wait for this.
-- Ready means: a play session, no door load under way, no cutscene playing,
-- not in a vehicle, and the scene and area unchanged -- all of it held for a
-- moment, so nothing lands the instant he walks in.
--
-- A door load is not is_in_game going false: across 124 area loads in one
-- 2026-09-26 session that flipped twice (save load and quit). So a load is
-- taken as running from the moment a door is used (DoorRandomizer's areaJump
-- hook) until the loaded scene changes, with a timeout in case it never does.

local Shared = require("DRAP/Shared")

local M = {}
local log = Shared.create_logger("PlayerReady")

local DEFAULT_SETTLE = 2.0
local CHECK_EVERY = 0.1
local JUMP_TIMEOUT = 20.0

local ETM_TYPE = "app.solid.gamemastering.EventTimelineManager"
local PM_TYPE = "app.solid.PlayerManager"
local AM_TYPE = "app.solid.gamemastering.AreaManager"

local ready_since = nil
local blocked_by = "not started"
local last_area = nil
local last_level = nil
local jump_seen = nil       -- the DoorRandomizer jump time last acted on
local jump_level = nil      -- the scene that jump left from
local sampled_level = nil   -- the scene at the previous check
local next_check = 0

local function cutscene_playing()
    local etm = sdk.get_managed_singleton(ETM_TYPE)
    if not etm then return false end
    return Shared.safe(function() return etm:call("isEventPlaying") end) == true
end

local function in_vehicle()
    local pm = sdk.get_managed_singleton(PM_TYPE)
    if not pm then return false end
    local v = Shared.safe(function() return pm:get_field("<VehicleType>k__BackingField") end)
    return v ~= nil and v ~= 0
end

local function has_player()
    local pm = sdk.get_managed_singleton(PM_TYPE)
    return pm ~= nil and Shared.safe(function() return pm:call("get_CurrentPlayer") end) ~= nil
end

local function area_index()
    local am = sdk.get_managed_singleton(AM_TYPE)
    return am and Shared.to_int(Shared.safe(function() return am:get_field("mAreaIndex") end)) or nil
end

local function level_path()
    local am = sdk.get_managed_singleton(AM_TYPE)
    local p = am and Shared.safe(function() return am:get_field("CurrentLevelPath") end)
    return p and tostring(p) or nil
end

--- A door was used and the scene it left is still the one loaded. The scene
--- it left is the one from the previous check, which is always from before
--- the jump; the current one may already be the new scene.
local function door_loading(level)
    local dr = package.loaded["DRAP/DoorRandomizer"]
    local at = dr and dr.last_jump_at
    if at and at ~= jump_seen then
        jump_seen = at
        jump_level = sampled_level
    end
    return jump_seen ~= nil and level == jump_level
        and os.clock() - jump_seen < JUMP_TIMEOUT
end

local function update()
    local why
    local level = level_path()
    if not Shared.is_in_game() or not has_player() then
        why = "loading"
    elseif door_loading(level) then
        why = "going through a door"
    elseif cutscene_playing() then
        why = "cutscene"
    elseif in_vehicle() then
        why = "in a vehicle"
    else
        local a = area_index()
        if a ~= last_area or level ~= last_level then
            last_area, last_level = a, level
            why = "area changed"
        end
    end
    sampled_level = level
    if why then
        ready_since = nil
        blocked_by = why
    elseif not ready_since then
        ready_since = os.clock()
    end
end

re.on_frame(function()
    local now = os.clock()
    if now < next_check then return end
    next_check = now + CHECK_EVERY
    pcall(update)
end)

--- True once Frank has been on foot, out of cutscenes and settled in one
--- area for `settle` seconds (default 2).
function M.ready(settle)
    return ready_since ~= nil and os.clock() - ready_since >= (settle or DEFAULT_SETTLE)
end

--- What is holding things back, for the log.
function M.blocked_by()
    if ready_since then return "settling in" end
    return blocked_by
end

_G.drap_player_ready = function()
    log(string.format("ready=%s  %s", tostring(M.ready()), M.blocked_by()))
end

return M
