/*
===============================================================================
Quality Checks: Silver Layer
===============================================================================
Validates data integrity, domain constraints, formatting, and standardizations.
===============================================================================
*/

-- ====================================================================
-- 1. CRM Domain Checks
-- ====================================================================

-- crm_cust_info: PK Nulls/Duplicates (Expect: 0 rows)
SELECT cst_id, COUNT(*) 
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- crm_cust_info: Unwanted Spaces (Expect: 0 rows)
SELECT cst_key FROM silver.crm_cust_info WHERE cst_key != TRIM(cst_key);

-- crm_cust_info: Value Standardization
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;

-----------------------------------------------------------------------

-- crm_prd_info: PK Nulls/Duplicates (Expect: 0 rows)
SELECT prd_id, COUNT(*) 
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- crm_prd_info: Unwanted Spaces (Expect: 0 rows)
SELECT prd_nm FROM silver.crm_prd_info WHERE prd_nm != TRIM(prd_nm);

-- crm_prd_info: Invalid Cost Values (Expect: 0 rows)
SELECT prd_cost FROM silver.crm_prd_info WHERE prd_cost < 0 OR prd_cost IS NULL;

-- crm_prd_info: Value Standardization
SELECT DISTINCT prd_line FROM silver.crm_prd_info;

-- crm_prd_info: Invalid Date Ranges (Expect: 0 rows)
SELECT * FROM silver.crm_prd_info WHERE prd_end_dt < prd_start_dt;

-----------------------------------------------------------------------

-- crm_sales_details: Source Date Format/Range Integrity (Expect: 0 rows)
SELECT NULLIF(sls_due_dt, 0) AS sls_due_dt 
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
   OR LEN(sls_due_dt) != 8 
   OR sls_due_dt > 20500101 
   OR sls_due_dt < 19000101;

-- crm_sales_details: Invalid Date Sequence (Expect: 0 rows)
SELECT * FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- crm_sales_details: Sales Amount Math Consistency (Expect: 0 rows)
SELECT DISTINCT sls_sales, sls_quantity, sls_price 
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
   OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

-- ====================================================================
-- 2. ERP Domain Checks
-- ====================================================================

-- erp_cust_az12: Out-of-Range Birthdates (Expect: 0 rows)
SELECT DISTINCT bdate FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE();

-- erp_cust_az12: Value Standardization
SELECT DISTINCT gen FROM silver.erp_cust_az12;

-----------------------------------------------------------------------

-- erp_loc_a101: Value Standardization
SELECT DISTINCT cntry FROM silver.erp_loc_a101 ORDER BY cntry;

-----------------------------------------------------------------------

-- erp_px_cat_g1v2: Unwanted Spaces (Expect: 0 rows)
SELECT * FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

-- erp_px_cat_g1v2: Value Standardization
SELECT DISTINCT maintenance FROM silver.erp_px_cat_g1v2;
