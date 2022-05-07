CREATE USER 'vagrant'@'localhost' IDENTIFIED BY 'vagrant';
GRANT ALL PRIVILEGES ON test.* TO 'vagrant'@'localhost';
GRANT SELECT ON performance_schema.* TO 'vagrant'@'localhost';
