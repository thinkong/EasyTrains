local depot = clone("train-stop", "train-stop", "train-stop-depot")
depot.icon = "__SamTrain__/graphics/icons/train-stop-depot.png"
depot.fast_replaceable_group = "train-stop"

depot.animations = make_4way_animation_from_spritesheet({ layers =
{
    {
    filename = "__SamTrain__/graphics/entity/train-stop-bottom-depot.png",
    line_length = 4,
    width = 71,
    height = 146,
    direction_count = 4,
    shift = util.by_pixel(-0.5, -27),
        hr_version =
        {
        filename = "__SamTrain__/graphics/entity/hr-train-stop-bottom-depot.png",
        line_length = 4,
        width = 140,
        height = 291,
        direction_count = 4,
        shift = util.by_pixel(-0.5, -26.75),
        scale = 0.5
        }
    },
    {
    filename = "__base__/graphics/entity/train-stop/train-stop-shadow.png",
    line_length = 4,
    width = 361,
    height = 304,
    direction_count = 4,
    shift = util.by_pixel(-7.5, 18),
    draw_as_shadow = true,
        hr_version =
        {
        filename = "__base__/graphics/entity/train-stop/hr-train-stop-shadow.png",
        line_length = 4,
        width = 720,
        height = 607,
        direction_count = 4,
        shift = util.by_pixel(-7.5, 17.75),
        draw_as_shadow = true,
        scale = 0.5
        }
    }
}})

local supplier = clone("train-stop", "train-stop", "train-stop-supplier")
supplier.icon = "__SamTrain__/graphics/icons/train-stop-supplier.png"
supplier.fast_replaceable_group = "train-stop"

supplier.animations = make_4way_animation_from_spritesheet({ layers =
{
    {
    filename = "__SamTrain__/graphics/entity/train-stop-bottom-supplier.png",
    line_length = 4,
    width = 71,
    height = 146,
    direction_count = 4,
    shift = util.by_pixel(-0.5, -27),
        hr_version =
        {
        filename = "__SamTrain__/graphics/entity/hr-train-stop-bottom-supplier.png",
        line_length = 4,
        width = 140,
        height = 291,
        direction_count = 4,
        shift = util.by_pixel(-0.5, -26.75),
        scale = 0.5
        }
    },
    {
    filename = "__base__/graphics/entity/train-stop/train-stop-shadow.png",
    line_length = 4,
    width = 361,
    height = 304,
    direction_count = 4,
    shift = util.by_pixel(-7.5, 18),
    draw_as_shadow = true,
        hr_version =
        {
        filename = "__base__/graphics/entity/train-stop/hr-train-stop-shadow.png",
        line_length = 4,
        width = 720,
        height = 607,
        direction_count = 4,
        shift = util.by_pixel(-7.5, 17.75),
        draw_as_shadow = true,
        scale = 0.5
        }
    }
}})


local consumer = clone("train-stop", "train-stop", "train-stop-consumer")
consumer.icon = "__SamTrain__/graphics/icons/train-stop-consumer.png"
consumer.fast_replaceable_group = "train-stop"
consumer.animations = make_4way_animation_from_spritesheet({ layers =
{
    {
    filename = "__SamTrain__/graphics/entity/train-stop-bottom-consumer.png",
    line_length = 4,
    width = 71,
    height = 146,
    direction_count = 4,
    shift = util.by_pixel(-0.5, -27),
        hr_version =
        {
        filename = "__SamTrain__/graphics/entity/hr-train-stop-bottom-consumer.png",
        line_length = 4,
        width = 140,
        height = 291,
        direction_count = 4,
        shift = util.by_pixel(-0.5, -26.75),
        scale = 0.5
        }
    },
    {
    filename = "__base__/graphics/entity/train-stop/train-stop-shadow.png",
    line_length = 4,
    width = 361,
    height = 304,
    direction_count = 4,
    shift = util.by_pixel(-7.5, 18),
    draw_as_shadow = true,
        hr_version =
        {
        filename = "__base__/graphics/entity/train-stop/hr-train-stop-shadow.png",
        line_length = 4,
        width = 720,
        height = 607,
        direction_count = 4,
        shift = util.by_pixel(-7.5, 17.75),
        draw_as_shadow = true,
        scale = 0.5
        }
    }
}})

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
