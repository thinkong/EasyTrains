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

        for configName, configData in pairs(config) do
            stop[configName] = configData.default

			if configData.enable_disable then
				stop[configName .. "_enable_disable"] = false
			end
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
			Tracker.update_train_stop(existing_data_entity, entity)
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
		local train_stop_entity = get_existing_train_stop(entity)

		if train_stop_entity then
			train_stop = global.conductor.train_stops[train_stop_entity.unit_number]

			if data_entity then
				data_entity.destroy()
				train_stop.data_entity = nil
			end

			Tracker.update_train_stop(entity, train_stop)
			train_stop.data_entity = entity
		end
	end

	if train_stop then
		Tracker.update_data_entity(train_stop)
	end
	return entity
end

function encode(train_stop)
	local t = {}
	t.rt = train_stop.resource_type

	for configName, configData in pairs(config) do
		if configName ~= 'enabled' and train_stop[configName] and (configData.exclude == nil or  not configData.exclude:has(train_stop.type)) then
			t[configData.short_name] = train_stop[configName]

			if configData.enable_disable then
				t['_' .. configData.short_name] = train_stop[configName .. "_enable_disable"]
			end
		end
	end

	-- 0 for version
	return '0' .. game.table_to_json(t)
end

function decode(data_entity, train_stop)
	local alert_message = data_entity.alert_parameters.alert_message
	local version = alert_message:sub(1,1)
	local t

	if version ~= '0' then
		t = game.json_to_table(alert_message)
	else
		local mapping_table = {}

		mapping_table['rt'] = 'resource_type'
		for configName, configData in pairs(config) do
			mapping_table[configData.short_name] = configName
			if configData.enable_disable then
				mapping_table['_' .. configData.short_name] = configName .. "_enable_disable"
			end
		end

		local json = alert_message:sub(2)
		local encoded_t = game.json_to_table(json)

		t = {}
		for key, value in pairs(encoded_t) do
			t[mapping_table[key]] = value
		end
	end

	for key, value in pairs(t) do
		train_stop[key] = value
	end
end

function Tracker.update_data_entity(stop)
	local train_stop = global.conductor.train_stops[stop.unit_number]
	
	if not train_stop then return end

	local data_entity = train_stop.data_entity
	if data_entity and not data_entity.valid then
		train_stop.data_entity = nil
		data_entity = nil
	end

	if not data_entity then 
		data_entity = Tracker.add_data_entity(stop)
	end

	local encoded = encode(train_stop)

	data_entity.alert_parameters = {
		alert_message = encoded,
		show_alert = false,
		show_on_map = false
	}
end

function Tracker.update_train_stop(data_entity, train_stop)
	decode(data_entity, train_stop)
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