
/*
===============================================================================
Stored Procedure: Load Silver Layer (ETL)
===============================================================================
Script Purpose:
    Executes the ETL process to populate the Silver layer from the Bronze layer.
    Performs data cleaning, standardization, handling missing values, 
    and deduplication across CRM and ERP source tables.

Parameters:
    None.

Usage:
    EXEC silver.load_silver;
===============================================================================
*/

USE datawarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver 
AS 
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @starttime DATETIME, 
            @endtime DATETIME, 
            @batch_start_time DATETIME, 
            @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        PRINT '==================================================';
        PRINT 'Loading Silver Layer';
        PRINT '==================================================';

        -- --------------------------------------------------------------------
        -- Loading: silver.crm_cust_info
        -- --------------------------------------------------------------------
        SET @starttime = GETDATE();
        PRINT '>> Truncating table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        
        PRINT '>> Inserting data into: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            TRIM(cst_key),
            TRIM(cst_firstname),
            TRIM(cst_lastname),
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'N/A'
            END AS cst_marital_status,
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'N/A'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (
                       PARTITION BY cst_id
                       ORDER BY cst_create_date DESC
                   ) AS rn
            FROM bronze.crm_cust_info
        ) t
        WHERE rn = 1 AND cst_id IS NOT NULL;
        
        SET @endtime = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS VARCHAR) + ' seconds';
        PRINT '--------------------------------------------------';

        -- --------------------------------------------------------------------
        -- Loading: silver.crm_prd_info
        -- --------------------------------------------------------------------
        SET @starttime = GETDATE();
        PRINT '>> Truncating table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        
        PRINT '>> Inserting data into: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT 
            prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'T' THEN 'Touring'
                WHEN 'S' THEN 'Other sales'
                ELSE 'N/A'
            END AS prd_line,
            prd_start_dt,
            DATEADD(DAY, -1, LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
        FROM bronze.crm_prd_info;
        
        SET @endtime = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS VARCHAR) + ' seconds';
        PRINT '--------------------------------------------------';

        -- --------------------------------------------------------------------
        -- Loading: silver.crm_sales_details
        -- --------------------------------------------------------------------
        SET @starttime = GETDATE();
        PRINT '>> Truncating table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        
        PRINT '>> Inserting data into: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT 
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE 
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CASE 
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
            CASE 
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
            CASE 
                WHEN sls_sales != ABS(sls_price) * sls_quantity OR sls_sales IS NULL OR sls_sales <= 0  
                THEN ABS(sls_price) * sls_quantity
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            CASE 
                WHEN sls_price IS NULL OR sls_price <= 0  
                THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price 
        FROM bronze.crm_sales_details;
        
        SET @endtime = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS VARCHAR) + ' seconds';
        PRINT '--------------------------------------------------';

        -- --------------------------------------------------------------------
        -- Loading: silver.erp_cust_az12
        -- --------------------------------------------------------------------
        SET @starttime = GETDATE();
        PRINT '>> Truncating table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        
        PRINT '>> Inserting data into: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid, 
            CASE
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,
            CASE
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'N/A'
            END AS gen
        FROM bronze.erp_cust_az12;
        
        SET @endtime = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS VARCHAR) + ' seconds';
        PRINT '--------------------------------------------------';

        -- --------------------------------------------------------------------
        -- Loading: silver.erp_loc_a101
        -- --------------------------------------------------------------------
        SET @starttime = GETDATE();
        PRINT '>> Truncating table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        
        PRINT '>> Inserting data into: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT 
            REPLACE(cid, '-', '') AS cid,
            CASE 
                WHEN LOWER(cntry) IN ('united states', 'us', 'usa') THEN 'USA' 
                WHEN UPPER(cntry) = 'DE' THEN 'Germany' 
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'N/A' 
                ELSE TRIM(cntry) 
            END AS cntry 
        FROM bronze.erp_loc_a101;
        
        SET @endtime = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS VARCHAR) + ' seconds';
        PRINT '--------------------------------------------------';

        -- --------------------------------------------------------------------
        -- Loading: silver.erp_px_cat_g1v2
        -- --------------------------------------------------------------------
        SET @starttime = GETDATE();
        PRINT '>> Truncating table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        
        PRINT '>> Inserting data into: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT 
            id,
            cat,
            subcat,
            maintenance 
        FROM bronze.erp_px_cat_g1v2;
        
        SET @endtime = GETDATE();
        PRINT '>> Load duration: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS VARCHAR) + ' seconds';
        PRINT '--------------------------------------------------';

        -- Summary
        SET @batch_end_time = GETDATE();
        PRINT '==================================================';
        PRINT 'Silver Layer Loaded Successfully!';
        PRINT 'Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '==================================================';

    END TRY
    BEGIN CATCH
        PRINT '==================================================';
        PRINT 'ERROR OCCURRED DURING LOADING!';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number : ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State  : ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==================================================';
    END CATCH
END;
GO
