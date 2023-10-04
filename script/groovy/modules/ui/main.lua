--- TODO UI module for GLab

---@class GLab.UI
local UI = {
    this_path = GLab.ThisPath(...),

    is_created = false,

    ---@type UIC # main holder for GLab buttons n' such.
    main_holder = nil,

    ---@type table<string, GLab.UI.Element>
    __elements = {},
}

GLab.UI = UI

--- TODO base class for UI elements
    --- OnClick
    -- resize, move, etc
    -- destroy

--- TODO UI element types
    --- TODO text button
    --- TODO text
    --- TODO button
    --- TODO text input
    --- TODO lists/listviews
    --- TODO panel
    --- TODO checkbox
    --- TODO radio button
    --- TODO dropdown
    --- TODO slider
    --- TODO progress bar
    --- TODO image
    --- TODO canvas
    --- TODO color picker

--- TODO UIC events

--- TODO popup

---@type GLab.UI.Element
UI.Element = GLab.LoadModule("ui_element", UI.this_path)

local this_path_types = UI.this_path .. "types/"
UI.Types = {
    ---@type GLab.UI.Text
    Text = GLab.LoadModule("text", this_path_types),
    ---@type GLab.UI.Button
    Button = GLab.LoadModule("button", this_path_types),

    Buttons = {
        ---@type GLab.UI.Button.Character
        Character = GLab.LoadModule("character", this_path_types .. "buttons/")
    }
}

--- Called when the UI module is loaded. Loads up all the necessary types and doo-dads.
function UI:Init()
    core:add_listener(
        "GLab.UI.OnClick",
        "ComponentLClickUp",
        function(context)
            return not is_nil(self.__elements[tostring(context.component)])
        end,
        function(context)
            UI:__OnClick(context.component)
        end,
        true
    )
end

---@param elem GLab.UI.Element
function UI:TrackElement(elem, addr)
    if is_nil(addr) then
        addr = tostring(elem:GetAddress())
    else
        addr = tostring(addr)
    end

    self.__elements[addr] = elem
end

function UI:NewButton(key, parent, icon, tooltip, template, size)
    local btn = self.Types.Button:New(key, parent, icon, tooltip, template, size)
    self:TrackElement(btn)

    return btn
end

function UI:NewCharacterButton(key, parent, character)
    local btn = self.Types.Buttons.Character:New(key, parent, character)
    self:TrackElement(btn)

    return btn
end

function UI:__OnClick(addr)
    local elem = self.__elements[tostring(addr)]
    if not elem then
        return
    end

    elem:__OnClick()
end

--- Triggered when the UI root is available to interact with.
function UI:Created()
    if self.is_created then
        return
    end
    
    self.is_created = true
    
    GLab.Log("UI Created!")
end

function UI:AddOnCreatedCallback(callback)
    if self.is_created then
        callback()
    else
        core:add_ui_created_callback(callback)
    end
end

local top_bar_callbacks = {}
---@param parent UIC
function UI:CreateTopBarHolder(parent)
    parent:SetVisible(true)

    self.main_holder = parent

    for _,callback in ipairs(top_bar_callbacks) do
        self:CreateTopBarButton(callback.name, callback.icon, callback.tooltip)
    end
end

---@param name string
---@param icon string
---@param tooltip string
function UI:CreateTopBarButton(name, icon, tooltip)
    if not is_uicomponent(self.main_holder) then
        -- GLab.Error("Tried to create a topbar button, but the topbar holder doesn't exist!")
        top_bar_callbacks[#top_bar_callbacks+1] = {
            name = name,
            icon = icon,
            tooltip = tooltip,
        }
        return
    end

    local button = core:get_or_create_component(name, "ui/templates/round_small_button", self.main_holder)

    button:SetImagePath(icon, 0)
    button:SetTooltipText(tooltip, true)

    button:SetVisible(true)

    return button
end

UI:Init()

if core:is_ui_created() then
    if core:is_battle() then
        local parent_component = find_uicomponent("menu_bar", "buttongroup")

        UI:Created()
        UI:CreateTopBarHolder(parent_component)
    end
else
    core:add_ui_created_callback(function()
    
        local parent_component = nil
    
        if core:is_frontend() then
            GLab.Log("Frontend!")
    
            -- parent_component = find_uicomponent("sp_frame", "menu_bar")

            local p = find_uicomponent("sp_frame")

            local old = find_uicomponent(p, "menu_bar")
            -- old:Destroy()

            local new = core:get_or_create_component("menu_bar_new", "ui/groovy/menu_bar", p)
            parent_component = find_uicomponent(new, "buttongroup")
        elseif core:is_campaign() then
            GLab.Log("Campaign!")
    
            parent_component = find_uicomponent("menu_bar", "buttongroup")
        elseif core:is_battle() then
            GLab.Log("Battle!")
    
            parent_component = find_uicomponent("menu_bar", "buttongroup")
        end
    
        if not parent_component then
            GLab.Log("Failed to find the parent component!")
            return
        end

        UI:CreateTopBarHolder(parent_component)
    end)
end
