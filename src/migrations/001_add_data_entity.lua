for _, surface in pairs(game.surfaces) do
	local entities = surface.find_entities_filtered({
		name = {'train-stop-depot', 'train-stop-supplier', 'train-stop-consumer'}
	})

	Tracker.Trace( "Migrating...")
	
	for _, entity in pairs(entities) do
		-- conversion from SamTrain to SamTrain_v18 - recreate the item		
		if entity.unit_number == nil then
			local new_entity
			new_entity = entity.surface.create_entity({
				name = entity.name,
				type = entity.type,
				position = entity.position,
				direction = entity.direction,
				force = entity.force,
				resource_type = entity.resource_type,
				assigned_trains = entity.assigned_trains,
				trains = entity.trains,
				min_length = entity.min_length,
				max_length = entity.max_length,
			})
			if entity.name ~= 'train-stop-depot' then	
				new_entity.enabled = entity.enabled
				new_entity.resource = entity.resource
				new_entity.priority = entity.priority
				new_entity.max_number_of_trains = entity.max_number_of_trains
				new_entity.timeout = entity.timeout
				new_entity.warning_timeout = entity.warning_timeout
			end
			if entity.name == 'train-stop-consumer' then
				new_entity.count = entity.count
			end
			new_entity.entity = new_entity
			Tracker.Trace( 'Replace Entity: ' .. new_entity.name)

			Tracker.add_data_entity(new_entity)
			entity.destroy()
		else	
			Tracker.Trace( 'ADE: ' .. entity.name )
			Tracker.add_data_entity(entity)
		end
		
	end
end

