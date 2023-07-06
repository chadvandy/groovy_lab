---@alias UIComponent UIC
-- --- Helpers and extended functionality for using UIComponents, to prevent bugs and crashes and shit, or to make some stuff easier to do.

-- local log,logf,errlog,errlogf = get_vlog("[helpers]")

--- bloopy
---@param root UIC
---@param name string?
---@return UIC
local function create_dummy(root, name)
	name = is_string(name) and name or "script_dummy"
	local path = "ui/campaign ui/script_dummy"

	local dummy = core:get_or_create_component(name, path, root)

	return dummy
end

--- Delete one or many components!
---@param component UIC|UIC[]
function delete_component(component)
	local dummy = create_dummy(core:get_ui_root())

	if is_table(component) then
		for i = 1, #component do
			if is_uicomponent(component[i]) then
                dummy:Adopt(component[i]:Address())
			end
		end

        dummy:DestroyChildren()
	elseif is_uicomponent(component) then
		component:Destroy()
	end
end