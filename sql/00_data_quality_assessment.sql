/*
File Purpose:
This script performs initial data quality assessment across all core tables.
The objective is to evaluate data completeness, detect duplication risks,
and identify potential integrity issues before any cleaning or analysis is applied.

Scope:
- Missing value assessment
- Duplicate detection
- Early data integrity validation

Note:
This file is intentionally exploratory and non-destructive.
No transformations are applied at this stage.
*/


USE customer_analytics_suite;

/* ---------------------------- Customer Table ----------------------------------*/
/* missing values */
SELECT
count(*) - count(customerID) AS missing_ID,
count(*) - count(Gender) AS missing_gender,
count(*) - count(Location) AS missing_location,
count(*) - count(Tenure_Months) AS missing_tenure_months
FROM customersdata;

/* duplicates values */
SELECT COUNT(*) AS duplicates_id FROM customersdata
GROUP BY CustomerID HAVING duplicates_id > 1;


/* ---------------------------- Discount Table ----------------------------------*/
/* missing values */
SELECT 
COUNT(*) - COUNT(Month) AS missing_month,
COUNT(*) - COUNT(Product_Category) AS missing_category,
COUNT(*) - COUNT(Coupon_Code) AS missing_coupon_code,
COUNT(*) - COUNT(Discount_pct) AS missing_pct
FROM discount_coupon;


/* ---------------------------- Spend Table ----------------------------------*/
/* missing values */
SELECT 
COUNT(*) - COUNT(Date) AS missing_date,
COUNT(*) - COUNT(Offline_Spend) AS missing_offline_spend,
COUNT(*) - COUNT(Online_Spend) AS missing_online_spend
FROM marketing_spend;


/* ---------------------------- Sales Table ----------------------------------*/
/* missing values */
SELECT 
COUNT(*) - COUNT(CustomerID) AS missing_customer_id,
COUNT(*) - COUNT(Transaction_ID) AS missing_transaction_id,
COUNT(*) - COUNT(Transaction_Date) AS missing_transaction_date,
COUNT(*) - COUNT(Product_SKU) AS missing_SKU,
COUNT(*) - COUNT(Product_Description) AS missing_description,
COUNT(*) - COUNT(Product_Category) AS missing_product_category,
COUNT(*) - COUNT(Quantity) AS missing_quantity,
COUNT(*) - COUNT(unit_Price) AS missing_price,
COUNT(*) - COUNT(Delivery_Charges) AS missing_delivery_charges,
COUNT(*) - COUNT(Coupon_Status) AS missing_coupon_status
FROM online_sales;


/* ------------------------------------- Tax Table --------------------------------- */
/* Missing Values */
SELECT 
COUNT(*) - COUNT(Product_Category) AS missing_product_category,
COUNT(*) - COUNT(GST) AS missing_GST
FROM tax_amount;



