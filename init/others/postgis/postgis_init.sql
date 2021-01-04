CREATE USER osm_db WITH PASSWORD 'osmRocks!' SUPERUSER;
\c postgres osm_db
CREATE DATABASE osm_db;
\c osm_db
CREATE EXTENSION postgis;
CREATE EXTENSION hstore;
