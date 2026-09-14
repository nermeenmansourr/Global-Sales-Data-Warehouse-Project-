/*
===============================================================================
Quality Checks: Gold Layer
===============================================================================
Validates key uniqueness and referential integrity across dimensions & facts.
===============================================================================
*/

-- Check Customer Key Uniqueness (Expect: 0 rows)
SELECT customer_key, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check Product Key Uniqueness (Expect: 0 rows)
SELECT product_key, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Check Referential Integrity / Orphan Keys (Expect: 0 rows)
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p  ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL;
