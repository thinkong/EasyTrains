local Tracker = {}

-- local cache to catch deleting a train then it being used to create a new train, doesn't need to be saved
Tracker.deleted_trains = {}

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

		Tracker.add_data_entity(entity)
    end
end


local function get_config_table(train_stop)
	local t = {}
	for configName, _ in pairs(config) do
        t[configName] = train_stop[configName]
    end
	t.resource_type = train_stop.resource_type
	return t
end


local function get_existing_data_entity(parent_entity)
  local entities = parent_entity.surface.find_entities_filtered({
    position = parent_entity.position,
    name = 'st-data-entity'
  })

  for _, matching_entity in pairs(entities) do
    if matching_entity ~= parent_entity then
      return matching_entity
    end
  end

  return nil
end

local function get_existing_train_stop(parent_entity)
  local entities = parent_entity.surface.find_entities_filtered({
    position = parent_entity.position,
    name = {'train-stop-depot', 'train-stop-supplier', 'train-stop-consumer'}
  })

  for _, matching_entity in pairs(entities) do
    if matching_entity ~= parent_entity then
      return matching_entity
    end
  end

  return nil
end

function Tracker.add_data_entity(entity)
	local data_entity = get_existing_data_entity(entity)
	local train_stop

	if entity.name == 'train-stop-depot' or entity.name == 'train-stop-supplier' or entity.name == 'train-stop-consumer' then
		if data_entity then
			Tracker.update_train_stop(entity, existing_data_entity)
		else
			data_entity = entity.surface.create_entity({
				name = 'st-data-entity',
				position = entity.position,
				direction = entity.direction,
				force = entity.force
			})
			data_entity.destructible = false

			train_stop = global.conductor.train_stops[entity.unit_number]
			train_stop.data_entity = data_entity
		end
	elseif entity.name == 'st-data-entity' then
		if not data_entity then return end

		local train_stop_entity = get_existing_train_stop(entity)
		train_stop = global.conductor.train_stops[train_stop_entity.unit_number]

		Tracker.update_train_stop(train_stop, entity)
	end

	Tracker.update_data_entity(train_stop)
end

function Tracker.update_data_entity(stop)
	local data_entity = stop.data_entity
	if not data_entity then return end

	data_entity.alert_parameters = {
		alert_message = game.table_to_json(get_config_table(stop)),
		show_alert = false,
		show_on_map = false
	}
end

function Tracker.update_train_stop(stop, data_entity)
	local json = data_entity.alert_parameters.alert_message
	local t = game.json_to_table(json)

	for key, value in pairs(t) do
		stop[key] = value
	end
	t.enabled = false
	t.resource_type = stop.resource_type
end

function Tracker.remove_data_entity(stop)
	if not stop.data_entity then return end
	
	stop.data_entity.destroy()
	stop.data_entity = nil
end

function Tracker.remove_stop(unit_number, name, type)
    local train_stop = global.conductor.train_stops[unit_number]
    if train_stop ~= nil then
        global.conductor.train_stops[unit_number] = nil
		Tracker.remove_data_entity(train_stop)
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