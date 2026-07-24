/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'Datawarehouse' after checking if it
    already exists. If the database exists, it is dropped and recreated.
    Additionally, the script sets up three schemas within the database:
    'bronze', 'silver', and 'gold'.

WARNING:
    Running this script will drop the entire 'Datawarehouse' database if it exists.
    All data in the database will be permanently deleted. Proceed with caution
    and ensure you have proper backups before running this script.
=============================================================
*/

USE master;
GO

-- ============================================================
-- 1. Drop and recreate the 'Datawarehouse' database
-- ============================================================

-- Check if the database exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Datawarehouse')
BEGIN
    -- Force single-user mode to disconnect any active connections before dropping
    ALTER DATABASE Datawarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Datawarehouse;
    PRINT 'Existing database "Datawarehouse" was dropped.';
END
GO

-- Create the 'Datawarehouse' database
CREATE DATABASE Datawarehouse;
GO
PRINT 'Database "Datawarehouse" created successfully.';
GO

USE Datawarehouse;
GO

-- ============================================================
-- 2. Create Schemas (bronze, silver, gold)
-- ============================================================

-- Bronze Layer Schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bronze')
BEGIN
    EXEC('CREATE SCHEMA bronze');
    PRINT 'Schema "bronze" created successfully.';
END
ELSE
    PRINT 'Schema "bronze" already exists. Skipped.';
GO

-- Silver Layer Schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
BEGIN
    EXEC('CREATE SCHEMA silver');
    PRINT 'Schema "silver" created successfully.';
END
ELSE
    PRINT 'Schema "silver" already exists. Skipped.';
GO

-- Gold Layer Schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
    PRINT 'Schema "gold" created successfully.';
END
ELSE
    PRINT 'Schema "gold" already exists. Skipped.';
GO

PRINT 'Database and schema initialization completed successfully.';
GO
