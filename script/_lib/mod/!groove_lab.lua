--- Create a new class object!
---@type fun(className:string,attr:table) : Class
local new_class = require "script.groovy.includes.30-log"

local path_of_groove = "script/groovy/"

do
    local Old = ModLog
    function ModLog(text)
        Old(tostring(text))
    end
end

---@class GLab : Class
local defaults = {
    ---@type table<string, GLab.Log>
    logs = {
        -- lib = nil,
    },

    --- TODO pointers for all of the currently loaded modules
    _Modules = {},
}

---@class GLab : Class
GLab = new_class("GLab", defaults)

---@type json
GLab.Json = require "script.groovy.includes.json"

---@class GLab.Log : Class
local log_defaults = {
    prefix = "[lib]",
    show_time = true,

    current_tab = 0,

    lines = {},
    
    file_name = "",

    enabled = true,

    ---@type file*
    file = nil,
}

---@class GLab.Log : Class
---@field __new fun():GLab.Log
local Log = new_class("GLab_Log", log_defaults)

--- Create a new Log Object.
---@param key string
---@param file_name string?
---@param prefix string?
function Log.new(key, file_name, prefix)
    local o = Log:__new()
    ---@cast o GLab.Log
    o:init(key, file_name, prefix)

    return o
end

function Log:init(key, file_name, prefix)
    self.key = key
    self.file_name = file_name or "logging.txt"
    self.prefix = prefix or "[lib]"

    --- TODO some test to see if this file was made in this session
    local file = io.open(self.file_name, "w+")
    self.file = file
end

function Log:__call(...)
    self:log(...)
end

function Log:get_tabs()
    local t = ""
    for i = 1,self.current_tab do
        t = t .. "\t"
    end

    return t
end

function Log:log(t, ...)
    if not self.enabled then return end

    --- TODO prevent errors if the string fails to format (ie. you pass a %s but no varargs)
    if ... then
        t = string.format(t, ...)
    end

    t = string.format("\n%s %s%s", self.prefix, self:get_tabs(), t)

    self.lines[#self.lines+1] = t
    self.file:write(t)
end

function Log:set_enabled(b)
    if not is_boolean(b) then b = true end

    self.enabled = b
end

--- Change the tab amount for this log.
---@param change number? The amount to change the tabs by (ie. -1, 1). Defaults to 1 if left blank.
function Log:tab(change)
    if not is_number(change) then change = 1 end
    self.current_tab = self.current_tab + change
end

--- Set the absolute amount for the tab.
---@param tab_amount number? The number of tabs to force, ie. if 4 is used then 4 tabs will be printed. Defaults to 0.
function Log:tab_abs(tab_amount)
    if not is_number(tab_amount) then tab_amount = 0 end
    self.current_tab = tab_amount
end

function GLab.FlushLogs()
    for _,log in pairs(GLab.logs) do
        log.file:flush()
    end
end

function GLab.init()
    --- TODO print
    GLab.logs.lib = GLab.NewLog("lib", "!groove_log.txt")

    local function start_flush()
        core:get_tm():repeat_real_callback(function()
            GLab.FlushLogs()
        end, 10, "GLab_logging")
    end 

    if core:is_campaign() then
        cm:add_first_tick_callback(start_flush)
    else
        start_flush()
    end

    GLab.LoadInternalModules()
end

--- Create a new Class object, which can be used to simulate OOP systems.
---@generic T : Class
---@param key string The name of the Class object.
---@param params T #An optional table of defaults to assign to the Class and every Instance of it.
---@return T
function GLab.NewClass(key, params)
    if not params then params = {} end
    return new_class(key, params)
end

--- Create a new Log Object.
---@param key string
---@param file_name string?
---@param prefix string?
function GLab.NewLog(key, file_name, prefix)
    if GLab.logs[key] then
        return GLab.logs[key]
    end

    --- TODO errcheck the types
    local o = Log.new(key, file_name, prefix)
    GLab.logs[key] = o

    return o
end

--- Get the @LogObj with this name.
---@param name string? The name of the log object when created. Leave blank to get the default one.
---@return GLab.Log?
function GLab.GetLog(name)
    if not is_string(name) then name = "lib" end
    local t = GLab.logs[name]
    if t then
        return t
    end

    GLab.Warn("Tried to get a Log with the name %s but none was found. Returning the default log object.", name)
end

function GLab.Log(t, ...)
    GLab.logs.lib:log(t, ...)
end

function GLab.Warn(t, ...)
    GLab.logs.lib:log("WARNING!\n" .. t, ...)
end

function GLab.Error(t, ...)
    GLab.logs.lib:log("ERROR!\n" .. t, ...)
    GLab.logs.lib:log(debug.traceback(1))
end

--- TODO handle the internal loading of modules!
function GLab.LoadInternalModules()
    local helpers_path = path_of_groove .. "helpers/"
    local modules_path = path_of_groove .. "modules/"

    --- Load all Helper files.
    GLab.LoadModules(helpers_path, "*.lua", nil, function(f, err) GLab.Error("Failed to load helper file %s! Error:\n%s", f, err) end)
    
    -- get individual modules!
    local function m(p) return modules_path .. p .. "/" end

    -- Load all main.lua files in the modules folder.
    GLab.LoadModules(modules_path, "*/main.lua", nil, function(f, err) GLab.Error("Failed to load module %s! Error:\n%s", f, err) end)
    
    -- GLab.LoadModule("main", m("mp_communicator"))

    -- --- load up MCT
    -- --- TODO make this prettier; provide a path and autoload main.lua?
    -- local mct = GLab.LoadModule("main", m("mct"))

    -- ---@type CommandManager
    -- GLab.CommandManager = GLab.LoadModule("main", m("command_manager"))
    -- GLab.CommandManager:init()
end

--- Load a single file, and return its contents.
---@param module_name string The name of the file, without the ".lua" extension
---@param path string The path to the file, from .pack.
---@return any
function GLab.LoadModule(module_name, path)
    local full_path = path .. module_name .. ".lua"

    if GLab._Modules[full_path] then
        vlogf("Found an existing module %s! Returning that! Yay!", module_name)
        return GLab._Modules[full_path]
    end

    vlogf("Loading module w/ full path %q", full_path)
    local file, load_error = loadfile(full_path)

    if not file then
        verr("Attempted to load module with name ["..module_name.."], but loadfile had an error: ".. load_error .."")
        --return
    else
        vlog("Loading module with name [" .. module_name .. ".lua]")

        local global_env = core:get_env()
        setfenv(file, global_env)

        -- passing the `file` chunk any parameters turn into the vararg accessible in that file! Useful for localizing file paths.
        local lua_module = file(full_path)

        if lua_module ~= false then
            vlog("[" .. full_path .. "] loaded successfully!")
        end

        GLab._Modules[full_path] = lua_module

        return lua_module
    end

    local ok, msg = pcall(function() require(module_name) end)

    if not ok then
        verr("Tried to load module with name [" .. module_name .. ".lua], failed on runtime. Error below:")
        verr(msg)
        return false
    end
end

--- Load every file, and return the Lua module, from within the folder specified, using the pattern specified.
---@param path string The path you're checking. Local to data, so if you're checking for any file within the script folder, use "script/" as the path.
---@param search_override string The file you're checking for. I believe it requires a wildcard somewhere, "*", but I haven't messed with it enough. Use "*" for any file, or "*.lua" for any lua file, or "*/main.lua" for any file within a subsequent folder with the name main.lua.
---@param func_for_each fun(filename:string, module:table)? Code to run for each module loaded.
---@param fail_func fun(filename:string, err:string)? Code to run if a module fails.
function GLab.LoadModules(path, search_override, func_for_each, fail_func)
    if not search_override then search_override = "*.lua" end
    vlogf("Checking %s for all %s files!", path, search_override)

    local file_str = common.filesystem_lookup(path, search_override)
    vlogf("\tFound: %s", file_str)
    
    for filename in string.gmatch(file_str, '([^,]+)') do
        vlogf("\tLoading module %s", filename)
        local filename_for_out = filename

        local pointer = 1
        while true do
            local next_sep = string.find(filename, "\\", pointer) or string.find(filename, "/", pointer)

            if next_sep then
                pointer = next_sep + 1
            else
                if pointer > 1 then
                    filename = string.sub(filename, pointer)
                end
                break
            end
        end

        local suffix = string.sub(filename, string.len(filename) - 3)

        if string.lower(suffix) == ".lua" then
            filename = string.sub(filename, 1, string.len(filename) -4)
        end

        if not fail_func then
            fail_func = function(f, err) 
                verr("Failed to load module: " .. f)
                verr(err)
            end
        end

        GLab.CurrentlyLoadingFile = {
            name = filename,
            path = filename_for_out,
        }

        local module
        local ok, err = pcall(function()
            module = GLab.LoadModule(filename, string.gsub(filename_for_out, filename..".lua", ""))
            if func_for_each and is_function(func_for_each) then
                func_for_each(filename, module)
            end
            
        end)
        
        if not ok then
            ---@cast err string
            verr(err)
            fail_func(filename, err)
        end
    end

    GLab.CurrentlyLoadingFile = {}
end

--- (...) converts the full path of this file (ie. script/folder/folders/this_file.lua) to just the path leading to specifically this file (ie. script/folder/folders/), to grab subfolders easily while still allowing me to restructure this entire mod four times a year!
---@return string #Full path for this file!
function GLab.ThisPath(...)
    local s = (...)
    local path = string.gsub(s, "[^/\\]+$", "")
    return path
end

function GLab.CopyToClipboard(txt)
    assert(is_string(txt), "You must pass a string to the clipboard!")

    common.set_context_value("CcoScriptObject", "GLibClipboard", txt)
    common.call_context_command("CcoScriptObject", "GLibClipboard", "CopyStringToClipboard(StringValue)")
end

--- Investigate an object and its metatable, and log all functions found.
---@param obj userdata
function GLab.Investigate(obj, name)
    if not name then name = "Unknown Object" end

    local l = GLab.Log

    l("Investigating object: %s", name)

    local mt = getmetatable(obj)

    if mt then
        for k,v in pairs(mt) do
            if is_function(v) then
                l("\tFound " .. name.."."..k.."()")
            elseif k == "__index" then
                l("\tIn index!")
                for ik,iv in pairs(v) do
                    if is_function(iv) then
                        l("\t\tFound " .. name.."."..ik.."()")
                    else
                        l("\t\tFound " .. name.."."..ik)
                    end
                end
            else
                l("\tFound " .. name.."."..k)
            end
        end
    end
end

function get_vlog(prefix)
    if not is_string(prefix) then prefix = "[lib]" end

    return --- Return log,logf,err,errf
        function(text) GLab.Log(prefix .. " " .. text) end,
        function(text, ...) GLab.Log(prefix .. " " .. text, ...) end,
        function(text) GLab.Error(prefix .. " " .. text) end,
        function(text, ...) GLab.Error(prefix .. " " .. text, ...) end
end

function vlog(text)
    GLab.Log(text)
end

function vlogf(text, ...)
    GLab.Log(text, ...)
end

function verr(text)
    GLab.Error(text)
end

function verrf(text, ...)
    GLab.Error(text, ...)
end

function GLab.EnableInternalLogging(b)
    GLab.logs.lib:set_enabled(b)
end

function GLab.EnableGameLogging(b)
    if b then
        -- Already enabled!
        if __write_output_to_logfile == true then
            return
        end

        __write_output_to_logfile = true

        -- if the logfile wasn't made yet, set it to the default.
        if __logfile_path == "" then
            -- Set the path to script_log_DDMMYY_HHMM.txt, based on the time this session was started (current_time - run_time)
            __logfile_path = "script_log_" .. os.date("%d".."".."%m".."".."%y".."_".."%H".."".."%M", os.time() - os.clock()) .. ".txt"

            local file, err_str = io.open(__logfile_path, "w");
	
            if not file then
                __write_output_to_logfile = false;
                script_error("ERROR: tried to create logfile with filename " .. __logfile_path .. " but operation failed with error: " .. tostring(err_str));
            else
                file:write("\n");
                file:write("creating logfile " .. __logfile_path .. "\n");
                file:write("\n");
                file:close();
                _G.logfile_path = __logfile_path;
            end;
        end
    else
        __write_output_to_logfile = false
    end
end

core:add_listener(
    "MctInitialized",
    "MctInitialized",
    true,
    function()
        local mod = get_mct():get_mod_by_key("mct_mod")
        local lib_logging = mod:get_option_by_key("lib_logging")
        local game_logging = mod:get_option_by_key("game_logging")

        -- if __write_output_to_logfile is already set, we can assume the user has already enabled it, so we should disable these functions.
        if __write_output_to_logfile then
            function GLab.EnableGameLogging() end

            game_logging:set_locked(true, "Another mod has already enabled game logging!")
        else
            game_logging:set_locked(false)
        end

        GLab.EnableInternalLogging(lib_logging:get_finalized_setting())
        GLab.EnableGameLogging(game_logging:get_finalized_setting())
    end,
    true
)

core:add_listener(
    "MctFinalized",
    "MctFinalized",
    true,
    function()
        local mod = get_mct():get_mod_by_key("mct_mod")
        local lib_logging = mod:get_option_by_key("lib_logging")
        local game_logging = mod:get_option_by_key("game_logging")

        GLab.EnableInternalLogging(lib_logging:get_finalized_setting())
        GLab.EnableGameLogging(game_logging:get_finalized_setting())
    end,
    true
)

GLab.init()

-- Backwards compat
VLib = GLab
GLib = GLab