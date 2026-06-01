CREATE TABLE IF NOT EXISTS `qbx_weed_locations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(80) NOT NULL,
  `job` varchar(60) NOT NULL DEFAULT 'whitewidow',
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `blip_coords` longtext NULL,
  `boss_coords` longtext NULL,
  `boss_size` longtext NULL,
  `boss_rotation` float NOT NULL DEFAULT 0,
  `boss_label` varchar(80) NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `qbx_weed_stations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `location_id` int NOT NULL,
  `station_type` varchar(30) NOT NULL,
  `label` varchar(80) NOT NULL,
  `coords` longtext NOT NULL,
  `size` longtext NOT NULL,
  `rotation` float NOT NULL DEFAULT 0,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `location_id` (`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Existing installs are auto-migrated by server/main.lua, but these are here if you patch manually.
-- ALTER TABLE qbx_weed_locations ADD COLUMN blip_coords LONGTEXT NULL;
-- ALTER TABLE qbx_weed_locations ADD COLUMN boss_coords LONGTEXT NULL;
-- ALTER TABLE qbx_weed_locations ADD COLUMN boss_size LONGTEXT NULL;
-- ALTER TABLE qbx_weed_locations ADD COLUMN boss_rotation FLOAT NOT NULL DEFAULT 0;
-- ALTER TABLE qbx_weed_locations ADD COLUMN boss_label VARCHAR(80) NULL;


CREATE TABLE IF NOT EXISTS `qbx_weed_stashes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `location_id` int NOT NULL,
  `label` varchar(80) NOT NULL,
  `stash_name` varchar(100) NOT NULL,
  `coords` longtext NOT NULL,
  `size` longtext NOT NULL,
  `rotation` float NOT NULL DEFAULT 0,
  `slots` int NOT NULL DEFAULT 60,
  `weight` int NOT NULL DEFAULT 250000,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `stash_name` (`stash_name`),
  KEY `location_id` (`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `qbx_weed_supply_stores` (
  `id` int NOT NULL AUTO_INCREMENT,
  `location_id` int NOT NULL,
  `label` varchar(80) NOT NULL,
  `shop_name` varchar(100) NOT NULL,
  `coords` longtext NOT NULL,
  `size` longtext NOT NULL,
  `rotation` float NOT NULL DEFAULT 0,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `shop_name` (`shop_name`),
  KEY `location_id` (`location_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


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
