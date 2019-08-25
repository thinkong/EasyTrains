local depot = clone("train-stop", "item", "train-stop-depot")
depot.icon = "__SamTrain__/graphics/icons/depot.png"
depot.order = depot.order .. "-c"

local supplier = clone("train-stop", "item", "train-stop-supplier")
supplier.icon = "__SamTrain__/graphics/icons/supplier.png"
supplier.order = supplier.order .. "-c"

local consumer = clone("train-stop", "item", "train-stop-consumer")
consumer.icon = "__SamTrain__/graphics/icons/consumer.png"
consumer.order = consumer.order .. "-c"

data:extend(
    {
        depot,
        supplier,
        consumer
    }
)
