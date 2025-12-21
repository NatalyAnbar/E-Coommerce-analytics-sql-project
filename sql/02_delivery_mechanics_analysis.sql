/*
Delivery & Pricing Mechanics Analysis
-------------------------------------
This analysis focuses on invoice-level delivery behavior rather than customer-level segmentation.

Objectives:
- Validate delivery cost logic at the invoice level
- Identify extreme but commercially valid delivery scenarios
- Detect delivery-to-price imbalances that may affect demand

All calculations are intentionally performed at the transaction (invoice) level
to reflect real commercial behavior and avoid misleading row-level aggregation.
*/



-------------------------------
-- Delivery Cost Distribution Analysis
-------------------------------
SELECT ROUND(AVG(Delivery_each_transction), 2) AS avg_delivery,
    MIN(Delivery_each_transction) AS min_delivery,
    ROUND(MAX(Delivery_each_transction),1) AS max_delivery,
    ROUND(STDDEV(Delivery_each_transction),1) AS std_delivery
FROM(
        SELECT Transaction_ID,
            MAX(Delivery_Charges) AS Delivery_each_transction
        FROM online_sales
        GROUP BY Transaction_ID
    ) AS delivery_per_transaction;
-- Insight:
-- Delivery charges were calculated per invoice, not per row, since delivery applies to the entire transaction.
-- The standard deviation exceeds half the average, indicating a high level of dispersion in delivery costs.
-- This variability reflects a mix of small and bulk orders, with some invoices showing unusually high delivery charges.
-- Interpretation
-- The presence of high delivery values is commercially valid, especially in invoices with large quantities 
-- of low-priced items. These outliers should be retained in the dataset, as they represent real operational 
-- scenarios rather than data errors.



-------------------------------
-- High Delivery Charge Transactions
-------------------------------
SELECT *
FROM online_sales
WHERE Delivery_Charges >= 500;
-- Insight:
-- Only 2 invoices had delivery charges above $500
-- Product prices ranged between $2.5 and $9.5
-- Quantities were 185 and 600 units respectively
-- 3 additional invoices had delivery charges between $400 and $500
-- Product prices were standard, with one item priced at $60
-- Quantities averaged around 80 units per invoice
-- These high delivery charges are justified by the large quantities involved,
-- even when product prices are low. They are not anomalies—they reflect real logistical costs tied to bulk orders
-- Interpretation
-- High delivery values should not be excluded from analysis
-- They represent valid commercial behavior and are part of the dataset’s operational reality



-------------------------------
-- Delivery-to-Base Price Ratio Analysis
-------------------------------
SELECT MAX(percentage) AS max_delivery_pct,
    MIN(percentage) AS min_delivery_pct
FROM (
        SELECT Transaction_ID,
            Delivery,
            base_price,
            ROUND(Delivery * 100 / base_price, 2) AS percentage
        FROM sales_pricing_details
    ) AS delivery_percentage_summary;
-- Insight:
-- Delivery cost ratios range from 0% to 1200% of the base invoice value
-- This includes:
-- Free delivery invoices (0%)
-- Extreme cases where delivery charges exceed the product value itself



-------------------------------
-- High Delivery-to-Price Ratio Transactions
-------------------------------
SELECT ROUND(
        COUNT(*) * 100 /(
            SELECT COUNT(*)
            FROM sales_pricing_details
        ),
        2
    ) AS percentage
FROM sales_pricing_details
WHERE ROUND(Delivery * 100 / base_price, 2) >= 100;
-- Insight:
-- Approximately 1.7% of invoices have delivery charges that are equal to or greater than the base price of the products
-- These cases represent extreme ratios, where delivery cost matches or exceeds the value of the purchased items



-------------------------------
-- High Delivery Ratio Transaction Details
-------------------------------
SELECT o.Transaction_ID, 
    GROUP_CONCAT(Coupon_Status SEPARATOR ','),
    GROUP_CONCAT(Product_Category SEPARATOR ',') AS Product_Category,
    GROUP_CONCAT(Product_Description SEPARATOR ',') AS Product_Description,
    GROUP_CONCAT(Location SEPARATOR ',') AS Location,
    SUM(Quantity * Unit_Price) AS base_price,
    MAX(Delivery_Charges) AS Delivery_Charges,
    MAX(transaction_date) as date,
    MAX(Tenure_Months) AS Tenure_Months
FROM online_sales AS o
INNER JOIN customersdata AS c
USING(CustomerID)
WHERE o.Transaction_ID IN (
        SELECT Transaction_ID
        FROM sales_pricing_details
        WHERE ROUND(Delivery * 100 / base_price, 2) >= 100
    )
GROUP BY o.Transaction_ID;
-- Insight:
-- These cases are not related to product category, transaction date, location, customer tenure, or coupon status



-------------------------------
-- Selected Transactions with 1200% Delivery-to-Price Ratio
-------------------------------
SELECT Transaction_ID,
    transaction_date,
    product_description,
    Quantity,
    Unit_Price,
    Delivery_Charges,
    Location
FROM online_sales AS o
    INNER JOIN customersdata AS c USING(CustomerID)
WHERE Transaction_ID IN (43354, 43581, 45053, 45271, 47060);
-- Insight:
-- All cases belong to a single product priced at $0.5 with 
-- a fixed delivery charge of $6. The product is YouTube Custom Decals,
-- always ordered in a quantity of 1 unit. Delivery locations were Chicago 
-- and New Jersey, during November and December. This pattern suggests that 
-- the delivery fee is fixed regardless of item price, which leads to a disproportionately high delivery-to-price ratio
-- Recommendation:
-- Low-priced, single-unit products with fixed delivery fees should be reviewed carefully.
-- Consider adjusting delivery pricing for symbolic or lightweight items to encourage demand 
-- and avoid discouraging purchases due to disproportionate delivery costs



-------------------------------
-- Average Delivery Cost by State
-------------------------------
SELECT Location,
    ROUND(AVG(max_delivery), 2) AS delivery_charge_per_transaction
FROM (
        SELECT Transaction_ID,
            Location,
            MAX(Delivery_Charges) AS max_delivery
        FROM online_sales
            INNER JOIN customersdata USING(CustomerID)
        GROUP BY Transaction_ID,
            Location
    ) AS delivery_by_location
GROUP BY Location
ORDER BY delivery_charge_per_transaction DESC;
-- Insight:
-- Delivery charges are relatively consistent across states, as all locations fall within the United States.
-- California has the highest average delivery cost (~$9)
-- Washington has the lowest (~$8.7)
-- Recommendation:
-- The minimal variation suggests a uniform delivery pricing policy nationwide.
-- No immediate adjustment is required unless future segmentation by region becomes necessary



-------------------------------
-- Free Delivery Transactions by Category
-------------------------------
SELECT product_category,
    ROUND(
        COUNT(*) * 100 / (
            SELECT COUNT(*)
            FROM online_sales
        ),
        3
    ) AS free_delivery_pct_by_category
FROM online_sales
WHERE Delivery_Charges = 0
GROUP BY product_category;
-- Insight:
-- Free delivery cases were observed in the dataset. Most of them are linked 
-- to non-physical gift cards, which logically explains the absence of delivery charges
-- One case involved symbolic and lightweight products, which may fall under a special delivery policy 
-- or result from a data entry error
-- Recommendation:
-- Review the delivery policy for symbolic or lightweight items. Clarify whether these products are 
-- officially exempt from delivery charges to ensure accurate commercial analysis