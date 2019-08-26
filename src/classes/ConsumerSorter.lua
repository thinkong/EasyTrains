local ConsumerSorter = {}

function ConsumerSorter:new(consumers, empty_trains, trains_with_resource)
  o = {}
  setmetatable(o, self)
  self.__index = self

  -- load in the actual consumer train stops
  o.consumers = {}

	for resource_type, resources in pairs(consumers) do
   		if empty_trains[resource_type] == nil and trains_with_resource[resource_type] == nil then
			-- early exit
			if DEBUG_MODE then
				logger(string.format('No trains for resource type %s', resource_type))
			end
			goto nextresourcetype
		end

		for resource, resource_consumers in pairs(resources) do
		  for _, consumer_unit_number in pairs(resource_consumers) do
			local consumer = global.conductor.train_stops[consumer_unit_number]
			if #global.conductor.train_stops_by_name[consumer.name] ~= 1 then
			  logger(string.format("Consumer stop %s has duplicate stops and will be ignored", consumer.name))
			elseif not is_train_stop_enabled(consumer) then
			  if DEBUG_MODE then
				logger(string.format("Consumer stop %s is disabled", consumer.name))
			  end
			elseif not consumer.entity.valid then
			  if DEBUG_MODE then
				logger(string.format("Consumer stop %s entity is no longer valid", consumer.name))
			  end
			else
			  table.insert(o.consumers, consumer)
			end
		  end
		end
		::nextresourcetype::
	end
  return o
end

function ConsumerSorter:NextConsumer()
  local keys = {}
  for consumer_index, consumer in pairs(self.consumers) do
    if consumer.assigned_trains >= consumer.max_number_of_trains then
      -- if supplier does not have available train slots, skip to next supplier
      if DEBUG_MODE then
        logger(
          string.format(
            " ... consumer %s already at [%d] maximum number of trains [%d]",
            consumer.name,
            consumer.assigned_trains,
            consumer.max_number_of_trains
          )
        )
      end
    else
      keys[#keys + 1] = {
        consumer_index = consumer_index,
        consumer = consumer,
		position = global.conductor.consumer_round_robin:get_position(consumer.unit_number)
      }
    end
  end

  table.sort(
    keys,
    function(left, right)
      if left.consumer.priority < right.consumer.priority then
        return true
      elseif left.consumer.priority > right.consumer.priority then
        return false
      end

      if left.consumer.assigned_trains < right.consumer.assigned_trains then
        return true
      elseif left.consumer.assigned_trains > right.consumer.assigned_trains then
        return false
      end

--      local left_position = global.conductor.consumer_round_robin:get_position(left.consumer.unit_number)
--      local right_position = global.conductor.consumer_round_robin:get_position(right.consumer.unit_number)
      return left.position < right.position
    end
  )

  if keys[1] then
    return keys[1].consumer_index, keys[1].consumer
  end
end

function ConsumerSorter:RemoveConsumer(index)
  table.remove(self.consumers, index)
end

return ConsumerSorter
