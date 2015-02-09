CREATE DATABASE IF NOT EXISTS assetmanager;
GRANT SELECT ON *.* TO 'assetmanager'@'localhost';
DROP USER 'assetmanager'@'localhost';
FLUSH PRIVILEGES;
CREATE USER 'assetmanager'@'localhost' IDENTIFIED BY 'StRaW101';
GRANT SELECT, INSERT, UPDATE, DELETE ON assetmanager.* TO 'assetmanager'@'localhost';
FLUSH PRIVILEGES;
