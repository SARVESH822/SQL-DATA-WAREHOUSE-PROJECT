----CLEANING CST TABLES AND INSERTING INTO SILVER LAYER
----checking null and duplicated values
--------------CRM
select cst_id,count(*)
from bronze.crm_cust_info
group by cst_id
having count(*)>1 or cst_id= null


----string cleaning unwanted spaces

select cst_firstname from bronze.crm_cust_info
where cst_firstname!= TRIM(cst_firstname);


----string cleaning unwanted spaces

select cst_firstname from bronze.crm_cust_info
where cst_firstname!= TRIM(cst_firstname);
select * from bronze.crm_cust_info;

----gender and marital
select DISTINCT cst_gndr from bronze.crm_cust_info;

---- getting only the latest data (using created date)
--INSERTING INTO SILVER LAYER
TRUNCATE TABLE silver.crm_cust_info
INSERT INTO silver.crm_cust_info (cst_id,cst_key,cst_firstname,cst_lastname,cst_gndr,cst_marital_status,cst_create_date)
select 
cst_id,
cst_key,
TRIM(cst_firstname) as cst_firstname,
TRIM(cst_lastname) as cst_lastname,
CASE WHEN UPPER(TRIM(cst_gndr))='F' THEN 'Female'
     WHEN UPPER(TRIM(cst_gndr))='M' THEN 'Male'
	 ELSE 'NOT AVAILABLE'
END cst_gndr,
CASE WHEN UPPER(TRIM(cst_marital_status))='S' THEN 'Single'
     WHEN UPPER(TRIM(cst_marital_status))='M' THEN 'Married'
	 ELSE 'NOT AVAILABLE'
END cst_marital_status,
cst_create_date
from(select * 
,ROW_NUMBER()  OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_first
from bronze.crm_cust_info) where flag_first=1 ;

---VALIDATING SILVER LAYER CUST DETAILS

----checking null and duplicated values

select cst_id,count(*)
from silver.crm_cust_info
group by cst_id
having count(*)>1 or cst_id= null


----string cleaning unwanted spaces

select cst_firstname from silver.crm_cust_info
where cst_firstname!= TRIM(cst_firstname);


----string cleaning unwanted spaces

select cst_firstname from silver.crm_cust_info
where cst_firstname!= TRIM(cst_firstname);
select * from silver.crm_cust_info;

----gender and marital
select DISTINCT cst_gndr from silver.crm_cust_info;
select DISTINCT cst_marital_status from silver.crm_cust_info;


-----CLEAN AND LOAD PRD TABLES
select * from bronze.crm_prd_info;


---STRING OPERTAIONS
select prd_key from bronze.crm_prd_info
where prd_key!= TRIM(prd_key);

---CHECKING PRIMARY KEY
select prd_id,count(*)
from bronze.crm_prd_info
group by prd_id
having count(*)>1 or prd_id= null;


---NUMERIC FEATURES
select prd_cost from bronze.crm_prd_info where prd_cost< 0 or prd_cost is NULL;


---DATE
select * from bronze.crm_prd_info where prd_start_dt>prd_end_dt;

select * from bronze.crm_prd_info;
select * from silver.crm_prd_info;
----CORRECTED CODE
TRUNCATE TABLE silver.crm_prd_info
INSERT INTO silver.crm_prd_info (prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
select
prd_id,
REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
SUBSTRING(prd_key,7,LENGTH(prd_key)) as prd_key,
prd_nm,
COALESCE(prd_cost,0) as prd_cost,
CASE WHEN UPPER(TRIM(prd_line))='M' THEN 'Mountain'
     WHEN UPPER(TRIM(prd_line))='R' THEN 'Road'
	 WHEN UPPER(TRIM(prd_line))='T' THEN 'Touring'
	 WHEN UPPER(TRIM(prd_line))='S' THEN 'Other Sales'
	 ELSE 'Not Available'
END as prd_line,
CAST(prd_start_dt as DATE) as prd_start_dt,
CAST(LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt)-1 as DATE) as prd_end_dt 
from bronze.crm_prd_info;



---VALIDATING SILVER LAYER FOR PRODUCTS 

-----CLEAN AND LOAD PRD TABLES
select * from silver.crm_prd_info;


---STRING OPERTAIONS
select prd_key from silver.crm_prd_info
where prd_key!= TRIM(prd_key);

---CHECKING PRIMARY KEY
select prd_id,count(*)
from silver.crm_prd_info
group by prd_id
having count(*)>1 or prd_id= null;


---NUMERIC FEATURES
select prd_cost from silver.crm_prd_info where prd_cost< 0 or prd_cost is NULL;


---DATE
select * from silver.crm_prd_info where prd_start_dt>prd_end_dt;




---clean and load sales tables
select * from bronze.crm_sales_details;

----UNWANTED SPACES
select sls_ord_num  from bronze.crm_sales_details
where sls_ord_num!= TRIM(sls_ord_num);

---making connections 
select * from bronze.crm_sales_details
where sls_prd_key NOT IN (select prd_key from silver.crm_prd_info);

select * from bronze.crm_sales_details
where sls_cust_id NOT IN (select cst_id from silver.crm_cust_info);


----DATE(EVERY THING IN INTEGERS)
-----0 OR NEGATIVE
select sls_order_dt from bronze.crm_sales_details where sls_order_dt<=0;
select sls_ship_dt from bronze.crm_sales_details where sls_ship_dt<=0;

-----THE NO. OF DIGITS
select sls_order_dt from bronze.crm_sales_details  WHERE LENGTH(CAST(sls_order_dt AS TEXT)) != 8;


--- inavalid date orders
select * from bronze.crm_sales_details where sls_order_dt>sls_ship_dt or sls_order_dt>sls_due_dt;


----sales data consistency
select * from bronze.crm_sales_details 
where 
sls_quantity!=sls_sales/sls_price
or
sls_quantity <=0
or
sls_quantity IS NULL
or
sls_sales <=0
or
sls_sales IS NULL
or
sls_price <=0
or
sls_price IS NULL
---corrected code(EVERY THING IN INTEGERS)
TRUNCATE TABLE silver.crm_sales_details
INSERT INTO silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,
sls_order_dt,sls_ship_dt,sls_due_dt,sls_quantity,sls_sales,sls_price)
select
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE WHEN sls_order_dt!=8 or sls_order_dt=0 THEN NULL
     ELSE CAST(CAST(sls_order_dt as VARCHAR(50)) AS DATE )
END AS sls_order_dt,
CASE WHEN sls_ship_dt!=8 or sls_ship_dt=0 THEN NULL
     ELSE CAST(CAST(sls_ship_dt as VARCHAR(50)) AS DATE )
END AS sls_ship_dt,
CASE WHEN sls_due_dt!=8 or sls_due_dt=0 THEN NULL
     ELSE CAST(CAST(sls_due_dt as VARCHAR(50)) AS DATE )
END AS sls_due_dt,
sls_quantity,
CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales!=sls_quantity*ABS(sls_price)
     THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <=0 OR sls_price!=ABS(sls_sales)/(sls_quantity)
     THEN ABS(sls_sales)/(sls_quantity)
	 ELSE sls_price
END AS sls_price
from bronze.crm_sales_details



------------ERP
-----------gender
select DISTINCT gen from (select  
CASE WHEN UPPER(TRIM(gen))='' THEN 'NOT_AVAILABLE'
     WHEN UPPER(TRIM(gen))='F' THEN 'Female'
	 WHEN UPPER(TRIM(gen))='M'  THEN 'Male'
	 WHEN UPPER(TRIM(gen)) ISNULL THEN 'NOT_AVAILABLE'
	 ELSE gen
END as gen 
from bronze.erp_cust_az12);


---INSERT
TRUNCATE TABLE silver.erp_cust_az12
INSERT INTO silver.erp_cust_az12 (cid,bdate,gen)
select * from bronze.erp_cust_az12;
select 
CASE WHEN cid like 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
     ELSE cid
END as cid,
CASE WHEN bdate>NOW() THEN NULL
     ELSE bdate
END as bdate,
CASE WHEN UPPER(TRIM(gen))='' THEN 'Not_AVAILABLE'
     WHEN UPPER(TRIM(gen))='F' THEN 'Female'
	 WHEN UPPER(TRIM(gen))='M'  THEN 'Male'
	 WHEN UPPER(TRIM(gen)) ISNULL THEN 'NOT_AVAILABLE'
	 ELSE gen
END as gen
from bronze.erp_cust_az12;
select * from silver.erp_cust_az12;




----location
select * from bronze.erp_loc_a101;
TRUNCATE TABLE silver.erp_loc_a101
INSERT INTO silver.erp_loc_a101(cid,cntry)
select
REPLACE(cid,'-','') cid,
CASE WHEN UPPER(TRIM(cntry))= 'DE' THEN 'Germany'
     WHEN UPPER(TRIM(cntry)) in ('US','USA') THEN 'United States'
	 WHEN UPPER(TRIM(cntry))= '' THEN 'NOT_AVAILABLE'
	 WHEN UPPER(TRIM(cntry)) ISNULL THEN 'NOT_AVAILABLE'
	 ELSE cntry
END as cntry
from bronze.erp_loc_a101;



	
---- categories
select * from bronze.erp_px_cat_g1v2;
----- cat
select DISTINCT cat from bronze.erp_px_cat_g1v2;
----subcat
select DISTINCT subcat from bronze.erp_px_cat_g1v2;
-----maintenance
select DISTINCT maintenance  from bronze.erp_px_cat_g1v2;
TRUNCATE TABLE silver.erp_px_cat_g1v2;
INSERT INTO silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
select
id,cat,subcat,maintenance from bronze.erp_px_cat_g1v2;
