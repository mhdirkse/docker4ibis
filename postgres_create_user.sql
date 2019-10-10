create database :db;
create user :user with encrypted password ':user';
grant all privileges on database :db to :user;