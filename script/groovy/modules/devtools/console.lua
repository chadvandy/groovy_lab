local GLab = GLab

-- The Singleton manager handling the Lua-Console side of the Devtools.

--- TODO add in "enter" support (not likely)
--- TODO resizable

---@class DevTools.Console
local defaults = {
    ---@type UIC
    frame = nil,
    ---@type UIC
    panel = nil,

    ---@type number The current line selected.
	_current_line = 0,

	---@type number The number of line components currently created
	_num_lines = 0,

	---@type number The last visible line, for when there are more lines created than visible. Only executes code up to this line.
	_last_visible_line = 0,

	---@type number The maximum number of lines. Currently effectively disabled, I don't think it's needed.
	_max_lines = 9000,

	_output_text = {},
}

---@class DevTools.Console
local Console = GLab.NewClass("Console", defaults)

---@param panel UIC
function Console:FirstFill(panel)
    self.frame = UIComponent(panel:Parent())
    self.panel = panel
	local listview = find_uicomponent(panel, "listview")

	local bottom_bar = core:get_or_create_component("bottom_bar", "ui/campaign ui/script_dummy", panel)
	bottom_bar:SetDockingPoint(8)
	bottom_bar:SetDockOffset(0, -10)
	bottom_bar:Resize(800, 40)

	local copy_paste_holder = core:get_or_create_component("copy_paste_holder", "ui/groovy/layouts/hlist", bottom_bar)
	copy_paste_holder:SetDockingPoint(4)
	copy_paste_holder:SetDockOffset(15, 0)
	copy_paste_holder:Resize(100, 40)

	local run_clear_holder = core:get_or_create_component("run_clear_holder", "ui/groovy/layouts/hlist", bottom_bar)
	run_clear_holder:SetDockingPoint(5)
	run_clear_holder:SetDockOffset(0, 0)
	run_clear_holder:Resize(550, 40)

	local add_remove_holder = core:get_or_create_component("add_remove_holder", "ui/groovy/layouts/hlist", bottom_bar)
	add_remove_holder:SetDockingPoint(6)
	add_remove_holder:SetDockOffset(-15, 0)
	add_remove_holder:Resize(100, 40)

	local button_add_line = core:get_or_create_component("button_add_line", "ui/templates/square_small_button", add_remove_holder)
	local button_remove_line = core:get_or_create_component("button_remove_line", "ui/templates/square_small_button", add_remove_holder)

	local button_copy = core:get_or_create_component("button_copy", "ui/templates/square_small_button", copy_paste_holder)
	local button_paste = core:get_or_create_component("button_paste", "ui/templates/square_small_button", copy_paste_holder)

	local button_run = core:get_or_create_component("button_run", "ui/templates/square_medium_text_button", run_clear_holder)
	local button_clear = core:get_or_create_component("button_clear", "ui/templates/square_medium_text_button", run_clear_holder)
	local button_show_output = core:get_or_create_component("button_show_output", "ui/templates/square_medium_text_button", run_clear_holder)

	button_run:Resize(180, 40)
	button_clear:Resize(180, 40)
	button_show_output:Resize(180, 40)

	find_uicomponent(button_run, "button_txt"):SetText("Run Code")
	find_uicomponent(button_clear, "button_txt"):SetText("Clear Code")
	find_uicomponent(button_show_output, "button_txt"):SetText("Show Output")

	find_uicomponent(button_copy, "icon"):SetVisible(false)
	find_uicomponent(button_paste, "icon"):SetVisible(false)
	find_uicomponent(button_add_line, "icon"):SetVisible(false)
	find_uicomponent(button_remove_line, "icon"):SetVisible(false)

	-- find_uicomponent(button_copy, "icon"):SetImagePath(common.get_context_value("AddDefaultSkinPath(\"icon_encyclopedia.png\")"))
	-- find_uicomponent(button_paste, "icon"):SetImagePath(common.get_context_value("AddDefaultSkinPath(\"icon_rename.png\")"))
	button_copy:SetImagePath("ui/skins/default/icon_encyclopedia.png")
	button_paste:SetImagePath("ui/skins/default/icon_rename.png")
	button_add_line:SetImagePath("ui/skins/default/icon_plus_small.png")
	button_remove_line:SetImagePath("ui/skins/default/icon_minus_small.png")

	button_copy:SetTooltipText("Copy the contents of the Lua Console to the clipboard.", true)
	button_paste:SetTooltipText("Paste the contents of your clipboard to the Lua Console.\nBegins pasting on the first line after your existing code; if there aren't available lines, they will be created.", true)
	button_add_line:SetTooltipText("Add a new line.", true)
	button_remove_line:SetTooltipText("Remove the final line (text will be preserved, but not executed).", true)

	button_copy:SetCanResizeWidth(true) button_copy:SetCanResizeHeight(true)
	button_paste:SetCanResizeWidth(true) button_paste:SetCanResizeHeight(true)
	button_add_line:SetCanResizeWidth(true) button_add_line:SetCanResizeHeight(true)
	button_remove_line:SetCanResizeWidth(true) button_remove_line:SetCanResizeHeight(true)

	local w,h = 36,36

	button_copy:Resize(w, h)
	button_paste:Resize(w, h)
	button_add_line:Resize(w, h)
	button_remove_line:Resize(w, h)

	--- TODO text input
	self:create_output_panel()
	self:setup_text_input()
end

function Console:create_output_panel()
	local output_panel = core:get_or_create_component("output_panel", "ui/groovy/frames/basic", self.panel)
	output_panel:SetDockingPoint(6+9)
	output_panel:SetDockOffset(5, 0)
	output_panel:Resize(500, 400)
	output_panel:SetVisible(false)

	local panel_title = find_uicomponent(output_panel, "panel_title")
	panel_title:SetVisible(false)

	local textview = core:get_or_create_component("textview", "ui/groovy/layouts/textview", output_panel)
	textview:SetDockingPoint(2)
	textview:SetDockOffset(0, 15)
	textview:Resize(output_panel:Width() * 0.95, output_panel:Height() * 0.8)

	local text = find_uicomponent(textview, "text")
	text:SetText("")

	local action_bar = core:get_or_create_component("action_bar", "ui/groovy/layouts/hlist", output_panel)
	action_bar:SetDockingPoint(8)
	action_bar:SetDockOffset(0, -10)
	action_bar:Resize(output_panel:Width() * 0.95, 40)

	local button_clear = core:get_or_create_component("button_clear_output", "ui/templates/square_medium_text_button", action_bar)
	button_clear:Resize(180, 40)
	find_uicomponent(button_clear, "button_txt"):SetText("Clear Output")
end

function Console:set_output_panel_visibility(b)
	local output_panel = find_uicomponent(self.frame, "output_panel")
	local button = find_uicomponent(self.frame, "tab_lua", "run_clear_holder", "button_show_output", "button_txt")

	if not is_boolean(b) then
		b = not output_panel:Visible()
	end

	output_panel:SetVisible(b)

	if b == true then
		button:SetText("Hide Output")
	else
		button:SetText("Show Output")
	end
end

function Console:setup_text_input()
	for i = 1, 15 do
		self:create_text_line(i)
	end

	self:set_current_line(1)
end

---@return UIC
function Console:create_text_line(i)
	local listview = find_uicomponent(self.frame, "listview")
	local text_box = find_uicomponent(listview, "list_clip", "list_box")

	if not i then i = self._num_lines + 1 end
	if i >= self._max_lines then return find_uicomponent(text_box, "line_"..self._max_lines) end

	local extant = find_uicomponent(text_box, "line_"..i)
	if is_uicomponent(extant) then
		if extant:Visible() then return extant end
		extant:SetVisible(true)
		self._last_visible_line = i
		return extant
	end

	local w,h = listview:Dimensions()
	local hi = h/15
	local wi = w*.9

	---@type UIC
	GLab.Log("Creating line_"..i)
	local text_holder = core:get_or_create_component("line_"..i, "ui/campaign ui/script_dummy", text_box)
	text_holder:Resize(wi, hi)
	text_holder:SetDockingPoint(1)
	
	local line_text = core:get_or_create_component("num_text", "ui/groovy/text/fe_bold", text_holder)
	local cw = line_text:Width()*1.5
	line_text:Resize(cw, hi)
	line_text:SetDockingPoint(4)
	line_text:SetDockOffset(0, 0)
	line_text:SetText(tostring(i)..":")

	line_text:SetTextVAlign("centre")

	local tw = line_text:TextDimensions()
	
	local text_input = core:get_or_create_component("text_input", "ui/groovy/text_box", text_holder)
	text_input:SetCanResizeHeight(true) text_input:SetCanResizeWidth(true)
	text_input:Resize(wi-tw-10, hi)
	text_input:SetDockingPoint(4)
	text_input:SetDockOffset(tw+10, 0)

	text_input:SetCanResizeHeight(false) text_input:SetCanResizeWidth(false)

	self._num_lines = i
	self:show_line(i)

	text_box:Layout()

	return text_input
end

--- Hide the final line in the block. Keeps the line created, so it can be re-added and 
---@param i any
function Console:remove_line(i)
	if not i then i = self._last_visible_line end

	if i <= 5 then return end

	local input = find_uicomponent(self.frame, "listview", "list_clip", "list_box")
	local line = find_uicomponent(input, "line_"..i)
	if is_uicomponent(line) then
		line:SetVisible(false)
		self._last_visible_line = i - 1
		return true
	end

	return false
end

function Console:show_line(i)
	if not i then i = self._last_visible_line + 1 end


	local input = find_uicomponent(self.frame, "listview", "list_clip", "list_box")
	local line = find_uicomponent(input, "line_"..i)
	if is_uicomponent(line) then
		line:SetVisible(true)
		self._last_visible_line = i
		return true
	end

	return false
end

function Console:set_current_line(i)
	if not is_number(i) then
		--- errmsg
		return false
	end
	
	local input = self:get_text_input(i)
	if not input then
		input = self:create_text_line(i)
	end

	self._current_line = i
	input:SimulateLClick()
end

---@return UIC?
function Console:get_text_input(i)
	if not i then i = 1 end
	local entry_box = find_uicomponent(self.frame, "listview", "list_clip", "list_box")
	local text_input = find_uicomponent(entry_box, "line_"..i, "text_input")

	if not text_input then
		--- TODO error? return 1?
		GLab.Log("Can't find text input " .. i)
		return
	end

	return text_input
end

function Console:display_output_text()
	local textview = find_uicomponent(self.frame, "output_panel", "textview")
	local text_uic = find_uicomponent(textview, "text")

	local t = table.concat(self._output_text, "\n")
	text_uic:SetStateText(t)
end

function Console:add_output_text(t)
	self._output_text[#self._output_text+1] = tostring(t)
	self:display_output_text()
end

function Console:clear_output_text()
	self._output_text = {}
	self:display_output_text()
end

function Console:get_text(visible_only)
	local num_lines = self._num_lines
	local str = ""

	if visible_only then num_lines = self._last_visible_line end

	for i = 1, num_lines do
		local line = self:get_text_input(i)
        if line then
            local t = line:GetStateText()
            if t ~= "" then
                if i ~= 1 then str = str .. "\n" end
                str = str .. t
            end
        end
	end

	return str
end

function Console:set_visible_up_to_line(i)
	if not i then i = self._num_lines end
	if i < self._last_visible_line then i = self._last_visible_line end

	for j = 1, i do
		self:show_line(j)
	end
end

--- Grab the final line with any user input within.
---@param visible_only boolean? If we should check all lines, or just currently visible ones.
---@return integer
function Console:get_last_used_line(visible_only)
	local start = visible_only and self._last_visible_line or self._num_lines
	local last_line

	for i = start, 1, -1 do
		local line = self:get_text_input(i)
		if line then
			local text = line:GetStateText()
			
			if text ~= "" then
				break
			end
			
			last_line = i
		end
	end

	return last_line
end

function Console:copy_to_clipboard()
	local text = self:get_text(true)
	-- ModLog("Copying to Clipboard: \n" .. text)

	common.set_context_value("CcoScriptObject", "LuaConsoleText", text)
	common.call_context_command("CcoScriptObject", "LuaConsoleText", "CopyStringToClipboard(StringValue)")
end

local function string_split(str, delimiter)
	local result = { }
	local from  = 1
	local delim_from, delim_to = string.find( str, delimiter, from  )
	while delim_from do
		table.insert( result, string.sub( str, from , delim_from-1 ) )
		from  = delim_to + 1
		delim_from, delim_to = string.find( str, delimiter, from  )
	end
	table.insert( result, string.sub( str, from  ) )
	return result
end

--- TODO issue if you have 10 lines written, hide the last 2, and then try to paste - it will paste at 11, but will still have 9-10 hidden.
function Console:paste_from_clipboard()
	-- ModLog("Pasting from clipboard!")

	--- get the last line that is untouched
	local last_line = self:get_last_used_line()
	if not last_line then
		self:create_text_line()
		last_line = self._num_lines
	end

	self:set_visible_up_to_line(last_line)

	-- ModLog("Pasting from clipboard - last line with stuff is " .. last_line)

	-- starting from the last untouched line, loop and paste.
	local clipboard = common.get_context_value("PasteStringFromClipboard")
	local tab = string_split(clipboard, "\n")
	
	-- ModLog("Clipboard text is " .. clipboard)
	-- ModLog("Number of lines: "..#tab)

	for i = 1, #tab do
		local this_line = last_line + (i-1)
		ModLog("Pasting on line " .. this_line)
		self:create_text_line(this_line)
		local line = self:get_text_input(this_line)
        if line then
            line:SetStateText(tab[i])
        end
	end
end

function Console:clear_text()
	for i = 1, self._num_lines do 
		local input = self:get_text_input(i)
        if input then
            input:SetStateText("")
        end
	end
	
	self:set_current_line(1)
end

--- TODO print out to a logfile as well.

--- TODO trigger errors as you type?
--- TODO stack print results!
--- Make use of the error popup to print return values
function Console:print(text)
	self:add_output_text(text)
end

function Console:printf(text, ...)
	text = string.format(text, ...)
	self:print(text)
end

function Console:execute()
	GLab.Log("Executing")
	local text = self:get_text(true)

	GLab.Log("Executing text: " .. text)

    local func, err = loadstring(text);
    
    if not func then 
		script_error("ERROR: Lua Console attempted to run a script command but an error was reported when loading the command string into a function. Command and error will follow this message.");
		GLab.Log("Command:");
		GLab.Log(text);
		GLab.Log("Error:");
		GLab.Log(err);
		self:printf("[[col:red]] Error: %s[[/col]]", err)
		return;
	end

	local env = core:get_env()
    setfenv(func, env);
    
    local ok, result = pcall(func);

	if not ok then 
		script_error("ERROR: Lua Console attempted to run a script command but an error was reported when executing the function. Command and error will follow this message.");
		GLab.Log("Command:");
		GLab.Log(text);
		GLab.Log("Error:");
		GLab.Log(result);
		self:printf("[[col:red]] Error: %s[[/col]]", result)
		return
	else
		if result then
			self:print(tostring(result))
		end
	end;
end

function Console:Populate()

end

---@param uic UIC
function Console:OnClick(uic)
    local id = uic:Id()
    if id == "button_run" then
        self:execute()
    elseif id == "button_clear" then
        self:clear_text()
    elseif id == "button_clear_output" then
        self:clear_output_text()
    elseif id == "button_show_output" then
        self:set_output_panel_visibility()
    elseif id == "button_add_line" then
        if not self:show_line() then
            self:create_text_line()
        end
    elseif id == "button_remove_line" then
        self:remove_line()
    elseif id == "button_copy" then
        local ok, err = pcall(function()
            self:copy_to_clipboard()
        end) if not ok then ModLog(err) end
    elseif id == "button_paste" then
        local ok, err = pcall(function()
            self:paste_from_clipboard()
        end) if not ok then ModLog(err) end
    end
end

return Console