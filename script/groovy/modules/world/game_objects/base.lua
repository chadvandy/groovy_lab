--- TODO a parent class for each interface, to make getting ez

---@class GLab.GameObject.Base : Class
local defaults = {
    ---@type string The key to get this game object.
    _key = "",
    _game_object = nil,

    --- The individual getter function for this game object. Should never be directly called - use __get instead!
    ---@return any
    _get_func = function() return nil end,

    _callbacks = {
        ---@type function[]
        init = {},
        ---@type function[]
        first_tick = {},
        ---@type function[]
        each_tick = {},
    }
}

---@class GLab.GameObject.Base : Class
local GameObject = GLab.NewClass("GameObject.Base", defaults)

GLab.World.GameObjectClasses.Base = GameObject

GameObject.__newindex  = function(t, k, v)
    if k == "first_tick_callback" then
        table.insert(t._callbacks.first_tick, v)
    elseif k == "each_tick_callback" then
        table.insert(t._callbacks.each_tick, v)
    elseif k == "init_callback" then
        table.insert(t._callbacks.init, v)
    else
        rawset(t, k, v)
    end
end

--- TODO should NEVER be called!!!?!?!?!
function GameObject:new()
    assert(false, "This function should NEVER be called!")
    return nil
end

--- TODO verify that this is a valid game object; if not, abort!
function GameObject:__init()
    if not cm.model_is_created then
        function self:first_tick_callback()
            self:__init()
        end
    else
        local go = self:__get()
    end
end

function GameObject:get_key()
    return self._key
end

function GameObject:first_tick_callback()

end

function GameObject:each_tick_callback()

end

function GameObject:init_callback()

end

--- Called every game tick to clear unhealthy internals. 
function GameObject:__clear()
    self._game_object = nil
end

--- TODO cache the return value and empty it out after a tick?
---@return userdata #Get the script interface for this game object!
function GameObject:__get()
    assert(cm.model_is_created)
    if self._game_object then return self._game_object end
    
    return self._get_func()
end

return GameObject