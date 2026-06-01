local locations = {}
local itemLabel


local function notify(src, msg, type)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Weed Factory', description = msg, type = type or 'inform' })
end

local function player(src)
    local ok, p = pcall(function()
        return exports.qbx_core:GetPlayer(src)
    end)
    if ok and p then return p end

    ok, p = pcall(function()
        return exports['qbx_core']:GetPlayer(src)
    end)
    if ok and p then return p end

    return nil
end

local function getPlayerData(src)
    local p = player(src)
    if p and p.PlayerData then return p.PlayerData end

    local ok, data = pcall(function()
        return exports.qbx_core:GetPlayerData(src)
    end)
    if ok and data then return data end

    return nil
end

local function jobName(src)
    local data = getPlayerData(src)
    return data and data.job and data.job.name or nil
end

local function isBoss(src)
    local data = getPlayerData(src)
    local job = data and data.job
    if not job then return false end
    if job.isboss == true or job.isBoss == true then return true end
    if type(job.grade) == 'table' then
        if job.grade.isboss == true or job.grade.isBoss == true then return true end
        if tonumber(job.grade.level or job.grade.grade) and tonumber(job.grade.level or job.grade.grade) >= (Config.BossGrade or 4) then return true end
    elseif tonumber(job.grade) and tonumber(job.grade) >= (Config.BossGrade or 4) then
        return true
    end
    return false
end

local function isAdmin(src)
    if src == 0 then return true end
    if IsPlayerAceAllowed(src, Config.AdminAce) then return true end
    for _, group in ipairs(Config.AdminGroups or {}) do
        local ok, allowed = pcall(function()
            return exports.qbx_core:HasPermission(src, group)
        end)
        if ok and allowed then return true end
    end
    local p = player(src)
    if p and p.Functions and p.Functions.HasPermission then
        for _, group in ipairs(Config.AdminGroups or {}) do
            local ok, allowed = pcall(function() return p.Functions.HasPermission(group) end)
            if ok and allowed then return true end
        end
    end
    return false
end

local function canEditLocation(src, loc)
    if isAdmin(src) then return true end
    return Config.AllowBossEditor and loc and loc.job == jobName(src) and isBoss(src)
end

local function hasLocationJob(src, locationId)
    local loc = locations[tonumber(locationId)]
    if not loc then return false end
    if not loc.job or loc.job == '' or loc.job == 'none' then return true end
    return jobName(src) == loc.job
end

local function addCash(src, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local p = player(src)
    if p and p.Functions and p.Functions.AddMoney then
        local ok = pcall(function() p.Functions.AddMoney('cash', amount, reason or 'weedfactory') end)
        if ok then return true end
    end

    local ok = pcall(function()
        exports.qbx_core:AddMoney(src, 'cash', amount, reason or 'weedfactory')
    end)
    if ok then return true end

    ok = pcall(function()
        exports.ox_inventory:AddItem(src, 'money', amount)
    end)
    return ok
end



local function addPlayerMoney(src, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    account = account == 'bank' and 'bank' or 'cash'
    local p = player(src)
    if p and p.Functions and p.Functions.AddMoney then
        local ok, result = pcall(function() return p.Functions.AddMoney(account, amount, reason or 'weedfactory-refund') end)
        if ok and result ~= false then return true end
    end
    local ok, result = pcall(function() return exports.qbx_core:AddMoney(src, account, amount, reason or 'weedfactory-refund') end)
    if ok and result ~= false then return true end
    if account == 'cash' then
        ok, result = pcall(function() return exports.ox_inventory:AddItem(src, 'money', amount) end)
        if ok and result ~= false then return true end
    end
    return false
end

local function removePlayerMoney(src, account, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    account = account == 'bank' and 'bank' or 'cash'
    local p = player(src)
    if p and p.Functions and p.Functions.RemoveMoney then
        local ok, result = pcall(function() return p.Functions.RemoveMoney(account, amount, reason or 'weedfactory-purchase') end)
        if ok and result ~= false then return true end
    end
    local ok, result = pcall(function() return exports.qbx_core:RemoveMoney(src, account, amount, reason or 'weedfactory-purchase') end)
    if ok and result ~= false then return true end
    if account == 'cash' then
        ok, result = pcall(function() return exports.ox_inventory:RemoveItem(src, 'money', amount) end)
        if ok and result == true then return true end
    end
    return false
end

local function businessAccountName(job)
    local prefix = Config.CustomerBusinessDeposit and Config.CustomerBusinessDeposit.accountPrefix or ''
    return (prefix or '') .. tostring(job or Config.DefaultJob or 'whitewidow')
end

local function normalizeBankingMode()
    local mode = Config.CustomerBusinessDeposit and Config.CustomerBusinessDeposit.mode or 'auto'
    mode = tostring(mode)
    if mode == 'okok' or mode == 'okok-banking' or mode == 'okok_banking' then mode = 'okokBanking' end
    return mode
end

local function addOkokAttempts(attempts, account, amount, action, reason)
    if action == 'deposit' then
        -- okokBanking society exports commonly use AddMoney(society, amount).
        attempts[#attempts + 1] = function() return exports['okokBanking']:AddMoney(account, amount) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:AddMoney(account, amount, reason) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:AddAccountMoney(account, amount) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:addAccountMoney(account, amount) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:DepositMoney(account, amount) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:Deposit(account, amount) end
    elseif action == 'withdraw' then
        attempts[#attempts + 1] = function() return exports['okokBanking']:RemoveMoney(account, amount) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:RemoveMoney(account, amount, reason) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:RemoveAccountMoney(account, amount) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:removeAccountMoney(account, amount) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:WithdrawMoney(account, amount) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:Withdraw(account, amount) end
    elseif action == 'balance' then
        attempts[#attempts + 1] = function() return exports['okokBanking']:GetAccount(account) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:GetAccountMoney(account) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:GetMoney(account) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:GetBalance(account) end
        attempts[#attempts + 1] = function() return exports['okokBanking']:getAccountMoney(account) end
    end
end

local function extractBalance(result)
    if type(result) == 'table' then
        return tonumber(result.money or result.balance or result.amount or result.account_balance or result.value or result.funds) or 0
    end
    if type(result) == 'boolean' then return result end
    return tonumber(result) or result
end

local function tryAccountExport(account, amount, action, reason)
    local attempts = {}
    local mode = normalizeBankingMode()

    if mode == 'auto' or mode == 'okokBanking' then
        addOkokAttempts(attempts, account, amount, action, reason)
    end

    if action == 'deposit' then
        if mode == 'auto' or mode == 'renewed-banking' then
            attempts[#attempts + 1] = function() return exports['Renewed-Banking']:addAccountMoney(account, amount) end
            attempts[#attempts + 1] = function() return exports['renewed-banking']:addAccountMoney(account, amount) end
            attempts[#attempts + 1] = function() return exports['Renewed-Banking']:AddMoney(account, amount) end
            attempts[#attempts + 1] = function() return exports['renewed-banking']:AddMoney(account, amount) end
        end
        if mode == 'auto' or mode == 'qbx_management' then
            attempts[#attempts + 1] = function() return exports.qbx_management:AddMoney(account, amount, reason) end
            attempts[#attempts + 1] = function() return exports['qbx_management']:AddMoney(account, amount, reason) end
            attempts[#attempts + 1] = function() return exports.qbx_management:AddMoney(account, amount) end
            attempts[#attempts + 1] = function() return exports['qbx_management']:AddMoney(account, amount) end
        end
        if mode == 'auto' or mode == 'qb-management' then
            attempts[#attempts + 1] = function() return exports['qb-management']:AddMoney(account, amount) end
        end
    elseif action == 'withdraw' then
        if mode == 'auto' or mode == 'renewed-banking' then
            attempts[#attempts + 1] = function() return exports['Renewed-Banking']:removeAccountMoney(account, amount) end
            attempts[#attempts + 1] = function() return exports['renewed-banking']:removeAccountMoney(account, amount) end
            attempts[#attempts + 1] = function() return exports['Renewed-Banking']:RemoveMoney(account, amount) end
            attempts[#attempts + 1] = function() return exports['renewed-banking']:RemoveMoney(account, amount) end
        end
        if mode == 'auto' or mode == 'qbx_management' then
            attempts[#attempts + 1] = function() return exports.qbx_management:RemoveMoney(account, amount, reason) end
            attempts[#attempts + 1] = function() return exports['qbx_management']:RemoveMoney(account, amount, reason) end
            attempts[#attempts + 1] = function() return exports.qbx_management:RemoveMoney(account, amount) end
            attempts[#attempts + 1] = function() return exports['qbx_management']:RemoveMoney(account, amount) end
        end
        if mode == 'auto' or mode == 'qb-management' then
            attempts[#attempts + 1] = function() return exports['qb-management']:RemoveMoney(account, amount) end
        end
    elseif action == 'balance' then
        if mode == 'auto' or mode == 'renewed-banking' then
            attempts[#attempts + 1] = function() return exports['Renewed-Banking']:getAccountMoney(account) end
            attempts[#attempts + 1] = function() return exports['renewed-banking']:getAccountMoney(account) end
            attempts[#attempts + 1] = function() return exports['Renewed-Banking']:GetAccountMoney(account) end
            attempts[#attempts + 1] = function() return exports['renewed-banking']:GetAccountMoney(account) end
        end
        if mode == 'auto' or mode == 'qbx_management' then
            attempts[#attempts + 1] = function() return exports.qbx_management:GetAccount(account) end
            attempts[#attempts + 1] = function() return exports['qbx_management']:GetAccount(account) end
            attempts[#attempts + 1] = function() return exports.qbx_management:GetMoney(account) end
            attempts[#attempts + 1] = function() return exports['qbx_management']:GetMoney(account) end
        end
        if mode == 'auto' or mode == 'qb-management' then
            attempts[#attempts + 1] = function() return exports['qb-management']:GetAccount(account) end
            attempts[#attempts + 1] = function() return exports['qb-management']:GetMoney(account) end
        end
    end

    for _, fn in ipairs(attempts) do
        local ok, result = pcall(fn)
        if ok and result ~= nil and result ~= false then
            return true, extractBalance(result)
        end
    end

    return false, nil
end

local function getBusinessMoney(job)
    local account = businessAccountName(job)
    local ok, balance = tryAccountExport(account, 0, 'balance')
    if ok then
        if type(balance) == 'number' then return balance, account end
        local n = tonumber(balance)
        return n or 0, account
    end
    return nil, account
end

local function depositBusinessMoney(job, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    local mode = normalizeBankingMode()
    if mode == 'none' then return true end
    local account = businessAccountName(job)
    local ok = tryAccountExport(account, amount, 'deposit', reason or 'weedfactory-business-deposit')
    if ok then return true end
    print(('[benz_weedshops] Business deposit failed for account %s amount %s. Configure Config.CustomerBusinessDeposit.'):format(account, amount))
    return false
end

local function withdrawBusinessMoney(job, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local mode = normalizeBankingMode()
    if mode == 'none' then return false end
    local account = businessAccountName(job)
    local ok = tryAccountExport(account, amount, 'withdraw', reason or 'weedfactory-business-withdraw')
    if ok then return true end
    print(('[benz_weedshops] Business withdrawal failed for account %s amount %s. Configure Config.CustomerBusinessDeposit.'):format(account, amount))
    return false
end

local function removeItem(src, item, count)
    count = tonumber(count) or 1
    local ok, result = pcall(function()
        return exports.ox_inventory:RemoveItem(src, item, count)
    end)
    return ok and result == true
end

local function addItem(src, item, count, metadata)
    count = tonumber(count) or 1
    local ok, result = pcall(function()
        return exports.ox_inventory:AddItem(src, item, count, metadata)
    end)

    -- ox_inventory normally returns true on success, but some builds/wrappers can return
    -- another truthy value. Only treat false/nil or a thrown error as a failure.
    if not ok or result == false or result == nil then
        print(('[benz_weedshops] Failed to give %sx %s to player %s. Make sure the item exists in ox_inventory/items.lua and the player has inventory space.'):format(count, tostring(item), tostring(src)))
        return false
    end

    return true
end

local function canCarryItem(src, item, count, metadata)
    count = tonumber(count) or 1
    local ok, result = pcall(function()
        return exports.ox_inventory:CanCarryItem(src, item, count, metadata)
    end)
    if not ok then return true end
    return result == true
end

local function hasItem(src, item, count)
    local ok, result = pcall(function()
        return exports.ox_inventory:GetItemCount(src, item)
    end)
    return ok and (result or 0) >= (count or 1)
end

local function giveCraftReward(src, item, count, metadata)
    count = tonumber(count) or 1

    if not canCarryItem(src, item, count, metadata) then
        notify(src, ('Not enough inventory space for %sx %s.'):format(count, itemLabel(item)), 'error')
        return false
    end

    if not addItem(src, item, count, metadata) then
        notify(src, ('Could not give %sx %s. Check ox_inventory item setup.'):format(count, itemLabel(item)), 'error')
        return false
    end

    return true
end

local function encodeVec(v)
    return json.encode({ x = v.x or v[1] or 0.0, y = v.y or v[2] or 0.0, z = v.z or v[3] or 0.0 })
end

local function decodeVec(data, fallback)
    local ok, decoded = pcall(json.decode, data or '{}')
    if not ok or not decoded then decoded = fallback or {} end
    return vec3(tonumber(decoded.x or decoded[1] or 0.0), tonumber(decoded.y or decoded[2] or 0.0), tonumber(decoded.z or decoded[3] or 0.0))
end

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS qbx_weed_locations (
            id INT NOT NULL AUTO_INCREMENT,
            name VARCHAR(80) NOT NULL,
            job VARCHAR(60) NOT NULL DEFAULT 'whitewidow',
            enabled TINYINT(1) NOT NULL DEFAULT 1,
            blip_coords LONGTEXT NULL,
            boss_coords LONGTEXT NULL,
            boss_size LONGTEXT NULL,
            boss_rotation FLOAT NOT NULL DEFAULT 0,
            boss_label VARCHAR(80) NULL,
            PRIMARY KEY (id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS qbx_weed_stations (
            id INT NOT NULL AUTO_INCREMENT,
            location_id INT NOT NULL,
            station_type VARCHAR(30) NOT NULL,
            label VARCHAR(80) NOT NULL,
            coords LONGTEXT NOT NULL,
            size LONGTEXT NOT NULL,
            rotation FLOAT NOT NULL DEFAULT 0,
            enabled TINYINT(1) NOT NULL DEFAULT 1,
            PRIMARY KEY (id),
            INDEX location_id (location_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS qbx_weed_stashes (
            id INT NOT NULL AUTO_INCREMENT,
            location_id INT NOT NULL,
            label VARCHAR(80) NOT NULL,
            stash_name VARCHAR(100) NOT NULL,
            coords LONGTEXT NOT NULL,
            size LONGTEXT NOT NULL,
            rotation FLOAT NOT NULL DEFAULT 0,
            slots INT NOT NULL DEFAULT 60,
            weight INT NOT NULL DEFAULT 250000,
            enabled TINYINT(1) NOT NULL DEFAULT 1,
            PRIMARY KEY (id),
            UNIQUE KEY stash_name (stash_name),
            INDEX location_id (location_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS qbx_weed_supply_stores (
            id INT NOT NULL AUTO_INCREMENT,
            location_id INT NOT NULL,
            label VARCHAR(80) NOT NULL,
            shop_name VARCHAR(100) NOT NULL,
            coords LONGTEXT NOT NULL,
            size LONGTEXT NOT NULL,
            rotation FLOAT NOT NULL DEFAULT 0,
            enabled TINYINT(1) NOT NULL DEFAULT 1,
            PRIMARY KEY (id),
            UNIQUE KEY shop_name (shop_name),
            INDEX location_id (location_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])


    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS qbx_weed_customer_stores (
            id INT NOT NULL AUTO_INCREMENT,
            location_id INT NOT NULL,
            label VARCHAR(80) NOT NULL,
            coords LONGTEXT NOT NULL,
            size LONGTEXT NOT NULL,
            rotation FLOAT NOT NULL DEFAULT 0,
            enabled TINYINT(1) NOT NULL DEFAULT 1,
            PRIMARY KEY (id),
            INDEX location_id (location_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    local columns = MySQL.query.await('SHOW COLUMNS FROM qbx_weed_locations') or {}
    local have = {}
    for _, col in ipairs(columns) do have[col.Field] = true end
    if not have.blip_coords then MySQL.query.await('ALTER TABLE qbx_weed_locations ADD COLUMN blip_coords LONGTEXT NULL') end
    if not have.boss_coords then MySQL.query.await('ALTER TABLE qbx_weed_locations ADD COLUMN boss_coords LONGTEXT NULL') end
    if not have.boss_size then MySQL.query.await('ALTER TABLE qbx_weed_locations ADD COLUMN boss_size LONGTEXT NULL') end
    if not have.boss_rotation then MySQL.query.await('ALTER TABLE qbx_weed_locations ADD COLUMN boss_rotation FLOAT NOT NULL DEFAULT 0') end
    if not have.boss_label then MySQL.query.await('ALTER TABLE qbx_weed_locations ADD COLUMN boss_label VARCHAR(80) NULL') end
end

local function loadLocations()
    locations = {}
    local locRows = MySQL.query.await('SELECT * FROM qbx_weed_locations ORDER BY id ASC') or {}
    for _, row in ipairs(locRows) do
        locations[row.id] = { id = row.id, name = row.name, job = row.job, enabled = true, blip = decodeVec(row.blip_coords), boss = { coords = decodeVec(row.boss_coords), size = decodeVec(row.boss_size, { x = 1.4, y = 1.4, z = 1.6 }), rotation = row.boss_rotation or 0.0, label = row.boss_label or Config.BossMenuLabel }, stations = {}, stashes = {}, supplyStores = {}, customerStores = {} }
    end
    local stationRows = MySQL.query.await('SELECT * FROM qbx_weed_stations ORDER BY id ASC') or {}
    for _, row in ipairs(stationRows) do
        if locations[row.location_id] then
            locations[row.location_id].stations[#locations[row.location_id].stations + 1] = {
                id = row.id,
                locationId = row.location_id,
                type = row.station_type,
                label = row.label,
                coords = decodeVec(row.coords),
                size = decodeVec(row.size, { x = 2.0, y = 2.0, z = 2.0 }),
                rotation = row.rotation or 0.0,
                enabled = true
            }
        end
    end
    local stashRows = MySQL.query.await('SELECT * FROM qbx_weed_stashes ORDER BY id ASC') or {}
    for _, row in ipairs(stashRows) do
        if locations[row.location_id] then
            locations[row.location_id].stashes[#locations[row.location_id].stashes + 1] = {
                id = row.id,
                locationId = row.location_id,
                label = row.label,
                stashName = row.stash_name,
                coords = decodeVec(row.coords),
                size = decodeVec(row.size, { x = 1.5, y = 1.5, z = 1.6 }),
                rotation = row.rotation or 0.0,
                slots = tonumber(row.slots) or Config.DefaultStashSlots or 60,
                weight = tonumber(row.weight) or Config.DefaultStashWeight or 250000,
                enabled = true
            }
        end
    end
    local supplyRows = MySQL.query.await('SELECT * FROM qbx_weed_supply_stores ORDER BY id ASC') or {}
    for _, row in ipairs(supplyRows) do
        if locations[row.location_id] then
            locations[row.location_id].supplyStores[#locations[row.location_id].supplyStores + 1] = {
                id = row.id,
                locationId = row.location_id,
                label = row.label,
                shopName = row.shop_name,
                coords = decodeVec(row.coords),
                size = decodeVec(row.size, { x = 1.6, y = 1.6, z = 1.8 }),
                rotation = row.rotation or 0.0,
                enabled = true
            }
        end
    end
    local customerRows = MySQL.query.await('SELECT * FROM qbx_weed_customer_stores ORDER BY id ASC') or {}
    for _, row in ipairs(customerRows) do
        if locations[row.location_id] then
            locations[row.location_id].customerStores[#locations[row.location_id].customerStores + 1] = {
                id = row.id,
                locationId = row.location_id,
                label = row.label,
                coords = decodeVec(row.coords),
                size = decodeVec(row.size, { x = 1.6, y = 1.6, z = 1.8 }),
                rotation = row.rotation or 0.0,
                enabled = true
            }
        end
    end

end

local function registerBusinessStashes()
    if Config.EnableBusinessStashes == false then return end
    for _, loc in pairs(locations) do
        for _, stash in ipairs(loc.stashes or {}) do
            local groups
            if loc.job and loc.job ~= '' and loc.job ~= 'none' then
                groups = { [loc.job] = 0 }
            end
            pcall(function()
                exports.ox_inventory:RegisterStash(
                    stash.stashName or ('weed_stash_' .. stash.id),
                    stash.label or 'Business Stash',
                    tonumber(stash.slots) or Config.DefaultStashSlots or 60,
                    tonumber(stash.weight) or Config.DefaultStashWeight or 250000,
                    false,
                    groups
                )
            end)
        end
    end
end

local function buildSupplyInventory()
    local inventory = {}
    for _, item in ipairs(Config.SupplyStoreItems or {}) do
        inventory[#inventory + 1] = {
            name = item.name,
            price = tonumber(item.price) or 1,
            count = tonumber(item.count) or 500,
            metadata = item.metadata
        }
    end
    for _, strain in pairs(Config.Strains or {}) do
        if strain.seed then
            inventory[#inventory + 1] = { name = strain.seed, price = tonumber(strain.seedPrice) or 50, count = 500 }
        end
    end
    return inventory
end

local function registerSupplyStores()
    if Config.EnableSupplyStores == false then return end
    local inventory = buildSupplyInventory()
    for _, loc in pairs(locations) do
        for _, store in ipairs(loc.supplyStores or {}) do
            pcall(function()
                exports.ox_inventory:RegisterShop(store.shopName or ('weed_supply_' .. store.id), {
                    name = store.label or 'Business Supply Store',
                    inventory = inventory
                })
            end)
        end
    end
end

local function seedDefaultsIfEmpty()
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM qbx_weed_locations') or 0
    if count > 0 then return end
    for _, loc in ipairs(Config.DefaultLocations or {}) do
        local id = MySQL.insert.await('INSERT INTO qbx_weed_locations (name, job, enabled, blip_coords, boss_coords, boss_size, boss_rotation, boss_label) VALUES (?, ?, 1, ?, ?, ?, ?, ?)', { loc.name, loc.job or Config.DefaultJob, encodeVec(loc.blip or (loc.stations and loc.stations[1] and loc.stations[1].coords) or vec3(0.0, 0.0, 0.0)), encodeVec(loc.boss and loc.boss.coords or vec3(0.0, 0.0, 0.0)), encodeVec(loc.boss and loc.boss.size or vec3(1.4, 1.4, 1.6)), loc.boss and loc.boss.rotation or 0.0, loc.boss and loc.boss.label or Config.BossMenuLabel })
        for _, st in ipairs(loc.stations or {}) do
            local def = Config.StationTypes[st.type] or {}
            MySQL.insert.await('INSERT INTO qbx_weed_stations (location_id, station_type, label, coords, size, rotation, enabled) VALUES (?, ?, ?, ?, ?, ?, ?)', {
                id, st.type, st.label or def.label or st.type, encodeVec(st.coords), encodeVec(st.size or vec3(2.0, 2.0, 2.0)), st.rotation or 0.0, 1
            })
        end
    end
end

local function applyForcedDefaultMLOStations()
    -- This is intentionally disabled unless Config.ForceDefaultMLOStations is set to true.
    -- Leaving it enabled caused edited in-game station/blip/boss locations to be overwritten
    -- every time the resource or server restarted.
    if Config.ForceDefaultMLOStations ~= true then return end

    print('[benz_weedshops] ForceDefaultMLOStations is enabled. Default MLO stations will be reset this start.')

    local names = Config.ReplaceOldDefaultLocationNames or {}
    for _, loc in ipairs(Config.DefaultLocations or {}) do
        local id

        for _, oldName in ipairs(names) do
            local found = MySQL.single.await('SELECT id FROM qbx_weed_locations WHERE name = ? LIMIT 1', { oldName })
            if found and found.id then
                id = found.id
                break
            end
        end

        if not id then
            local found = MySQL.single.await('SELECT id FROM qbx_weed_locations WHERE name = ? LIMIT 1', { loc.name })
            id = found and found.id or nil
        end

        if id then
            MySQL.update.await('UPDATE qbx_weed_locations SET name = ?, job = ?, enabled = 1, blip_coords = ?, boss_coords = ?, boss_size = ?, boss_rotation = ?, boss_label = ? WHERE id = ?', { loc.name, loc.job or Config.DefaultJob, encodeVec(loc.blip or (loc.stations and loc.stations[1] and loc.stations[1].coords) or vec3(0.0, 0.0, 0.0)), encodeVec(loc.boss and loc.boss.coords or vec3(0.0, 0.0, 0.0)), encodeVec(loc.boss and loc.boss.size or vec3(1.4, 1.4, 1.6)), loc.boss and loc.boss.rotation or 0.0, loc.boss and loc.boss.label or Config.BossMenuLabel, id })
            MySQL.update.await('DELETE FROM qbx_weed_stations WHERE location_id = ?', { id })
        else
            id = MySQL.insert.await('INSERT INTO qbx_weed_locations (name, job, enabled, blip_coords, boss_coords, boss_size, boss_rotation, boss_label) VALUES (?, ?, 1, ?, ?, ?, ?, ?)', { loc.name, loc.job or Config.DefaultJob, encodeVec(loc.blip or (loc.stations and loc.stations[1] and loc.stations[1].coords) or vec3(0.0, 0.0, 0.0)), encodeVec(loc.boss and loc.boss.coords or vec3(0.0, 0.0, 0.0)), encodeVec(loc.boss and loc.boss.size or vec3(1.4, 1.4, 1.6)), loc.boss and loc.boss.rotation or 0.0, loc.boss and loc.boss.label or Config.BossMenuLabel })
        end

        for _, st in ipairs(loc.stations or {}) do
            local def = Config.StationTypes[st.type] or {}
            MySQL.insert.await('INSERT INTO qbx_weed_stations (location_id, station_type, label, coords, size, rotation, enabled) VALUES (?, ?, ?, ?, ?, ?, 1)', {
                id,
                st.type,
                st.label or def.label or st.type,
                encodeVec(st.coords),
                encodeVec(st.size or vec3(2.0, 2.0, 2.0)),
                st.rotation or 0.0
            })
        end
    end
end

local defaultStationOrder = { 'grow', 'dry', 'roll', 'edibles', 'bags', 'bong', 'sell' }

local defaultStationOffsets = {
    grow = vec3(0.0, 0.0, 0.0),
    dry = vec3(2.5, 0.0, 0.0),
    roll = vec3(5.0, 0.0, 0.0),
    edibles = vec3(7.5, 0.0, 0.0),
    bags = vec3(0.0, 2.5, 0.0),
    bong = vec3(2.5, 2.5, 0.0),
    sell = vec3(5.0, 2.5, 0.0)
}

local function vecAdd(a, b)
    return vec3((a.x or 0.0) + (b.x or 0.0), (a.y or 0.0) + (b.y or 0.0), (a.z or 0.0) + (b.z or 0.0))
end

local function stationTypeExists(locationId, stationType)
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM qbx_weed_stations WHERE location_id = ? AND station_type = ?', { locationId, stationType }) or 0
    return count > 0
end

local function insertDefaultStation(locationId, stationType, baseCoords, rotation)
    local def = Config.StationTypes[stationType] or {}
    local coords = vecAdd(baseCoords or vec3(0.0, 0.0, 0.0), defaultStationOffsets[stationType] or vec3(0.0, 0.0, 0.0))
    MySQL.insert.await('INSERT INTO qbx_weed_stations (location_id, station_type, label, coords, size, rotation, enabled) VALUES (?, ?, ?, ?, ?, ?, 1)', {
        locationId,
        stationType,
        def.label or stationType,
        encodeVec(coords),
        encodeVec(vec3(2.0, 2.0, 2.0)),
        rotation or 0.0
    })
end

local function ensureAllStationsForLocation(locationId, baseCoords, rotation)
    for _, stationType in ipairs(defaultStationOrder) do
        if Config.StationTypes[stationType] and not stationTypeExists(locationId, stationType) then
            insertDefaultStation(locationId, stationType, baseCoords, rotation)
        else
            MySQL.update.await('UPDATE qbx_weed_stations SET enabled = 1 WHERE location_id = ? AND station_type = ?', { locationId, stationType })
        end
    end
end

local function ensureAllDefaultStations()
    local rows = MySQL.query.await('SELECT id FROM qbx_weed_locations') or {}
    for _, row in ipairs(rows) do
        local baseRow = MySQL.single.await('SELECT coords, rotation FROM qbx_weed_stations WHERE location_id = ? ORDER BY id ASC LIMIT 1', { row.id })
        local baseCoords = baseRow and decodeVec(baseRow.coords) or vec3(0.0, 0.0, 0.0)
        local rotation = baseRow and (baseRow.rotation or 0.0) or 0.0
        ensureAllStationsForLocation(row.id, baseCoords, rotation)
        MySQL.update.await('UPDATE qbx_weed_locations SET enabled = 1 WHERE id = ?', { row.id })
    end
end

CreateThread(function()
    if Config.UseDatabaseLocations then
        ensureTables()
        seedDefaultsIfEmpty()
        applyForcedDefaultMLOStations()
        ensureAllDefaultStations()
        loadLocations()
        registerBusinessStashes()
        registerSupplyStores()
    else
        for id, loc in ipairs(Config.DefaultLocations or {}) do
            locations[id] = loc
            locations[id].id = id
            for _, st in ipairs(loc.stations or {}) do st.locationId = id end
            for _, stash in ipairs(loc.stashes or {}) do stash.locationId = id end
            for _, store in ipairs(loc.supplyStores or {}) do store.locationId = id end
        end
    end
    local loadedCount = 0
    for _ in pairs(locations) do loadedCount = loadedCount + 1 end
    print(('[benz_weedshops] Loaded %s weed locations.'):format(loadedCount))
end)


lib.callback.register('benz_weedshops:server:getBusinessAccount', function(src, locationId)
    local loc = locations[tonumber(locationId)]
    if not loc or not hasLocationJob(src, locationId) then return nil end
    if not (isAdmin(src) or isBoss(src)) then return nil end
    local balance, account = getBusinessMoney(loc.job or Config.DefaultJob)
    return { account = account, balance = balance, unknown = balance == nil, job = loc.job or Config.DefaultJob }
end)

RegisterNetEvent('benz_weedshops:server:depositBusinessAccount', function(locationId, amount, payAccount)
    local src = source
    local loc = locations[tonumber(locationId)]
    amount = math.floor(tonumber(amount) or 0)
    payAccount = payAccount == 'bank' and 'bank' or 'cash'
    if amount <= 0 then return notify(src, 'Enter a valid amount.', 'error') end
    if not loc or not hasLocationJob(src, locationId) or not (isAdmin(src) or isBoss(src)) then return notify(src, 'No permission.', 'error') end
    if not removePlayerMoney(src, payAccount, amount, 'weedfactory-business-deposit') then
        return notify(src, ('Not enough %s to deposit.'):format(payAccount), 'error')
    end
    if not depositBusinessMoney(loc.job or Config.DefaultJob, amount, 'weedfactory-business-deposit') then
        addPlayerMoney(src, payAccount, amount, 'weedfactory-business-deposit-refund')
        return notify(src, 'Business account deposit failed. Payment refunded. Check banking config/export.', 'error')
    end
    notify(src, ('$%s deposited into business account.'):format(amount), 'success')
end)

RegisterNetEvent('benz_weedshops:server:withdrawBusinessAccount', function(locationId, amount, payoutAccount)
    local src = source
    local loc = locations[tonumber(locationId)]
    amount = math.floor(tonumber(amount) or 0)
    payoutAccount = payoutAccount == 'bank' and 'bank' or 'cash'
    if amount <= 0 then return notify(src, 'Enter a valid amount.', 'error') end
    if not loc or not hasLocationJob(src, locationId) or not (isAdmin(src) or isBoss(src)) then return notify(src, 'No permission.', 'error') end
    if not withdrawBusinessMoney(loc.job or Config.DefaultJob, amount, 'weedfactory-business-withdraw') then
        return notify(src, 'Business account withdrawal failed. Check balance or banking config/export.', 'error')
    end
    if not addPlayerMoney(src, payoutAccount, amount, 'weedfactory-business-withdraw') then
        depositBusinessMoney(loc.job or Config.DefaultJob, amount, 'weedfactory-business-withdraw-refund')
        return notify(src, 'Could not pay player. Money returned to business account.', 'error')
    end
    notify(src, ('$%s withdrawn from business account.'):format(amount), 'success')
end)

lib.callback.register('benz_weedshops:server:getLocations', function(src)
    return locations
end)

lib.callback.register('benz_weedshops:server:getEditorData', function(src)
    if not isAdmin(src) and not Config.AllowBossEditor then return false end
    return { locations = locations, stationTypes = Config.StationTypes, playerJob = jobName(src), admin = isAdmin(src), boss = isBoss(src) }
end)

RegisterNetEvent('benz_weedshops:server:createLocation', function(data)
    local src = source
    if not isAdmin(src) then return notify(src, 'Admin only.', 'error') end
    local name = tostring(data.name or 'New Weed Location'):sub(1, 80)
    local job = tostring(data.job or Config.DefaultJob):sub(1, 60)
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local id = MySQL.insert.await('INSERT INTO qbx_weed_locations (name, job, enabled, blip_coords, boss_coords, boss_size, boss_rotation, boss_label) VALUES (?, ?, 1, ?, ?, ?, ?, ?)', { name, job, encodeVec(c), encodeVec(c), encodeVec(vec3(1.4, 1.4, 1.6)), h, Config.BossMenuLabel })
    ensureAllStationsForLocation(id, c, h)
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, ('Created location #%s with all stations enabled.'):format(id), 'success')
end)

RegisterNetEvent('benz_weedshops:server:updateLocation', function(id, data)
    local src = source
    id = tonumber(id)
    local loc = locations[id]
    if not canEditLocation(src, loc) then return notify(src, 'No permission for this location.', 'error') end
    local name = tostring(data.name or loc.name):sub(1, 80)
    local job = isAdmin(src) and tostring(data.job or loc.job):sub(1, 60) or loc.job
    MySQL.update.await('UPDATE qbx_weed_locations SET name = ?, job = ?, enabled = 1 WHERE id = ?', { name, job, id })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Location updated.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:deleteLocation', function(id)
    local src = source
    if not isAdmin(src) then return notify(src, 'Admin only.', 'error') end
    id = tonumber(id)
    MySQL.update.await('DELETE FROM qbx_weed_stations WHERE location_id = ?', { id })
    MySQL.update.await('DELETE FROM qbx_weed_stashes WHERE location_id = ?', { id })
    MySQL.update.await('DELETE FROM qbx_weed_supply_stores WHERE location_id = ?', { id })
    MySQL.update.await('DELETE FROM qbx_weed_locations WHERE id = ?', { id })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Location deleted.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:addStationHere', function(locationId, stationType, label, size)
    local src = source
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not canEditLocation(src, loc) then return notify(src, 'No permission for this location.', 'error') end
    if not Config.StationTypes[stationType] then return notify(src, 'Invalid station type.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local s = size or { x = 2.0, y = 2.0, z = 2.0 }
    MySQL.insert.await('INSERT INTO qbx_weed_stations (location_id, station_type, label, coords, size, rotation, enabled) VALUES (?, ?, ?, ?, ?, ?, 1)', {
        locationId, stationType, tostring(label or Config.StationTypes[stationType].label):sub(1, 80), encodeVec(c), json.encode(s), h
    })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Station added at your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:updateStationHere', function(stationId, label, size)
    local src = source
    stationId = tonumber(stationId)
    local found
    for _, loc in pairs(locations) do
        for _, st in ipairs(loc.stations or {}) do
            if st.id == stationId then found = { loc = loc, st = st } break end
        end
    end
    if not found or not canEditLocation(src, found.loc) then return notify(src, 'No permission for this station.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    MySQL.update.await('UPDATE qbx_weed_stations SET label = ?, coords = ?, size = ?, rotation = ?, enabled = 1 WHERE id = ?', {
        tostring(label or found.st.label):sub(1, 80), encodeVec(c), json.encode(size or { x = found.st.size.x, y = found.st.size.y, z = found.st.size.z }), h, stationId
    })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Station moved/updated to your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:deleteStation', function(stationId)
    local src = source
    stationId = tonumber(stationId)
    local found
    for _, loc in pairs(locations) do
        for _, st in ipairs(loc.stations or {}) do
            if st.id == stationId then found = loc break end
        end
    end
    if not canEditLocation(src, found) then return notify(src, 'No permission for this station.', 'error') end
    MySQL.update.await('DELETE FROM qbx_weed_stations WHERE id = ?', { stationId })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Station deleted.', 'success')
end)


RegisterNetEvent('benz_weedshops:server:addStashHere', function(locationId, label, slots, weight, size)
    local src = source
    if Config.EnableBusinessStashes == false then return notify(src, 'Business stashes are disabled.', 'error') end
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not canEditLocation(src, loc) then return notify(src, 'No permission for this location.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local stashLabel = tostring(label or 'Business Stash'):sub(1, 80)
    local stashSlots = math.max(1, tonumber(slots) or Config.DefaultStashSlots or 60)
    local stashWeight = math.max(1000, tonumber(weight) or Config.DefaultStashWeight or 250000)
    local s = size or { x = 1.5, y = 1.5, z = 1.6 }
    local tempName = ('pending_%s_%s_%s'):format(locationId, src, os.time())
    local insertId = MySQL.insert.await('INSERT INTO qbx_weed_stashes (location_id, label, stash_name, coords, size, rotation, slots, weight, enabled) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)', {
        locationId, stashLabel, tempName, encodeVec(c), json.encode(s), h, stashSlots, stashWeight
    })
    local stashName = ('benz_weedshops_%s_stash_%s'):format(locationId, insertId)
    MySQL.update.await('UPDATE qbx_weed_stashes SET stash_name = ? WHERE id = ?', { stashName, insertId })
    loadLocations()
    registerBusinessStashes()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Business stash added at your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:updateStashHere', function(stashId, label, slots, weight, size)
    local src = source
    stashId = tonumber(stashId)
    local found
    for _, loc in pairs(locations) do
        for _, stash in ipairs(loc.stashes or {}) do
            if stash.id == stashId then found = { loc = loc, stash = stash } break end
        end
    end
    if not found or not canEditLocation(src, found.loc) then return notify(src, 'No permission for this stash.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local s = size or { x = found.stash.size.x, y = found.stash.size.y, z = found.stash.size.z }
    MySQL.update.await('UPDATE qbx_weed_stashes SET label = ?, coords = ?, size = ?, rotation = ?, slots = ?, weight = ?, enabled = 1 WHERE id = ?', {
        tostring(label or found.stash.label):sub(1, 80), encodeVec(c), json.encode(s), h, tonumber(slots) or found.stash.slots or Config.DefaultStashSlots or 60, tonumber(weight) or found.stash.weight or Config.DefaultStashWeight or 250000, stashId
    })
    loadLocations()
    registerBusinessStashes()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Business stash moved/updated to your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:deleteStash', function(stashId)
    local src = source
    stashId = tonumber(stashId)
    local found
    for _, loc in pairs(locations) do
        for _, stash in ipairs(loc.stashes or {}) do
            if stash.id == stashId then found = loc break end
        end
    end
    if not canEditLocation(src, found) then return notify(src, 'No permission for this stash.', 'error') end
    MySQL.update.await('DELETE FROM qbx_weed_stashes WHERE id = ?', { stashId })
    loadLocations()
    registerBusinessStashes()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Business stash deleted.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:openStash', function(locationId, stashName)
    local src = source
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not loc or not hasLocationJob(src, locationId) then return notify(src, 'You do not have access to this stash.', 'error') end
    for _, stash in ipairs(loc.stashes or {}) do
        if stash.stashName == stashName then
            return TriggerClientEvent('benz_weedshops:client:openStash', src, stash.stashName)
        end
    end
    notify(src, 'Stash not found.', 'error')
end)


RegisterNetEvent('benz_weedshops:server:addSupplyStoreHere', function(locationId, label, size)
    local src = source
    if Config.EnableSupplyStores == false then return notify(src, 'Supply stores are disabled.', 'error') end
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not canEditLocation(src, loc) then return notify(src, 'No permission for this location.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local storeLabel = tostring(label or 'Business Supply Store'):sub(1, 80)
    local s = size or { x = 1.6, y = 1.6, z = 1.8 }
    local tempName = ('pending_supply_%s_%s_%s'):format(locationId, src, os.time())
    local insertId = MySQL.insert.await('INSERT INTO qbx_weed_supply_stores (location_id, label, shop_name, coords, size, rotation, enabled) VALUES (?, ?, ?, ?, ?, ?, 1)', {
        locationId, storeLabel, tempName, encodeVec(c), json.encode(s), h
    })
    local shopName = ('benz_weedshops_%s_supply_%s'):format(locationId, insertId)
    MySQL.update.await('UPDATE qbx_weed_supply_stores SET shop_name = ? WHERE id = ?', { shopName, insertId })
    loadLocations()
    registerSupplyStores()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Supply store added at your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:updateSupplyStoreHere', function(storeId, label, size)
    local src = source
    storeId = tonumber(storeId)
    local found
    for _, loc in pairs(locations) do
        for _, store in ipairs(loc.supplyStores or {}) do
            if store.id == storeId then found = { loc = loc, store = store } break end
        end
    end
    if not found or not canEditLocation(src, found.loc) then return notify(src, 'No permission for this supply store.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local s = size or { x = found.store.size.x, y = found.store.size.y, z = found.store.size.z }
    MySQL.update.await('UPDATE qbx_weed_supply_stores SET label = ?, coords = ?, size = ?, rotation = ?, enabled = 1 WHERE id = ?', {
        tostring(label or found.store.label):sub(1, 80), encodeVec(c), json.encode(s), h, storeId
    })
    loadLocations()
    registerSupplyStores()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Supply store moved/updated to your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:deleteSupplyStore', function(storeId)
    local src = source
    storeId = tonumber(storeId)
    local found
    for _, loc in pairs(locations) do
        for _, store in ipairs(loc.supplyStores or {}) do
            if store.id == storeId then found = loc break end
        end
    end
    if not canEditLocation(src, found) then return notify(src, 'No permission for this supply store.', 'error') end
    MySQL.update.await('DELETE FROM qbx_weed_supply_stores WHERE id = ?', { storeId })
    loadLocations()
    registerSupplyStores()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Supply store deleted.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:openSupplyStore', function(locationId, shopName)
    local src = source
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not loc or not hasLocationJob(src, locationId) then return notify(src, 'You do not have access to this supply store.', 'error') end
    for _, store in ipairs(loc.supplyStores or {}) do
        if store.shopName == shopName then
            return TriggerClientEvent('benz_weedshops:client:openSupplyStore', src, store.shopName)
        end
    end
    notify(src, 'Supply store not found.', 'error')
end)


local function buildCustomerProducts(locationId)
    local products = {}
    for strain, strainData in pairs(Config.Strains or {}) do
        for weight, w in pairs(Config.Weights or {}) do
            products[#products + 1] = {
                id = ('bag:%s:%s'):format(strain, weight),
                category = 'bags',
                item = w.itemPrefix .. strain,
                label = ('%s %s'):format(strainData.label, w.label),
                price = math.floor((strainData.price or 1) * (w.multiplier or 1.0) * (Config.CustomerPriceMultiplier or 1.0)),
                max = 25
            }
        end
        for rollType, r in pairs(Config.Rollables or {}) do
            products[#products + 1] = {
                id = ('roll:%s:%s'):format(strain, rollType),
                category = 'joints',
                item = r.itemPrefix .. strain,
                label = ('%s %s'):format(strainData.label, r.label),
                price = math.floor((strainData.price or 1) * (r.priceMultiplier or 1.4) * (Config.CustomerPriceMultiplier or 1.0)),
                max = 25
            }
        end
        for edibleType, e in pairs(Config.Edibles or {}) do
            products[#products + 1] = {
                id = ('edible:%s:%s'):format(strain, edibleType),
                category = 'edibles',
                item = e.itemPrefix .. strain,
                label = ('%s %s'):format(strainData.label, e.label),
                price = math.floor((strainData.price or 1) * (e.priceMultiplier or 1.8) * (Config.CustomerPriceMultiplier or 1.0)),
                max = 25
            }
        end
    end
    products[#products + 1] = { id = 'bong:glass', category = 'bongs', item = Config.RequiredItems.bong or 'glass_bong', label = itemLabel(Config.RequiredItems.bong or 'glass_bong'), price = 250, max = 5 }
    table.sort(products, function(a, b) return (a.label or a.item) < (b.label or b.item) end)
    return products
end

local function productMap(locationId)
    local map = {}
    for _, product in ipairs(buildCustomerProducts(locationId)) do
        map[product.id] = product
    end
    return map
end

local function countStashItem(stashName, item)
    local ok, result = pcall(function() return exports.ox_inventory:GetItemCount(stashName, item) end)
    if ok then return tonumber(result) or 0 end
    return 0
end

local function removeFromBusinessStashes(loc, item, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return true, {} end
    local removed = {}
    local remaining = amount
    for _, stash in ipairs(loc.stashes or {}) do
        if remaining <= 0 then break end
        local stashName = stash.stashName or ('weed_stash_' .. stash.id)
        local have = countStashItem(stashName, item)
        if have > 0 then
            local take = math.min(have, remaining)
            local ok, result = pcall(function() return exports.ox_inventory:RemoveItem(stashName, item, take) end)
            if ok and result == true then
                removed[#removed + 1] = { stash = stashName, item = item, count = take }
                remaining = remaining - take
            end
        end
    end
    return remaining <= 0, removed
end

local function returnToBusinessStashes(removed)
    for _, entry in ipairs(removed or {}) do
        pcall(function() exports.ox_inventory:AddItem(entry.stash, entry.item, entry.count) end)
    end
end

local function businessStockCount(loc, item)
    local total = 0
    for _, stash in ipairs(loc.stashes or {}) do
        total = total + countStashItem(stash.stashName or ('weed_stash_' .. stash.id), item)
    end
    return total
end

lib.callback.register('benz_weedshops:server:getCustomerProducts', function(src, locationId)
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not loc then return nil end
    local products = buildCustomerProducts(locationId)
    if Config.CustomerStockFromBusinessStashes ~= false then
        for _, product in ipairs(products) do
            product.stock = businessStockCount(loc, product.item)
        end
    end
    return {
        location = { id = loc.id, name = loc.name, job = loc.job },
        categories = Config.CustomerMenuCategories or {},
        products = products
    }
end)

RegisterNetEvent('benz_weedshops:server:checkoutCustomerCart', function(locationId, cart, payAccount)
    local src = source
    if Config.EnableCustomerMenus == false then return notify(src, 'Customer menus are disabled.', 'error') end
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not loc then return notify(src, 'Store not found.', 'error') end
    payAccount = payAccount == 'bank' and 'bank' or 'cash'
    if Config.CustomerPaymentAccounts and Config.CustomerPaymentAccounts[payAccount] == false then
        return notify(src, 'That payment type is not enabled.', 'error')
    end
    if type(cart) ~= 'table' then return notify(src, 'Cart is empty.', 'error') end

    local map = productMap(locationId)
    local totals = {}
    local totalPrice = 0
    local itemCount = 0
    for productId, qty in pairs(cart) do
        local product = map[tostring(productId)]
        qty = math.floor(tonumber(qty) or 0)
        if product and qty > 0 then
            qty = math.min(qty, tonumber(product.max) or 25)
            local existing = totals[product.item]
            if existing then
                existing.count = existing.count + qty
                existing.price = existing.price + (qty * product.price)
            else
                totals[product.item] = { item = product.item, label = product.label, count = qty, price = qty * product.price }
            end
            totalPrice = totalPrice + (qty * product.price)
            itemCount = itemCount + qty
        end
    end

    if itemCount <= 0 or totalPrice <= 0 then return notify(src, 'Cart is empty.', 'error') end

    for _, entry in pairs(totals) do
        if not canCarryItem(src, entry.item, entry.count) then
            return notify(src, ('Not enough inventory space for %sx %s.'):format(entry.count, itemLabel(entry.item)), 'error')
        end
        if Config.CustomerStockFromBusinessStashes ~= false and businessStockCount(loc, entry.item) < entry.count then
            return notify(src, ('Not enough stock for %s.'):format(entry.label or itemLabel(entry.item)), 'error')
        end
    end

    if not removePlayerMoney(src, payAccount, totalPrice, 'weedfactory-customer-purchase') then
        return notify(src, ('Not enough %s for this purchase.'):format(payAccount), 'error')
    end

    local allRemoved = {}
    if Config.CustomerStockFromBusinessStashes ~= false then
        for _, entry in pairs(totals) do
            local ok, removed = removeFromBusinessStashes(loc, entry.item, entry.count)
            for _, r in ipairs(removed or {}) do allRemoved[#allRemoved + 1] = r end
            if not ok then
                returnToBusinessStashes(allRemoved)
                addPlayerMoney(src, payAccount, totalPrice, 'weedfactory-customer-refund')
                return notify(src, ('Stock changed while checking out. Refunded $%s.'):format(totalPrice), 'error')
            end
        end
    end

    local given = {}
    for _, entry in pairs(totals) do
        if not addItem(src, entry.item, entry.count) then
            for _, g in ipairs(given) do removeItem(src, g.item, g.count) end
            returnToBusinessStashes(allRemoved)
            addPlayerMoney(src, payAccount, totalPrice, 'weedfactory-customer-refund')
            return notify(src, ('Could not give %sx %s. Refunded $%s.'):format(entry.count, itemLabel(entry.item), totalPrice), 'error')
        end
        given[#given + 1] = { item = entry.item, count = entry.count }
    end

    local deposited = depositBusinessMoney(loc.job or Config.DefaultJob, totalPrice, 'weedfactory-customer-sale')
    if not deposited and Config.CustomerRequireBusinessDeposit == true then
        for _, g in ipairs(given) do removeItem(src, g.item, g.count) end
        returnToBusinessStashes(allRemoved)
        addPlayerMoney(src, payAccount, totalPrice, 'weedfactory-customer-refund')
        return notify(src, 'Business deposit failed. Purchase refunded.', 'error')
    end

    notify(src, ('Purchase complete: %s item(s) for $%s.'):format(itemCount, totalPrice), 'success')
end)

RegisterNetEvent('benz_weedshops:server:addCustomerStoreHere', function(locationId, label, size)
    local src = source
    if Config.EnableCustomerMenus == false then return notify(src, 'Customer menus are disabled.', 'error') end
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not canEditLocation(src, loc) then return notify(src, 'No permission for this location.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local storeLabel = tostring(label or 'Customer Menu'):sub(1, 80)
    local s = size or { x = 1.6, y = 1.6, z = 1.8 }
    MySQL.insert.await('INSERT INTO qbx_weed_customer_stores (location_id, label, coords, size, rotation, enabled) VALUES (?, ?, ?, ?, ?, 1)', {
        locationId, storeLabel, encodeVec(c), json.encode(s), h
    })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Customer menu added at your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:updateCustomerStoreHere', function(storeId, label, size)
    local src = source
    storeId = tonumber(storeId)
    local found
    for _, loc in pairs(locations) do
        for _, store in ipairs(loc.customerStores or {}) do
            if store.id == storeId then found = { loc = loc, store = store } break end
        end
    end
    if not found or not canEditLocation(src, found.loc) then return notify(src, 'No permission for this customer menu.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local s = size or { x = found.store.size.x, y = found.store.size.y, z = found.store.size.z }
    MySQL.update.await('UPDATE qbx_weed_customer_stores SET label = ?, coords = ?, size = ?, rotation = ?, enabled = 1 WHERE id = ?', {
        tostring(label or found.store.label):sub(1, 80), encodeVec(c), json.encode(s), h, storeId
    })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Customer menu moved/updated to your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:deleteCustomerStore', function(storeId)
    local src = source
    storeId = tonumber(storeId)
    local found
    for _, loc in pairs(locations) do
        for _, store in ipairs(loc.customerStores or {}) do
            if store.id == storeId then found = loc break end
        end
    end
    if not canEditLocation(src, found) then return notify(src, 'No permission for this customer menu.', 'error') end
    MySQL.update.await('DELETE FROM qbx_weed_customer_stores WHERE id = ?', { storeId })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Customer menu deleted.', 'success')
end)

local function getLocationBaseCoords(loc)
    if loc and loc.stations and loc.stations[1] and loc.stations[1].coords then return loc.stations[1].coords end
    if loc and loc.blip then return loc.blip end
    return vec3(0.0, 0.0, 0.0)
end

local function vecSub(a, b)
    return vec3((a.x or 0.0) - (b.x or 0.0), (a.y or 0.0) - (b.y or 0.0), (a.z or 0.0) - (b.z or 0.0))
end

RegisterNetEvent('benz_weedshops:server:setLocationBlipHere', function(locationId)
    local src = source
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not canEditLocation(src, loc) then return notify(src, 'No permission for this location.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    MySQL.update.await('UPDATE qbx_weed_locations SET blip_coords = ?, enabled = 1 WHERE id = ?', { encodeVec(c), locationId })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Store blip moved to your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:setBossMenuHere', function(locationId, label, size)
    local src = source
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not canEditLocation(src, loc) then return notify(src, 'No permission for this location.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local s = size or { x = 1.4, y = 1.4, z = 1.6 }
    MySQL.update.await('UPDATE qbx_weed_locations SET boss_coords = ?, boss_size = ?, boss_rotation = ?, boss_label = ?, enabled = 1 WHERE id = ?', {
        encodeVec(c), json.encode(s), h, tostring(label or Config.BossMenuLabel):sub(1, 80), locationId
    })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Boss menu moved to your position.', 'success')
end)

RegisterNetEvent('benz_weedshops:server:moveLocationHere', function(locationId, moveStations, moveBlip, moveBoss)
    local src = source
    locationId = tonumber(locationId)
    local loc = locations[locationId]
    if not canEditLocation(src, loc) then return notify(src, 'No permission for this location.', 'error') end
    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    local oldBase = getLocationBaseCoords(loc)
    local delta = vecSub(c, oldBase)

    if moveStations then
        for _, st in ipairs(loc.stations or {}) do
            local newCoords = vecAdd(st.coords, delta)
            MySQL.update.await('UPDATE qbx_weed_stations SET coords = ?, rotation = ?, enabled = 1 WHERE id = ?', { encodeVec(newCoords), h, st.id })
        end
    end

    if moveBlip then
        MySQL.update.await('UPDATE qbx_weed_locations SET blip_coords = ? WHERE id = ?', { encodeVec(c), locationId })
    end

    if moveBoss then
        MySQL.update.await('UPDATE qbx_weed_locations SET boss_coords = ?, boss_rotation = ?, boss_label = COALESCE(boss_label, ?) WHERE id = ?', { encodeVec(c), h, Config.BossMenuLabel, locationId })
    end

    MySQL.update.await('UPDATE qbx_weed_locations SET enabled = 1 WHERE id = ?', { locationId })
    loadLocations()
    TriggerClientEvent('benz_weedshops:client:refreshZones', -1, locations)
    notify(src, 'Location moved/updated.', 'success')
end)


function itemLabel(item)
    if not item then return 'Unknown Item' end
    local ok, items = pcall(function() return exports.ox_inventory:Items() end)
    if ok and items and items[item] and items[item].label then
        return items[item].label
    end
    return tostring(item):gsub('_', ' ')
end

local function getCount(src, item)
    if not item then return 0 end
    return exports.ox_inventory:GetItemCount(src, item) or 0
end

local function buildRequirements(src, action, data)
    data = data or {}
    local strain = data.strain
    local s = strain and Config.Strains[strain] or nil
    if not s then
        return { title = 'Invalid Item', actionLabel = 'Crafting', hasAll = false, items = {} }
    end

    local reqs = {}
    local title = 'Item Requirements'
    local actionLabel = 'Crafting'

    local function add(item, amount)
        amount = tonumber(amount) or 1
        reqs[#reqs + 1] = {
            item = item,
            label = itemLabel(item),
            need = amount,
            have = getCount(src, item),
            ok = getCount(src, item) >= amount
        }
    end

    if action == 'grow' then
        title = 'Grow ' .. s.label
        actionLabel = 'Grow Plant'
        add(s.seed, 1)
        add(Config.RequiredItems.soil, 1)
        add(Config.RequiredItems.water, 1)
    elseif action == 'dry' then
        title = 'Dry/Cure ' .. s.label
        actionLabel = 'Dry Flower'
        add('wet_' .. s.bud, 1)
    elseif action == 'roll' then
        local rollType = data.rollType or 'classic_joint'
        local r = Config.Rollables and Config.Rollables[rollType] or nil
        if not r then return { title = 'Invalid Rollable', actionLabel = 'Roll Product', hasAll = false, items = {} } end
        title = 'Make ' .. s.label .. ' ' .. r.label
        actionLabel = 'Roll Product'
        add(s.bud, r.flower or 1)
        add(r.requiredItem or Config.RequiredItems.rollingPaper, 1)
    elseif action == 'edible' then
        local edibleType = data.edibleType or 'brownie'
        local e = Config.Edibles and Config.Edibles[edibleType] or nil
        if not e then return { title = 'Invalid Edible', actionLabel = 'Make Edible', hasAll = false, items = {} } end
        title = 'Make ' .. s.label .. ' ' .. e.label
        actionLabel = 'Make Edible'
        add(s.bud, e.flower or 1)
        add(e.baseItem or Config.RequiredItems.edibleBase, 1)
    elseif action == 'bong' then
        title = 'Pack ' .. s.label .. ' Bong'
        actionLabel = 'Pack Bong'
        add(s.bud, 1)
        add(Config.RequiredItems.bong, 1)
    elseif action == 'bag' then
        local weight = data.weight or 'gram'
        local w = Config.Weights and Config.Weights[weight] or nil
        if not w then return { title = 'Invalid Bag Weight', actionLabel = 'Package Bag', hasAll = false, items = {} } end
        title = 'Package ' .. s.label .. ' ' .. w.label
        actionLabel = 'Package Bag'
        add(s.bud, w.amount or 1)
        add(Config.RequiredItems.baggie, 1)
    end

    local hasAll = true
    for _, req in ipairs(reqs) do
        if not req.ok then hasAll = false break end
    end

    return { title = title, actionLabel = actionLabel, hasAll = hasAll, items = reqs }
end

lib.callback.register('benz_weedshops:server:getRequirements', function(source, action, data)
    if data and data.locationId and not hasLocationJob(source, data.locationId) then
        return { title = 'No Access', actionLabel = 'Crafting', hasAll = false, items = {} }
    end
    return buildRequirements(source, action, data)
end)

local function process(src, locationId, cb)
    if not hasLocationJob(src, locationId) then return notify(src, 'You do not have access to this location.', 'error') end
    return cb()
end

RegisterNetEvent('benz_weedshops:server:grow', function(strain, locationId)
    local src = source
    process(src, locationId, function()
        local s = Config.Strains[strain]; if not s then return end
        if not hasItem(src, s.seed, 1) or not hasItem(src, Config.RequiredItems.soil, 1) or not hasItem(src, Config.RequiredItems.water, 1) then return notify(src, 'Missing seed, soil, or water.', 'error') end
        local rewardAmount = math.random(2, 5)
        local rewardItem = 'wet_' .. s.bud
        local rewardMeta = { strain = s.label }
        if not giveCraftReward(src, rewardItem, rewardAmount, rewardMeta) then return end
        if not removeItem(src, s.seed, 1) or not removeItem(src, Config.RequiredItems.soil, 1) or not removeItem(src, Config.RequiredItems.water, 1) then
            removeItem(src, rewardItem, rewardAmount)
            return notify(src, 'Could not remove required items. Craft cancelled.', 'error')
        end
        notify(src, ('Plant harvested. Received %sx %s.'):format(rewardAmount, itemLabel(rewardItem)), 'success')
    end)
end)

RegisterNetEvent('benz_weedshops:server:dry', function(strain, locationId)
    local src = source
    process(src, locationId, function()
        local s = Config.Strains[strain]; if not s then return end
        local wet = 'wet_' .. s.bud
        if not hasItem(src, wet, 1) then return notify(src, 'Missing wet flower.', 'error') end
        local rewardMeta = { strain = s.label }
        if not giveCraftReward(src, s.bud, 1, rewardMeta) then return end
        if not removeItem(src, wet, 1) then
            removeItem(src, s.bud, 1)
            return notify(src, 'Could not remove required items. Craft cancelled.', 'error')
        end
        notify(src, ('Flower dried and cured. Received 1x %s.'):format(itemLabel(s.bud)), 'success')
    end)
end)

RegisterNetEvent('benz_weedshops:server:roll', function(strain, rollType, locationId)
    local src = source
    process(src, locationId, function()
        local s = Config.Strains[strain]
        local r = Config.Rollables and Config.Rollables[rollType] or nil
        if not s or not r then return end
        local requiredItem = r.requiredItem or Config.RequiredItems.rollingPaper
        local flowerAmount = r.flower or 1
        if not hasItem(src, s.bud, flowerAmount) or not hasItem(src, requiredItem, 1) then
            return notify(src, ('Missing %sx flower or %s.'):format(flowerAmount, requiredItem), 'error')
        end
        local rewardItem = r.itemPrefix .. strain
        local rewardMeta = { strain = s.label, product = r.label, effect = r.effect or 'joint' }
        if not giveCraftReward(src, rewardItem, 1, rewardMeta) then return end
        if not removeItem(src, s.bud, flowerAmount) or not removeItem(src, requiredItem, 1) then
            removeItem(src, rewardItem, 1)
            return notify(src, 'Could not remove required items. Craft cancelled.', 'error')
        end
        notify(src, ('%s rolled. Received 1x %s.'):format(r.label, itemLabel(rewardItem)), 'success')
    end)
end)

RegisterNetEvent('benz_weedshops:server:edible', function(strain, edibleType, locationId)
    local src = source
    process(src, locationId, function()
        local s = Config.Strains[strain]
        local e = Config.Edibles and Config.Edibles[edibleType] or nil
        if not s or not e then return end
        local baseItem = e.baseItem or Config.RequiredItems.edibleBase
        local flowerAmount = e.flower or 1
        if not hasItem(src, s.bud, flowerAmount) or not hasItem(src, baseItem, 1) then
            return notify(src, ('Missing %sx flower or %s.'):format(flowerAmount, baseItem), 'error')
        end
        local rewardItem = e.itemPrefix .. strain
        local rewardMeta = { strain = s.label, product = e.label, effect = e.effect or 'edible' }
        if not giveCraftReward(src, rewardItem, 1, rewardMeta) then return end
        if not removeItem(src, s.bud, flowerAmount) or not removeItem(src, baseItem, 1) then
            removeItem(src, rewardItem, 1)
            return notify(src, 'Could not remove required items. Craft cancelled.', 'error')
        end
        notify(src, ('%s prepared. Received 1x %s.'):format(e.label, itemLabel(rewardItem)), 'success')
    end)
end)

RegisterNetEvent('benz_weedshops:server:bong', function(strain, locationId)
    local src = source
    process(src, locationId, function()
        local s = Config.Strains[strain]; if not s then return end
        if not hasItem(src, s.bud, 1) or not hasItem(src, Config.RequiredItems.bong, 1) then return notify(src, 'Missing flower or bong.', 'error') end
        removeItem(src, s.bud, 1)
        TriggerClientEvent('benz_weedshops:client:useEffect', src, 'bong')
        notify(src, 'Bong used.', 'success')
    end)
end)

RegisterNetEvent('benz_weedshops:server:bag', function(strain, weight, locationId)
    local src = source
    process(src, locationId, function()
        local s = Config.Strains[strain]
        local w = Config.Weights[weight]
        if not s or not w then return end

        local flowerAmount = tonumber(w.amount) or 1
        local baggieItem = Config.RequiredItems.baggie
        local rewardItem = w.itemPrefix .. strain
        local rewardMeta = { strain = s.label, weight = w.label }

        if not hasItem(src, s.bud, flowerAmount) or not hasItem(src, baggieItem, 1) then
            return notify(src, 'Missing flower or empty baggie.', 'error')
        end

        -- Packaging must remove inputs first so the finished bag can fit in ox_inventory.
        -- This fixes crafts finishing without giving the packaged item when players are
        -- close to their weight/slot limit.
        if not removeItem(src, s.bud, flowerAmount) then
            return notify(src, 'Could not remove required flower. Craft cancelled.', 'error')
        end

        if not removeItem(src, baggieItem, 1) then
            addItem(src, s.bud, flowerAmount, { strain = s.label })
            return notify(src, 'Could not remove empty baggie. Craft cancelled.', 'error')
        end

        if not giveCraftReward(src, rewardItem, 1, rewardMeta) then
            -- Give ingredients back if the reward item cannot be added.
            addItem(src, s.bud, flowerAmount, { strain = s.label })
            addItem(src, baggieItem, 1)
            return
        end

        notify(src, ('%s packaged. Received 1x %s.'):format(w.label, itemLabel(rewardItem)), 'success')
    end)
end)

RegisterNetEvent('benz_weedshops:server:sellAll', function(locationId)
    local src = source
    process(src, locationId, function()
        local total = 0
        for strain, s in pairs(Config.Strains) do
            local sellables = {}
            for _, r in pairs(Config.Rollables or {}) do sellables[#sellables + 1] = { item = r.itemPrefix .. strain, price = math.floor(s.price * (r.priceMultiplier or 1.4)) } end
            for _, e in pairs(Config.Edibles or {}) do sellables[#sellables + 1] = { item = e.itemPrefix .. strain, price = math.floor(s.price * (e.priceMultiplier or 1.8)) } end
            for _, w in pairs(Config.Weights) do sellables[#sellables + 1] = { item = w.itemPrefix .. strain, price = math.floor(s.price * w.multiplier) } end
            for _, data in pairs(sellables) do
                local count = exports.ox_inventory:GetItemCount(src, data.item)
                if count > 0 then removeItem(src, data.item, count); total = total + (count * data.price) end
            end
        end
        if total <= 0 then return notify(src, 'You have nothing to sell.', 'error') end
        if not addCash(src, total, 'weedfactory-sale') then
            return notify(src, 'Sale completed, but payment failed. Check qbx_core money export or ox_inventory money item.', 'error')
        end
        notify(src, ('Sold products for $%s.'):format(total), 'success')
    end)
end)

for strain, s in pairs(Config.Strains) do
    exports(s.bud, function(event) if event == 'usingItem' then return true end end)
    for _, r in pairs(Config.Rollables or {}) do
        exports(r.itemPrefix .. strain, function(event, item, inventory)
            if event == 'usedItem' then TriggerClientEvent('benz_weedshops:client:useEffect', inventory.id, r.effect or 'joint') end
        end)
    end
    for _, e in pairs(Config.Edibles or {}) do
        exports(e.itemPrefix .. strain, function(event, item, inventory)
            if event == 'usedItem' then TriggerClientEvent('benz_weedshops:client:useEffect', inventory.id, e.effect or 'edible') end
        end)
    end
end
