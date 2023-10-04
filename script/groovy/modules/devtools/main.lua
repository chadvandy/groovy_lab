--- TODO put an info button
--- TODO MP support

local GLab = GLab
local this_path = GLab.ThisPath(...)

local UI = GLab.UI

---@class DevTools
local DevTools = {
	_name = "devtools",
	_layout_path = "ui/groovy/frames/devtools",
	_shortcut_to_open = "script_shift_F3", --- TODO expose to MCT
	_shortcut_to_execute = "script_shift_F4", --- TODO expose to MCT

	---@type UIC
	_frame = nil,

	---@type "lua"|"inspector"
	_open_tab = "lua",
}

---@type DevTools.Inspector
DevTools.Inspector = GLab.LoadModule("inspector", this_path)

---@type DevTools.Console
DevTools.Console = GLab.LoadModule("console", this_path)

function DevTools:create()
	self._button = GLab.UI:CreateTopBarButton("button_devtools", "ui/skins/default/icon_tech.png", "Lua Console")


    core:add_listener(
        "button_devtools_on_clicked",
        "ComponentLClickUp",
        function(context)
            return context.string == "button_devtools"
        end,
        function(context)
            self:swap_visibility()
        end,
        true
    )
	
	self._frame = core:get_or_create_component(self._name, self._layout_path)
	self._frame:SetMoveable(true)
	self._frame:SetDockingPoint(5)
	self._frame:SetVisible(false)

	local button_close = core:get_or_create_component("button_close", "ui/templates/round_small_button", self._frame)
	button_close:SetDockingPoint(3)
	button_close:SetDockOffset(-10, 10)
	button_close:SetImagePath("ui/skins/default/icon_cross.png")
	button_close:SetTooltipText("Close DevTools", true)

	self.Console:FirstFill(find_uicomponent(self._frame, "tab_lua"))
	self.Inspector:FirstFill(find_uicomponent(self._frame, "tab_inspector"))

	if __game_mode ~= __lib_type_campaign then
		local b = find_uicomponent(self._frame, "holder", "tab_button_inspector")
		b:SetState("inactive")
		b:SetTooltipText("Inspector is only available in Campaign!", true)

		find_uicomponent(self._frame, "tab_inspector"):SetVisible(false)

		self:apply_tab("lua")
	end

	self:init_listeners()
end

function DevTools:apply_tab(tab)
	-- local panel = find_uicomponent(self:get_frame(), "tab_"..tab)

	self._open_tab = tab

	if tab == "lua" then
		self.Console:Populate()
	elseif tab == "inspector" then
		self.Inspector:Populate()
	end
end

function DevTools:swap_visibility()
	local uic = self:get_frame()
	if uic then
		local b = not uic:Visible()
		uic:SetVisible(b)

		-- if b then self:set_current_line(1) end
	end
end

function DevTools:get_frame()
	return self._frame
end

function DevTools:init_listeners()
	core:add_listener(
		"lua_console_listener",
		"ShortcutPressed",
		function(context)
			return context.string == DevTools._shortcut_to_open or context.string == DevTools._shortcut_to_execute
		end,
		function(context)
			if context.string == self._shortcut_to_open then
				DevTools:swap_visibility()
			elseif context.string == self._shortcut_to_execute then
				if DevTools:get_frame():Visible() then
					DevTools.Console:execute()
				end
			end
		end,
		true
	);

	core:add_listener(
		"lua_console_lclickup",
		"ComponentLClickUp",
		function(context)
			return uicomponent_descended_from(UIComponent(context.component), DevTools._name)
		end,
		function(context)
			local id = context.string
			local uic = UIComponent(context.component)

			local p = UIComponent(uic:Parent())

			if uicomponent_descended_from(uic, self.Console.panel:Id()) then
				self.Console:OnClick(uic)
				return
			elseif uicomponent_descended_from(uic, self.Inspector.panel:Id()) then
				self.Inspector:OnClick(uic)
				return
			end

			--- TODO I'm too old to do an if/else string like this, clean up pls
			if id == "button_close" then
				DevTools:swap_visibility()
			elseif id == "tab_button_lua" then
				DevTools:apply_tab("lua")
			elseif id == "tab_button_inspector" then
				DevTools:apply_tab("inspector")
			end
		end,
		true
	)


	core:add_listener(
		"lua_console_moved",
		"ComponentMoved",
		function(context)
			return context.string == DevTools._name
		end,
		function(context)
			local uic = UIComponent(context.component)
			local x,y = uic:Position()

			local function f() uic:MoveTo(x, y) end
			local i = 5
			local k = "refresh_lua_console"
			
			---@type timer_manager
			local tm = core:get_static_object("timer_manager")
			tm:real_callback(f, i, k)
		end,
		true
	)
end

function console_print(t)
	vlog(t)
	DevTools.Console:print(t)
end

function console_printf(t, ...)
	vlogf(t, ...)
	DevTools.Console:printf(t, ...)
end

c_print = console_print 
c_printf = console_printf

function t_get(t, i)
	if not is_table(t) then return end
	-- if not is_number(i) and not is_string(i) then return end

	return t[i]
end

function t_set(t, i, v)
	if not is_table(t) then return end
	-- if not is_number(i) and not is_string(i) then return end
	
	t[i] = v
end

if not core:is_battle() then
	core:add_ui_created_callback(
		function()
			if core:is_campaign() then 
				cm:add_post_first_tick_callback(function()
					DevTools:create()
				end)
			elseif core:is_frontend() then
				DevTools:create()
			end
			-- end) if not ok then GLab.Log(err) end
	
			-- GLab.Log("Created")
		end
	);
else
	bm:register_phase_change_callback("Deployment", function() DevTools:create() end)
end