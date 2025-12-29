CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    v_message TEXT;
    v_state   TEXT;

    batch_start_time TIMESTAMP;
    batch_end_time   TIMESTAMP;
    batch_duration   INTERVAL;
BEGIN
    -- ================= START =================
    batch_start_time := clock_timestamp();
    RAISE NOTICE '🚀 Silver load started at %', batch_start_time;

    /* ================= CRM CUSTOMER ================= */
    RAISE NOTICE '➡ Loading silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info
    (cst_id, cst_key, cst_firstname, cst_lastname, cst_gndr, cst_marital_status, cst_create_date)
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname),
        TRIM(cst_lastname),
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'NOT AVAILABLE'
        END,
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'NOT AVAILABLE'
        END,
        cst_create_date
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS rn
        FROM bronze.crm_cust_info
    ) t
    WHERE rn = 1;

    /* ================= CRM PRODUCT ================= */
    RAISE NOTICE '➡ Loading silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info
    (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'),
        SUBSTRING(prd_key, 7),
        prd_nm,
        COALESCE(prd_cost, 0),
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            ELSE 'Not Available'
        END,
        prd_start_dt::DATE,
        (LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)
         - INTERVAL '1 day')::DATE
    FROM bronze.crm_prd_info;

    /* ================= CRM SALES ================= */
    RAISE NOTICE '➡ Loading silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details
    (sls_ord_num, sls_prd_key, sls_cust_id,
     sls_order_dt, sls_ship_dt, sls_due_dt,
     sls_quantity, sls_sales, sls_price)
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        CASE
            WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
            ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
        END,
        CASE
            WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
            ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
        END,
        CASE
            WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
            ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
        END,
        sls_quantity,
        CASE
            WHEN sls_sales IS NULL
              OR sls_sales <= 0
              OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END,
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END
    FROM bronze.crm_sales_details;

    /* ================= ERP TABLES ================= */
    RAISE NOTICE '➡ Loading ERP tables';

    TRUNCATE TABLE silver.erp_cust_az12;
    INSERT INTO silver.erp_cust_az12
    SELECT
        CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4) ELSE cid END,
        CASE WHEN bdate > CURRENT_DATE THEN NULL ELSE bdate END,
        CASE
            WHEN gen IS NULL OR TRIM(gen) = '' THEN 'NOT AVAILABLE'
            WHEN UPPER(TRIM(gen)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(gen)) = 'M' THEN 'Male'
            ELSE gen
        END
    FROM bronze.erp_cust_az12;

    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101
    SELECT
        REPLACE(cid, '-', ''),
        CASE
            WHEN UPPER(TRIM(cntry)) = 'DE' THEN 'Germany'
            WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United States'
            WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'NOT AVAILABLE'
            ELSE cntry
        END
    FROM bronze.erp_loc_a101;

    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    INSERT INTO silver.erp_px_cat_g1v2
    SELECT * FROM bronze.erp_px_cat_g1v2;

    -- ================= END =================
    batch_end_time := clock_timestamp();
    batch_duration := batch_end_time - batch_start_time;

    RAISE NOTICE '✅ Silver load completed successfully';
    RAISE NOTICE '⏱ Start Time : %', batch_start_time;
    RAISE NOTICE '⏱ End Time   : %', batch_end_time;
    RAISE NOTICE '⏱ Duration   : %', batch_duration;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_message = MESSAGE_TEXT,
            v_state   = RETURNED_SQLSTATE;

        RAISE NOTICE '❌ ERROR MESSAGE : %', v_message;
        RAISE NOTICE '❌ ERROR STATE   : %', v_state;
        RAISE NOTICE '⏱ Failed At     : %', clock_timestamp();

        RAISE EXCEPTION 'SILVER LOAD FAILED';
END;
$$;

CALL bronze.load_bronze();
CALL silver.load_silver();
