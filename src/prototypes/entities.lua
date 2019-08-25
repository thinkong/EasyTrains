local depot = clone("train-stop", "train-stop", "train-stop-depot")
depot.icon = "__SamTrain__/graphics/icons/depot.png"
depot.fast_replaceable_group = "train-stop"
local supplier = clone("train-stop", "train-stop", "train-stop-supplier")
supplier.icon = "__SamTrain__/graphics/icons/supplier.png"
supplier.fast_replaceable_group = "train-stop"
local consumer = clone("train-stop", "train-stop", "train-stop-consumer")
consumer.icon = "__SamTrain__/graphics/icons/consumer.png"
consumer.fast_replaceable_group = "train-stop"

data:extend(
    {
        depot,
        supplier,
        consumer
    }
)
