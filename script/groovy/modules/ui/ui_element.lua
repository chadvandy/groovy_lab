--- base class for UI Elements.

---@class GLab.UI.Element : Class
local def = {
    ---@type UIC
    uic = nil,

    __OnClick = function() end,
}

---@class GLab.UI.Element : Class
local UI_Element = GLab.NewClass("UI_Element", def)

function UI_Element:New()
    local o = self:__new()
    o:Init()
    return o
end

function UI_Element:Init(name, parent, template)
    local uic = core:get_or_create_component(name, template, parent)
    
    self.uic = uic
    return self
end

function UI_Element:GetUic()
    --- TODO return a null object if nil
    return self.uic
end

function UI_Element:GetAddress()
    return self:GetUic():Address()
end

function UI_Element:Destroy()
    self:GetUic():Destroy()
end

function UI_Element:Show()
    self:GetUic():SetVisible(true)
end

function UI_Element:Hide()
    self:GetUic():SetVisible(false)
end

function UI_Element:ToggleVisibility()
    self:GetUic():SetVisible(not self:GetUic():Visible())
end

function UI_Element:IsVisible()
    return self:GetUic():Visible()
end

function UI_Element:MoveTo(x, y)
    self:GetUic():MoveTo(x, y)
end

function UI_Element:Resize(w, h)
    self:GetUic():Resize(w, h)
end

function UI_Element:MoveAndResize(x, y, w, h)
    self:GetUic():MoveTo(x, y)
    self:GetUic():Resize(w, h)
end

function UI_Element:MoveRelative(uic, x, y)
    if is_uicomponent(uic) then
        local uic_x, uic_y = uic:Position()
        x = x + uic_x
        y = y + uic_y
    elseif uic.className == "UI_BaseClass" then
        local uic_x, uic_y = uic:GetUic():Position()
        x = x + uic_x
        y = y + uic_y
    end

    self:GetUic():MoveTo(x, y)
end

function UI_Element:Center()
    self:GetUic():SetDockingPoint(5)
    self:GetUic():SetDockOffset(0, 0)
end

function UI_Element:OnClick(f)
    if not is_function(f) then return end
    self.__OnClick = f
end


return UI_Element