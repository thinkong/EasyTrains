local function build_trains_tab_content(tbl_trains)
    tbl_trains.add {
        type = "label",
        caption = {"easytrain_overview.type"},
        style = "caption_label"
    }

    tbl_trains.add {
        type = "label",
		caption = {"easytrain_overview.task"},
        style = "caption_label"
    }

	local label_depot = tbl_trains.add {
        type = "label",
		caption = {"easytrain_overview.depot"},
        style = "caption_label"
    }
	label_depot.style.minimal_width = 100

    tbl_trains.add {
        type = "label",
        caption = {"easytrain_overview.resource"},
        style = "caption_label"
    }

    tbl_trains.add {
        type = "label",
        caption = {"easytrain_overview.size"},
        style = "caption_label"
    }

    for _, train in pairs(global.conductor.trains) do
		if not train.depot_name then goto continue end

        local label_type =
            tbl_trains.add {
            type = "sprite"
        }
        if train.type == "item" then
            label_type.sprite = "item/cargo-wagon"
        elseif train.type == "fluid" then
            label_type.sprite = "item/fluid-wagon"
        end

        local label_mission =
            tbl_trains.add {
            type = "label",
			name = "et-train-label-" .. train.id,
            caption = (train.mission or "")
        }
		label_mission.style.horizontally_stretchable = true

		tbl_trains.add {
            type = "label",
            caption = train.depot_name or ''
        }

        local label_sprite =
            tbl_trains.add {
            type = "sprite"
        }

        if train.supplier ~= nil and train.supplier.resource_type ~= nil and train.supplier.resource ~= nil then
            label_sprite.sprite = train.supplier.resource_type .. "/" .. train.supplier.resource
        elseif train.consumer ~= nil and train.consumer.resource_type ~= nil and train.consumer.resource ~= nil then
            label_sprite.sprite = train.consumer.resource_type .. "/" .. train.consumer.resource
        end

        local label_size =
            tbl_trains.add {
            type = "label",
            caption = tostring(train.size)
        }

		::continue::
    end

	return tbl_trains
end

local function build_trains_tab(tabbed_pane, caption)
    local tab_trains = tabbed_pane.add {type = "tab", caption = caption}
    local tab_trains_scroll_pane = tabbed_pane.add {type = "scroll-pane"}
    tab_trains_scroll_pane.style.maximal_height = 600

    tabbed_pane.add_tab(tab_trains, tab_trains_scroll_pane)

	local tbl_trains =
        tab_trains_scroll_pane.add {
        type = "table",
        column_count = 5,
        style = "bordered_table"
    }

	build_trains_tab_content(tbl_trains)
	return tbl_trains
end

local function build_train_stop_tab_content(tbl, train_stop_type)
    tbl.add {
        type = "label",
		caption = {"easytrain_overview.enabled"},
        style = "caption_label"
    }

    local label_name =
        tbl.add {
        type = "label",
        caption = {"easytrain_overview.name"},
        style = "caption_label"
    }
    label_name.style.horizontally_stretchable = true

    tbl.add {
        type = "label",
        caption = {"easytrain_overview.resource"},
        style = "caption_label"
    }

    tbl.add {
        type = "label",
        caption = {"easytrain_overview.priority"},
        style = "caption_label"
    }

    tbl.add {
        type = "label",
        caption = {"", {"easytrain_overview.trains"}, "", " [img=info]"},
        tooltip = {"easytrain_overview.trains_tooltip"},
        style = "caption_label"
    }

    tbl.add {
        type = "label",
        caption = {"", {"easytrain_overview.size"}, "", " [img=info]"},
        tooltip = {"easytrain_overview.size_tooltip"},
        style = "caption_label"
    }

    for _, train_stop in pairs(global.conductor.train_stops) do
        if train_stop.type == train_stop_type then
            local sprite_enabled =
                tbl.add {
                type = "sprite"
            }

            if train_stop.enabled then
                sprite_enabled.sprite = "virtual-signal/signal-check"
            end

            tbl.add {
                type = "label",
				name = "et-train-stop-label-" .. train_stop.unit_number,
                caption = "[train-stop=" .. train_stop.unit_number .. "] " .. train_stop.name,
            }

            local sprite_resource =
                tbl.add {
                type = "sprite"
            }

            if type(train_stop.resource) == "table" then
                train_stop.resource_type = train_stop.resource.type
                train_stop.resource = train_stop.resource.name
            end
            if train_stop.resource_type and train_stop.resource then
                sprite_resource.sprite = train_stop.resource_type .. "/" .. train_stop.resource
            end

            tbl.add {
                type = "label",
                caption = train_stop.priority
            }

            tbl.add {
                type = "label",
                caption = train_stop.assigned_trains .. "/" .. train_stop.max_number_of_trains
            }

            tbl.add {
                type = "label",
                caption = train_stop.min_length .. "/" .. train_stop.max_length
            }
        end
    end
end

local function build_train_stop_tab(tabbed_pane, caption, train_stop_type)
    local tab = tabbed_pane.add {type = "tab", caption = caption}

    local scroll_pane = tabbed_pane.add {type = "scroll-pane"}
    scroll_pane.style.maximal_height = 600
    tabbed_pane.add_tab(tab, scroll_pane)

    local tbl =
        scroll_pane.add {
        type = "table",
        column_count = 6,
        style = "bordered_table"
    }

	build_train_stop_tab_content(tbl, train_stop_type)
	return tbl
end

local function destroy(player_index)
	if global.gui[player_index] and global.gui[player_index].overview ~= nil then
		if global.gui[player_index].overview.window ~= nil then
			global.gui[player_index].overview.window.visible = false
			global.gui[player_index].overview.window.destroy()
		end

		global.gui[player_index].overview = nil
	end
end

local function refresh()
	for player_index, player_gui in pairs(global.gui) do
		if player_gui.overview == nil or player_gui.overview.window == nil or not player_gui.overview.window.visible then
			goto continue
		end

		local overview = player_gui.overview
		local window = overview.window
		overview.tbl_trains.clear()
		overview.tbl_consumers.clear()
		overview.tbl_suppliers.clear()

		build_trains_tab_content(overview.tbl_trains)
		build_train_stop_tab_content(overview.tbl_consumers, 'consumer')
		build_train_stop_tab_content(overview.tbl_suppliers, 'supplier')
		::continue::
	end
end

local function build(player_index)
    local parent = game.players[player_index].gui.center
    local tabbed_pane = parent.add {
        type = "tabbed-pane",
		name = "et-window-overview"
    }
    tabbed_pane.style.minimal_width = 750

    local tbl_trains = build_trains_tab(tabbed_pane, "Trains")
    local tbl_consumers = build_train_stop_tab(tabbed_pane, "Consumers", "consumer")
    local tbl_suppliers = build_train_stop_tab(tabbed_pane, "Suppliers", "supplier")

	if global.gui[player_index] == nil then
		global.gui[player_index] = {}
	end

    global.gui[player_index].overview = {
        window = tabbed_pane,
		tbl_trains = tbl_trains,
		tbl_consumers = tbl_consumers,
		tbl_suppliers = tbl_suppliers
    }
end

local function show(player_index)
	destroy(player_index)

	build(player_index)

	local window = global.gui[player_index].overview.window
	window.visible = true
	game.players[player_index].opened = window
end

local function hide(player_index)
	if global.gui[player_index] ~= nil and global.gui[player_index].overview ~= nil then
		global.gui[player_index].overview.window.visible = false

		if game.players[player_index].opened == global.gui[player_index].overview.window then
			game.players[player_index].opened = nil
		end
	end
end

 local function toggle_overview(event)
	local player_index = event.player_index
	if global.gui[player_index] ~= nil and global.gui[player_index].overview ~= nil and global.gui[player_index].overview.window ~= nil and global.gui[player_index].overview.window.visible == true then
		hide(player_index)
	else
		show(player_index)
	end
end

local function close_overview(event)
	hide(event.player_index)
end

local function show_train(event, match)
	local train = global.conductor.trains[tonumber(match)]

	if train then
		for locomotive_type, locomotives in pairs(train.train.locomotives) do
			for _, locomotive in pairs(locomotives) do
				hide(event.player_index)
				game.players[event.player_index].opened = locomotive
				return
			end
		end
	end
end

local function show_train_stop(event, match)
	local train_stop = global.conductor.train_stops[tonumber(match)]

	if train_stop then
		hide(event.player_index)
		game.players[event.player_index].opened = train_stop.entity
	end
end

local function overview_map_events()
	events.map_gui_closed["et-window-overview"] = close_overview
	events.map_gui_click["et-button-showoverview"] = toggle_overview
	events.map_gui_click_match["et%-train%-label%-(%d+)"] = show_train
	events.map_gui_click_match["et%-train%-stop%-label%-(%d+)"] = show_train_stop
end

local function add_button(player_index)
	local player = game.players[player_index]

	local button_flow = mod_gui.get_button_flow(player)
	if button_flow["et-button-showoverview"] then
		button_flow["et-button-showoverview"].destroy()
	end

	button_flow.add {
		type = "button",
		style = mod_gui.button_style,
		caption = "[item=train-stop] Easy Trains",
		name = "et-button-showoverview"
	}
end	

return {
	add_button = add_button,
	map_events = overview_map_events,
	build = build,
	show = show,
	hide = hide,
	destroy = destroy,
	refresh = refresh
}