local table = require("__stdlib__/stdlib/utils/table")

function add_to_list_of_lists(list, key, item)
    if list[key] == nil then
        list[key] = {}
        table.insert(list[key], item)
    else
        local exists = table.any(list[key], function(i) return i == item end)
        if not exists then
            table.insert(list[key], item)
        end
    end
end

function add_to_list_of_lists_of_lists(list, key, key2, item)
    if list[key] == nil then
        list[key] = {}
    end

    add_to_list_of_lists(list[key], key2, item)
end

function remove_from_list_of_lists(list, key, item)
    if list[key] then
        remove_from_list(list[key], item)

        if table.is_empty(list[key]) then
            list[key] = nil
        end
    end
end

function remove_from_list_of_lists_of_lists(list, key, key2, item)
    if list[key] then
        remove_from_list_of_lists(list[key], key2, item)

        if table.is_empty(list[key]) then
            list[key] = nil
        end
    end
end

function remove_from_list(list, item)
    for index, i in pairs(list) do
        if i == item then
            table.remove(list, index)
            return
        end
    end
end

function cleanup_list_of_lists(list, validCallback)
	for key, outer_list in pairs(list) do
		for index, item in pairs(outer_list) do
			if not validCallback(item) then
				list[key][index] = nil
			end
		end
	end
end

function cleanup_list_of_lists_of_lists(list, validCallback)
	for _, key in pairs(list) do
		if list[key] then
			cleanup_list_of_lists(list[key], validCallback)
		end
	end
end

return {
    add_to_list_of_lists = add_to_list_of_lists,
    add_to_list_of_lists_of_lists = add_to_list_of_lists_of_lists,
    remove_from_list = remove_from_list,
    remove_from_list_of_lists = remove_from_list_of_lists,
    remove_from_list_of_lists_of_lists = remove_from_list_of_lists_of_lists,
	cleanup_list_of_lists = cleanup_list_of_lists,
	cleanup_list_of_lists_of_lists = cleanup_list_of_lists_of_lists
}
