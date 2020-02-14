data:extend(
    {
        {
            type = "technology",
            name = "easytrain",
            icon = "__EasyTrains__/thumbnail.png",
            icon_size = 144,
            prerequisites = {"automated-rail-transportation"},
            effects = {
                {
                    type = "unlock-recipe",
                    recipe = "train-stop-depot"
                },
                {
                    type = "unlock-recipe",
                    recipe = "train-stop-supplier"
                },
                {
                    type = "unlock-recipe",
                    recipe = "train-stop-consumer"
                }
            },
            unit = {
                count = 30,
                time = 75,
                order = "d-s-c",
                ingredients = {
                    {"automation-science-pack", 1},
                    {"logistic-science-pack", 1}
                }
            }
        }
    }
)
