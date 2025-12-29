----CLEANING CST TABLES AND INSERTING INTO SILVER LAYER
----checking null and duplicated values

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

