local depot = clone("train-stop", "recipe", "train-stop-depot")
depot.ingredients = {
    {"train-stop", 1},
    {"iron-plate", 6},
    {"steel-plate", 3},
    {"iron-stick", 6},
    {"electronic-circuit", 5}
}
local supplier = clone("train-stop", "recipe", "train-stop-supplier")
supplier.ingredients = {
    {"train-stop", 1},
    {"iron-plate", 6},
    {"steel-plate", 3},
    {"iron-stick", 6},
    {"electronic-circuit", 5}
}
local consumer = clone("train-stop", "recipe", "train-stop-consumer")
consumer.ingredients = {
    {"train-stop", 1},
    {"iron-plate", 6},
    {"steel-plate", 3},
    {"iron-stick", 6},
    {"electronic-circuit", 5}
}

data:extend(
    {
        depot,
        supplier,
        consumer
    }
)
