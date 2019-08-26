local string_array = require("__stdlib__/stdlib/utils/classes/string_array")
local config = {
    ["enabled"] = {
        type = "checkbox",
        default = false,
        exclude = {"depot"}
    },
    ["resource"] = {
        type = "element",
        default = nil,
        exclude = {"depot"}
    },
    ["priority"] = {
        type = "text",
        default = 100,
        exclude = {"depot"},
        tooltip = {"samtrain.priority_tooltip"}
    },
    ["max_number_of_trains"] = {
        type = "text",
        default = 1,
        exclude = {"depot"},
        tooltip = {"samtrain.max_number_of_trains_tooltip"}
    },
    ["min_length"] = {
        type = "text",
        default = 2,
        tooltip = {"samtrain.min_length_tooltip"}
    },
    ["max_length"] = {
        type = "text",
        default = 6,
        tooltip = {"samtrain.max_length_tooltip"}
    },
	["timeout"] = {
		type = "slider",
		default = 120,
		tooltip = {"samtrain.timeout_tooltip"},
		exclude = {"depot"},
		enable_disable = true,
		options = {
			minimum_value = 1,
			maximum_value = 120,
		}
	},
	["count"] = {
		type = "text",
		default = nil,
		exclude = {"depot", "supplier"},
		enable_disable = true
	}
}

for name, data in pairs(config) do
    if data.exclude ~= nil then
        setmetatable(data.exclude, string_array)
    end
end

return config