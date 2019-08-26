local depot = clone("train-stop", "train-stop", "train-stop-depot")
depot.icon = "__SamTrain__/graphics/icons/depot.png"
depot.fast_replaceable_group = "train-stop"
local supplier = clone("train-stop", "train-stop", "train-stop-supplier")
supplier.icon = "__SamTrain__/graphics/icons/supplier.png"
supplier.fast_replaceable_group = "train-stop"
local consumer = clone("train-stop", "train-stop", "train-stop-consumer")
consumer.icon = "__SamTrain__/graphics/icons/consumer.png"
consumer.fast_replaceable_group = "train-stop"

local st_data_entity = clone('programmable-speaker', 'programmable-speaker', 'st-data-entity')
st_data_entity.minable = { hardness = 0, mining_time = 0, result = 'st-data-entity' }
st_data_entity.max_health = 3
st_data_entity.icon = "__SamTrain__/graphics/icons/data-entity.png"
st_data_entity.item_slot_count = 100
st_data_entity.selectable_in_game = false
st_data_entity.collision_mask = {"not-colliding-with-itself"}
st_data_entity.flags = {"player-creation", "not-repairable"}
st_data_entity.sprite = {
	layers = {
		{ 
			filename = "__core__/graphics/empty.png",
			priority = "extra-high",
			width = 1,
			height = 1,
			hr_version = {
				filename = "__core__/graphics/empty.png",
				priority = "extra-high",
				width = 1,
				height = 1
			}
		}
	}
}
st_data_entity.energy_usage_per_tick = "1W"
st_data_entity.energy_source = {
      type = "void",
      usage_priority = "primary-input",
      emissions = 0,
    }


data:extend(
    {
        depot,
        supplier,
        consumer,
		st_data_entity
    }
)
