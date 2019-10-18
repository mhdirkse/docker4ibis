DROP USER IF EXISTS @user;
DROP DATABASE IF EXISTS @db;

CREATE USER @user IDENTIFIED BY '@user';

CREATE DATABASE @db CHARACTER SET utf8 COLLATE utf8_bin;

USE @db

GRANT ALL ON `@db`.* TO '@user'@'%';

ALTER USER '@user'@'%' IDENTIFIED WITH mysql_native_password BY '@user';

