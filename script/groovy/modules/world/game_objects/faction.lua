--- TODO a system of game interfaces that links the separate modify and query models of the game in one convenient package.

--- TODO get the Super by doing GLib.LoadModule and returning a previously created module?
-- local Super = GLib.LoadModule()

---@class GLab.GameObject.Faction : GLab.GameObject.Base
local defaults = {
    _key = "",
}

local Super = GLab.World.GameObjectClasses.Base

---@class GLab.GameObject.Faction : GLab.GameObject.Base
local go_Faction = Super:extend("GameObject.Faction", defaults)

GLab.World.GameObjectClasses.Faction = go_Faction

function go_Faction:new(key)
    local o = self:__new()

    o:init(key)

    return o
end

---@return FACTION_SCRIPT_INTERFACE
function go_Faction:__get()
    return cm:get_faction(self._key)
end

function go_Faction:init(key)
    -- TODO once we're ready to, confirm that this faction actually exists!
    self._key = key
end

--[[
    Money and similar resources!
--]]

--- Get the amount of money this faction currently has!
---@return number
function go_Faction:Treasury()
    local go = self:__get()
    return go:treasury()
end

function go_Faction:Income()
    local go = self:__get()
    return go:income()
end

--- TODO get the proper name actually.
function go_Faction:Name()
    local go = self:__get()
    return go:name()
end

---@return GLab.GameObject.Character
function go_Faction:FactionLeader()
    local go = self:__get()
    local int_faction_leader = go:faction_leader()
    return GLab.World:GetCharacter(int_faction_leader:command_queue_index())
end

-- function go_Faction:ModifyTreasury(n)
--     local go = self:__get()
--     local i = self:Treasury()

--     cm:treasury_mod(self:get_key(), i + n)
-- end

function go_Faction:ModifyTreasury(n)
    local go = self:__get()
    cm:treasury_mod(self:get_key(), n)
end

--- TODO PR stuff

--- TODO spawn RoR
function go_Faction:spawn_mercenary_to_pool(key, count)
    
end

--- TODO spawn agent
function go_Faction:spawn_agent()

end

function go_Faction:spawn_unique_agent()

end

function go_Faction:spawn_army()

end

