local ConsumerSorter = require "classes.ConsumerSorter"
local SupplierSorter = require "classes.SupplierSorter"

global.conductor = {
    train_stops = {},
    depots = {},
    trains = {},
    trains_at_depot = {},
    trains_by_type = {},
	tick_alarms = {},
	need_to_refresh = false
}

function is_train_stop_enabled(train_stop)
	if not train_stop.enabled then return false end
	local control_behavior = train_stop.entity.get_control_behavior()
	if control_behavior and control_behavior.enable_disable and control_behavior.disabled then
		return false
	end
	return true
end

function get_resource_for_train_stop(train_stop)
	local entity = train_stop.entity

	if train_stop.resource_type and train_stop.resource then
		return train_stop.resource_type, train_stop.resource
	end

	local signals = {}
	if entity.circuit_connected_entities then
		if entity.circuit_connected_entities.red then
			local circuit_network = entity.get_circuit_network(defines.wire_type.red)
			if circuit_network and circuit_network.signals then
				for _, signal in pairs(circuit_network.signals) do
					table.insert(signals, signal)
				end
			end
		end

		if entity.circuit_connected_entities.green then
			local circuit_network = entity.get_circuit_network(defines.wire_type.green)
			if circuit_network and circuit_network.signals then
				for _, signal in pairs(circuit_network.signals) do
					table.insert(signals, signal)
				end
			end
		end

		local selected_signal
		for _, signal in pairs(signals) do
			if selected_signal then
				return nil
			end

			selected_signal = signal
		end

		return selected_signal
	end

	return nil
end

function on_train_arrives(event)
	local train = event.train
	
    if global.conductor.trains[train.id] == nil then
        Tracker.add_train(train)
    end
    local train_data = global.conductor.trains[train.id]

	local scheduled_rail
	if train.schedule and train.schedule.records and train.schedule.records[train.schedule.current] and train.schedule.records[train.schedule.current].rail then
		scheduled_rail = train.schedule.records[train.schedule.current].rail
	end
	
	local station
	if train.station then 
		station = train.station
	elseif train_data.consumer ~= nil and train_data.consumer.entity.valid and train_data.consumer.entity.connected_rail == scheduled_rail then
		station = train_data.consumer.entity
    elseif train_data.supplier ~= nil and train_data.supplier.entity.valid and train_data.supplier.entity.connected_rail == scheduled_rail then
		station = train_data.supplier.entity
    end

	if station == nil then
		return
	end

    if station.name == "train-stop-depot" then
        if DEBUG_MODE then
            logger("train has arrived at depot, resetting")
        end
        train_data.depot_name = station.backer_name
        train_data.location = "depot"

        utils.add_to_list_of_lists_of_lists(
            global.conductor.trains_at_depot,
            train_data.type,
            train_data.size,
            train.id
        )

        local schedule = {current = 1, records = {}}
		schedule.records[1] = {
			station = station.backer_name, 
			wait_conditions={
				{type = "inactivity", ticks = 180, compare_type = "and"} -- wait for the train to be inactive... hopefully fueling
			}
		}        
		train.schedule = schedule

        if train_data.mission ~= nil then
            logger(string.format("Train mission %s has completed", train_data.mission))
            train_data.mission = nil
        end

		if train_data.consumer ~= nil then
            train_data.consumer.assigned_trains = train_data.consumer.assigned_trains - 1
            utils.remove_from_list(train_data.consumer.trains, train.id)
            train_data.consumer = nil
        end

		if train_data.supplier ~= nil then
			train_data.supplier.assigned_trains = train_data.supplier.assigned_trains - 1
			utils.remove_from_list(train_data.supplier.trains, train.id)
			train_data.supplier = nil
		end
	elseif station.name == 'train-stop-consumer' and train_data.consumer ~= nil then
        train_data.location = "consumer"
		if train_data.consumer.warning_timeout_enable_disable then
			local tick = game.tick + (train_data.consumer.warning_timeout * 60)
			train_data.consumer.tick_alarm = tick
			utils.add_to_list_of_lists(global.conductor.tick_alarms, tick, train_data.consumer.unit_number)
		end
    elseif station.name == 'train-stop-supplier' and train_data.supplier ~= nil then
        train_data.location = "supplier"
		if train_data.supplier.warning_timeout_enable_disable then
			local tick = game.tick + (train_data.supplier.warning_timeout * 60)
			train_data.supplier.tick_alarm = tick
			utils.add_to_list_of_lists(global.conductor.tick_alarms, tick, train_data.supplier.unit_number)
		end
    end

	if DEBUG_MODE  then
        logger(string.format("train %d has arrived at %s", train.id, station.backer_name))
    end

	if DEBUG_MODE then
		logger('train location is now: ' .. (train_data.location or 'nil'))
	end
end

function on_train_leaves(event)
	local train = event.train
    local train_data = global.conductor.trains[train.id]
    if train_data ~= nil then
        if DEBUG_MODE  then
            logger(string.format("train %d leaving station %s", train.id, train_data.location))
        end

        if train_data.location == "consumer" then
            if train_data.consumer ~= nil then
				if train_data.consumer.tick_alarm then
					utils.remove_from_list_of_lists(global.conductor.tick_alarms, train_data.consumer.tick_alarm, train_data.consumer.unit_number)
				end
                train_data.consumer.assigned_trains = train_data.consumer.assigned_trains - 1
                utils.remove_from_list(train_data.consumer.trains, train.id)
                train_data.consumer = nil
            end
        elseif train_data.location == "supplier" then
            if train_data.supplier ~= nil then
				if train_data.supplier.tick_alarm then
					utils.remove_from_list_of_lists(global.conductor.tick_alarms, train_data.supplier.tick_alarm, train_data.supplier.unit_number)
				end
                train_data.supplier.assigned_trains = train_data.supplier.assigned_trains - 1
                utils.remove_from_list(train_data.supplier.trains, train.id)
                train_data.supplier = nil
            end
        end
        train_data.location = nil
    end
end

local Conductor = {
    suppliers = {},
    consumers = {},
	empty_trains = {},
	trains_with_resource = {}
}

function Conductor:build_consumers()
	local t = {}

	for _, train_stop in pairs(global.conductor.train_stops) do
		if train_stop.type == 'consumer' then
			if not train_stop.entity or not train_stop.entity.valid or not train_stop.entity.connected_rail then goto continue end
			local resource_type = train_stop.resource_type
			local resource = train_stop.resource

			if not resource_type or not resource then goto continue end
			if not t[resource_type] then t[resource_type] = {} end
			if not t[resource_type][resource] then t[resource_type][resource] = {} end

			if resource then
				table.insert(t[resource_type][resource], train_stop.unit_number)
			end

			::continue::
		end
	end

	return t
end

function Conductor:build_suppliers()
	local t = {}

	for _, train_stop in pairs(global.conductor.train_stops) do
		if train_stop.type == 'supplier' then
			if not train_stop.entity or not train_stop.entity.valid or not train_stop.entity.connected_rail then goto continue end
			local resource_type, resource = get_resource_for_train_stop(train_stop)
			if not resource then goto continue end
			if not t[resource_type] then t[resource_type] = {} end
			if not t[resource_type][resource] then t[resource_type][resource] = {} end

			if resource then
				table.insert(t[resource_type][resource], train_stop.unit_number)
			end

			::continue::
		end
	end

	return t
end

function Conductor:tick()
    local profiler
    if DEBUG_MODE then
        profiler = game.create_profiler()
        logger("start tick")
    end

	local empty_trains, empty_train_length, trains_with_resource, trains_with_resource_length = self:build_train_list()
	if DEBUG_MODE then
		logger('empty_trains: ' .. serpent.line(empty_trains))
		logger('trains_with_resource: ' .. serpent.line(trains_with_resource))
	end
	if empty_train_length == 0 and trains_with_resource_length == 0 then
		if DEBUG_MODE then
			logger('skipping tick as no available trains')
		end
	else
		self.consumers = Conductor:build_consumers()
		self.suppliers = Conductor:build_suppliers()
		self.empty_trains = empty_trains
		self.trains_with_resource = trains_with_resource

		local sorter = ConsumerSorter:new(self.consumers, self.empty_trains, self.trains_with_resource)
		while true do
			local consumer_index, consumer = sorter:NextConsumer()

			if consumer == nil then
				break
			else
				if DEBUG_MODE then
					logger(
						string.format(
							"Looking for supplier for consumer %s (%d/%d assigned trains)",
							consumer.name,
							consumer.assigned_trains,
							consumer.max_number_of_trains
						)
					)
				end

				local supplier, train = Conductor:get_supplier_and_train_for_consumer(consumer)
				if supplier == nil then
					if DEBUG_MODE then
						logger(" ... no available supplier")
					end
					sorter:RemoveConsumer(consumer_index)
				else
					if DEBUG_MODE then
						logger(string.format(" ... got supplier %s and train %d %s", supplier.name, train.id, train.type))
					end

					logger(
						string.format(
							"Found supplier for consumer %s (%d/%d assigned trains)",
							consumer.name,
							consumer.assigned_trains,
							consumer.max_number_of_trains
						)
					)
					-- dispatch
					Conductor:dispatch_train(train, supplier, consumer)
				end
			end
			::continue::
		end
    end

    if DEBUG_MODE then
        profiler.stop()
        --game.print(profiler)
        logger.write()
        logger("tick completed")
    end

	if global.conductor.need_to_refresh then
		gui_overview.refresh()
		global.conductor.need_to_refresh = false
	end
end

function Conductor:build_train_list()
	local empty_trains = {}
	local empty_trains_length = 0
	local trains_with_resource = {}
	local trains_with_resource_length = 0

	for resource_type, trains_by_length in pairs(global.conductor.trains_at_depot) do
		for length, train_ids in pairs(trains_by_length) do
			for _, train_id in pairs(train_ids) do
				local train_data = global.conductor.trains[train_id]
				local actual_train = train_data.train
			
				if not actual_train.valid then goto continue end
				if actual_train.manual_mode then goto continue end
				-- if not self:fully_fueled(actual_train) then goto continue end

				local contents = actual_train.get_contents()
				local table_size_contents = table_size(contents)
				local fluid_contents = actual_train.get_fluid_contents()
				local table_size_fluid_contents = table_size(fluid_contents)

				if table_size_contents == 0 and table_size_fluid_contents == 0 then
					-- empty train
					if not empty_trains[resource_type] then empty_trains[resource_type] = {} end
					if not empty_trains[resource_type][length] then empty_trains[resource_type][length] = {} end

					table.insert(empty_trains[resource_type][length], train_data)
					empty_trains_length = empty_trains_length + 1
				elseif (table_size_contents == 1 and table_size_fluid_contents == 0) or (table_size_contents == 0 and table_size_fluid_contents == 1) then
					local resource = self:get_train_resource(contents, fluid_contents)

					-- item or fluid train
					if not trains_with_resource[resource_type] then trains_with_resource[resource_type] = {} end
					if not trains_with_resource[resource_type][resource] then trains_with_resource[resource_type][resource] = {} end
					if not trains_with_resource[resource_type][resource][length] then trains_with_resource[resource_type][resource][length] = {} end

					table.insert(trains_with_resource[resource_type][resource][length], train_data)
					trains_with_resource_length = trains_with_resource_length + 1
				else goto continue end
			
				::continue::
			end
		end
	end

	return empty_trains, empty_trains_length, trains_with_resource, trains_with_resource_length
end

function Conductor:get_train_resource(contents, fluid_contents)
	for item, count in pairs(contents) do
		return item
	end

	for item, count in pairs(fluid_contents) do
		return item
	end
end

function Conductor:get_supplier_and_train_for_consumer(consumer)
    local resource_type_suppliers = self.suppliers[consumer.resource_type]

    if resource_type_suppliers == nil then
        logger(string.format("No suppliers for resource type %s", consumer.resource_type))
        logger(serpent.block(consumer))
        return nil
    end

    resource_suppliers = resource_type_suppliers[consumer.resource]
    if resource_suppliers == nil then
        logger(string.format("No suppliers for %s", consumer.resource))
        return nil
    end

    local sorter = SupplierSorter:new(resource_suppliers)

    -- order suppliers by least number of assigned trains
    for supplier_unit_number, supplier in sorter:iterate() do
        if consumer.min_length > supplier.max_length or consumer.max_length < supplier.min_length then
            -- if supplier train slots do not fit in consumer slots, skip to next supplier
            --   ie. consumer requests maxlength 3 train, supplier has minlength of 6
            if DEBUG_MODE then
                logger(
                    string.format(
                        " ... supplier train size mismatch with consumer. Supplier: [%d-%d] Consumer: [%d-%d]",
                        supplier.min_length,
                        supplier.max_length,
                        consumer.min_length,
                        consumer.max_length
                    )
                )
            end
        else
            -- match available trains in depot to slots by largest train to smallest train
            local min_length = math.max(consumer.min_length, supplier.min_length)
            local max_length = math.min(consumer.max_length, supplier.max_length)
            
			for length = max_length, min_length, -1 do
				local train = self:get_train_for_resource_and_length(consumer.resource_type, consumer.resource, length)

				if train ~= nil then
					return supplier, train
				end
			end
          
            if DEBUG_MODE then
                logger(
                    string.format(
                        " ... no trains for supplier %s of type %s with size between %d and %d at depot",
                        supplier.name,
                        consumer.resource_type,
                        min_length,
                        max_length
                    )
                )
            end
        end
    end
    return nil
end

function Conductor:get_train_for_resource_and_length(resource_type, resource, length)
	--logger(string.format(' ... looking for train %s - %s - %d', resource_type, resource, length))

	if self.trains_with_resource[resource_type] and self.trains_with_resource[resource_type][resource] and self.trains_with_resource[resource_type][resource][length] then
		for index, train_data in pairs(self.trains_with_resource[resource_type][resource][length]) do
			self.trains_with_resource[resource_type][resource][length][index] = nil
			return train_data
		end
	end

	if self.empty_trains[resource_type] and self.empty_trains[resource_type][length] then
		for index, train_data in pairs(self.empty_trains[resource_type][length]) do
			self.empty_trains[resource_type][length][index] = nil
			return train_data
		end
	end

	return nil
end

function Conductor:fully_fueled(train)
	if train.valid then
		for _, direction_locomotives in pairs(train.locomotives) do
			for _, locomotive in pairs(direction_locomotives) do
				local fuel_inventory = locomotive.get_fuel_inventory() 

				-- infinity trains don't have a fuel inventory
				if fuel_inventory == nil then
					return true
				end
			
				for i=1,#fuel_inventory do
					if not fuel_inventory[i].valid_for_read then
						logger('empty fuel_inventory slot ' .. i)
						return false
					end
				end

				local contents = fuel_inventory.get_contents()

				for item, count in pairs(contents) do
					--print('item ' .. item .. ' count ' .. count)
					local prototype = game.item_prototypes[item]

					if count < prototype.stack_size then
						return false
					end
				end
			end
		end
	end
	return true
end

function Conductor:create_schedule(depot_name, supplier, consumer)
    local schedule = {current = 1, records = {}}
    -- back to depot
    schedule.records[1] = {
        station = depot_name,
        wait_conditions = {
			{type = "inactivity", ticks = 180, compare_type = "and"}	-- make sure the train is fully fueled
        }
    }
	-- to supplier
	if settings.global["duplicate_station_names"] == true then
		schedule.records[2] = {
			rail = supplier.entity.connected_rail,
			wait_conditions = {{type = "full", compare_type = "and"}}
		}
	else
		schedule.records[2] = {
		station = supplier.name,
		wait_conditions = {{type = "full", compare_type = "and"}}
	}
	end
	
	if consumer.count_enable_disable == true and consumer.count then
		schedule.records[2].wait_conditions = 
		{ 
			{
				type = "item_count", 
				compare_type = 'or',
				condition = {
					comparator = '≥',
					first_signal = {
						type = consumer.resource_type,
						name = consumer.resource
					},
					constant = consumer.count
				}
			}
		}
	end

	if supplier.timeout_enable_disable == true and supplier.timeout then
		table.insert(schedule.records[2].wait_conditions, {
			type = "time",
			ticks = supplier.timeout * 60,
			compare_type = 'or'
		})
	end

    -- to consumer
	if settings.global["duplicate_station_names"]  == true then
		schedule.records[3] = {
			rail = consumer.entity.connected_rail,
			wait_conditions = {{type = "empty", compare_type = "and"}}
		}
	else		
		schedule.records[3] = {
		station = consumer.name,
		wait_conditions = {{type = "empty", compare_type = "and"}}
	}
	end
	
	if consumer.timeout_enable_disable == true and consumer.timeout then
		table.insert(schedule.records[3].wait_conditions, {
			type = "time",
			ticks = consumer.timeout * 60,
			compare_type = 'or'
		})
	end

    return schedule
end

function Conductor:dispatch_train(train, supplier, consumer)
    -- remove train from depot
    utils.remove_from_list_of_lists_of_lists(global.conductor.trains_at_depot, train.type, train.size, train.id)

    global.conductor.consumer_round_robin:consume(consumer.unit_number)
    global.conductor.supplier_round_robin:consume(supplier.unit_number)

    -- increment assigned trains on both sides
    train.consumer = consumer
    train.supplier = supplier
    consumer.assigned_trains = consumer.assigned_trains + 1
    supplier.assigned_trains = supplier.assigned_trains + 1

    -- assign train
    table.insert(consumer.trains, train.id)
    table.insert(supplier.trains, train.id)

    -- dispatch train
    local actual_train = train.train

    if consumer.entity.color then
        for _, locomotive in pairs(actual_train.locomotives.front_movers) do
            locomotive.color = consumer.entity.color
        end
        for _, locomotive in pairs(actual_train.locomotives.back_movers) do
            locomotive.color = consumer.entity.color
        end
    end
    local schedule = Conductor:create_schedule(train.depot_name, supplier, consumer)
    actual_train.schedule = schedule
    --actual_train.go_to_station(2)
    train.mission = string.format("%s to %s", supplier.name, consumer.name)
    logger(string.format(" ... starting train %d for mission %s", train.id, train.mission))
end

function Conductor:fixstations()
	for index, train_stop in pairs(global.conductor.train_stops) do
		if train_stop.name ~= 'train-stop-depot' then
			if train_stop.enabled == false then
				logger(serpent.line(train_stop))
				train_stop.enabled = true
				-- train_stop.backer_name
				local _, _, item_type, item_name = train_stop.name:find('%[(.*)=(.*)%] ')
				train_stop.resource_type = item_type
				train_stop.resource = item_name
			end 
		end
	end
end

function Conductor:cleanup()
	for index, train_stop in pairs(global.conductor.train_stops) do
		if train_stop.entity == nil or not train_stop.entity.valid then
			logger('invalid train stop, removing' .. serpent.line(train_stop))

			if train_stop.data_entity and train_stop.data_entity.valid then
				train_stop.data_entity.destroy()
			end

			global.conductor.train_stops[index] = nil
		end

		if train_stop.assigned_trains < 0 then
			train_stop.assigned_trains = 0
		end
	end

	for index, train in pairs (global.conductor.trains) do
		if train.train == nil or not train.train.valid then
			logger('invalid train, removing' .. serpent.line(train))
			global.conductor.trains[index] = nil
		end
	end
	 
	utils.cleanup_list_of_lists_of_lists(global.conductor.trains_at_depot, function (item)
		return global.conductor.trains[item] ~= nil
	end)

	utils.cleanup_list_of_lists(global.conductor.trains_by_type, function (item)
		return global.conductor.trains[item] ~= nil
	end)

	if global.conductor.consumer_round_robin then
		for _, value in pairs(global.conductor.consumer_round_robin:get()) do
			if global.conductor.train_stops[value] == nil then
				global.conductor.consumer_round_robin:remove(value)
			end
		end
	end

	if global.conductor.supplier_round_robin then
		for _, value in pairs(global.conductor.supplier_round_robin:get()) do
			if global.conductor.train_stops[value] == nil then
				global.conductor.supplier_round_robin:remove(value)
			end
		end
	end
end

script.on_nth_tick(120, function()
    Conductor:tick()
end)

script.on_nth_tick(3600, function()
    Conductor:cleanup()
end)

script.on_event(defines.events.on_tick, function(event)
	if global.conductor.tick_alarms[game.tick] then
		for _, unit_number in pairs(global.conductor.tick_alarms[game.tick]) do
			local train_stop = global.conductor.train_stops[unit_number]

			if train_stop and train_stop.warning_timeout_enable_disable and train_stop.warning_timeout and train_stop.entity.valid then
				local time_in_seconds = train_stop.warning_timeout
				game.print({"train_waiting_warning", train_stop.name, time_in_seconds})
			end
		end
		global.conductor.tick_alarms[game.tick] = nil
	end
end)

commands.add_command('et_cleanup', '', function()
	Conductor:cleanup()
end)

commands.add_command('et_fix', '', function()
	Conductor:fixstations()
end)

local function conductor_map_events()
	events.map_train_changed_state[defines.train_state.wait_station] = on_train_arrives
	events.map_train_changed_state["leaves_station"] = on_train_leaves
end

return {
	map_events = conductor_map_events
}