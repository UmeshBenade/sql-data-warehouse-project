/*
================================================================================
DDL Script: Create Silver Tables
--------------------------------------------------------------------------------
Script Purpose:
   This script creates tables in the 'silver' schema, dropping existing tables
   if they already exist.
   Run this script to re-define the DDL structure of 'bronze' Tables
================================================================================
*/
/*
================================================================================
                                METADATA COLUMNS
================================================================================
Extra columns added by data engineers that do not originate from the source data.

create_date   : The record's load timestamp.
update_date   : The record's last update timestamp.
source_system : The origin system of the record.
file_location : The file source of the record.
================================================================================
*/


IF Object_ID ('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
create table silver.crm_cust_info(
    cst_id					INT,
    cst_key					NVARCHAR(50),
    cst_firstname			NVARCHAR(50), 
    cst_lasttname			NVARCHAR(50),
    cst_martial_status		NVARCHAR(50),
    cst_gndr				NVARCHAR(50),
    cst_craete_date			DATE,
    dwh_create_date			DATETIME2 DEFAULT GETDATE()
);

IF Object_ID ('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;

GO

create table silver.crm_prd_info(
    prd_id			INT,
    cat_id			NVARCHAR(50),
    prd_key			NVARCHAR(50),
    prd_nm			NVARCHAR(50), 
    prd_cost		INT,
    prd_line		NVARCHAR(50),
    prd_start_dt	DATETIME,
    prd_end_dt		DATETIME,
    dwh_create_date	DATETIME2 DEFAULT GETDATE()
);

IF Object_ID ('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;

GO

create table silver.crm_sales_details(
    sls_ord_num			NVARCHAR(50),
    sls_prd_key			NVARCHAR(50),
    sls_cust_id			INT, 
    sls_order_dt		DATE,
    sls_ship_dt			DATE,
    sls_due_dt			DATE,
    sls_sales			INT,
    sls_quantity		INT,
    sls_price			INT,
    dwh_create_date		DATETIME2 DEFAULT GETDATE()
);
GO

IF Object_ID ('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;

GO

create table silver.erp_cust_az12(
    cid					NVARCHAR(50),
    bdate				DATE,
    gen					NVARCHAR(50),
    dwh_create_date		DATETIME2 DEFAULT GETDATE()
);
GO

IF Object_ID ('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;

GO

create table silver.erp_loc_a101(
    cid					NVARCHAR(50),
    cntry				NVARCHAR(50),
    dwh_create_date		DATETIME2 DEFAULT GETDATE()
);
GO

IF Object_ID ('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;

GO

create table silver.erp_px_cat_g1v2(
    id					NVARCHAR(50),
    cat					NVARCHAR(50),
    subcat				NVARCHAR(50),
    maintainance		NVARCHAR(50),
    dwh_create_date		DATETIME2 DEFAULT GETDATE()
);
GO
