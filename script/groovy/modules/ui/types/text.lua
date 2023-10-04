local BaseClass = GLab.UI.Element

---@class GLab.UI.Text : GLab.UI.Element
local def = {
    ---@type UIC
    uic = nil,
}

---@class GLab.UI.Text : GLab.UI.Element
local UI_Text = BaseClass:extend("Text", def)

function UI_Text:New(name, parent, text)
    local o = self:__new()
    o:Init(name, parent, text)
    return o
end

function UI_Text:Init(name, parent, text)
    local uic = core:get_or_create_component(name, "ui/groovy/text/fe_default", parent)
    uic:SetText(text)

    self.uic = uic
    return self
end

return UI_Text