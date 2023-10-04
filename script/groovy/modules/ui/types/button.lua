--- a standard button component; round or square, small medium or large, with a custom icon and tooltip

local BaseClass = GLab.UI.Element

---@alias GLab.UI.Button.Template "round"|"square"
---@alias GLab.UI.Button.Size "small"|"medium"|"large"

---@class GLab.UI.Button : GLab.UI.Element
local def = {
    -- ---@type UIC
    -- uic = nil,
    templates = {
        round = {
            small = "ui/templates/round_small_button",
            medium = "ui/templates/round_medium_button",
            large = "ui/templates/round_large_button",
        },
        square = {
            small = "ui/templates/square_small_button",
            medium = "ui/templates/square_medium_button",
            large = "ui/templates/square_large_button",
        },
    },
}

---@class GLab.UI.Button : GLab.UI.Element
local UI_Button = BaseClass:extend("UI_Button", def)

---@param key string
---@param parent UIC|GLab.UI.Element
---@param icon string
---@param tooltip string
---@param template GLab.UI.Button.Template
---@param size GLab.UI.Button.Size
function UI_Button:New(key, parent, icon, tooltip, template, size)
    local o = self:__new()
    o:Init(key, parent, icon, tooltip, template, size)
    return o
end

function UI_Button:Init(key, parent, icon, tooltip, template, size)
    if not is_uicomponent(parent) then
        GLab.Error("Tried to create a button, but the parent doesn't exist!")
        return
    end

    if not is_string(key) then
        GLab.Error("Tried to create a button, but the key is not a string!")
        return
    end

    if not is_string(icon) then
        GLab.Error("Tried to create a button, but the icon is not a string!")
        return
    end

    if not is_string(tooltip) then
        GLab.Error("Tried to create a button, but the tooltip is not a string!")
        return
    end

    if not is_string(template) then
        GLab.Error("Tried to create a button, but the template is not a string!")
        return
    end

    if not is_string(size) then
        GLab.Error("Tried to create a button, but the size is not a string!")
        return
    end

    if not self.templates[template] then
        GLab.Error("Tried to create a button, but the template doesn't exist!")
        return
    end

    if not self.templates[template][size] then
        GLab.Error("Tried to create a button, but the size doesn't exist!")
        return
    end

    local uic = core:get_or_create_component(key, self.templates[template][size], parent)
    uic:SetImagePath(icon, 0)
    uic:SetTooltipText(tooltip, true)

    self.uic = uic
    return self
end

return UI_Button