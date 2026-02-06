-- Snowflake bootstrap for Spotify pipeline
-- Run in Snowsight worksheet as ACCOUNTADMIN

use role ACCOUNTADMIN;

-- Create role
create role if not exists SPOTIFY_ROLE;

-- Create warehouse
create warehouse if not exists SPOTIFY_WH
  warehouse_size = 'XSMALL'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

-- Create database and schema
create database if not exists SPOTIFY_ANALYTICS;
create schema if not exists SPOTIFY_ANALYTICS.BRONZE;
create schema if not exists SPOTIFY_ANALYTICS.SILVER;
create schema if not exists SPOTIFY_ANALYTICS.GOLD;
create schema if not exists SPOTIFY_ANALYTICS.DBT_DEV;

-- Create user (CHANGE PASSWORD!)
create user if not exists SPOTIFY_USER
  password = ''
  must_change_password = false
  default_role = SPOTIFY_ROLE
  default_warehouse = SPOTIFY_WH
  default_namespace = SPOTIFY_ANALYTICS.BRONZE;

-- Grant role to user
grant role SPOTIFY_ROLE to user SPOTIFY_USER;

-- Grant permissions
grant usage on warehouse SPOTIFY_WH to role SPOTIFY_ROLE;
grant usage on database SPOTIFY_ANALYTICS to role SPOTIFY_ROLE;

grant usage on schema SPOTIFY_ANALYTICS.BRONZE to role SPOTIFY_ROLE;
grant usage on schema SPOTIFY_ANALYTICS.SILVER to role SPOTIFY_ROLE;
grant usage on schema SPOTIFY_ANALYTICS.GOLD to role SPOTIFY_ROLE;
grant usage on schema SPOTIFY_ANALYTICS.DBT_DEV to role SPOTIFY_ROLE;

grant all privileges on schema SPOTIFY_ANALYTICS.BRONZE to role SPOTIFY_ROLE;
grant all privileges on future tables in schema SPOTIFY_ANALYTICS.BRONZE to role SPOTIFY_ROLE;
grant all privileges on schema SPOTIFY_ANALYTICS.SILVER to role SPOTIFY_ROLE;
grant all privileges on future tables in schema SPOTIFY_ANALYTICS.SILVER to role SPOTIFY_ROLE;
grant all privileges on schema SPOTIFY_ANALYTICS.GOLD to role SPOTIFY_ROLE;
grant all privileges on future tables in schema SPOTIFY_ANALYTICS.GOLD to role SPOTIFY_ROLE;
grant all privileges on schema SPOTIFY_ANALYTICS.DBT_DEV to role SPOTIFY_ROLE;
grant all privileges on future tables in schema SPOTIFY_ANALYTICS.DBT_DEV to role SPOTIFY_ROLE;