    --
    -- setting up tables for tests
    --

    USE assetmanager;

    DROP TABLE IF EXISTS asset_test;
    DROP TABLE IF EXISTS datacentre_test;
    DROP TABLE IF EXISTS software_test;
    DROP TABLE IF EXISTS asset_software_test;

    CREATE TABLE datacentre_test (
           id          INT  NOT NULL PRIMARY KEY AUTO_INCREMENT,
           name        VARCHAR(255) NOT NULL,
           UNIQUE INDEX name_uniq (name),
           INDEX (name)
    ) ENGINE=InnoDB;
    CREATE TABLE asset_test (
           id          INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
           name        VARCHAR(255) NOT NULL,
           datacentre    INT NOT NULL,
           FOREIGN KEY (datacentre) references datacentre_test(id),
           UNIQUE INDEX name_cat_uniq (name, datacentre),
           INDEX (name, datacentre)
    ) ENGINE=InnoDB;
    CREATE TABLE software_test (
           id          INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
           name        VARCHAR(255) NOT NULL,
           UNIQUE INDEX name_uniq (name),
           INDEX (name)
           
    ) ENGINE=InnoDB;
    CREATE TABLE asset_software_test (
           asset     INT NOT NULL,
           software       INT NOT NULL,
           UNIQUE INDEX asst_softw_uniq (asset, software),
           INDEX (asset),
           INDEX (software),
           PRIMARY KEY (asset, software)
    ) ENGINE=InnoDB;

    INSERT INTO software_test VALUES (NULL, 'Apache 2.2');
    INSERT INTO software_test VALUES (NULL, 'Gimp 2.2');
    INSERT INTO software_test VALUES (NULL, 'graphite 2.2');
    INSERT INTO software_test VALUES (NULL, 'HAProxy 2.2');
    INSERT INTO software_test VALUES (NULL, 'Apache 2.4');
    INSERT INTO software_test VALUES (NULL, 'nodejs 2.2');
    INSERT INTO software_test VALUES (NULL, 'Catalyst 5.9');
