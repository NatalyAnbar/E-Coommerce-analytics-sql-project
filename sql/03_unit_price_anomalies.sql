/*
Unit Price Behavior & Anomaly Analysis
--------------------------------------
This analysis examines unit price consistency across products, dates, locations,
quantities, and coupon usage.

Objectives:
- Detect unit price inconsistencies for identical SKUs
- Evaluate quantity-based and location-based pricing behavior
- Identify potential data quality issues or undocumented pricing rules

This analysis intentionally avoids assumptions about pricing logic
and focuses on observed transactional behavior.
*/



-------------------------------
-- Unit Price Distribution Summary
-------------------------------
SELECT 
    MIN(Unit_price) AS min_unit_price,
    MAX(Unit_Price) AS max_unit_price,
    ROUND(AVG(Unit_Price), 1) AS avg_unit_price,
    ROUND(STDDEV(Unit_Price)) AS std_unit_price
FROM online_sales;
-- Notes:
-- There is significant dispersion in unit prices. 
-- The lowest price is $0.39, and the highest is $355.74. 
-- The distribution shows a positive skew, indicating the presence of 
-- high-value products that raise the overall average



-------------------------------
-- SKU Pricing by Date and Location
-------------------------------
SELECT 
    DISTINCT transaction_date,
    Location,
    Product_SKU,
    Unit_Price,
    Coupon_Status,
    Quantity
FROM online_sales
    INNER JOIN customersdata USING(CustomerID)
WHERE Product_SKU = 'GGOEYOLR018699'
ORDER BY transaction_date;
-- Insight:
-- Unit price sometimes decreases as quantity increases, even when date and location remain constant.
-- In other cases, price changes with location despite identical quantity and date
-- Larger quantities within the same city and date can result in lower unit prices
-- These patterns suggest pricing policies vary by country and may include automatic quantity-based discounts
-- Recommendation:
-- Review and document pricing policies for each product to ensure clarity.
-- Clear pricing logic is essential for building reliable commercial analysis and understanding regional or quantity-based pricing behaviors



-------------------------------
-- Nest Preorder Pricing Anomaly
-------------------------------
SELECT *
FROM online_sales
WHERE Product_Category = 'Nest'
    AND Product_Description = 'Nest Cam IQ Outdoor - USA (Preorder)'
    AND MONTH(transaction_date) = 10;
-- Insight:
-- A unit was priced at $349, despite being a single item. Other transactions with the same quantity 
-- and date show the standard price, indicating that neither quantity nor date explains the discrepancy
-- The issue likely stems from a data entry error, even though the SKU is identical



-------------------------------
-- YouTube Tee SKU Pricing by Date and Location
-------------------------------
SELECT DISTINCT transaction_date,
    Location,
    Product_SKU,
    Unit_Price,
    Coupon_Status,
    Quantity
FROM online_sales
    INNER JOIN customersdata USING(CustomerID)
WHERE Product_Description = 'YouTube Youth Short Sleeve Tee Red'
    AND Product_SKU = 'GGOEYAYR068624'
ORDER BY transaction_date;
-- Insight:
-- There are noticeable differences in unit price despite having the same SKU
-- Even within the same country, prices vary across transactions. 
-- This indicates that price changes are not driven by location, and may reflect inconsistencies or untracked pricing logic



-------------------------------
-- SKU Unit Price Variants by Date and Location
-------------------------------
SELECT transaction_date,
    location,
    COUNT(DISTINCT Unit_Price) AS price_variants
FROM online_sales
    INNER JOIN customersdata USING(CustomerID)
WHERE Product_SKU = 'GGOEYAYR068624'
GROUP BY transaction_date,
    location;
-- Insight:
-- Unit price discrepancies were observed for a specific SKU, despite identical values for location,
-- date, quantity, and coupon status. 
-- In some cases, the unit price was higher when a coupon was applied,
-- which contradicts standard commercial logic
-- Recommendation:
-- Coupon status should not be treated as a direct influencer of unit price
-- It must be analyzed within the context of the total invoice value, not the unit price alone
-- These inconsistencies may reflect pricing logic errors or data entry issues, and should be reviewed for accuracy



-------------------------------
-- Quantity vs. Unit Price Summary
-------------------------------
SELECT Product_SKU,
    Quantity,
    ROUND(AVG(Unit_Price), 2)
FROM online_sales
GROUP BY Product_SKU,
    Quantity
ORDER BY Product_SKU;
-- Insight:
-- There is no strong positive or negative correlation between unit price and quantity
-- Recommendation:
-- Classify products based on their pricing behavior—fixed pricing, quantity-based variation, 
-- and location-based variation—to enable clearer commercial analysis and support future segmentation strategies



