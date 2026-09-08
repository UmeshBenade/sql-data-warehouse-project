/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
   This stored procedure performs the ETL (Extract, Transform, Load) process to
   populate the 'silver' schema tables from the 'bronze' schema.
   Actions Performed:
     - Truncates Silver tables.
     - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
   None.
   This stored procedure does not accept any parameters or return any values.

Usage Example:
   EXEC silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    -- Tells SQL Server to print row count messages like "(X rows affected)"
    SET NOCOUNT OFF;

    -- Declare time tracking variables
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        -- Start the entire batch timer
        SET @batch_start_time = GETDATE();

        PRINT '==================================================';
        PRINT 'Loading Silver Layer';
        PRINT '==================================================';

        PRINT '--------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '--------------------------------------------------';

        BEGIN TRANSACTION;

        -- ====================================================================
        -- 1. LOAD: silver.crm_cust_info
        -- ====================================================================
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Inserting Data into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id, cst_key, cst_firstname, cst_lasttname, 
            cst_martial_status, cst_gndr, cst_craete_date
        )
        SELECT 
            cst_id, cst_key, TRIM(cst_firstname) AS cst_firstname, TRIM(cst_lasttname) AS cst_lastname,
            CASE WHEN UPPER(TRIM(cst_martial_status)) = 'S' THEN 'Single' WHEN UPPER(TRIM(cst_martial_status)) = 'M' THEN 'Married' ELSE 'N/A' END AS cst_martial_status,
            CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' ELSE 'N/A' END AS cst_gndr, 
            cst_craete_date
        FROM (
            SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_craete_date DESC) AS flag_last
            FROM bronze.crm_cust_info WHERE cst_id IS NOT NULL
        ) t WHERE flag_last = 1;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -----------------------';

        -- ====================================================================
        -- 2. LOAD: silver.crm_prd_info
        -- ====================================================================
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Inserting Data into: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
        )
        SELECT 
            prd_id, REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, prd_nm, ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line)) WHEN 'M' THEN 'Mountain' WHEN 'R' THEN 'Road' WHEN 'S' THEN 'Other' WHEN 'T' THEN 'Touring' ELSE 'N/A' END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt, CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -----------------------';

        -- ====================================================================
        -- 3. LOAD: silver.crm_sales_details
        -- ====================================================================
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.crm_sales_details ';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Inserting Data into: silver.crm_sales_details ';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price
        )
        SELECT 
            sls_ord_num, sls_prd_key, sls_cust_id,
            CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) END AS sls_order_dt,
            CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE) END AS sls_ship_dt,
            CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,
            CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price) ELSE sls_sales END AS sls_sales,
            sls_quantity,
            CASE WHEN prs.sls_price IS NULL OR prs.sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0) ELSE prs.sls_price END AS sls_price
        FROM bronze.crm_sales_details AS prs;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -----------------------';

        PRINT '--------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '--------------------------------------------------';

        -- ====================================================================
        -- 4. LOAD: silver.erp_cust_az12
        -- ====================================================================
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Inserting Data into: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
        SELECT
            CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) ELSE cid END AS cid,
            CASE WHEN bdate > GETDATE() THEN NULL ELSE bdate END AS bdate, 
            CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male' ELSE 'n/a' END AS gen  
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -----------------------';

        -- ====================================================================
        -- 5. LOAD: silver.erp_loc_a101
        -- ====================================================================
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Inserting Data into: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (cid, cntry)
        SELECT 
            REPLACE(cid, '-', '') AS cid, 
            CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany' WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States' WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a' ELSE TRIM(cntry) END AS cntry
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -----------------------';

        -- ====================================================================
        -- 6. LOAD: silver.erp_px_cat_g1v2
        -- ====================================================================
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Inserting Data into: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintainance)
        SELECT id, cat, subcat, maintainance FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -----------------------';

        COMMIT TRANSACTION;

        -- End the total batch timer
        SET @batch_end_time = GETDATE();
        PRINT '==================================================';
        PRINT 'Loading Silver Layer is Completed';
        PRINT '   Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '==================================================';

    END TRY
    BEGIN CATCH
        -- Roll back if an error occurs
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        PRINT '==================================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==================================================';
    END CATCH
END;
