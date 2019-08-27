local function does_train_stop_have_data_entity(entity)
	for _, train_stop in pairs(global.conductor.train_stops) do
		if train_stop.data_entity == entity then
			return true
		end
	end

	return false
end

for _, surface in pairs(game.surfaces) do
	local entities = surface.find_entities_filtered({
		name = {'st-data-entity'}
	})

	for _, entity in pairs(entities) do
		if not does_train_stop_have_data_entity(entity) then
			entity.destroy()
		end
	end
end