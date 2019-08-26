for _, surface in pairs(game.surfaces) do
	local entities = surface.find_entities_filtered({
		name = {'train-stop-depot', 'train-stop-supplier', 'train-stop-consumer'}
	})

	for _, entity in pairs(entities) do
		Tracker.add_data_entity(entity)
	end
end