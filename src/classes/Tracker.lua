local Tracker = {}

-- local cache to catch deleting a train then it being used to create a new train, doesn't need to be saved
Tracker.deleted_trains = {}

function Tracker.is_stop_name_in_use(name)
    local name_in_use = false
    if global.conductor.train_stops_by_name[name] ~= nil then
        -- if any of the other stops are not depots this is a problem
        for _, unit_number in pairs(global.conductor.train_stops_by_name[name]) do
            local train_stop = global.conductor.train_stops[unit_number]
            if train_stop == nil or train_stop.type ~= 'depot' then
                name_in_use = true
                break
            end
        end
    end
    return name_in_use
end

function Tracker.add_stop(entity)
	local train_stop_type = string.match(entity.name, 'train%-stop%-(.*)')

    if train_stop_type ~= nil then
        local stop = {}
        stop.unit_number = entity.unit_number
        stop.name = entity.backer_name
        stop.type = train_stop_type
        stop.resource = nil
        stop.resource_type = nil
        stop.assigned_trains = 0
        stop.trains = {}
		stop.entity = entity
        -- stop.error = false

        for configName, configData in pairs(config) do
            stop[configName] = configData.default
        end

        global.conductor.train_stops[entity.unit_number] = stop
        if train_stop_type == 'depot' then
            global.conductor.depots[entity.unit_number] = stop
        elseif train_stop_type == 'consumer' then
            global.conductor.consumer_round_robin:insert(entity.unit_number)
        elseif train_stop_type == 'supplier' then
            global.conductor.supplier_round_robin:insert(entity.unit_number)
        end

		global.conductor.need_to_refresh = true
    end

     Tracker.add_stop_name(entity)
end

function Tracker.add_stop_name(entity)
	local train_stop_type = string.match(entity.name, 'train%-stop%-(.*)')
	
	if train_stop_type and train_stop_type ~= 'depot' then
        if Tracker.is_stop_name_in_use(entity.backer_name) then
            game.print( 'Train stop name ' .. entity.backer_name .. ' already in use. Stops with this name will not be used until this is resolved.' )
        end
    end

	utils.add_to_list_of_lists(global.conductor.train_stops_by_name, entity.backer_name, entity.unit_number)
end

function Tracker.remove_stop(unit_number, name, type)
    local train_stop = global.conductor.train_stops[unit_number]
    if train_stop ~= nil then
        global.conductor.train_stops[unit_number] = nil
		global.conductor.need_to_refresh = true

        if type == 'depot' then
            table.remove(global.conductor.depots, unit_number)
        elseif type == 'consumer' then
            global.conductor.consumer_round_robin:remove(unit_number)

            if train_stop.resource then
                local assigned_trains = train_stop.assigned_trains
                if assigned_trains > 0 then
                    game.print(
                        string.format(
                            'Deleted train stop has %d assigned trains, bad things might happen',
                            assigned_trains
                        )
                    )
                end
                utils.remove_from_list_of_lists_of_lists(
                    global.conductor.consumers,
                    train_stop.resource_type,
                    train_stop.resource,
                    unit_number
                )
            end
        elseif type == 'supplier' then
            global.conductor.supplier_round_robin:remove(unit_number)

            if train_stop.resource then
                local assigned_trains = train_stop.assigned_trains
                if assigned_trains > 0 then
                    game.print(
                        string.format(
                            'Deleted train stop has %d assigned trains, bad things might happen',
                            assigned_trains
                        )
                    )
                end
                utils.remove_from_list_of_lists_of_lists(
                    global.conductor.suppliers,
                    train_stop.resource_type,
                    train_stop.resource,
                    unit_number
                )
            end
        end
    end
    Tracker.remove_stop_name(unit_number, name)
end

function Tracker.remove_stop_name(unit_number, name)
    utils.remove_from_list_of_lists(global.conductor.train_stops_by_name, name, unit_number)
end


function Tracker.add_train(train)
    local size = table_size(train.carriages)

    local train_data = global.conductor.trains[train.id]
    if train_data == nil then
        train_data = {
            id = train.id,
            train = train,
            depot_name = nil,
            consumer = nil,
            supplier = nil,
            mission = nil,
            size = size,
            location = nil,
            type = nil
        }
        global.conductor.trains[train.id] = train_data
    end

    local old_type = train_data.type
    local new_type

    if #train.cargo_wagons > 0 and #train.fluid_wagons == 0 then
        new_type = 'item'
    elseif #train.cargo_wagons == 0 and #train.fluid_wagons > 0 then
        new_type = 'fluid'
    elseif #train.cargo_wagons > 0 and #train.fluid_wagons > 0 then
        new_type = 'mixed'
    else
        new_type = 'none'
    end

    if old_type ~= new_type then
        if old_type ~= nil then
            utils.remove_from_list_of_lists(global.conductor.trains_by_type, train_data.type, train.id)
        end

        train_data.type = new_type
        utils.add_to_list_of_lists(global.conductor.trains_by_type, train_data.type, train.id)
    end

    if train.station ~= nil and train.station.name == 'train-stop-depot' then
        utils.add_to_list_of_lists_of_lists(global.conductor.trains_at_depot, train_data.type, size, train.id)
    end

    if DEBUG_MODE then
        logger(string.format('added train %d type %s size %d', train.id, train_data.type, size))
    end

	global.conductor.need_to_refresh = true
    return train_data
end

function Tracker.remove_train(train)
    local train_data = global.conductor.trains[train.id]
    if DEBUG_MODE then
        logger('removing train ' .. train.id)
    end

    if train_data ~= nil then
        Tracker.deleted_trains[train.id] = train_data
        if train_data.consumer ~= nil then
            train_data.consumer.assigned_trains = train_data.consumer.assigned_trains - 1
            utils.remove_from_list(train_data.consumer.trains, train.id)
        end
        if train_data.supplier ~= nil then
            train_data.supplier.assigned_trains = train_data.supplier.assigned_trains - 1
            utils.remove_from_list(train_data.supplier.trains, train.id)
        end

        utils.remove_from_list_of_lists_of_lists(
            global.conductor.trains_at_depot,
            train_data.type,
            train_data.size,
            train.id
        )
        utils.remove_from_list_of_lists(global.conductor.trains_by_type, train_data.type, train.id)
        global.conductor.trains[train.id] = nil

		global.conductor.need_to_refresh = true
    end
end

return Tracker