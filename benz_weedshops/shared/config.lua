Config = {}

Config.Debug = false
Config.UseDatabaseLocations = true
-- IMPORTANT: keep this false after you place/move locations in-game.
-- When true, the included White Widow preset will be force-restored on every resource/server restart.
-- Only turn it on once if you intentionally want to reset the default White Widow layout.
Config.ForceDefaultMLOStations = false
Config.ReplaceOldDefaultLocationNames = { 'White Widow Downtown', 'White Widow MLO' }
Config.EnableAdminEditor = true
Config.AdminGroups = { 'admin', 'god' }
Config.AdminAce = 'benz_weedshops.admin'
Config.AdminCommand = 'weedadmin'
Config.CoordCommand = 'wwcoords'
Config.AllowBossEditor = true -- boss grade players can edit locations locked to their own job
Config.DefaultJob = 'whitewidow'
Config.BossGrade = 4
Config.JobLockMode = 'location' -- location = each shop has its own job lock


-- Business stash settings. Stashes are placed in-game from /weedadmin and saved in the database.
Config.EnableBusinessStashes = true
Config.DefaultStashSlots = 60
Config.DefaultStashWeight = 250000 -- ox_inventory weight in grams
Config.StashTargetIcon = 'fa-solid fa-box-archive'
Config.StashTargetLabel = 'Open Business Stash'


-- Supply store settings. Supply stores are placed in-game from /weedadmin and saved in the database.
-- Players with the matching business job can buy crafting supplies here through ox_inventory.
Config.EnableSupplyStores = true
Config.SupplyStoreTargetIcon = 'fa-solid fa-cart-shopping'
Config.SupplyStoreTargetLabel = 'Open Supply Store'
Config.DefaultSupplyStoreSize = vec3(1.6, 1.6, 1.8)
Config.SupplyStoreItems = {
    { name = 'weed_soil', price = 25, count = 500 },
    { name = 'weed_water', price = 15, count = 500 },
    { name = 'empty_baggie', price = 5, count = 1000 },
    { name = 'rolling_paper', price = 8, count = 1000 },
    { name = 'king_rolling_paper', price = 12, count = 1000 },
    { name = 'infused_paper', price = 35, count = 500 },
    { name = 'blunt_wrap', price = 15, count = 1000 },
    { name = 'honey_blunt_wrap', price = 20, count = 1000 },
    { name = 'grape_blunt_wrap', price = 20, count = 1000 },
    { name = 'premium_blunt_wrap', price = 45, count = 500 },
    { name = 'brownie_mix', price = 30, count = 500 },
    { name = 'cookie_dough', price = 30, count = 500 },
    { name = 'gummy_base', price = 35, count = 500 },
    { name = 'rice_treat_base', price = 30, count = 500 },
    { name = 'cupcake_mix', price = 35, count = 500 },
    { name = 'chocolate_bar_base', price = 40, count = 500 },
    { name = 'cereal_bar_base', price = 35, count = 500 },
    { name = 'lollipop_base', price = 25, count = 500 },
    { name = 'glass_bong', price = 150, count = 100 }
}




-- Customer dispensary menu settings. Customer stores are placed in-game from /weedadmin and saved in the database.
-- Customers can browse products, build a cart, checkout with cash/bank, and sales deposit into the business account.
Config.EnableCustomerMenus = true
Config.CustomerStoreTargetIcon = 'fa-solid fa-store'
Config.CustomerStoreTargetLabel = 'Open Dispensary Menu'
Config.DefaultCustomerStoreSize = vec3(1.6, 1.6, 1.8)
Config.CustomerStockFromBusinessStashes = true -- when true, customer purchases pull items from placed business stashes
Config.CustomerRequireBusinessDeposit = false -- if true, checkout fails when no banking/management deposit export works
Config.CustomerPaymentAccounts = { cash = true, bank = true }
Config.CustomerBusinessDeposit = {
    mode = 'okokBanking', -- okokBanking, auto, renewed-banking, qbx_management, qb-management, none
    accountPrefix = '', -- example: 'society_' if your banking account names are society_whitewidow
    reason = 'weedfactory-customer-sale',
    -- okokBanking normally uses the job/account name like 'whitewidow'.
    -- If your okokBanking society accounts use society_whitewidow, set accountPrefix = 'society_'.
}
Config.CustomerMenuCategories = {
    bags = { label = 'Flower Bags', icon = 'fa-solid fa-bag-shopping' },
    joints = { label = 'Joints & Blunts', icon = 'fa-solid fa-cannabis' },
    edibles = { label = 'Edibles', icon = 'fa-solid fa-cookie' },
    bongs = { label = 'Bongs', icon = 'fa-solid fa-bong' }
}
Config.CustomerPriceMultiplier = 1.0

-- Store blips and boss menu target settings
Config.EnableStoreBlips = true
Config.Blip = {
    sprite = 140,
    color = 2,
    scale = 0.75,
    shortRange = true,
    namePrefix = ''
}

-- Boss menu target. Set BossMenuMode to match your server.
-- This resource now uses its own built-in business account UI for deposits/withdrawals.
Config.EnableBossMenuTarget = true
Config.BossMenuMode = 'qbx_management'
Config.OpenBossMenuEvent = nil
Config.OpenBossMenuCommand = nil -- example: 'bossmenu' if your server uses a command
Config.BossMenuLabel = 'Open Boss Menu'
Config.BossMenuIcon = 'fa-solid fa-user-tie'

Config.Progress = {
    Grow = 12000,
    Harvest = 7000,
    Dry = 10000,
    Roll = 6500,
    Edible = 8000,
    BongPack = 5000,
    Sell = 4500,
    Smoke = 7000
}

Config.Effects = {
    joint = { duration = 45000, effect = 'DrugsTrevorClownsFight' },
    blunt = { duration = 55000, effect = 'DrugsTrevorClownsFight' },
    bong = { duration = 65000, effect = 'DrugsMichaelAliensFight' },
    edible = { duration = 90000, effect = 'DrugsDrivingIn' }
}

Config.Strains = {
    purple_punch = { label = 'Purple Punch', seed = 'weed_seed_purple_punch', bud = 'weed_purple_punch', price = 95 },
    cereal_milk = { label = 'Cereal Milk', seed = 'weed_seed_cereal_milk', bud = 'weed_cereal_milk', price = 110 },
    lemon_tree = { label = 'Lemon Tree', seed = 'weed_seed_lemon_tree', bud = 'weed_lemon_tree', price = 90 },
    kush_mintz = { label = 'Kush Mintz', seed = 'weed_seed_kush_mintz', bud = 'weed_kush_mintz', price = 120 },
    apple_fritter = { label = 'Apple Fritter', seed = 'weed_seed_apple_fritter', bud = 'weed_apple_fritter', price = 105 },
    sunset_sherbert = { label = 'Sunset Sherbert', seed = 'weed_seed_sunset_sherbert', bud = 'weed_sunset_sherbert', price = 100 },
    tropical_punch = { label = 'Tropical Punch', seed = 'weed_seed_tropical_punch', bud = 'weed_tropical_punch', price = 98 },
    mimosa = { label = 'Mimosa', seed = 'weed_seed_mimosa', bud = 'weed_mimosa', price = 115 },
    devil_kiss = { label = "Devil's Kiss", seed = 'weed_seed_devil_kiss', bud = 'weed_devil_kiss', price = 125 },
    white_widow = { label = 'White Widow', seed = 'weed_seed_white_widow', bud = 'weed_white_widow', price = 130 },
    blue_dream = { label = 'Blue Dream', seed = 'weed_seed_blue_dream', bud = 'weed_blue_dream', price = 102 },
    og_kush = { label = 'OG Kush', seed = 'weed_seed_og_kush', bud = 'weed_og_kush', price = 118 },
    gelato = { label = 'Gelato', seed = 'weed_seed_gelato', bud = 'weed_gelato', price = 122 },
    runtz = { label = 'Runtz', seed = 'weed_seed_runtz', bud = 'weed_runtz', price = 128 },
    wedding_cake = { label = 'Wedding Cake', seed = 'weed_seed_wedding_cake', bud = 'weed_wedding_cake', price = 124 },
    granddaddy_purple = { label = 'Granddaddy Purple', seed = 'weed_seed_granddaddy_purple', bud = 'weed_granddaddy_purple', price = 112 },
    sour_diesel = { label = 'Sour Diesel', seed = 'weed_seed_sour_diesel', bud = 'weed_sour_diesel', price = 108 },
    pineapple_express = { label = 'Pineapple Express', seed = 'weed_seed_pineapple_express', bud = 'weed_pineapple_express', price = 116 },
    zkittlez = { label = 'Zkittlez', seed = 'weed_seed_zkittlez', bud = 'weed_zkittlez', price = 119 },
    ice_cream_cake = { label = 'Ice Cream Cake', seed = 'weed_seed_ice_cream_cake', bud = 'weed_ice_cream_cake', price = 126 }
}

Config.Rollables = {
    classic_joint = { label = 'Classic Joint', itemPrefix = 'joint_', requiredItem = 'rolling_paper', flower = 1, priceMultiplier = 1.4, effect = 'joint' },
    king_size_joint = { label = 'King Size Joint', itemPrefix = 'king_joint_', requiredItem = 'king_rolling_paper', flower = 2, priceMultiplier = 2.4, effect = 'joint' },
    infused_joint = { label = 'Infused Joint', itemPrefix = 'infused_joint_', requiredItem = 'infused_paper', flower = 2, priceMultiplier = 3.0, effect = 'joint' },
    classic_blunt = { label = 'Classic Blunt', itemPrefix = 'blunt_', requiredItem = 'blunt_wrap', flower = 2, priceMultiplier = 2.7, effect = 'blunt' },
    honey_blunt = { label = 'Honey Blunt', itemPrefix = 'honey_blunt_', requiredItem = 'honey_blunt_wrap', flower = 2, priceMultiplier = 3.1, effect = 'blunt' },
    grape_blunt = { label = 'Grape Blunt', itemPrefix = 'grape_blunt_', requiredItem = 'grape_blunt_wrap', flower = 2, priceMultiplier = 3.1, effect = 'blunt' },
    white_widow_blunt = { label = 'White Widow Signature Blunt', itemPrefix = 'ww_blunt_', requiredItem = 'premium_blunt_wrap', flower = 3, priceMultiplier = 4.2, effect = 'blunt' }
}

Config.Edibles = {
    brownie = { label = 'Brownie', itemPrefix = 'edible_brownie_', baseItem = 'brownie_mix', flower = 1, priceMultiplier = 1.8, effect = 'edible' },
    cookie = { label = 'Cookie', itemPrefix = 'edible_cookie_', baseItem = 'cookie_dough', flower = 1, priceMultiplier = 1.7, effect = 'edible' },
    gummy_bears = { label = 'Gummy Bears', itemPrefix = 'edible_gummies_', baseItem = 'gummy_base', flower = 1, priceMultiplier = 1.9, effect = 'edible' },
    rice_treat = { label = 'Rice Treat', itemPrefix = 'edible_rice_treat_', baseItem = 'rice_treat_base', flower = 1, priceMultiplier = 1.75, effect = 'edible' },
    cupcake = { label = 'Cupcake', itemPrefix = 'edible_cupcake_', baseItem = 'cupcake_mix', flower = 1, priceMultiplier = 2.0, effect = 'edible' },
    chocolate_bar = { label = 'Chocolate Bar', itemPrefix = 'edible_chocolate_', baseItem = 'chocolate_bar_base', flower = 2, priceMultiplier = 2.6, effect = 'edible' },
    cereal_bar = { label = 'Cereal Bar', itemPrefix = 'edible_cereal_bar_', baseItem = 'cereal_bar_base', flower = 2, priceMultiplier = 2.4, effect = 'edible' },
    lollipop = { label = 'Lollipop', itemPrefix = 'edible_lollipop_', baseItem = 'lollipop_base', flower = 1, priceMultiplier = 1.65, effect = 'edible' }
}

Config.Weights = {
    gram = { label = '1g Bag', amount = 1, multiplier = 1.0, itemPrefix = 'weed_bag_1g_' },
    eighth = { label = '3.5g Bag', amount = 4, multiplier = 3.3, itemPrefix = 'weed_bag_35g_' },
    quarter = { label = '7g Bag', amount = 7, multiplier = 6.5, itemPrefix = 'weed_bag_7g_' },
    ounce = { label = '28g Bag', amount = 28, multiplier = 25.0, itemPrefix = 'weed_bag_28g_' }
}

Config.RequiredItems = {
    soil = 'weed_soil',
    water = 'weed_water',
    baggie = 'empty_baggie',
    rollingPaper = 'rolling_paper', -- legacy fallback
    edibleBase = 'edible_base', -- legacy fallback
    bong = 'glass_bong'
}

Config.StationTypes = {
    grow = { label = 'Grow Plants', icon = 'fa-solid fa-seedling' },
    dry = { label = 'Dry/Cure Flower', icon = 'fa-solid fa-fan' },
    roll = { label = 'Roll Joints & Blunts', icon = 'fa-solid fa-cannabis' },
    edibles = { label = 'Make Edibles', icon = 'fa-solid fa-cookie' },
    bags = { label = 'Package Weed Bags', icon = 'fa-solid fa-bag-shopping' },
    bong = { label = 'Pack Bong', icon = 'fa-solid fa-bong' },
    sell = { label = 'Sell Products', icon = 'fa-solid fa-cash-register' }
}

-- These seed locations are loaded when the DB is empty. Add as many shops as you want.
Config.DefaultLocations = {
    --[[{
        -- Preset for the uploaded White Widow MLO using the hw1_23 / md_weedshop_mlo map.
        -- If your MLO shell is slightly offset, use /wwcoords or /weedadmin to move stations in-game.
        name = 'White Widow MLO',
        job = 'whitewidow',
        enabled = true,
        blip = vec3(188.74, -242.61, 54.08),
        boss = { coords = vec3(200.35, -239.42, 54.08), size = vec3(1.4, 1.2, 1.6), rotation = 250.0, label = 'White Widow Boss Menu' },
        stations = {
            -- Front sales counter / register area
            { type = 'sell', coords = vec3(188.74, -242.61, 54.08), size = vec3(2.0, 1.1, 1.6), rotation = 250.0, label = 'Front Counter Sales' },

            -- Main customer floor / display counters
            { type = 'bong', coords = vec3(190.63, -247.33, 54.08), size = vec3(1.4, 1.4, 1.6), rotation = 250.0, label = 'Pack Bong' },
            { type = 'roll', coords = vec3(192.69, -244.87, 54.08), size = vec3(2.0, 1.2, 1.6), rotation = 250.0, label = 'Roll Joints & Blunts' },
            { type = 'bags', coords = vec3(194.86, -242.91, 54.08), size = vec3(2.0, 1.2, 1.6), rotation = 250.0, label = 'Package Weed Bags' },

            -- Back work room / prep area
            { type = 'edibles', coords = vec3(198.34, -241.70, 54.08), size = vec3(2.0, 1.5, 1.6), rotation = 250.0, label = 'Make Edibles' },
            { type = 'dry', coords = vec3(201.30, -243.26, 54.08), size = vec3(2.0, 1.5, 1.8), rotation = 250.0, label = 'Dry/Cure Flower' },

            -- Grow room / rear room
            { type = 'grow', coords = vec3(204.33, -240.97, 54.08), size = vec3(2.6, 2.2, 2.0), rotation = 250.0, label = 'Grow Plants' }
        }
    }]]--
}