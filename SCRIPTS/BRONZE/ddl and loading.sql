
/*
===============================================================================
DDL Script: Create Bronze Tables (PostgreSQL)
===============================================================================
Purpose:
    Drops and recreates all tables in the bronze schema.
    Safe to re-run (idempotent).
===============================================================================
*/

-- ===============================
-- CRM CUSTOMER
-- ===============================
DROP TABLE IF EXISTS bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_marital_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE
);

-- ===============================
-- CRM PRODUCT
-- ===============================
DROP TABLE IF EXISTS bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
    prd_id          INT,
    prd_key         VARCHAR(50),
    prd_nm          VARCHAR(50),
    prd_cost        INT,
    prd_line        VARCHAR(50),
    prd_start_dt    DATE,
    prd_end_dt      DATE
);

-- ===============================
-- CRM SALES
-- ===============================
DROP TABLE IF EXISTS bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num     VARCHAR(50),
    sls_prd_key     VARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    INT,
    sls_ship_dt     INT,
    sls_due_dt      INT,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT
);

-- ===============================
-- ERP LOCATION
-- ===============================
DROP TABLE IF EXISTS bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101 (
    cid     VARCHAR(50),
    cntry   VARCHAR(50)
);

-- ===============================
-- ERP CUSTOMER
-- ===============================
DROP TABLE IF EXISTS bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12 (
    cid     VARCHAR(50),
    bdate   DATE,
    gen     VARCHAR(50)
);

-- ===============================
-- ERP PRODUCT CATEGORY
-- ===============================
DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           VARCHAR(50),
    cat          VARCHAR(50),
    subcat       VARCHAR(50),
    maintenance  VARCHAR(50)
);

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $BODY$
DECLARE
    v_message TEXT;
    v_state   TEXT;
    v_start_time TIMESTAMP;
    v_end_time   TIMESTAMP;
    batch_start_time  TIMESTAMP;
    batch_end_time    TIMESTAMP;
BEGIN
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'LOADING THE BRONZE LAYER';
    RAISE NOTICE '==========================================';

    batch_start_time := clock_timestamp();

    RAISE NOTICE '-------------------------------------------';
    RAISE NOTICE 'LOADING THE CRM TABLES';
    RAISE NOTICE '--------------------------------------------';

    v_start_time := clock_timestamp();
    RAISE NOTICE '>>>>>>>>>TRUNCATING TABLE: bronze.crm_cust_info';
    TRUNCATE TABLE bronze.crm_cust_info;

    RAISE NOTICE '>>>>>>>>>INSERT DATA INTO: bronze.crm_cust_info';
    COPY bronze.crm_cust_info
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
    CSV HEADER
    DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'Time taken to load bronze.crm_cust_info  = % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    v_start_time := clock_timestamp();
    RAISE NOTICE '>>>>>>>>>TRUNCATING TABLE: bronze.crm_prd_info';
    TRUNCATE TABLE bronze.crm_prd_info;

    RAISE NOTICE '>>>>>>>>>INSERT DATA INTO: bronze.crm_prd_info';
    COPY bronze.crm_prd_info
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
    CSV HEADER
    DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'Time taken to load bronze.crm_prd_info  = % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    v_start_time := clock_timestamp();
    RAISE NOTICE '>>>>>>>>>TRUNCATING TABLE: bronze.crm_sales_details';
    TRUNCATE TABLE bronze.crm_sales_details;

    RAISE NOTICE '>>>>>>>>>INSERT DATA INTO: bronze.crm_sales_details';
    COPY bronze.crm_sales_details
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
    CSV HEADER
    DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'Time taken to load bronze.crm_sales_details  = % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    RAISE NOTICE '-------------------------------------------';
    RAISE NOTICE 'LOADING THE ERP TABLES';
    RAISE NOTICE '--------------------------------------------';

    v_start_time := clock_timestamp();
    RAISE NOTICE '>>>>>>>>>TRUNCATING TABLE: bronze.erp_cust_az12';
    TRUNCATE TABLE bronze.erp_cust_az12;

    RAISE NOTICE '>>>>>>>>>INSERT DATA INTO: bronze.erp_cust_az12';
    COPY bronze.erp_cust_az12
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
    CSV HEADER
    DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'Time taken to load bronze.erp_cust_az12  = % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    v_start_time := clock_timestamp();
    RAISE NOTICE '>>>>>>>>>TRUNCATING TABLE: bronze.erp_loc_a101';
    TRUNCATE TABLE bronze.erp_loc_a101;

    RAISE NOTICE '>>>>>>>>>INSERT DATA INTO: bronze.erp_loc_a101';
    COPY bronze.erp_loc_a101
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
    CSV HEADER
    DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'Time taken to load bronze.erp_loc_a101  = % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    v_start_time := clock_timestamp();
    RAISE NOTICE '>>>>>>>>>TRUNCATING TABLE: bronze.erp_px_cat_g1v2';
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    RAISE NOTICE '>>>>>>>>>INSERT DATA INTO: bronze.erp_px_cat_g1v2';
    COPY bronze.erp_px_cat_g1v2
    FROM 'D:/sql/f78e076e5b83435d84c6b6af75d8a679/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
    CSV HEADER
    DELIMITER ',';

    v_end_time := clock_timestamp();
    RAISE NOTICE 'Time taken to load bronze.erp_px_cat_g1v2  = % seconds',
        EXTRACT(EPOCH FROM (v_end_time - v_start_time));

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'BRONZE LOAD COMPLETED SUCCESSFULLY';
    RAISE NOTICE '==========================================';

    batch_end_time := clock_timestamp();
    RAISE NOTICE '   - Total Load Duration: % seconds',
    EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_message = MESSAGE_TEXT,
            v_state   = RETURNED_SQLSTATE;

        RAISE NOTICE '❌ ERROR MESSAGE : %', v_message;
        RAISE NOTICE '❌ ERROR STATE   : %', v_state;

        RAISE EXCEPTION 'BRONZE LOAD FAILED';
END;
$BODY$;

ALTER PROCEDURE bronze.load_bronze()
OWNER TO postgres;

/*-- calling the commands
*/
CALL bronze.load_bronze();
