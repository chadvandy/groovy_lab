--- a standard button component; round or square, small medium or large, with a custom icon and tooltip

local BaseClass = GLab.UI.Element

---@class GLab.UI.Button.Character : GLab.UI.Element
local def = {
    -- ---@type UIC
    -- uic = nil,
    template = "ui/groovy/game_objects/character",

    __show_rank_icon = true,
}

---@class GLab.UI.Button.Character : GLab.UI.Element
local UIE = BaseClass:extend("UI_Button_Character", def)

---@param key string
---@param parent UIC|GLab.UI.Element
---@param character ComponentContextObject
function UIE:New(key, parent, character)
    local o = self:__new()
    o:Init(key, parent, character)
    return o
end

---@param key string
---@param parent UIC|GLab.UI.Element
---@param character ComponentContextObject
function UIE:Init(key, parent, character)
    if not is_uicomponent(parent) then
        GLab.Error("Tried to create a button, but the parent doesn't exist!")
        return
    end

    if not is_string(key) then
        GLab.Error("Tried to create a button, but the key is not a string!")
        return
    end

    self:CreateComponent(key, parent, character)
    local uic = find_uicomponent(self:GetUic(), "button")
    
    GLab.UI:TrackElement(self, uic:Address())

    return self
end

function UIE:CreateComponent(key, parent, character)
    self.uic = core:get_or_create_component(key, self.template, parent)
    self:SetCharacter(character)
    self:ShowRankIcon(self.__show_rank_icon)
end

function UIE:ShowRankIcon(b)
    self.__show_rank_icon = b

    local icon = find_uicomponent(self.uic, "rank_dspl_small")
    icon:SetVisible(b)
end

function UIE:SetCharacter(cco_this)
    self.uic:SetContextObject(cco_this)
end

return UIE