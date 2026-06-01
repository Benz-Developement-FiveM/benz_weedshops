local createdZones = {}
local createdBlips = {}
local createdBossZones = {}
local createdStashZones = {}
local createdSupplyStoreZones = {}
local createdCustomerStoreZones = {}
local currentLocationId = nil
local cachedLocations = {}
local currentRollType = nil
local currentEdibleType = nil
local customerCart = {}
local customerProducts = {}
local currentCustomerLocationId = nil

local function notify(msg, type)
    lib.notify({ title = 'Weed Factory', description = msg, type = type or 'inform' })
end

local function doProgress(label, duration, anim)
    return lib.progressCircle({
        duration = duration,
        label = label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = anim or { dict = 'amb@prop_human_bum_bin@base', clip = 'base' }
    })
end

local function requirementLines(req)
    local lines = {}
    for _, item in ipairs(req.items or {}) do
        local status = item.ok and '✅' or '❌'
        lines[#lines + 1] = ('%s %s: %s/%s'):format(status, item.label or item.item, item.have or 0, item.need or 0)
    end
    return table.concat(lines, '\n')
end

local function showRequirementPopup(action, args, progressLabel, duration, anim, serverEvent)
    args = args or {}
    local req = lib.callback.await('benz_weedshops:server:getRequirements', false, action, args)
    if not req then
        return notify('Unable to load item requirements.', 'error')
    end

    local description = requirementLines(req)
    if description == '' then description = 'No item requirements found.' end

    local options = {
        {
            title = req.title or 'Item Requirements',
            description = description,
            icon = req.hasAll and 'circle-check' or 'circle-xmark',
            disabled = true
        }
    }

    if req.hasAll then
        options[#options + 1] = {
            title = 'Start ' .. (req.actionLabel or 'Crafting'),
            description = 'You have everything needed for this item.',
            icon = 'play',
            onSelect = function()
                if doProgress(progressLabel, duration, anim) then
                    TriggerServerEvent(serverEvent, table.unpack(args.serverArgs or {}))
                end
            end
        }
    else
        options[#options + 1] = {
            title = 'Missing Required Items',
            description = 'Gather the items above before making this.',
            icon = 'triangle-exclamation',
            disabled = true
        }
    end

    lib.registerContext({
        id = 'weed_requirements_popup',
        title = req.title or 'Item Requirements',
        options = options
    })
    lib.showContext('weed_requirements_popup')
end

local function strainOptions(eventName)
    local opts = {}
    for strain, data in pairs(Config.Strains) do
        opts[#opts + 1] = { title = data.label, description = 'Use this strain', event = eventName, args = { strain = strain, locationId = currentLocationId } }
    end
    table.sort(opts, function(a, b) return a.title < b.title end)
    return opts
end

local function openStrainMenu(id, title, eventName, locationId)
    currentLocationId = locationId or currentLocationId
    lib.registerContext({ id = id, title = title, options = strainOptions(eventName) })
    lib.showContext(id)
end


local function rollTypeOptions(locationId)
    currentLocationId = locationId or currentLocationId
    local opts = {}
    for rollType, data in pairs(Config.Rollables or {}) do
        opts[#opts + 1] = {
            title = data.label,
            description = ('Requires %sx flower + %s'):format(data.flower or 1, data.requiredItem or Config.RequiredItems.rollingPaper),
            onSelect = function()
                currentRollType = rollType
                openStrainMenu('weed_roll_strain_' .. rollType, 'Roll ' .. data.label, 'benz_weedshops:client:roll', currentLocationId)
            end
        }
    end
    table.sort(opts, function(a, b) return a.title < b.title end)
    lib.registerContext({ id = 'weed_roll_type_menu', title = 'Roll Joints & Blunts', options = opts })
    lib.showContext('weed_roll_type_menu')
end

local function edibleTypeOptions(locationId)
    currentLocationId = locationId or currentLocationId
    local opts = {}
    for edibleType, data in pairs(Config.Edibles or {}) do
        opts[#opts + 1] = {
            title = data.label,
            description = ('Requires %sx flower + %s'):format(data.flower or 1, data.baseItem or Config.RequiredItems.edibleBase),
            onSelect = function()
                currentEdibleType = edibleType
                openStrainMenu('weed_edible_strain_' .. edibleType, 'Make ' .. data.label, 'benz_weedshops:client:edible', currentLocationId)
            end
        }
    end
    table.sort(opts, function(a, b) return a.title < b.title end)
    lib.registerContext({ id = 'weed_edible_type_menu', title = 'Make Edibles', options = opts })
    lib.showContext('weed_edible_type_menu')
end

RegisterNetEvent('benz_weedshops:client:growMenu', function(data) openStrainMenu('weed_grow_menu', 'Select Strain To Grow', 'benz_weedshops:client:grow', data and data.locationId) end)
RegisterNetEvent('benz_weedshops:client:dryMenu', function(data) openStrainMenu('weed_dry_menu', 'Dry/Cure Flower', 'benz_weedshops:client:dry', data and data.locationId) end)
RegisterNetEvent('benz_weedshops:client:rollMenu', function(data) rollTypeOptions(data and data.locationId) end)
RegisterNetEvent('benz_weedshops:client:edibleMenu', function(data) edibleTypeOptions(data and data.locationId) end)
RegisterNetEvent('benz_weedshops:client:bongMenu', function(data) openStrainMenu('weed_bong_menu', 'Pack Bong', 'benz_weedshops:client:bong', data and data.locationId) end)

for weight in pairs(Config.Weights) do
    RegisterNetEvent('benz_weedshops:client:bag:' .. weight, function(data)
        TriggerEvent('benz_weedshops:client:bag', { strain = data.strain, weight = weight, locationId = data.locationId or currentLocationId })
    end)
end

RegisterNetEvent('benz_weedshops:client:bagMenu', function(data)
    currentLocationId = data and data.locationId or currentLocationId
    local opts = {}
    for weight, wdata in pairs(Config.Weights) do
        opts[#opts + 1] = {
            title = wdata.label,
            description = ('Requires %s dried flower'):format(wdata.amount),
            onSelect = function()
                openStrainMenu('weed_bag_strain_' .. weight, 'Package ' .. wdata.label, 'benz_weedshops:client:bag:' .. weight, currentLocationId)
            end
        }
    end
    table.sort(opts, function(a, b) return a.title < b.title end)
    lib.registerContext({ id = 'weed_bag_menu', title = 'Package Weed Bags', options = opts })
    lib.showContext('weed_bag_menu')
end)

RegisterNetEvent('benz_weedshops:client:grow', function(data)
    showRequirementPopup('grow', {
        strain = data.strain,
        locationId = data.locationId,
        serverArgs = { data.strain, data.locationId }
    }, 'Growing plant...', Config.Progress.Grow, nil, 'benz_weedshops:server:grow')
end)
RegisterNetEvent('benz_weedshops:client:dry', function(data)
    showRequirementPopup('dry', {
        strain = data.strain,
        locationId = data.locationId,
        serverArgs = { data.strain, data.locationId }
    }, 'Drying flower...', Config.Progress.Dry, nil, 'benz_weedshops:server:dry')
end)
RegisterNetEvent('benz_weedshops:client:roll', function(data)
    local rollType = currentRollType or 'classic_joint'
    showRequirementPopup('roll', {
        strain = data.strain,
        rollType = rollType,
        locationId = data.locationId,
        serverArgs = { data.strain, rollType, data.locationId }
    }, 'Rolling product...', Config.Progress.Roll, { dict = 'amb@world_human_aa_smoke@male@idle_a', clip = 'idle_c' }, 'benz_weedshops:server:roll')
end)
RegisterNetEvent('benz_weedshops:client:edible', function(data)
    local edibleType = currentEdibleType or 'brownie'
    showRequirementPopup('edible', {
        strain = data.strain,
        edibleType = edibleType,
        locationId = data.locationId,
        serverArgs = { data.strain, edibleType, data.locationId }
    }, 'Making edible...', Config.Progress.Edible, nil, 'benz_weedshops:server:edible')
end)
RegisterNetEvent('benz_weedshops:client:bong', function(data)
    showRequirementPopup('bong', {
        strain = data.strain,
        locationId = data.locationId,
        serverArgs = { data.strain, data.locationId }
    }, 'Packing bong...', Config.Progress.BongPack, nil, 'benz_weedshops:server:bong')
end)
RegisterNetEvent('benz_weedshops:client:bag', function(data)
    showRequirementPopup('bag', {
        strain = data.strain,
        weight = data.weight,
        locationId = data.locationId,
        serverArgs = { data.strain, data.weight, data.locationId }
    }, 'Packaging bag...', Config.Progress.Roll, nil, 'benz_weedshops:server:bag')
end)
RegisterNetEvent('benz_weedshops:client:sellMenu', function(data)
    TriggerServerEvent('benz_weedshops:server:sellAll', data and data.locationId)
end)

RegisterNetEvent('benz_weedshops:client:useEffect', function(effectType)
    local cfg = Config.Effects[effectType]
    if not cfg then return end
    if doProgress('Using product...', Config.Progress.Smoke, { dict = 'amb@world_human_smoking@male@male_a@enter', clip = 'enter' }) then
        AnimpostfxPlay(cfg.effect, cfg.duration, false)
        ShakeGameplayCam('DRUNK_SHAKE', 0.35)
        SetTimecycleModifier('spectator5')
        Wait(cfg.duration)
        StopGameplayCamShaking(true)
        ClearTimecycleModifier()
        AnimpostfxStop(cfg.effect)
    end
end)

local validCoords

local zoneEvents = {
    grow = 'benz_weedshops:client:growMenu',
    dry = 'benz_weedshops:client:dryMenu',
    roll = 'benz_weedshops:client:rollMenu',
    edibles = 'benz_weedshops:client:edibleMenu',
    bags = 'benz_weedshops:client:bagMenu',
    bong = 'benz_weedshops:client:bongMenu',
    sell = 'benz_weedshops:client:sellMenu'
}

local function runStationAction(stationType, locationId, stationId)
    local event = zoneEvents[stationType]
    if not event then
        return notify(('Station type %s is not configured.'):format(stationType or 'unknown'), 'error')
    end
    currentLocationId = locationId or currentLocationId
    TriggerEvent(event, { locationId = locationId, stationId = stationId, stationType = stationType })
end


local function removeBlips()
    for _, blip in ipairs(createdBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    createdBlips = {}
end

local function removeBossZones()
    for _, zoneId in ipairs(createdBossZones) do exports.ox_target:removeZone(zoneId) end
    createdBossZones = {}
end

local function removeStashZones()
    for _, zoneId in ipairs(createdStashZones) do exports.ox_target:removeZone(zoneId) end
    createdStashZones = {}
end

local function removeSupplyStoreZones()
    for _, zoneId in ipairs(createdSupplyStoreZones) do exports.ox_target:removeZone(zoneId) end
    createdSupplyStoreZones = {}
end

local function removeCustomerStoreZones()
    for _, zoneId in ipairs(createdCustomerStoreZones) do exports.ox_target:removeZone(zoneId) end
    createdCustomerStoreZones = {}
end

local function openBossMenu(location)
    currentLocationId = location and location.id or currentLocationId
    if not currentLocationId then return notify('No business location found.', 'error') end

    local account = lib.callback.await('benz_weedshops:server:getBusinessAccount', false, currentLocationId)
    if not account then return notify('No permission to use the business account.', 'error') end

    local balanceText = account.unknown and 'Balance unavailable from banking export' or ('$' .. tostring(account.balance or 0))
    local opts = {
        {
            title = 'Business Account',
            description = ('Account: %s\nBalance: %s'):format(account.account or account.job or 'business', balanceText),
            icon = 'building-columns',
            disabled = true
        },
        {
            title = 'Deposit Money',
            description = 'Deposit cash or bank money into the society/business account.',
            icon = 'money-bill-transfer',
            onSelect = function()
                local input = lib.inputDialog('Deposit To Business', {
                    { type = 'number', label = 'Amount', default = 100, min = 1, required = true },
                    { type = 'select', label = 'From Account', default = 'cash', options = {
                        { value = 'cash', label = 'Cash' },
                        { value = 'bank', label = 'Bank' }
                    }, required = true }
                })
                if not input then return end
                TriggerServerEvent('benz_weedshops:server:depositBusinessAccount', currentLocationId, input[1], input[2])
            end
        },
        {
            title = 'Withdraw Money',
            description = 'Withdraw from the society/business account to yourself.',
            icon = 'hand-holding-dollar',
            onSelect = function()
                local input = lib.inputDialog('Withdraw From Business', {
                    { type = 'number', label = 'Amount', default = 100, min = 1, required = true },
                    { type = 'select', label = 'Pay To', default = 'cash', options = {
                        { value = 'cash', label = 'Cash' },
                        { value = 'bank', label = 'Bank' }
                    }, required = true }
                })
                if not input then return end
                TriggerServerEvent('benz_weedshops:server:withdrawBusinessAccount', currentLocationId, input[1], input[2])
            end
        },
        {
            title = 'Refresh Balance',
            icon = 'rotate',
            onSelect = function() openBossMenu(location) end
        }
    }

    lib.registerContext({ id = 'weed_business_account_' .. tostring(currentLocationId), title = (location and location.name or 'Business') .. ' Boss Menu', options = opts })
    lib.showContext('weed_business_account_' .. tostring(currentLocationId))
end

local function addStoreBlip(location)
    if not Config.EnableStoreBlips or not location or not validCoords(location.blip) then return end
    local blip = AddBlipForCoord(location.blip.x, location.blip.y, location.blip.z)
    SetBlipSprite(blip, (Config.Blip and Config.Blip.sprite) or 140)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, (Config.Blip and Config.Blip.scale) or 0.75)
    SetBlipColour(blip, (Config.Blip and Config.Blip.color) or 2)
    SetBlipAsShortRange(blip, Config.Blip == nil or Config.Blip.shortRange ~= false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(((Config.Blip and Config.Blip.namePrefix) or '') .. (location.name or 'Weed Store'))
    EndTextCommandSetBlipName(blip)
    createdBlips[#createdBlips + 1] = blip
end

local function addBossZone(location)
    if not Config.EnableBossMenuTarget or not location or not location.boss or not validCoords(location.boss.coords) then return end
    local zoneName = ('benz_weedshops_boss_%s'):format(location.id)
    local zoneId = exports.ox_target:addBoxZone({
        coords = location.boss.coords,
        size = location.boss.size or vec3(1.4, 1.4, 1.6),
        rotation = location.boss.rotation or 0.0,
        debug = Config.Debug,
        options = {{
            name = zoneName,
            icon = Config.BossMenuIcon or 'fa-solid fa-user-tie',
            label = location.boss.label or Config.BossMenuLabel or 'Open Boss Menu',
            groups = location.job and location.job ~= '' and location.job ~= 'none' and location.job or nil,
            distance = Config.TargetDistance or 2.0,
            onSelect = function()
                openBossMenu(location)
            end
        }}
    })
    createdBossZones[#createdBossZones + 1] = zoneId
end

local function addStashZone(location, stash)
    if Config.EnableBusinessStashes == false or not stash or not validCoords(stash.coords) then return end
    local zoneName = ('benz_weedshops_stash_%s_%s'):format(location.id, stash.id or math.random(10000,99999))
    local zoneId = exports.ox_target:addBoxZone({
        coords = stash.coords,
        size = stash.size or vec3(1.5, 1.5, 1.6),
        rotation = stash.rotation or 0.0,
        debug = Config.Debug,
        options = {{
            name = zoneName,
            icon = Config.StashTargetIcon or 'fa-solid fa-box-archive',
            label = stash.label or Config.StashTargetLabel or 'Open Business Stash',
            groups = location.job and location.job ~= '' and location.job ~= 'none' and location.job or nil,
            distance = Config.TargetDistance or 2.0,
            onSelect = function()
                TriggerServerEvent('benz_weedshops:server:openStash', location.id, stash.stashName)
            end
        }}
    })
    createdStashZones[#createdStashZones + 1] = zoneId
end


local function cartTotal()
    local total, count = 0, 0
    for id, qty in pairs(customerCart or {}) do
        local product = customerProducts[id]
        qty = tonumber(qty) or 0
        if product and qty > 0 then
            total = total + ((tonumber(product.price) or 0) * qty)
            count = count + qty
        end
    end
    return total, count
end

local function showCustomerCart()
    local total, count = cartTotal()
    local opts = {}
    for id, qty in pairs(customerCart or {}) do
        local product = customerProducts[id]
        if product and qty > 0 then
            opts[#opts + 1] = {
                title = ('%sx %s'):format(qty, product.label or product.item),
                description = ('$%s each | Remove from cart'):format(product.price or 0),
                icon = 'trash',
                onSelect = function()
                    customerCart[id] = nil
                    showCustomerCart()
                end
            }
        end
    end
    if #opts == 0 then
        opts[#opts + 1] = { title = 'Cart is empty', icon = 'cart-shopping', disabled = true }
    else
        opts[#opts + 1] = {
            title = ('Checkout - $%s'):format(total),
            description = ('%s item(s) in cart'):format(count),
            icon = 'credit-card',
            onSelect = function()
                lib.registerContext({ id = 'weed_customer_pay', title = 'Choose Payment', menu = 'weed_customer_cart', options = {
                    { title = 'Pay Cash', icon = 'money-bill', onSelect = function() TriggerServerEvent('benz_weedshops:server:checkoutCustomerCart', currentCustomerLocationId, customerCart, 'cash'); customerCart = {} end },
                    { title = 'Pay Bank', icon = 'building-columns', onSelect = function() TriggerServerEvent('benz_weedshops:server:checkoutCustomerCart', currentCustomerLocationId, customerCart, 'bank'); customerCart = {} end }
                }})
                lib.showContext('weed_customer_pay')
            end
        }
        opts[#opts + 1] = { title = 'Clear Cart', icon = 'ban', onSelect = function() customerCart = {}; showCustomerCart() end }
    end
    lib.registerContext({ id = 'weed_customer_cart', title = ('Cart - $%s'):format(total), menu = 'weed_customer_menu', options = opts })
    lib.showContext('weed_customer_cart')
end

local function addCustomerProduct(product)
    local stock = tonumber(product.stock)
    local maxQty = math.min(tonumber(product.max) or 25, stock and math.max(stock, 0) or 25)
    if maxQty <= 0 then return notify('This item is out of stock.', 'error') end
    local input = lib.inputDialog(product.label or product.item, {
        { type = 'number', label = 'Quantity', default = 1, min = 1, max = maxQty, required = true }
    })
    if not input then return end
    local qty = math.floor(tonumber(input[1]) or 1)
    if qty < 1 then return end
    customerCart[product.id] = (customerCart[product.id] or 0) + qty
    notify(('Added %sx %s to cart.'):format(qty, product.label or product.item), 'success')
end

local function openCustomerCategory(category, label)
    local opts = {}
    for _, product in pairs(customerProducts or {}) do
        if product.category == category then
            local stockText = product.stock ~= nil and ('Stock: %s | '):format(product.stock) or ''
            opts[#opts + 1] = {
                title = product.label or product.item,
                description = ('%s$%s'):format(stockText, product.price or 0),
                icon = 'basket-shopping',
                disabled = product.stock ~= nil and tonumber(product.stock) <= 0,
                onSelect = function() addCustomerProduct(product) end
            }
        end
    end
    if #opts == 0 then opts[#opts + 1] = { title = 'No products available', disabled = true } end
    table.sort(opts, function(a, b) return a.title < b.title end)
    lib.registerContext({ id = 'weed_customer_category_' .. category, title = label, menu = 'weed_customer_menu', options = opts })
    lib.showContext('weed_customer_category_' .. category)
end

local function openCustomerMenu(locationId)
    currentCustomerLocationId = locationId
    local data = lib.callback.await('benz_weedshops:server:getCustomerProducts', false, locationId)
    if not data then return notify('Unable to load customer menu.', 'error') end
    customerProducts = {}
    for _, product in ipairs(data.products or {}) do customerProducts[product.id] = product end
    local opts = {}
    local ordered = { 'bags', 'joints', 'edibles', 'bongs' }
    for _, key in ipairs(ordered) do
        local cat = data.categories and data.categories[key] or {}
        opts[#opts + 1] = {
            title = cat.label or key,
            icon = cat.icon or 'store',
            arrow = true,
            onSelect = function() openCustomerCategory(key, cat.label or key) end
        }
    end
    local total, count = cartTotal()
    opts[#opts + 1] = { title = ('View Cart - $%s'):format(total), description = ('%s item(s)'):format(count), icon = 'cart-shopping', onSelect = showCustomerCart }
    lib.registerContext({ id = 'weed_customer_menu', title = (data.location and data.location.name or 'Dispensary') .. ' Menu', options = opts })
    lib.showContext('weed_customer_menu')
end

local function addCustomerStoreZone(location, store)
    if Config.EnableCustomerMenus == false or not store or not validCoords(store.coords) then return end
    local zoneName = ('benz_weedshops_customer_store_%s_%s'):format(location.id, store.id or math.random(10000,99999))
    local zoneId = exports.ox_target:addBoxZone({
        coords = store.coords,
        size = store.size or Config.DefaultCustomerStoreSize or vec3(1.6, 1.6, 1.8),
        rotation = store.rotation or 0.0,
        debug = Config.Debug,
        options = {{
            name = zoneName,
            icon = Config.CustomerStoreTargetIcon or 'fa-solid fa-store',
            label = store.label or Config.CustomerStoreTargetLabel or 'Open Dispensary Menu',
            distance = Config.TargetDistance or 2.0,
            onSelect = function()
                openCustomerMenu(location.id)
            end
        }}
    })
    createdCustomerStoreZones[#createdCustomerStoreZones + 1] = zoneId
end

local function addSupplyStoreZone(location, store)
    if Config.EnableSupplyStores == false or not store or not validCoords(store.coords) then return end
    local zoneName = ('benz_weedshops_supply_store_%s_%s'):format(location.id, store.id or math.random(10000,99999))
    local zoneId = exports.ox_target:addBoxZone({
        coords = store.coords,
        size = store.size or Config.DefaultSupplyStoreSize or vec3(1.6, 1.6, 1.8),
        rotation = store.rotation or 0.0,
        debug = Config.Debug,
        options = {{
            name = zoneName,
            icon = Config.SupplyStoreTargetIcon or 'fa-solid fa-cart-shopping',
            label = store.label or Config.SupplyStoreTargetLabel or 'Open Supply Store',
            groups = location.job and location.job ~= '' and location.job ~= 'none' and location.job or nil,
            distance = Config.TargetDistance or 2.0,
            onSelect = function()
                TriggerServerEvent('benz_weedshops:server:openSupplyStore', location.id, store.shopName)
            end
        }}
    })
    createdSupplyStoreZones[#createdSupplyStoreZones + 1] = zoneId
end

local function removeZones()
    for _, zoneId in ipairs(createdZones) do exports.ox_target:removeZone(zoneId) end
    createdZones = {}
end

function validCoords(coords)
    return coords and not (coords.x == 0.0 and coords.y == 0.0 and coords.z == 0.0)
end

local function addStationZone(location, station)
    if not validCoords(station.coords) then return end
    local event = zoneEvents[station.type]
    if not event then return end
    local def = Config.StationTypes[station.type] or {}
    local zoneName = ('benz_weedshops_%s_%s_%s'):format(location.id, station.type, station.id or math.random(10000,99999))
    local zoneId = exports.ox_target:addBoxZone({
        coords = station.coords,
        size = station.size or vec3(2.0, 2.0, 2.0),
        rotation = station.rotation or 0.0,
        debug = Config.Debug,
        options = {{
            name = zoneName,
            icon = def.icon or 'fa-solid fa-cannabis',
            label = station.label or def.label or station.type,
            groups = location.job and location.job ~= '' and location.job ~= 'none' and location.job or nil,
            distance = Config.TargetDistance or 2.0,
            onSelect = function()
                runStationAction(station.type, location.id, station.id)
            end
        }}
    })
    createdZones[#createdZones + 1] = zoneId
end

local function buildZones(locations)
    removeZones()
    removeBossZones()
    removeStashZones()
    removeSupplyStoreZones()
    removeCustomerStoreZones()
    removeBlips()
    cachedLocations = locations or {}
    for _, location in pairs(cachedLocations) do
        addStoreBlip(location)
        addBossZone(location)
        for _, station in ipairs(location.stations or {}) do addStationZone(location, station) end
        for _, stash in ipairs(location.stashes or {}) do addStashZone(location, stash) end
        for _, store in ipairs(location.supplyStores or {}) do addSupplyStoreZone(location, store) end
        for _, store in ipairs(location.customerStores or {}) do addCustomerStoreZone(location, store) end
    end
end

RegisterNetEvent('benz_weedshops:client:refreshZones', function(locations)
    buildZones(locations)
    notify('Weed locations refreshed.', 'success')
end)

RegisterNetEvent('benz_weedshops:client:openStash', function(stashName)
    if not stashName then return end
    exports.ox_inventory:openInventory('stash', stashName)
end)

RegisterNetEvent('benz_weedshops:client:openSupplyStore', function(shopName)
    if not shopName then return end
    exports.ox_inventory:openInventory('shop', { type = shopName, id = 1 })
end)

CreateThread(function()
    Wait(1500)
    local locations = lib.callback.await('benz_weedshops:server:getLocations', false)
    buildZones(locations or {})
end)

local function promptLocation()
    local input = lib.inputDialog('Create Weed Location', {
        { type = 'input', label = 'Location Name', placeholder = 'White Widow Vinewood', required = true },
        { type = 'input', label = 'Locked Job Name', placeholder = Config.DefaultJob, default = Config.DefaultJob, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:createLocation', { name = input[1], job = input[2] })
end

local function editLocation(loc, canChangeJob)
    local input = lib.inputDialog('Edit ' .. loc.name, {
        { type = 'input', label = 'Location Name', default = loc.name, required = true },
        { type = 'input', label = 'Locked Job Name', default = loc.job, disabled = not canChangeJob, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:updateLocation', loc.id, { name = input[1], job = input[2] })
end


local function setLocationBlipHere(loc)
    TriggerServerEvent('benz_weedshops:server:setLocationBlipHere', loc.id)
end

local function setBossMenuHere(loc)
    local input = lib.inputDialog('Set Boss Menu At Your Position', {
        { type = 'input', label = 'Boss Menu Label', default = (loc.boss and loc.boss.label) or Config.BossMenuLabel or 'Open Boss Menu', required = true },
        { type = 'number', label = 'Size X', default = loc.boss and loc.boss.size and loc.boss.size.x or 1.4, required = true },
        { type = 'number', label = 'Size Y', default = loc.boss and loc.boss.size and loc.boss.size.y or 1.4, required = true },
        { type = 'number', label = 'Size Z', default = loc.boss and loc.boss.size and loc.boss.size.z or 1.6, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:setBossMenuHere', loc.id, input[1], { x = input[2], y = input[3], z = input[4] })
end

local function moveWholeLocationHere(loc)
    local input = lib.inputDialog('Move Whole Location', {
        { type = 'checkbox', label = 'Move all stations relative to my current position', checked = true },
        { type = 'checkbox', label = 'Also move store blip here', checked = true },
        { type = 'checkbox', label = 'Also move boss menu here', checked = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:moveLocationHere', loc.id, input[1] == true, input[2] == true, input[3] == true)
end

local function addStationMenu(loc)
    local values = {}
    for stationType, data in pairs(Config.StationTypes) do values[#values + 1] = { value = stationType, label = data.label } end
    table.sort(values, function(a, b) return a.label < b.label end)
    local input = lib.inputDialog('Add Station At Your Position', {
        { type = 'select', label = 'Station Type', options = values, required = true },
        { type = 'input', label = 'Station Label', placeholder = 'Leave custom label here', required = false },
        { type = 'number', label = 'Size X', default = 2.0, required = true },
        { type = 'number', label = 'Size Y', default = 2.0, required = true },
        { type = 'number', label = 'Size Z', default = 2.0, required = true }
    })
    if not input then return end
    local def = Config.StationTypes[input[1]] or {}
    TriggerServerEvent('benz_weedshops:server:addStationHere', loc.id, input[1], input[2] ~= '' and input[2] or def.label, { x = input[3], y = input[4], z = input[5] })
end

local function editStation(st)
    local input = lib.inputDialog('Move/Edit Station', {
        { type = 'input', label = 'Station Label', default = st.label, required = true },
        { type = 'number', label = 'Size X', default = st.size and st.size.x or 2.0, required = true },
        { type = 'number', label = 'Size Y', default = st.size and st.size.y or 2.0, required = true },
        { type = 'number', label = 'Size Z', default = st.size and st.size.z or 2.0, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:updateStationHere', st.id, input[1], { x = input[2], y = input[3], z = input[4] })
end

local function stationListMenu(loc)
    local opts = {
        { title = 'Add Station Here', icon = 'plus', onSelect = function() addStationMenu(loc) end }
    }
    for _, st in ipairs(loc.stations or {}) do
        local def = Config.StationTypes[st.type] or {}
        opts[#opts + 1] = {
            title = ('#%s - %s'):format(st.id or '?', st.label or def.label or st.type),
            description = ('Type: %s'):format(def.label or st.type),
            icon = def.icon or 'location-dot',
            arrow = true,
            onSelect = function()
                lib.registerContext({ id = 'weed_station_actions_' .. st.id, title = st.label, menu = 'weed_stations_' .. loc.id, options = {
                    { title = 'Move/Edit To My Position', icon = 'arrows-up-down-left-right', onSelect = function() editStation(st) end },
                    { title = 'Delete Station', icon = 'trash', onSelect = function() TriggerServerEvent('benz_weedshops:server:deleteStation', st.id) end }
                }})
                lib.showContext('weed_station_actions_' .. st.id)
            end
        }
    end
    lib.registerContext({ id = 'weed_stations_' .. loc.id, title = loc.name .. ' Stations', menu = 'weed_location_' .. loc.id, options = opts })
    lib.showContext('weed_stations_' .. loc.id)
end

local function addStashMenu(loc)
    local input = lib.inputDialog('Add Business Stash At Your Position', {
        { type = 'input', label = 'Stash Label', default = 'Business Stash', required = true },
        { type = 'number', label = 'Slots', default = Config.DefaultStashSlots or 60, required = true },
        { type = 'number', label = 'Max Weight', default = Config.DefaultStashWeight or 250000, required = true },
        { type = 'number', label = 'Size X', default = 1.5, required = true },
        { type = 'number', label = 'Size Y', default = 1.5, required = true },
        { type = 'number', label = 'Size Z', default = 1.6, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:addStashHere', loc.id, input[1], input[2], input[3], { x = input[4], y = input[5], z = input[6] })
end

local function editStash(stash)
    local input = lib.inputDialog('Move/Edit Business Stash', {
        { type = 'input', label = 'Stash Label', default = stash.label or 'Business Stash', required = true },
        { type = 'number', label = 'Slots', default = stash.slots or Config.DefaultStashSlots or 60, required = true },
        { type = 'number', label = 'Max Weight', default = stash.weight or Config.DefaultStashWeight or 250000, required = true },
        { type = 'number', label = 'Size X', default = stash.size and stash.size.x or 1.5, required = true },
        { type = 'number', label = 'Size Y', default = stash.size and stash.size.y or 1.5, required = true },
        { type = 'number', label = 'Size Z', default = stash.size and stash.size.z or 1.6, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:updateStashHere', stash.id, input[1], input[2], input[3], { x = input[4], y = input[5], z = input[6] })
end

local function stashListMenu(loc)
    local opts = {
        { title = 'Add Stash Here', icon = 'plus', onSelect = function() addStashMenu(loc) end }
    }
    for _, stash in ipairs(loc.stashes or {}) do
        opts[#opts + 1] = {
            title = ('#%s - %s'):format(stash.id or '?', stash.label or 'Business Stash'),
            description = ('Slots: %s | Weight: %s'):format(stash.slots or Config.DefaultStashSlots or 60, stash.weight or Config.DefaultStashWeight or 250000),
            icon = Config.StashTargetIcon or 'box-archive',
            arrow = true,
            onSelect = function()
                lib.registerContext({ id = 'weed_stash_actions_' .. stash.id, title = stash.label or 'Business Stash', menu = 'weed_stashes_' .. loc.id, options = {
                    { title = 'Move/Edit To My Position', icon = 'arrows-up-down-left-right', onSelect = function() editStash(stash) end },
                    { title = 'Delete Stash', icon = 'trash', onSelect = function() TriggerServerEvent('benz_weedshops:server:deleteStash', stash.id) end }
                }})
                lib.showContext('weed_stash_actions_' .. stash.id)
            end
        }
    end
    lib.registerContext({ id = 'weed_stashes_' .. loc.id, title = loc.name .. ' Stashes', menu = 'weed_location_' .. loc.id, options = opts })
    lib.showContext('weed_stashes_' .. loc.id)
end


local function addSupplyStoreMenu(loc)
    local input = lib.inputDialog('Add Supply Store At Your Position', {
        { type = 'input', label = 'Store Label', default = 'Business Supply Store', required = true },
        { type = 'number', label = 'Size X', default = 1.6, required = true },
        { type = 'number', label = 'Size Y', default = 1.6, required = true },
        { type = 'number', label = 'Size Z', default = 1.8, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:addSupplyStoreHere', loc.id, input[1], { x = input[2], y = input[3], z = input[4] })
end

local function editSupplyStore(store)
    local input = lib.inputDialog('Move/Edit Supply Store', {
        { type = 'input', label = 'Store Label', default = store.label or 'Business Supply Store', required = true },
        { type = 'number', label = 'Size X', default = store.size and store.size.x or 1.6, required = true },
        { type = 'number', label = 'Size Y', default = store.size and store.size.y or 1.6, required = true },
        { type = 'number', label = 'Size Z', default = store.size and store.size.z or 1.8, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:updateSupplyStoreHere', store.id, input[1], { x = input[2], y = input[3], z = input[4] })
end

local function supplyStoreListMenu(loc)
    local opts = {
        { title = 'Add Supply Store Here', icon = 'plus', onSelect = function() addSupplyStoreMenu(loc) end }
    }
    for _, store in ipairs(loc.supplyStores or {}) do
        opts[#opts + 1] = {
            title = ('#%s - %s'):format(store.id or '?', store.label or 'Business Supply Store'),
            description = 'Players with this business job can buy supplies here.',
            icon = Config.SupplyStoreTargetIcon or 'cart-shopping',
            arrow = true,
            onSelect = function()
                lib.registerContext({ id = 'weed_supply_store_actions_' .. store.id, title = store.label or 'Business Supply Store', menu = 'weed_supply_stores_' .. loc.id, options = {
                    { title = 'Move/Edit To My Position', icon = 'arrows-up-down-left-right', onSelect = function() editSupplyStore(store) end },
                    { title = 'Delete Supply Store', icon = 'trash', onSelect = function() TriggerServerEvent('benz_weedshops:server:deleteSupplyStore', store.id) end }
                }})
                lib.showContext('weed_supply_store_actions_' .. store.id)
            end
        }
    end
    lib.registerContext({ id = 'weed_supply_stores_' .. loc.id, title = loc.name .. ' Supply Stores', menu = 'weed_location_' .. loc.id, options = opts })
    lib.showContext('weed_supply_stores_' .. loc.id)
end



local function addCustomerStoreMenu(loc)
    local input = lib.inputDialog('Add Customer Menu At Your Position', {
        { type = 'input', label = 'Menu Label', default = 'Dispensary Menu', required = true },
        { type = 'number', label = 'Size X', default = 1.6, required = true },
        { type = 'number', label = 'Size Y', default = 1.6, required = true },
        { type = 'number', label = 'Size Z', default = 1.8, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:addCustomerStoreHere', loc.id, input[1], { x = input[2], y = input[3], z = input[4] })
end

local function editCustomerStore(store)
    local input = lib.inputDialog('Move/Edit Customer Menu', {
        { type = 'input', label = 'Menu Label', default = store.label or 'Dispensary Menu', required = true },
        { type = 'number', label = 'Size X', default = store.size and store.size.x or 1.6, required = true },
        { type = 'number', label = 'Size Y', default = store.size and store.size.y or 1.6, required = true },
        { type = 'number', label = 'Size Z', default = store.size and store.size.z or 1.8, required = true }
    })
    if not input then return end
    TriggerServerEvent('benz_weedshops:server:updateCustomerStoreHere', store.id, input[1], { x = input[2], y = input[3], z = input[4] })
end

local function customerStoreListMenu(loc)
    local opts = {
        { title = 'Add Customer Menu Here', icon = 'plus', onSelect = function() addCustomerStoreMenu(loc) end }
    }
    for _, store in ipairs(loc.customerStores or {}) do
        opts[#opts + 1] = {
            title = ('#%s - %s'):format(store.id or '?', store.label or 'Dispensary Menu'),
            description = 'Public menu where customers browse, cart, and checkout.',
            icon = Config.CustomerStoreTargetIcon or 'store',
            arrow = true,
            onSelect = function()
                lib.registerContext({ id = 'weed_customer_store_actions_' .. store.id, title = store.label or 'Dispensary Menu', menu = 'weed_customer_stores_' .. loc.id, options = {
                    { title = 'Move/Edit To My Position', icon = 'arrows-up-down-left-right', onSelect = function() editCustomerStore(store) end },
                    { title = 'Delete Customer Menu', icon = 'trash', onSelect = function() TriggerServerEvent('benz_weedshops:server:deleteCustomerStore', store.id) end }
                }})
                lib.showContext('weed_customer_store_actions_' .. store.id)
            end
        }
    end
    lib.registerContext({ id = 'weed_customer_stores_' .. loc.id, title = loc.name .. ' Customer Menus', menu = 'weed_location_' .. loc.id, options = opts })
    lib.showContext('weed_customer_stores_' .. loc.id)
end

local function openLocationActions(loc, editor)
    local canChangeJob = editor.admin == true
    local opts = {
        { title = 'Edit Name / Job Lock', icon = 'pen-to-square', onSelect = function() editLocation(loc, canChangeJob) end },
        { title = 'Move Whole Location Here', description = 'Moves stations relative to you, with optional blip/boss move', icon = 'arrows-up-down-left-right', onSelect = function() moveWholeLocationHere(loc) end },
        { title = 'Set Store Blip Here', icon = 'map-location-dot', onSelect = function() setLocationBlipHere(loc) end },
        { title = 'Set Boss Menu Here', icon = 'user-tie', onSelect = function() setBossMenuHere(loc) end },
        { title = 'Stations', description = 'Add, move, resize, or delete stations', icon = 'location-dot', arrow = true, onSelect = function() stationListMenu(loc) end },
        { title = 'Business Stashes', description = 'Add, move, resize, or delete ox_inventory stashes', icon = 'box-archive', arrow = true, onSelect = function() stashListMenu(loc) end },
        { title = 'Supply Stores', description = 'Add, move, or delete ox_inventory supply shops', icon = 'cart-shopping', arrow = true, onSelect = function() supplyStoreListMenu(loc) end },
        { title = 'Customer Menus', description = 'Add, move, or delete public dispensary menus', icon = 'store', arrow = true, onSelect = function() customerStoreListMenu(loc) end }
    }
    if editor.admin then
        opts[#opts + 1] = { title = 'Delete Location', icon = 'trash', onSelect = function() TriggerServerEvent('benz_weedshops:server:deleteLocation', loc.id) end }
    end
    lib.registerContext({ id = 'weed_location_' .. loc.id, title = loc.name, menu = 'weed_admin_menu', options = opts })
    lib.showContext('weed_location_' .. loc.id)
end

local function openAdminMenu()
    local editor = lib.callback.await('benz_weedshops:server:getEditorData', false)
    if not editor then return notify('No permission.', 'error') end
    local opts = {}
    if editor.admin then opts[#opts + 1] = { title = 'Create New Location', icon = 'plus', onSelect = promptLocation } end
    for _, loc in pairs(editor.locations or {}) do
        if editor.admin or loc.job == editor.playerJob then
            opts[#opts + 1] = {
                title = ('#%s %s'):format(loc.id, loc.name),
                description = ('Job: %s | Stations: %s | Stashes: %s | Supply Stores: %s | Customer Menus: %s'):format(loc.job or 'none', #(loc.stations or {}), #(loc.stashes or {}), #(loc.supplyStores or {}), #(loc.customerStores or {})),
                icon = 'store', arrow = true, onSelect = function() openLocationActions(loc, editor) end
            }
        end
    end
    lib.registerContext({ id = 'weed_admin_menu', title = 'Weed Location Editor', options = opts })
    lib.showContext('weed_admin_menu')
end

RegisterCommand(Config.AdminCommand or 'weedadmin', openAdminMenu, false)

RegisterCommand(Config.CoordCommand or 'wwcoords', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local line = ("coords = vec3(%.2f, %.2f, %.2f), rotation = %.2f"):format(coords.x, coords.y, coords.z, heading)
    print('[benz_weedshops] ' .. line)
    lib.setClipboard(line)
    notify('Coords copied and printed in F8.', 'success')
end, false)

-- ox_inventory client exports for usable rollables/edibles listed in sql/items.lua
CreateThread(function()
    Wait(500)
    for strain, _ in pairs(Config.Strains or {}) do
        for _, r in pairs(Config.Rollables or {}) do
            exports(r.itemPrefix .. strain, function()
                TriggerEvent('benz_weedshops:client:useEffect', r.effect or 'joint')
            end)
        end
        for _, e in pairs(Config.Edibles or {}) do
            exports(e.itemPrefix .. strain, function()
                TriggerEvent('benz_weedshops:client:useEffect', e.effect or 'edible')
            end)
        end
    end
end)


AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(1000)
    local locations = lib.callback.await('benz_weedshops:server:getLocations', false)
    buildZones(locations or {})
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1000)
    local locations = lib.callback.await('benz_weedshops:server:getLocations', false)
    buildZones(locations or {})
end)

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    Wait(1000)
    local locations = lib.callback.await('benz_weedshops:server:getLocations', false)
    buildZones(locations or {})
end)
