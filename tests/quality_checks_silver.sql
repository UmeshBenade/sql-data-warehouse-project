/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy,
    and standardization across the 'silver' schemas. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ============================================================================
-- Checking 'silver.crm_cust_info'
-- ============================================================================

/* 
   DETAILED POINT: CUSTOMER DUPLICATE CHECK
   - Purpose: Verifies Primary Key integrity by counting how many times each cst_id appears.
   - Why it matters: If IDs duplicate, financial reports will double-count customer metrics.
   - Expectation: Exactly 0 rows returned. This proves the ROW_NUMBER() filter worked perfectly.
*/
-- Check for Duplicates
-- Expectation: No Results
SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

/* 
   DETAILED POINT: CUSTOMER CATEGORY STANDARDIZATION
   - Purpose: Reviews distinct text strings for marital status and gender.
   - Why it matters: Raw data contains messy inputs ('M', 'S', 'male'). We inspect this list 
     to confirm they successfully cleaned into uniform values ('Male', 'Female', 'Married', 'Single').
*/
-- Data Standardization & Consistency
SELECT DISTINCT
    cst_martial_status
FROM silver.crm_cust_info;

SELECT DISTINCT
    cst_gndr
FROM silver.crm_cust_info;


-- ============================================================================
-- Checking 'silver.crm_prd_info'
-- ============================================================================

/* 
   DETAILED POINT: PRODUCT TIMELINE SANITY CHECK
   - Purpose: Validates that a product introduction date happens before its historical retirement date.
   - Why it matters: Prevents timeline corruptions. A product cannot stop being sold before it is introduced.
   - Expectation: Exactly 0 rows returned.
*/
-- Check for Invalid Date Sequences
-- Expectation: No Results
SELECT
    *
FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

/* 
   DETAILED POINT: PRODUCT LINE FIELD VERIFICATION
   - Purpose: Confirms all product groups have expanded descriptive words.
   - Why it matters: Ensures your CASE WHEN statement completely replaced code letters ('M', 'R') with full strings ('Mountain', 'Road').
*/
-- Data Standardization & Consistency
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;


-- ============================================================================
-- Checking 'silver.crm_sales_details'
-- ============================================================================

/* 
   DETAILED POINT: LOGICAL ORDER PROCESSING TIMELINE
   - Purpose: Scans for any transaction where the physical shipping date happens before the order purchase date.
   - Why it matters: In a realistic pipeline, an order cannot ship before a customer actually buys it.
   - Expectation: Exactly 0 rows returned.
*/
-- Check for Invalid Date Sequences
-- Expectation: No Results
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt;

/* 
   DETAILED POINT: STRIPPED TRAILING WHITESPACE SWEEP
   - Purpose: Compares lengths of the order ID string to a fully trimmed version.
   - Why it matters: Hidden white spaces (like 'ORD123 ') cause future table joins and search lookups to fail.
   - Expectation: Exactly 0 rows returned.
*/
-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num);

/* 
   DETAILED POINT: FINANCIAL LEDGER MATHEMATICAL INTEGRITY
   - Purpose: Recomputes the underlying financial formula: [Quantity * Unit Price] and checks if it matches Total Sales.
   - Why it matters: Total sales values must be mathematically precise to ensure bookkeeping metrics are not broken.
   - Expectation: Exactly 0 rows returned. Proves your load script successfully recalculated bad data points.
*/
-- Check Business Rules Consistency
-- Expectation: No Results
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price;


-- ============================================================================
-- Checking 'silver.erp_cust_az12'
-- ============================================================================

/* 
   DETAILED POINT: IMPOSSIBLE FUTURE BIRTHDAY NEUTRALIZATION
   - Purpose: Finds any profile containing a birth date ahead of the active system timestamp (GETDATE()).
   - Why it matters: Catches bad inputs where users or systems typed data incorrectly.
   - Expectation: Exactly 0 rows returned. Proves future records successfully changed into safe NULL values.
*/
-- Check for Out-of-Range Dates
-- Expectation: No Results
SELECT
    *
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

-- Data Standardization & Consistency
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;


-- ============================================================================
-- Checking 'silver.erp_loc_a101'
-- ============================================================================

/* 
   DETAILED POINT: GEOGRAPHIC MAPPING NORMALIZATION
   - Purpose: Alphabetically reviews country entries.
   - Why it matters: Ensures corporate variations (like US, USA, DE) are merged cleanly into complete names.
     This stops chart dashboards from splitting regional sales across broken country variants.
*/
-- Data Standardization & Consistency
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- ============================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ============================================================================

/* 
   DETAILED POINT: MULTI-FIELD BLANK SPACE SWEEP
   - Purpose: Evaluates category, subcategory, and maintenance attributes simultaneously for untrimmed padding.
   - Why it matters: String text integrity is vital for group filtering. Unwanted spaces split single category blocks 
     into separate broken segments on analytics tools.
   - Expectation: Exactly 0 rows returned.
*/
-- Check for Unwanted Spaces
-- Expectation: No Results
SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);

-- Data Standardization & Consistency
SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;
