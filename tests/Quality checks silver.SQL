/*
=============================================================
Quality Checks: Silver Layer
=============================================================
Script Purpose:
    This script performs quality checks for data consistency, accuracy,
    and standardization across the 'silver' schema tables. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency (e.g. gender, marital status, country).
    - Invalid date ranges and orders.
    - Data consistency between related fields (e.g. sales = quantity * price).

Usage Notes:
    - Run this script AFTER executing silver.load_silver.
    - Every query below should return NO ROWS if the data is clean.
    - Any row returned by a check flags a data quality issue that needs
      investigation, either in the source data or in the silver transformation
      logic (proc_load_silver.sql).
=============================================================
*/

USE Datawarehouse;
GO

-- ============================================================
-- Checking 'silver.crm_cust_info'
-- ============================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Check for unwanted spaces in string fields
-- Expectation: No Results
SELECT cst_key FROM silver.crm_cust_info WHERE cst_key != TRIM(cst_key);
SELECT cst_firstname FROM silver.crm_cust_info WHERE cst_firstname != TRIM(cst_firstname);
SELECT cst_lastname FROM silver.crm_cust_info WHERE cst_lastname != TRIM(cst_lastname);

-- Data standardization & consistency
-- Expectation: only 'Married', 'Single', 'n/a'
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;

-- Expectation: only 'Male', 'Female', 'n/a'
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;

-- ============================================================
-- Checking 'silver.crm_prd_info'
-- ============================================================

-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results
SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Check for unwanted spaces in string fields
-- Expectation: No Results
SELECT prd_nm FROM silver.crm_prd_info WHERE prd_nm != TRIM(prd_nm);

-- Check for NULLs or Negative Values in Cost
-- Expectation: No Results
SELECT prd_cost FROM silver.crm_prd_info WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data standardization & consistency
-- Expectation: only 'Mountain', 'Road', 'Other Sales', 'Touring', 'n/a'
SELECT DISTINCT prd_line FROM silver.crm_prd_info;

-- Check for Invalid Date Orders (Start Date > End Date)
-- Expectation: No Results
SELECT * FROM silver.crm_prd_info WHERE prd_end_dt < prd_start_dt;

-- ============================================================
-- Checking 'silver.crm_sales_details'
-- ============================================================

-- Check for Invalid Dates (order date after ship date or due date)
-- Expectation: No Results
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check that order/ship/due dates fall within a sane range
-- Expectation: No Results
SELECT sls_order_dt FROM silver.crm_sales_details
WHERE sls_order_dt < '1900-01-01' OR sls_order_dt > GETDATE();

-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results (values should be positive, non-null, and consistent)
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- ============================================================
-- Checking 'silver.erp_cust_az12'
-- ============================================================

-- Check for out-of-range birthdates (too old or in the future)
-- Expectation: No Results
SELECT DISTINCT bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE();

-- Data standardization & consistency
-- Expectation: only 'Male', 'Female', 'n/a'
SELECT DISTINCT gen FROM silver.erp_cust_az12;

-- Check that cid now matches the crm_cust_info.cst_key format
-- Expectation: No Results
SELECT cid
FROM silver.erp_cust_az12
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- ============================================================
-- Checking 'silver.erp_loc_a101'
-- ============================================================

-- Data standardization & consistency
-- Expectation: readable country names, no blanks/codes, and 'n/a' for unknowns
SELECT DISTINCT cntry FROM silver.erp_loc_a101 ORDER BY cntry;

-- Check that cid now matches the crm_cust_info.cst_key format
-- Expectation: No Results
SELECT cid
FROM silver.erp_loc_a101
WHERE cid NOT IN (SELECT cst_key FROM silver.crm_cust_info);

-- ============================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ============================================================

-- Check for unwanted spaces in string fields
-- Expectation: No Results
SELECT * FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

-- Data standardization & consistency
-- Expectation: only 'Yes', 'No'
SELECT DISTINCT maintenance FROM silver.erp_px_cat_g1v2;
