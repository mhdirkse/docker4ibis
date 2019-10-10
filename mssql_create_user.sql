CREATE LOGIN $(user) WITH PASSWORD = '$(user)00';
CREATE DATABASE $(db);

GO

USE $(db);

CREATE USER $(user);
GRANT CONTROL TO $(user);

GO
