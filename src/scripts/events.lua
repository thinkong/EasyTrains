events = {
    map_gui_opened = {},
    map_gui_closed = {},
    map_gui_click = {},
	map_gui_click_match = {},
    map_text_changed = {},
    map_gui_elem_changed = {},
    map_gui_checked_state = {},
	map_gui_value_changed = {},
	map_player_created = {},
	map_player_joined_game = {},
	map_train_changed_state = {}
}


events.on_gui_opened = function(event)
    if not event.entity or not events.map_gui_opened[event.entity.name] then
        return
    end
    events.map_gui_opened[event.entity.name](event)
end

events.on_gui_closed = function(event)
	if event.gui_type and event.gui_type ~= defines.gui_type.custom then
		if events.map_gui_closed[event.gui_type] then
			events.map_gui_closed[event.gui_type](event)
		end
		return
	end
    if not event.element or not events.map_gui_closed[event.element.name] then
        return
    end
    events.map_gui_closed[event.element.name](event)
end

events.on_gui_clicked = function(event)
    if event.element then 
		if events.map_gui_click[event.element.name] then
			events.map_gui_click[event.element.name](event)
			return
		end

		for key, callback in pairs(events.map_gui_click_match) do
			local match = string.match(event.element.name, key)
			if match ~= nil then
				callback(event, match)
				return
			end
		end
    end
end

events.on_gui_text_changed = function(event)
    if not event.element or not events.map_text_changed[event.element.name] then
        return
    end
    events.map_text_changed[event.element.name](event)
end

events.on_gui_elem_changed = function(event)
    if not event.element or not events.map_gui_elem_changed[event.element.name] then
        return
    end
    events.map_gui_elem_changed[event.element.name](event)
end

events.on_gui_value_changed = function(event)
    if not event.element or not events.map_gui_value_changed[event.element.name] then
        return
    end
    events.map_gui_value_changed[event.element.name](event)
end

events.on_gui_checked_state = function(event)
    if not event.element or not events.map_gui_checked_state[event.element.name] then
        return
    end
    events.map_gui_checked_state[event.element.name](event)
end

events.on_player_created = function(event)
	for _, func in pairs(events.map_player_created) do
		func(event)
	end
end

events.on_player_joined_game = function(event)
	for _, func in pairs(events.map_player_joined_game) do
		func(event)
	end
end

events.on_train_changed_state = function(event)
	if event.old_state == defines.train_state.wait_station then
		if events.map_train_changed_state["leaves_station"] then
			events.map_train_changed_state["leaves_station"](event)
		end
		return
	end

	if not events.map_train_changed_state[event.train.state] then
		return
	end
	events.map_train_changed_state[event.train.state](event)
end

script.on_event({defines.events.on_gui_opened}, events.on_gui_opened)
script.on_event({defines.events.on_gui_closed}, events.on_gui_closed)
script.on_event({defines.events.on_gui_click}, events.on_gui_clicked)
script.on_event({defines.events.on_gui_text_changed}, events.on_gui_text_changed)
script.on_event({defines.events.on_gui_elem_changed}, events.on_gui_elem_changed)
script.on_event({defines.events.on_gui_checked_state_changed}, events.on_gui_checked_state)
script.on_event({defines.events.on_gui_value_changed}, events.on_gui_value_changed)
script.on_event({defines.events.on_player_created}, events.on_player_created)
script.on_event({defines.events.on_player_joined_game}, events.on_player_joined_game)
script.on_event({defines.events.on_train_changed_state}, events.on_train_changed_state)

function events.map_events(lib)
	for _, lib in pairs(lib) do
		if lib.map_events then
			lib.map_events()
		end
	end
end

return events