GRANT SELECT ON *.* TO 'assetmanager'@'localhost';
DROP USER 'assetmanager'@'localhost';
GRANT SELECT ON *.* TO 'assetmanagerapi'@'localhost';
DROP USER 'assetmanagerapi'@'localhost';
FLUSH PRIVILEGES;
