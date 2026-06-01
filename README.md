# benz_weedshops

## Requirements
- qbx_core
- ox_lib
- ox_inventory
- ox_target
- oxmysql


Each shop location has:
- Location name
- Locked job name
- Enabled/disabled toggle
- Unlimited stations
- Station type: grow, dry, roll, edibles, bags, bong, sell
- Station label
- Station box size
- Station coords and heading
- Station enabled/disabled toggle

Locations and stations save to the database and reload after restart.

## In-Game Editor
Use:
```lua
/weedadmin
```

Admins can:
- Create locations
- Edit location names
- Change job locks
- Enable/disable locations
- Add stations at their current position
- Move stations to their current position
- Resize stations
- Rename stations
- Enable/disable stations
- Delete stations
- Delete locations

Boss grade employees can edit only locations locked to their own job when this is enabled:
```lua
Config.AllowBossEditor = true
```

Admins are controlled by:
```lua
Config.AdminGroups = { 'admin', 'god' }
Config.AdminAce = 'benz_weedshops.admin'
```

Example server.cfg ace:
```cfg
add_ace group.admin benz_weedshops.admin allow
```

## How To Use With Any White Widow MLO
1. Start the resource.
2. Go inside your White Widow MLO.
3. Run `/weedadmin`.
4. Create a new location or open an existing one.
5. Set the locked job, for example `whitewidow`, `smokeys`, or `cookies`.
6. Add stations while standing at each counter, table, grow room, kitchen, or register.
7. The station is saved instantly and refreshed for all players.

## Helpful Coord Command
Use:
```lua
/wwcoords
```
This copies your current coords and heading to clipboard and prints them in F8.

## Database
The script auto-creates its database tables on startup. A manual SQL file is also included:
```sql
sql/install.sql
```

## Items
Add the items from:
```lua
sql/items.lua
```
to your ox_inventory items.

## Station Types
- `grow` - grow/harvest fictional plants
- `dry` - dry/cure flower
- `roll` - roll joints
- `edibles` - make edibles
- `bags` - package 1g, 3.5g, 7g, 28g bags
- `bong` - use bong station
- `sell` - sell finished products

## Expanded Products

This version includes 20 configurable strains, 7 rollable products, 8 edible products, bong effects, and 4 packaged bag weights.

Edit these in `shared/config.lua`:
- `Config.Strains` for strain names, seeds, flower items, and base sale price.
- `Config.Rollables` for joints/blunts, required wrap/paper item, flower amount, sale multiplier, and effect type.
- `Config.Edibles` for brownies, cookies, gummies, chocolate, cereal bars, lollipops, and other edible recipes.
- `Config.Weights` for packaged bag sizes.

Copy the expanded `sql/items.lua` entries into `ox_inventory/data/items.lua` and restart `ox_inventory`.


## Station Target Patch
This version forces every weed location to have all default stations enabled:
- Grow Plants
- Dry/Cure Flower
- Roll Joints & Blunts
- Make Edibles
- Package Weed Bags
- Pack Bong
- Sell Products

All stations are registered through ox_target box zones. Existing database locations are automatically backfilled with missing stations on resource start. New locations created through `/weedadmin` automatically spawn every station enabled by default near the creator's position.

## okokBanking Society Accounts

This build supports okokBanking society/business funds.

Default config:
```lua
Config.CustomerBusinessDeposit = {
    mode = 'okokBanking',
    accountPrefix = '',
    reason = 'weedfactory-customer-sale'
}
```

Use `accountPrefix = ''` when your okokBanking society account is the job name, for example `whitewidow`.
Use `accountPrefix = 'society_'` only if your okokBanking account is named like `society_whitewidow`.

Make sure `okokBanking` starts before `benz_weedshops` in `server.cfg`.
