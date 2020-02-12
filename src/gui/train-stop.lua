local function update_value(player_index, name, value)
	if not global.gui[player_index] then return end
    local train_stop = global.gui[player_index].train_stop.train_stop

    if name == "resource" then
        local current_resource_type = train_stop.resource_type
        local current_resource = train_stop.resource

        if value ~= nil then
            local resource_type = value.type
            local resource = value.name
            train_stop.resource_type = resource_type
            train_stop.resource = resource
        else
            train_stop.resource_type = nil
            train_stop.resource = nil
        end
    else
        train_stop[name] = value
    end

	Tracker.update_data_entity(train_stop.entity)
end

local function text_changed(event)
    local name = string.match(event.element.name, "(.*)-text")
    local value = tonumber(event.text) or 0

    update_value(event.player_index, name, value)
end

local function on_gui_enable_disable_checked_state(event)
    local name = string.match(event.element.name, "(.*)%-enable%-disable%-checkbox")
    local value = (event.element.state == true) and true or false

	update_value(event.player_index, name .. "_enable_disable", value)
end

local function on_gui_checked_state(event)
    local name = string.match(event.element.name, "(.*)-checkbox")
    local value = (event.element.state == true) and true or false

    update_value(event.player_index, name, value)
end

local function on_gui_elem_changed(event)
    local name = string.match(event.element.name, "(.*)-element")

    update_value(event.player_index, name, event.element.elem_value)
end

local function on_gui_value_changed(event)
	local name = string.match(event.element.name, "(.*)%-slider")
    local value = event.element.slider_value

	update_value(event.player_index, name, value)
end

local function destroy(player_index)
	if global.gui[player_index] ~= nil and global.gui[player_index].train_stop ~= nil then
		if global.gui[player_index].train_stop.window ~= nil then 
			global.gui[player_index].train_stop.window.visible = false
			global.gui[player_index].train_stop.window.destroy()
		end
		global.gui[player_index].train_stop = nil
	end
end

local function build(player_index)
	local parent = game.players[player_index].gui.screen

    local main_frame = parent.add {
        type = "flow",
        name = "et-window-train-stop",
        direction = "horizontal"
    }

	local resolution = game.players[player_index].display_resolution
	main_frame.location = {
		x = 30,
		y = (resolution.height / 2) - 167
	}

    main_frame.style.padding = 0
    main_frame.style.horizontal_spacing = 3
    main_frame.visible = false

    local inner_frame =
        main_frame.add {
        type = "flow",
        name = "train-stop-gui-inner-frame",
        direction = "vertical"
    }
    inner_frame.style.horizontally_stretchable = true
    inner_frame.style.vertical_spacing = 0
    inner_frame.style.minimal_width = 200

    local table_frame =
        inner_frame.add {
        type = "frame",
        caption = {"entity-name.train-stop-depot"},
        direction = "vertical"
    }
    table_frame.style.horizontally_stretchable = true

    local table = table_frame.add {type = "table", column_count = 3}
    table.style.cell_padding = 2
    table.style.horizontally_stretchable = true

	local enable_disable = {}
    local fields = {}
    local labels = {}
    for name, data in pairs(config) do
		local field_enabled

		if data.enable_disable == true then
			field_enabled  = table.add {
				type = "checkbox",
				name = name .. "-enable-disable-checkbox",
				state = false
			}
		else
			field_enabled = table.add { type = "label" }
		end

        local caption
        if data.tooltip ~= nil then
            caption = {"", {"samtrain." .. name}, "", " [img=info]"}
        else
            caption = {"samtrain." .. name}
        end
        local label =
            table.add {
            type = "label",
            name = name .. "-label",
            caption = caption,
            tooltip = data.tooltip
        }
        local field = nil

        if data.type == "text" then
            field =
                table.add {
                type = "textfield",
                style = "short_number_textfield",
                name = name .. "-text",
                numeric = true,
                allow_decimal = false,
                allow_negative = false
            }
        elseif data.type == "element" then
            field =
                table.add {
                type = "choose-elem-button",
                name = name .. "-element",
                elem_type = "signal"
            }
        elseif data.type == "checkbox" then
            field =
                table.add {
                type = "checkbox",
                name = name .. "-checkbox",
                state = false
            }
		elseif data.type == "slider" then
			field = table.add {
				type = "slider",
				name = name .. "-slider",
				minimum_value = data.options.minimum_value,
				maximum_value = data.options.maximum_value
			}
        end
		enable_disable[name] = field_enabled
        labels[name] = label
        fields[name] = field
    end

	if global.gui[player_index] == nil then
		global.gui[player_index] = {}
	end

    global.gui[player_index].train_stop = {
        window = main_frame,
        table_frame = table_frame,
		enable_disable = enable_disable,
        labels = labels,
        fields = fields,
		train_stop = nil
    }
end

local function update(player_index, train_stop)
	local gui = global.gui[player_index].train_stop
	local window = gui.window
	gui.train_stop = train_stop

	-- update caption
	gui.table_frame.caption = {"entity-name.train-stop-" .. train_stop.type}

	-- update values
	for name, data in pairs(config) do
		if data.type == "text" then
			gui.fields[name].text = train_stop[name] and train_stop[name] or ""
		elseif data.type == "checkbox" then
			gui.fields[name].state = train_stop[name] and train_stop[name] or false
		elseif data.type == "element" then
			if train_stop[name] and train_stop[name .. "_type"] then
				gui.fields[name].elem_value = {
					name = train_stop[name],
					type = train_stop[name .. "_type"]
				}
			else
				gui.fields[name].elem_value = nil
			end
		elseif data.type == 'slider' then
			if train_stop[name] then
				gui.fields[name].slider_value = train_stop[name]
			end
		end

		if data.enable_disable then
			gui.enable_disable[name].state = train_stop[name .. '_enable_disable'] or false
		end

		local visible = data.exclude == nil or not data.exclude:has(train_stop.type) or false
		gui.enable_disable[name].visible = visible
		gui.labels[name].visible = visible
		gui.fields[name].visible = visible
	end
end

local function show(player_index, train_stop)
	destroy(player_index)

	build(player_index)
	
	if not train_stop then
		return
	end
	update(player_index, train_stop)
  
	local window = global.gui[player_index].train_stop.window
    --game.players[player_index].opened = window
	window.visible = true
end

local function hide(player_index)
	if global.gui[player_index] ~= nil and global.gui[player_index].train_stop ~= nil then
		global.gui[player_index].train_stop.window.visible = false
	end
end

local function show_gui_trainstop(event)
	show(event.player_index, global.conductor.train_stops[event.entity.unit_number])
end

local function train_stop_map_events()
	events.map_gui_opened['train-stop-depot'] = show_gui_trainstop
	events.map_gui_opened['train-stop-supplier'] = show_gui_trainstop
	events.map_gui_opened['train-stop-consumer'] = show_gui_trainstop
	events.map_gui_closed[defines.gui_type.entity] = function(event)
		hide(event.player_index)
	end

	for name, data in pairs(config) do		
		if data.enable_disable then
			events.map_gui_checked_state[name .. "-enable-disable-checkbox"] = on_gui_enable_disable_checked_state
		end
		if data.type == "text" then
			events.map_text_changed[name .. "-text"] = text_changed
		elseif data.type == "checkbox" then
			events.map_gui_checked_state[name .. "-checkbox"] = on_gui_checked_state
		elseif data.type == "element" then
			events.map_gui_elem_changed[name .. "-element"] = on_gui_elem_changed
		elseif data.type == 'slider' then
			events.map_gui_value_changed[name .. '-slider'] = on_gui_value_changed
		end
	end
end

return {
	build = build,
	show = show,
	hide = hide,
	destroy = destroy,
	map_events = train_stop_map_events
}
