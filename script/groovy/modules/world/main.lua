--- TODO the Game Objects system that'll handle all the wrappers for internal game objects.
--- TODO a Singleton for the "World"

local World = GLab.NewClass("World", {})
GLab.World = World

World.ThisPath = GLab.ThisPath(...)
World.GameObjects = {
    ---@type table<string, GLab.GameObject.Faction>
    Factions = {},
    ---@type table<number, GLab.GameObject.Character>
    Characters = {},
}

local go_path = World.ThisPath .. "game_objects/"
World.GameObjectClasses = {}

GLab.LoadModule("base", go_path)
GLab.LoadModule("character", go_path)
GLab.LoadModule("faction", go_path)
GLab.LoadModule("settlement", go_path)

function World:init()

end

function World:__clear()

end

-- Get a FactionObject by key
function World:GetFaction(key)
    local o = self.GameObjects.Factions[key]
    if not o then
        o = self.GameObjectClasses.Faction:new(key)
        self.GameObjects.Factions[key] = o
    end

    return o
end

function World:GetLocalFaction()
    return World:GetFaction(cm:get_local_faction_name(true))
end

function World:GetCharacter(cqi)
    local o = self.GameObjects.Characters[cqi]
    if not o then
        o = self.GameObjectClasses.Character:new(cqi)
        self.GameObjects.Characters[cqi] = o
    end

    return o
end