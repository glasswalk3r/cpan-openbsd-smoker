CREATE USER 'vagrant'@'localhost';
GRANT ALL PRIVILEGES ON test.* TO 'vagrant'@'localhost';
GRANT SELECT ON performance_schema.* TO 'vagrant'@'localhost';
