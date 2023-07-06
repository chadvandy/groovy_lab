--- TODO prevent cyclical references (add a table that's indexed by table pointers, if they're already in there don't do it again?)
--- TODO only allow fields that start with __, only allow fields that don't, etc etc etc
--- TODO exempted indices (ie. don't print anything that does or doesn't match a pattern, etc)


--- @param t table
--- @param ignored_fields table<string>
--- @param loop_value number
--- @return table<string>
local function inner_loop_fast_print(t, ignored_fields, loop_value)
    --- @type table<any>
	local table_string = {'{\n'}
	--- @type table<any>
	local temp_table = {}
    for key, value in pairs(t) do
        table_string[#table_string + 1] = string.rep('\t', loop_value + 1)

        if type(key) == "string" then
            table_string[#table_string + 1] = '["'
            table_string[#table_string + 1] = key
            table_string[#table_string + 1] = '"] = '
        elseif type(key) == "number" then
            table_string[#table_string + 1] = '['
            table_string[#table_string + 1] = key
            table_string[#table_string + 1] = '] = '
        else
            table_string[#table_string + 1] = '['
            table_string[#table_string + 1] = tostring(key)
            table_string[#table_string + 1] = '] = '
        end

		if type(value) == "table" then
			temp_table = inner_loop_fast_print(value, ignored_fields, loop_value + 1)
			for i = 1, #temp_table do
				table_string[#table_string + 1] = temp_table[i]
			end
		elseif type(value) == "string" then
			table_string[#table_string + 1] = '[=['
			table_string[#table_string + 1] = value
			table_string[#table_string + 1] = ']=],\n'
		else
			table_string[#table_string + 1] = tostring(value)
			table_string[#table_string + 1] = ',\n'
		end
    end

	table_string[#table_string + 1] = string.rep('\t', loop_value)
    table_string[#table_string + 1] = "},\n"

    return table_string
end


--- @param t table
--- @param ignored_fields table<string>?
--- @return string
function GLab.print_table(t, ignored_fields)
    if not (type(t) == "table") then
        return ""
    end

    --- @type table<any>
    local table_string = {'{\n'}
	--- @type table<any>
	local temp_table = {}

    for key, value in pairs(t) do

        table_string[#table_string + 1] = string.rep('\t', 1)
        if type(key) == "string" then
            table_string[#table_string + 1] = '["'
            table_string[#table_string + 1] = key
            table_string[#table_string + 1] = '"] = '
        elseif type(key) == "number" then
            table_string[#table_string + 1] = '['
            table_string[#table_string + 1] = key
            table_string[#table_string + 1] = '] = '
        else
            --- TODO skip it somehow?
            table_string[#table_string + 1] = '['
            table_string[#table_string + 1] = tostring(key)
            table_string[#table_string + 1] = '] = '
        end

        if type(value) == "table" then
            temp_table = inner_loop_fast_print(value, ignored_fields, 1)
            for i = 1, #temp_table do
                table_string[#table_string + 1] = temp_table[i]
            end
        elseif type(value) == "string" then
            table_string[#table_string + 1] = '[=['
            table_string[#table_string + 1] = value
            table_string[#table_string + 1] = ']=],\n'
        elseif type(value) == "boolean" or type(value) == "number" then
            table_string[#table_string + 1] = tostring(value)
            table_string[#table_string + 1] = ',\n'
        else
            -- unsupported type, technically.
            table_string[#table_string+1] = "nil,\n"
        end
    end

    table_string[#table_string + 1] = "}\n"

    return table.concat(table_string)
end