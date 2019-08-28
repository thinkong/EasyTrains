DEBUG_MODE = false
global = global or {}
global.gui = global.gui or {}

utils = require 'utils'
logger = require('__stdlib__/stdlib/misc/logger').new('log', true)
table = require('__stdlib__/stdlib/utils/table')
RoundRobin = require "classes.RoundRobin"
Tracker = require "classes.Tracker"

require 'mod-gui'
config = require "config"
events = require "scripts.events"
conductor = require "scripts.conductor"
gui_overview = require 'gui.overview'
gui_trainstop = require 'gui.train-stop'

events.map_events({ conductor, gui_overview, gui_trainstop })

script.on_load(function()
	if global.conductor.consumer_round_robin then
		setmetatable(global.conductor.consumer_round_robin, RoundRobin)
	end

	if global.conductor.supplier_round_robin then
		setmetatable(global.conductor.supplier_round_robin, RoundRobin)
	end
end)

script.on_init(function()
	global.conductor.consumer_round_robin = RoundRobin:new()
	global.conductor.supplier_round_robin = RoundRobin:new()

    for _, surface in pairs(game.surfaces) do
        local train_stops = surface.find_entities_filtered {type = 'train-stop'}
    end

	for _, player in pairs(game.players) do
		gui_overview.add_button(player.index)
	end
end)

function on_player_created(event)	
	gui_overview.add_button(event.player_index)
end
table.insert(events.map_player_created, on_player_created)

function on_player_joined_game(event)
	gui_overview.add_button(event.player_index)
end
table.insert(events.map_player_created, on_player_joined_game)


script.on_event(
    {defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built},
    function(event)
        local entity = event.created_entity or event.entity
        local train_stop_type = string.match(entity.name, 'train%-stop%-(.*)')

        if entity.name == 'train-stop' or train_stop_type ~= nil then
            Tracker.add_stop(entity)
		elseif entity.name == 'st-data-entity' then
			Tracker.add_data_entity(entity)
        end
    end
)

script.on_event(
    {
        defines.events.on_pre_player_mined_item,
        defines.events.on_robot_pre_mined,
        defines.events.on_entity_died,
        defines.events.script_raised_destroy
    },
    function(event)
        local entity = event.entity
        local train_stop_type = string.match(entity.name, 'train%-stop%-(.*)')
        if entity.name == 'train-stop' or train_stop_type ~= nil then
            Tracker.remove_stop(entity.unit_number, entity.backer_name, train_stop_type)
        end

        if entity.train then
            Tracker.remove_train(entity.train)
        end
    end
)

script.on_event(
    {defines.events.on_train_created},
    function(event)
        -- creating a train technically deletes old trains, we need to track this

        if event.old_train_id_1 ~= nil then
            local old_train_1 = global.conductor.trains[event.old_train_id_1]
            if old_train_1 ~= nil then
                Tracker.remove_train(old_train_1)
            end
        end

        if event.old_train_id_2 ~= nil then
            local old_train_2 = global.conductor.trains[event.old_train_id_2]
            if old_train_2 ~= nil then
                Tracker.remove_train(old_train_2)
            end
        end

        local created_train = Tracker.add_train(event.train)

        local copy_from_train_id = event.old_train_id_2 or event.old_train_id_1
        local copy_from_train = global.conductor.trains[copy_from_train_id] or Tracker.deleted_trains[copy_from_train_id]

        if copy_from_train ~= nil then
            created_train.mission = copy_from_train.mission
            created_train.depot_name = copy_from_train.depot_name

            local schedule = {current = 1, records = {}}

            local current = nil
            if copy_from_train.depot_name ~= nil then
                table.insert(
                    schedule.records,
                    {
                        station = copy_from_train.depot_name,
                        wait_conditions = {
                            {type = 'full', compare_type = 'and'} -- just to force the train to wait there indefinitely
                        }
                    }
                )
            end

            if copy_from_train.supplier then
                created_train.supplier = copy_from_train.supplier
                created_train.supplier.assigned_trains = created_train.supplier.assigned_trains + 1
                table.insert(created_train.supplier.trains, created_train.id)

                table.insert(
                    schedule.records,
                    {
                        station = created_train.supplier.name,
                        wait_conditions = {{type = 'full', compare_type = 'and'}}
                    }
                )
                -- if there is a supplier we always want to be scheduled to go there
                current = #schedule.records
            end

            if copy_from_train.consumer then
                created_train.consumer = copy_from_train.consumer
                created_train.consumer.assigned_trains = created_train.consumer.assigned_trains + 1
                table.insert(created_train.consumer.trains, created_train.id)

                table.insert(
                    schedule.records,
                    {
                        station = created_train.consumer.name,
                        wait_conditions = {{type = 'empty', compare_type = 'and'}}
                    }
                )

                -- if there is a supplier and a consumer we still need to go to the supplier
                if current == nil then
                    current = #schedule.records
                end
            end

            if current == nil then
                current = #schedule.records
            end

            if current ~= 0 then
                schedule.current = current
                event.train.schedule = schedule

                if event.train.station ~= nil and event.train.station.name ~= 'train-stop-depot' then
                    event.train.go_to_station(current)
                end
            end
        end
    end
)

script.on_event(
    {defines.events.on_pre_surface_deleted, defines.events.on_pre_surface_cleared},
    function(event)
        local surface = game.surfaces[event.surface_index]
        if surface then
            local train_stops = surface.find_entities_filtered {type = 'train-stop'}

            for _, entity in pairs(train_stops) do
                local train_stop_type = string.match(entity.name, 'train%-stop%-(.*)')
                Tracker.remove_stop(entity.unit_number, entity.backer_name, train_stop_type)
            end
        end
    end
)

script.on_event(
    {defines.events.on_entity_renamed},
    function(event)
        local old_name = event.old_name
        local new_name = event.entity.backer_name

        if old_name ~= new_name then
            if event.entity.name == 'train-stop' or string.match(event.entity.name, 'train%-stop%-(.*)') ~= nil then
                local train_stop = global.conductor.train_stops[event.entity.unit_number]
                if train_stop ~= nil then
                    train_stop.name = new_name
                end
            end
        end
    end
)

script.on_event(
    {defines.events.on_entity_settings_pasted},
    function(event)
        local source_train_stop_type = string.match(event.source.name, 'train%-stop%-(.*)')
        local dest_train_stop_type = string.match(event.destination.name, 'train%-stop%-(.*)')

        if
            (source_train_stop_type == 'consumer' or source_train_stop_type == 'supplier') and
                (dest_train_stop_type == 'consumer' or dest_train_stop_type == 'supplier')
         then
            local source_train_stop = global.conductor.train_stops[event.source.unit_number]
            local dest_train_stop = global.conductor.train_stops[event.destination.unit_number]

            if source_train_stop and dest_train_stop then
				for configName, configData in pairs(config) do
					if configName ~= "enabled" then
						dest_train_stop[configName] = source_train_stop[configName]
						if configData.enable_disable then
							local configNameEnableDisable = configName .. "_enable_disable"
							dest_train_stop[configNameEnableDisable] = source_train_stop[configNameEnableDisable]
						end
					end
				end

            end
        end
    end
)
