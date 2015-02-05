    --
    -- Create mysql database with the relevant tables
    --

    DROP DATABASE IF EXISTS assetmanager;
    CREATE DATABASE IF NOT EXISTS assetmanager DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

    USE assetmanager;

    DROP TABLE IF EXISTS asset;
    DROP TABLE IF EXISTS datacentre;
    DROP TABLE IF EXISTS software;
    DROP TABLE IF EXISTS asset_software;

    CREATE TABLE datacentre (
           id          INT  NOT NULL PRIMARY KEY AUTO_INCREMENT,
           name        VARCHAR(255) NOT NULL,
           UNIQUE INDEX name_uniq (name),
           INDEX (name)
    ) ENGINE=InnoDB;
    CREATE TABLE asset (
           id          INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
           name        VARCHAR(255) NOT NULL,
           datacentre    INT NOT NULL,
           FOREIGN KEY (datacentre) references datacentre(id),
           UNIQUE INDEX name_cat_uniq (name, datacentre),
           INDEX (name, datacentre)
    ) ENGINE=InnoDB;
    CREATE TABLE software (
           id          INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
           name        VARCHAR(255) NOT NULL,
           UNIQUE INDEX name_uniq (name),
           INDEX (name)
           
    ) ENGINE=InnoDB;
    CREATE TABLE asset_software (
           asset     INT NOT NULL,
           software       INT NOT NULL,
           UNIQUE INDEX cloth_outf_uniq (asset, software),
           INDEX (asset),
           INDEX (software),
           PRIMARY KEY (asset, software)
    ) ENGINE=InnoDB;

    INSERT INTO software VALUES (NULL, 'Apache 2.2');
    INSERT INTO software VALUES (NULL, 'Gimp 2.2');
    INSERT INTO software VALUES (NULL, 'graphite 2.2');
    INSERT INTO software VALUES (NULL, 'HAProxy 2.2');
    INSERT INTO software VALUES (NULL, 'Apache 2.4');
    INSERT INTO software VALUES (NULL, 'nodejs 2.2');
    INSERT INTO software VALUES (NULL, 'Catalyst 5.9');
