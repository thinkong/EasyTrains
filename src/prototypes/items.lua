local depot = clone("train-stop", "item", "train-stop-depot")
depot.icon = "__EasyTrains__/graphics/icons/train-stop-depot.png"
depot.order = "a[train-system]-c[train-stop]-d[train-stop-depot]"

local supplier = clone("train-stop", "item", "train-stop-supplier")
supplier.icon = "__EasyTrains__/graphics/icons/train-stop-supplier.png"
supplier.order = "a[train-system]-c[train-stop]-e[train-stop-depot]"

local consumer = clone("train-stop", "item", "train-stop-consumer")
consumer.icon = "__EasyTrains__/graphics/icons/train-stop-consumer.png"
consumer.order = "a[train-system]-c[train-stop]-f[train-stop-consumer]"

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
