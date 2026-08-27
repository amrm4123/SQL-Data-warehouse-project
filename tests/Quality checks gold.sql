/*
=============================================================
Quality Checks: Gold Layer
=============================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency,
    and accuracy of the Gold layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension views.
    - Validation of the relationships in the data model for analytical purposes.

Usage Notes:
    - Run this script AFTER executing silver.load_silver (Gold objects are
      views computed on the fly, so no separate Gold load is required).
    - Every query below should return NO ROWS if the data model is clean.
    - Any row returned by a check flags an issue to investigate, either in
      the Silver transformation logic or in the Gold view definitions
      (DDL_gold.sql).
=============================================================
*/

USE Datawarehouse;
GO

-- ============================================================
-- Checking 'gold.dim_customers'
-- ============================================================

-- Check the uniqueness of Customer Key (surrogate key)
-- Expectation: No Results
SELECT
    customer_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check for NULLs in the surrogate key
-- Expectation: No Results
SELECT * FROM gold.dim_customers WHERE customer_key IS NULL;

-- Data standardization & consistency
-- Expectation: only 'Male', 'Female', 'n/a'
SELECT DISTINCT gender FROM gold.dim_customers;

-- ============================================================
-- Checking 'gold.dim_products'
-- ============================================================

-- Check the uniqueness of Product Key (surrogate key)
-- Expectation: No Results
SELECT
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Check for NULLs in the surrogate key
-- Expectation: No Results
SELECT * FROM gold.dim_products WHERE product_key IS NULL;

-- Check for negative or NULL cost
-- Expectation: No Results
SELECT * FROM gold.dim_products WHERE cost < 0 OR cost IS NULL;

-- ============================================================
-- Checking 'gold.fact_sales'
-- ============================================================

-- Check the data model connectivity between fact and dimensions
-- (referential integrity: every FK in the fact must resolve to a dimension row)
-- Expectation: No Results
SELECT f.*
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE c.customer_key IS NULL OR p.product_key IS NULL;

-- Check for NULLs or negative values in measures
-- Expectation: No Results
SELECT *
FROM gold.fact_sales
WHERE sales_amount IS NULL OR sales_amount <= 0
   OR quantity IS NULL OR quantity <= 0
   OR price IS NULL OR price <= 0;

-- Check Data Consistency: Sales = Quantity * Price
-- Expectation: No Results
SELECT *
FROM gold.fact_sales
WHERE sales_amount != quantity * price;

-- Check for invalid date order (order date after shipping/due date)
-- Expectation: No Results
SELECT *
FROM gold.fact_sales
WHERE order_date > shipping_date OR order_date > due_date;

-- Check for duplicate order lines (same order + product should not repeat)
-- Expectation: No Results
SELECT
    order_number,
    product_key,
    COUNT(*) AS duplicate_count
FROM gold.fact_sales
GROUP BY order_number, product_key
HAVING COUNT(*) > 1;
