local depot = clone("train-stop", "item", "train-stop-depot")
depot.icon = "__SamTrain__/graphics/icons/depot.png"
depot.order = depot.order .. "-c"

local supplier = clone("train-stop", "item", "train-stop-supplier")
supplier.icon = "__SamTrain__/graphics/icons/supplier.png"
supplier.order = supplier.order .. "-c"

local consumer = clone("train-stop", "item", "train-stop-consumer")
consumer.icon = "__SamTrain__/graphics/icons/consumer.png"
consumer.order = consumer.order .. "-c"

local st_data_entity = {
	name = "st-data-entity",
	type = "item",
	icon = "__core__/graphics/empty.png",
	flags = { "hidden" },
	subgroup = "circuit-network",
	place_result = "st-data-entity",
	order = "b[combinators]-c[st-data-entity]",
	stack_size = 16384,
	icon_size = 1
}

data:extend(
    {
        depot,
        supplier,
        consumer,
		st_data_entity
    }
)
