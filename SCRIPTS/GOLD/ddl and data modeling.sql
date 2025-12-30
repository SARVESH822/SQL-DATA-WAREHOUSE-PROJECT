-- ============================================================
-- Inspect Silver Layer Tables
-- Purpose:
--   Quick validation of cleaned CRM and ERP customer data
-- ============================================================
select * from silver.crm_cust_info;
select * from silver.erp_cust_az12;
-- ============================================================
-- Duplicate Customer Check
-- Purpose:
--   Ensure one-to-one mapping at customer level after joins
--   Detect duplicate records caused by ERP / CRM joins
-- ============================================================
select cst_id,count(*)  FROM
(select
ci.cst_id,
ci.cst_key,
ci.cst_firstname,
ci.cst_lastname,
ci.cst_marital_status,
ci.cst_gndr,
ci.cst_create_date,
ca.bdate,
ca.gen,
la.cntry

from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid)
group by cst_id
having count(*)>1;

-- ============================================================
-- Gender Attribute Comparison
-- Purpose:
--   Compare gender values from CRM and ERP sources
--   Identify missing or conflicting master data
-- ============================================================
select
ci.cst_gndr,
ca.gen
from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid;

-- ============================================================
-- Dimension: Customers
-- Purpose:
--   Create a conformed customer dimension
--   Resolve gender using CRM as primary source, ERP as fallback
--   Generate surrogate key for analytics
-- ============================================================
CREATE VIEW gold.dim_customers AS
select
ROW_NUMBER() OVER(ORDER BY cst_id) as customer_key,----suurogate key
ci.cst_id as customer_id,
ci.cst_key as customer_number,
ci.cst_firstname as first_name,
ci.cst_lastname as last_name,
ci.cst_marital_status as marital_status,
CASE WHEN ci.cst_gndr!= 'NOT AVAILABLE' THEN ci.cst_gndr
     ELSE COALESCE(ca.gen,'NOT AVAILABLE') 
END AS gender,
ci.cst_create_date as create_date,
ca.bdate as birthdate,
la.cntry as country 

from silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key=ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key=la.cid;

select * from gold.dim_customers;

-- ============================================================
-- Dimension: Products
-- Purpose:
--   Build product master with category enrichment
--   Include only active products (SCD Type 1 approach)
-- ============================================================
CREATE VIEW gold.dim_products AS
select
row_number() over(order by pn.prd_start_dt,pn.prd_key)  as product_key,
pn.prd_id as product_id,
pn.prd_key as product_number,
pn.prd_nm as product_name,
pn.cat_id as category_id,
pc.cat as category,
pc.subcat as subcategory,
pc.maintenance as maintenance,
pn.prd_cost as product_cost,
pn.prd_line as product_line,
pn.prd_start_dt as product_start_date
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
ON pn.cat_id=pc.id
where pn.prd_end_dt is NULL;----only the current no history taken


select * from gold.dim_products;

-- ============================================================
-- Fact Table: Sales
-- Purpose:
--   Capture transactional sales data
--   Link customers and products via surrogate keys
-- ============================================================
CREATE VIEW gold.fact_sales as
SELECT
    sd.sls_ord_num    AS order_number,
    pr.product_key   AS product_key,
    cu.customer_key  AS customer_key,
    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS shipping_date,
    sd.sls_due_dt    AS due_date,
    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
select * from  gold.fact_sales;


-- ============================================================
-- Data Quality Check
-- Purpose:
--   Identify sales records without valid customer mapping
--   Detect referential integrity issues in fact table
-- ===========================================================

SELECT * FROM
gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key=f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key=f.product_key
WHERE c.customer_key IS NULL
;
