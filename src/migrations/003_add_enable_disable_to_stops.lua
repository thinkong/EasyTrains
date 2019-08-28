for _, train_stop in pairs(global.conductor.train_stops) do
   for configName, configData in pairs(config) do
		if train_stop[configName] == nil then
			train_stop[configName] = configData.default
		end
		if configData.enable_disable and train_stop[configName .. "_enable_disable"] == nil then
			train_stop[configName .. "_enable_disable"] = false
		end
    end
end