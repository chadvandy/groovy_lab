--- TODO a system of game interfaces that links the separate modify and query models of the game in one convenient package.

---@class GLab.GameObject.Character : GLab.GameObject.Base
local defaults = {
    _key = "",
    _cqi = 0,
}

local Super = GLab.World.GameObjectClasses.Base

---@class GLab.GameObject.Character : GLab.GameObject.Base
---@field __new fun(): GLab.GameObject.Character
local go_Character = Super:extend("GameObject.Character", defaults)

GLab.World.GameObjectClasses.Character = go_Character

function go_Character:new(cqi)
    local o = self:__new()

    o:init(cqi)

    return o
end

---@return CHARACTER_SCRIPT_INTERFACE
function go_Character:__get()
    return cm:get_character_by_cqi(self._cqi)
end

function go_Character:init(cqi)
    self._cqi = cqi
end

function go_Character:Name()
    local go = self:__get()
    return go:get_forename() .. " " .. go:get_surname()
end

function go_Character:CommandQueueIndex()
    return self._cqi
end