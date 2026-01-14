/*
===============================================================================
DDL Script: Create Bronze Tables (PostgreSQL)
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema,
    dropping existing tables if they already exist.
===============================================================================
*/

-- Ensure schema exists
CREATE SCHEMA IF NOT EXISTS bronze;

-- =========================
-- crm_cust_info
-- =========================
DROP TABLE IF EXISTS bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id              INTEGER,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE
);

-- =========================
-- crm_prd_info
-- =========================
DROP TABLE IF EXISTS bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
    prd_id       INTEGER,
    prd_key      VARCHAR(50),
    prd_nm       VARCHAR(50),
    prd_cost     INTEGER,
    prd_line     VARCHAR(50),
    prd_start_dt TIMESTAMP,
    prd_end_dt   TIMESTAMP
);

-- =========================
-- crm_sales_details
-- =========================
DROP TABLE IF EXISTS bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  VARCHAR(50),
    sls_prd_key  VARCHAR(50),
    sls_cust_id  INTEGER,
    sls_order_dt INTEGER,
    sls_ship_dt  INTEGER,
    sls_due_dt   INTEGER,
    sls_sales    INTEGER,
    sls_quantity INTEGER,
    sls_price    INTEGER
);

-- =========================
-- erp_loc_a101
-- =========================
DROP TABLE IF EXISTS bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101 (
    cid    VARCHAR(50),
    cntry  VARCHAR(50)
);

-- =========================
-- erp_cust_az12
-- =========================
DROP TABLE IF EXISTS bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12 (
    cid    VARCHAR(50),
    bdate  DATE,
    gen    VARCHAR(50)
);

-- =========================
-- erp_px_cat_g1v2
-- =========================
DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           VARCHAR(50),
    cat          VARCHAR(50),
    subcat       VARCHAR(50),
    maintenance  VARCHAR(50)
);


/*
===============================================================================
Procedure Name : bronze.load_bronze
Layer          : Bronze
Database       : PostgreSQL
Purpose        : Load raw CSV files into Bronze tables
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    v_message TEXT;
    v_state   TEXT;

    v_start_time TIMESTAMP;
    v_end_time   TIMESTAMP;

    batch_start_time TIMESTAMP;
    batch_end_time   TIMESTAMP;
BEGIN
    ---------------------------------------------------------------------------
    -- Batch start
    ---------------------------------------------------------------------------
    batch_start_time := clock_timestamp();

    RAISE NOTICE '=================================================';
    RAISE NOTICE 'STARTING BRONZE LAYER LOAD';
    RAISE NOTICE '=================================================';

    ---------------------------------------------------------------------------
    -- CRM TABLES
    ---------------------------------------------------------------------------
    RAISE NOTICE '------------------- CRM TABLES ------------------';

    -- crm_cust_info
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_cust_info;

    COPY bronze.crm_cust_info
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
    CSV HEADER DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'crm_cust_info loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- crm_prd_info
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_prd_info;

    COPY bronze.crm_prd_info
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
    CSV HEADER DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'crm_prd_info loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- crm_sales_details
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_sales_details;

    COPY bronze.crm_sales_details
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
    CSV HEADER DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'crm_sales_details loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    ---------------------------------------------------------------------------
    -- ERP TABLES
    ---------------------------------------------------------------------------
    RAISE NOTICE '------------------- ERP TABLES ------------------';

    -- erp_cust_az12
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_cust_az12;

    COPY bronze.erp_cust_az12
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
    CSV HEADER DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'erp_cust_az12 loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- erp_loc_a101
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_loc_a101;

    COPY bronze.erp_loc_a101
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
    CSV HEADER DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'erp_loc_a101 loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    -- erp_px_cat_g1v2
    v_start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    COPY bronze.erp_px_cat_g1v2
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
    CSV HEADER DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'erp_px_cat_g1v2 loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    ---------------------------------------------------------------------------
    -- Batch end
    ---------------------------------------------------------------------------
    batch_end_time := clock_timestamp();

    RAISE NOTICE '=================================================';
    RAISE NOTICE 'BRONZE LOAD COMPLETED SUCCESSFULLY';
    RAISE NOTICE 'TOTAL LOAD TIME: % seconds',
        EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '=================================================';

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_message = MESSAGE_TEXT,
            v_state   = RETURNED_SQLSTATE;

        RAISE NOTICE '❌ ERROR MESSAGE : %', v_message;
        RAISE NOTICE '❌ SQL STATE     : %', v_state;

        RAISE EXCEPTION 'BRONZE LOAD FAILED';
END;
$$;

ALTER PROCEDURE bronze.load_bronze()
OWNER TO postgres;

CALL bronze.load_bronze();



/*
===============================================================================
DDL Script: Create Silver Tables (PostgreSQL)
===============================================================================
Purpose:
    Creates tables in the 'silver' schema.
    Drops existing tables if they already exist.
===============================================================================
*/

-- Ensure schema exists
CREATE SCHEMA IF NOT EXISTS silver;

-- =====================================================
-- silver.crm_cust_info
-- =====================================================
DROP TABLE IF EXISTS silver.crm_cust_info;
CREATE TABLE silver.crm_cust_info (
    cst_id             INTEGER,
    cst_key            VARCHAR(50),
    cst_firstname      VARCHAR(50),
    cst_lastname       VARCHAR(50),
    cst_marital_status VARCHAR(50),
    cst_gndr           VARCHAR(50),
    cst_create_date    DATE,
    dwh_create_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- silver.crm_prd_info
-- =====================================================
DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id          INTEGER,
    cat_id          VARCHAR(50),
    prd_key         VARCHAR(50),
    prd_nm          VARCHAR(50),
    prd_cost        INTEGER,
    prd_line        VARCHAR(50),
    prd_start_dt    DATE,
    prd_end_dt      DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- silver.crm_sales_details
-- =====================================================
DROP TABLE IF EXISTS silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num     VARCHAR(50),
    sls_prd_key     VARCHAR(50),
    sls_cust_id     INTEGER,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INTEGER,
    sls_quantity    INTEGER,
    sls_price       INTEGER,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- silver.erp_loc_a101
-- =====================================================
DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid             VARCHAR(50),
    cntry           VARCHAR(50),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- silver.erp_cust_az12
-- =====================================================
DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid             VARCHAR(50),
    bdate           DATE,
    gen             VARCHAR(50),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- silver.erp_px_cat_g1v2
-- =====================================================
DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id              VARCHAR(50),
    cat             VARCHAR(50),
    subcat          VARCHAR(50),
    maintenance     VARCHAR(50),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Purpose:
    Transforms and loads cleansed data from Bronze into Silver schema.
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time       TIMESTAMP;
    v_end_time         TIMESTAMP;
    batch_start_time   TIMESTAMP;
    batch_end_time     TIMESTAMP;

    v_message TEXT;
    v_state   TEXT;
BEGIN
    batch_start_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '================================================';

    --------------------------------------------------------------------------
    -- CRM TABLES
    --------------------------------------------------------------------------
    RAISE NOTICE '------------------- Loading CRM Tables -------------------';

    --------------------------------------------------------------------------
    -- silver.crm_cust_info
    --------------------------------------------------------------------------
    v_start_time := clock_timestamp();
    TRUNCATE TABLE silver.crm_cust_info;

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
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END,
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END,
        cst_create_date
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY cst_id
                   ORDER BY cst_create_date DESC
               ) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE flag_last = 1;

    v_end_time := clock_timestamp();
    RAISE NOTICE 'crm_cust_info loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    --------------------------------------------------------------------------
    -- silver.crm_prd_info
    --------------------------------------------------------------------------
    v_start_time := clock_timestamp();
    TRUNCATE TABLE silver.crm_prd_info;

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
        REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_') AS cat_id,
        SUBSTRING(prd_key FROM 7) AS prd_key,
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END,
        prd_start_dt::DATE,
        (LEAD(prd_start_dt)
            OVER (PARTITION BY prd_key ORDER BY prd_start_dt)
         - INTERVAL '1 day')::DATE
    FROM bronze.crm_prd_info;

    v_end_time := clock_timestamp();
    RAISE NOTICE 'crm_prd_info loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    --------------------------------------------------------------------------
    -- silver.crm_sales_details
    --------------------------------------------------------------------------
    v_start_time := clock_timestamp();
    TRUNCATE TABLE silver.crm_sales_details;

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
            WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) <> 8 THEN NULL
            ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
        END,
        CASE
            WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) <> 8 THEN NULL
            ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
        END,
        CASE
            WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) <> 8 THEN NULL
            ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
        END,
        CASE
            WHEN sls_sales IS NULL
              OR sls_sales <= 0
              OR sls_sales <> sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END,
        sls_quantity,
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END
    FROM bronze.crm_sales_details;

    v_end_time := clock_timestamp();
    RAISE NOTICE 'crm_sales_details loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    --------------------------------------------------------------------------
    -- ERP TABLES
    --------------------------------------------------------------------------
    RAISE NOTICE '------------------- Loading ERP Tables -------------------';

    --------------------------------------------------------------------------
    -- silver.erp_cust_az12
    --------------------------------------------------------------------------
    v_start_time := clock_timestamp();
    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4)
            ELSE cid
        END,
        CASE
            WHEN bdate > CURRENT_DATE THEN NULL
            ELSE bdate
        END,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
            ELSE 'n/a'
        END
    FROM bronze.erp_cust_az12;

    v_end_time := clock_timestamp();
    RAISE NOTICE 'erp_cust_az12 loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    --------------------------------------------------------------------------
    -- silver.erp_loc_a101
    --------------------------------------------------------------------------
    v_start_time := clock_timestamp();
    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', ''),
        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
            ELSE TRIM(cntry)
        END
    FROM bronze.erp_loc_a101;

    v_end_time := clock_timestamp();
    RAISE NOTICE 'erp_loc_a101 loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    --------------------------------------------------------------------------
    -- silver.erp_px_cat_g1v2
    --------------------------------------------------------------------------
    v_start_time := clock_timestamp();
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

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

    v_end_time := clock_timestamp();
    RAISE NOTICE 'erp_px_cat_g1v2 loaded in % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    --------------------------------------------------------------------------
    -- Batch end
    --------------------------------------------------------------------------
    batch_end_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Silver Load Completed Successfully';
    RAISE NOTICE 'Total Load Time: % seconds',
        EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '================================================';

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_message = MESSAGE_TEXT,
            v_state   = RETURNED_SQLSTATE;

        RAISE NOTICE '❌ ERROR MESSAGE : %', v_message;
        RAISE NOTICE '❌ SQL STATE     : %', v_state;

        RAISE EXCEPTION 'Silver Load Failed';
END;
$$;
call silver.load_silver();




/*
===============================================================================
DDL Script: Create Gold Views (PostgreSQL)
===============================================================================
Purpose:
    Creates Gold layer dimension and fact views using Silver layer data.
===============================================================================
*/

-- Ensure schema exists
CREATE SCHEMA IF NOT EXISTS gold;

-- ============================================================================
-- Dimension: gold.dim_customers
-- ============================================================================
DROP VIEW IF EXISTS gold.dim_customers;

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- Surrogate key
    ci.cst_id                             AS customer_id,
    ci.cst_key                            AS customer_number,
    ci.cst_firstname                      AS first_name,
    ci.cst_lastname                       AS last_name,
    la.cntry                              AS country,
    ci.cst_marital_status                 AS marital_status,
    CASE
        WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr      -- CRM is primary
        ELSE COALESCE(ca.gen, 'n/a')                    -- ERP fallback
    END                                   AS gender,
    ca.bdate                              AS birthdate,
    ci.cst_create_date                    AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;

-- ============================================================================
-- Dimension: gold.dim_products
-- ============================================================================
DROP VIEW IF EXISTS gold.dim_products;

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY pn.prd_start_dt, pn.prd_key
    ) AS product_key, -- Surrogate key
    pn.prd_id          AS product_id,
    pn.prd_key         AS product_number,
    pn.prd_nm          AS product_name,
    pn.cat_id          AS category_id,
    pc.cat             AS category,
    pc.subcat          AS subcategory,
    pc.maintenance     AS maintenance,
    pn.prd_cost        AS cost,
    pn.prd_line        AS product_line,
    pn.prd_start_dt    AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Only current (active) products

-- ============================================================================
-- Fact: gold.fact_sales
-- ============================================================================
DROP VIEW IF EXISTS gold.fact_sales;

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num     AS order_number,
    pr.product_key     AS product_key,
    cu.customer_key    AS customer_key,
    sd.sls_order_dt    AS order_date,
    sd.sls_ship_dt     AS shipping_date,
    sd.sls_due_dt      AS due_date,
    sd.sls_sales       AS sales_amount,
    sd.sls_quantity    AS quantity,
    sd.sls_price       AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
select distinct category from gold.dim_products
