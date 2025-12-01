-- DRAP Lookups
-- This file contains all items and locations for Dead Rising Deluxe Remaster
-- IDs must match those defined in the Python apworld files

local Lookups = {}

-- Items lookup table
-- dr_code matches the dr_code in Items.py
Lookups.items = {
    -- Events
    { name = "Victory", dr_code = 1000, category = "EVENT" },

    -- Consumables
    { name = "Orange Juice", dr_code = 1, category = "CONSUMABLE" },
    { name = "Pizza", dr_code = 2, category = "CONSUMABLE" },
    { name = "Milk", dr_code = 3, category = "CONSUMABLE" },
    { name = "Coffee Creamer", dr_code = 4, category = "CONSUMABLE" },
    { name = "Wine", dr_code = 5, category = "CONSUMABLE" },
    { name = "Well Done Steak", dr_code = 6, category = "CONSUMABLE" },
    { name = "Yogurt", dr_code = 7, category = "CONSUMABLE" },
    { name = "Apple", dr_code = 8, category = "CONSUMABLE" },
    { name = "Pie", dr_code = 9, category = "CONSUMABLE" },
    { name = "Bread", dr_code = 10, category = "CONSUMABLE" },
}

-- Locations lookup table
-- Each location needs an id, name, region, and can have properties like randomized, victory, sent, force_item
Lookups.locations = {
    -- Rooftop (base_id + 0*1000 = 1230000-1230999)
    { id = 1230000, name = "Start the game", region = "Rooftop", randomized = 0, victory = true },

    -- Heliport (base_id + 1*1000 = 1231000-1231999)
    { id = 1231000, name = "Rescue Jeff Meyer", region = "Heliport", randomized = 1 },
    { id = 1231001, name = "Rescue Natalie Meyer", region = "Heliport", randomized = 1 },

    -- Paradise Plaza (base_id + 2*1000 = 1232000-1232999)
    { id = 1232000, name = "Rescue Greg Simpson", region = "Paradise Plaza", randomized = 1 },
    { id = 1232001, name = "Rescue Leah Stein", region = "Paradise Plaza", randomized = 1 },
    { id = 1232002, name = "Rescue Kindell Johnson", region = "Paradise Plaza", randomized = 1 },
    { id = 1232003, name = "Rescue Beth Shrake", region = "Paradise Plaza", randomized = 1 },
    { id = 1232004, name = "Rescue Cheryl Jones", region = "Paradise Plaza", randomized = 1 },
    { id = 1232005, name = "Rescue Nathan Crabbe", region = "Paradise Plaza", randomized = 1 },

    -- Level Ups (base_id + 3*1000 = 1233000-1233999)
    { id = 1233000, name = "Reach Level 2", region = "Level Ups", randomized = 1 },
    { id = 1233001, name = "Reach Level 3", region = "Level Ups", randomized = 1 },
    { id = 1233002, name = "Reach Level 4", region = "Level Ups", randomized = 1 },
    { id = 1233003, name = "Reach Level 5", region = "Level Ups", randomized = 1 },
    { id = 1233004, name = "Reach Level 6", region = "Level Ups", randomized = 1 },
    { id = 1233005, name = "Reach Level 7", region = "Level Ups", randomized = 1 },
    { id = 1233006, name = "Reach Level 8", region = "Level Ups", randomized = 1 },
    { id = 1233007, name = "Reach Level 9", region = "Level Ups", randomized = 1 },
    { id = 1233008, name = "Reach Level 10", region = "Level Ups", randomized = 1 },
    { id = 1233009, name = "Reach Level 11", region = "Level Ups", randomized = 1 },
    { id = 1233010, name = "Reach Level 12", region = "Level Ups", randomized = 1 },
    { id = 1233011, name = "Reach Level 13", region = "Level Ups", randomized = 1 },
    { id = 1233012, name = "Reach Level 14", region = "Level Ups", randomized = 1 },
    { id = 1233013, name = "Reach Level 15", region = "Level Ups", randomized = 1 },
    { id = 1233014, name = "Reach Level 16", region = "Level Ups", randomized = 1 },
    { id = 1233015, name = "Reach Level 17", region = "Level Ups", randomized = 1 },
    { id = 1233016, name = "Reach Level 18", region = "Level Ups", randomized = 1 },
    { id = 1233017, name = "Reach Level 19", region = "Level Ups", randomized = 1 },
    { id = 1233018, name = "Reach Level 20", region = "Level Ups", randomized = 1 },
    { id = 1233019, name = "Reach Level 21", region = "Level Ups", randomized = 1 },
    { id = 1233020, name = "Reach Level 22", region = "Level Ups", randomized = 1 },
    { id = 1233021, name = "Reach Level 23", region = "Level Ups", randomized = 1 },
    { id = 1233022, name = "Reach Level 24", region = "Level Ups", randomized = 1 },
    { id = 1233023, name = "Reach Level 25", region = "Level Ups", randomized = 1 },
    { id = 1233024, name = "Reach Level 26", region = "Level Ups", randomized = 1 },
    { id = 1233025, name = "Reach Level 27", region = "Level Ups", randomized = 1 },
    { id = 1233026, name = "Reach Level 28", region = "Level Ups", randomized = 1 },
    { id = 1233027, name = "Reach Level 29", region = "Level Ups", randomized = 1 },
    { id = 1233028, name = "Reach Level 30", region = "Level Ups", randomized = 1 },
    { id = 1233029, name = "Reach Level 31", region = "Level Ups", randomized = 1 },
    { id = 1233030, name = "Reach Level 32", region = "Level Ups", randomized = 1 },
    { id = 1233031, name = "Reach Level 33", region = "Level Ups", randomized = 1 },
    { id = 1233032, name = "Reach Level 34", region = "Level Ups", randomized = 1 },
    { id = 1233033, name = "Reach Level 35", region = "Level Ups", randomized = 1 },
    { id = 1233034, name = "Reach Level 36", region = "Level Ups", randomized = 1 },
    { id = 1233035, name = "Reach Level 37", region = "Level Ups", randomized = 1 },
    { id = 1233036, name = "Reach Level 38", region = "Level Ups", randomized = 1 },
    { id = 1233037, name = "Reach Level 39", region = "Level Ups", randomized = 1 },
    { id = 1233038, name = "Reach Level 40", region = "Level Ups", randomized = 1 },
    { id = 1233039, name = "Reach Level 41", region = "Level Ups", randomized = 1 },
    { id = 1233040, name = "Reach Level 42", region = "Level Ups", randomized = 1 },
    { id = 1233041, name = "Reach Level 43", region = "Level Ups", randomized = 1 },
    { id = 1233042, name = "Reach Level 44", region = "Level Ups", randomized = 1 },
    { id = 1233043, name = "Reach Level 45", region = "Level Ups", randomized = 1 },
    { id = 1233044, name = "Reach Level 46", region = "Level Ups", randomized = 1 },
    { id = 1233045, name = "Reach Level 47", region = "Level Ups", randomized = 1 },
    { id = 1233046, name = "Reach Level 48", region = "Level Ups", randomized = 1 },
    { id = 1233047, name = "Reach Level 49", region = "Level Ups", randomized = 1 },
    { id = 1233048, name = "Reach Level 50", region = "Level Ups", randomized = 1 },
}

return Lookups
