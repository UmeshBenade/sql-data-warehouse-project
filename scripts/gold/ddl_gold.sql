/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema).

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- ============================================================================
-- 1. Create Dimension Tables
-- ============================================================================

-- Create Customer Dimension View
CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lasttname AS last_name,
    la.cntry AS country,
    ci.cst_martial_status AS martial_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender info 
        ELSE COALESCE(ca.gen, 'n/a')
    END AS gender,
    ca.bdate AS birth_date,
    ci.cst_craete_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid   
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;

-- Create Product Dimension View
CREATE VIEW gold.dim_product AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, 
    pn.prd_id AS produt_id,
    pn.prd_key AS produt_number,
    pn.prd_nm AS produt_name,
    pn.cat_id AS category_id,
    pc.cat AS category, 
    pc.subcat AS subcategory,
    pc.maintainance AS maintainance,
    pn.prd_cost AS product_cost,
    pn.prd_line AS produt_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id;


-- ============================================================================
-- 2. Create Fact Tables
-- ============================================================================

-- Create Sales Fact View
CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num AS order_number,
    pr.product_key,
    cu.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS ship_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_product pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;


-- ============================================================================
-- 3. Data Quality & Integrity Checks
-- ============================================================================

/*
-- Verify views were created properly:
SELECT * FROM gold.dim_product;
SELECT * FROM gold.fact_sales;

-- Foreign Key Integrity Checks (Dimensions):
-- Check for orphan rows in Customers dimension
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
WHERE c.customer_key IS NULL;

-- Check for orphan rows in Product dimension
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_product p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL;
*/
