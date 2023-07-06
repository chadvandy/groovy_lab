--- TODO system for creating logfiles

GLab.Log("param to logging file: " .. (...))
local this_path = GLab.ThisPath(...)
GLab.Log("We've loaded the logging module main file!")
GLab.Log("This path is: " .. this_path)

local sub = GLab.LoadModule("sub", this_path)
GLab.Log(sub)