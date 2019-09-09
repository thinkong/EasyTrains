local string_array = require("__stdlib__/stdlib/utils/classes/string_array")
local config = {
    ["enabled"] = {
		short_name = "e",
        type = "checkbox",
        default = false,
        exclude = {"depot"}
    },
    ["resource"] = {
		short_name = "r",
        type = "element",
        default = nil,
        exclude = {"depot"}
    },
    ["priority"] = {
		short_name = "p",
        type = "text",
        default = 100,
        exclude = {"depot"},
        tooltip = {"samtrain.priority_tooltip"}
    },
    ["max_number_of_trains"] = {
		short_name = "t",
        type = "text",
        default = 1,
        exclude = {"depot"},
        tooltip = {"samtrain.max_number_of_trains_tooltip"}
    },
    ["min_length"] = {
		short_name = "min",
        type = "text",
        default = 2,
        tooltip = {"samtrain.min_length_tooltip"}
    },
    ["max_length"] = {
		short_name = "max",
        type = "text",
        default = 6,
        tooltip = {"samtrain.max_length_tooltip"}
    },
	["count"] = {
		short_name = "c",
		type = "text",
		default = nil,
		tooltip = {"samtrain.count_tooltip"},
		exclude = {"depot", "supplier"},
		enable_disable = true
	},
	["timeout"] = {
		short_name = "to",
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
	["warning_timeout"] = {
		short_name = "wto",
		type = "slider",
		default = 120,
		tooltip = {"samtrain.warning_timeout_tooltip"},
		exclude = {"depot"},
		enable_disable = true,
		options = {
			minimum_value = 1,
			maximum_value = 600
		}
	}
}

for name, data in pairs(config) do
    if data.exclude ~= nil then
        setmetatable(data.exclude, string_array)
    end
end

return config