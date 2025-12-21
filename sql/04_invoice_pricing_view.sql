/*
Invoice-Level Pricing Architecture
----------------------------------
This script defines a reusable analytical view that consolidates
base price, discounts, tax, and delivery into a single invoice-level model.

Design Rationale:
- Centralize pricing logic to avoid duplicated calculations
- Ensure consistency across downstream analyses
- Reflect real invoice economics instead of row-level artifacts

The view is intentionally designed using defensive SQL patterns
to handle missing discounts, taxes, and delivery values safely.
*/



-------------------------------
-- Technical Design Note:
-- This view abstracts complex pricing logic (tax, discount, delivery)
-- into a single reusable analytical layer.
-- This prevents duplicated logic and ensures pricing consistency across all downstream analyses.
-------------------------------
CREATE VIEW sales_pricing_details AS (
    WITH base_table AS (
        SELECT 
            CustomerID,
            Transaction_ID,
            converted_month,
            o.Product_Category,
            Quantity,
            Unit_Price,
            Delivery_Charges,
            Coupon_Status,
            Discount_pct,
            COALESCE(CAST(GST AS decimal) / 100, 0) AS tax,
            CASE
                WHEN Coupon_Status = 'Used' THEN Discount_pct / 100
                ELSE 0
            END AS Discount_rate
        FROM online_sales AS o
            LEFT JOIN vw_coupon_month_numeric AS d ON o.Product_Category = d.Product_Category
            AND MONTH(o.transaction_date) = d.converted_month
            LEFT JOIN tax_amount AS t ON o.Product_Category = t.Product_Category
    )
    SELECT Transaction_ID,
        MAX(Delivery_Charges) AS Delivery,
        ROUND(SUM(Unit_Price * Quantity), 1) AS base_price,
        GROUP_CONCAT(product_category SEPARATOR ',') AS product_category,
        SUM(Quantity) AS Quantity,
        SUM(Delivery_Charges) AS Delivery_Charges,
        GROUP_CONCAT (Coupon_Status SEPARATOR ',') AS Coupon_Status,
        GROUP_CONCAT (Unit_Price SEPARATOR ',') AS Unit_Price,
        SUM(Discount_pct) AS Discount_pct,
        MAX(converted_month) AS month,
        ROUND(
            SUM(
                Unit_Price * Quantity * COALESCE(Discount_rate, 0)
            ),
            1
        ) AS effect_discount,
        ROUND(SUM(Unit_Price * Quantity * tax), 1) AS effect_tax,
        ROUND(
            SUM(
                Unit_Price * Quantity * (1 - COALESCE(Discount_rate, 0))
            ),
            1
        ) AS price_after_discount,
        ROUND(
            SUM(
                Unit_Price * Quantity * (1 - COALESCE(Discount_rate, 0)) * (1 + tax)
            ),
            1
        ) AS price_after_gst,
        ROUND(
            SUM(
                Unit_Price * Quantity * (1 - COALESCE(Discount_rate, 0)) * (1 + tax)
            ) + MAX(Delivery_Charges),
            1
        ) AS final_price
    FROM base_table
    GROUP BY Transaction_ID
    ORDER BY Transaction_ID
);
-- Notes:
-- A LEFT JOIN was used to ensure all transactions are included, whether or not they have associated discounts or taxes
-- The view merges three tables to calculate comprehensive pricing metrics per transaction



-------------------------------
-- Final Invoice Price Distribution
-------------------------------
SELECT 
ROUND(MAX(final_price),1) AS max_final_price,
ROUND(MIN(final_price),1) AS min_final_price,
ROUND(AVG(final_price),1) AS avg_final_price,
ROUND(STDDEV(final_price),1) AS std_final_price
FROM sales_pricing_details;
-- Insight:
-- There is a strong positive skew in the distribution
-- The lowest invoice value is $6.4, while the highest reaches $25,458.4
-- The standard deviation is nearly twice the average, indicating significant dispersion and a bias toward high-value invoices



-------------------------------
-- Top 10 Highest Final Invoice Prices
-------------------------------
SELECT * FROM sales_pricing_details
ORDER BY final_price DESC
LIMIT 10;
-- Notes:
-- This query helps surface extreme values in final invoice pricing,
-- which may indicate outliers or special-case transactions requiring further review



-------------------------------
-- Tax-Dominant Transactions with Low Quantity
-------------------------------
SELECT * FROM sales_pricing_details 
WHERE effect_tax > effect_discount + Delivery_Charges
AND Quantity <= 50
ORDER BY final_price DESC;
-- Insight:
-- Tax significantly increases the final price in several low-quantity transactions
-- The Smart Devices category shows the strongest tax dominance, even with minimal quantities
-- Clothing is also affected by tax, but to a lesser extent than smart devices



-------------------------------
-- Tax Rate Comparison: Apparel vs. Smart Devices
-------------------------------
SELECT product_category,
ROUND(AVG(GST),1) AS avg_tax 
FROM tax_amount
WHERE product_category = 'Apparel'
OR product_category LIKE 'NEST%'
GROUP BY product_category
ORDER BY avg_tax DESC;
-- Insight:
-- Apparel is subject to a higher average tax rate (18%)
-- Smart devices (e.g., Nest products) are taxed at a lower average rate (10%) 
-- This confirms that the greater tax impact on smart devices is not due to a higher rate, 
-- but rather due to their higher base prices, which amplify the absolute tax amount



-------------------------------
-- Average Unit Price: Smart Devices vs. Apparel
-------------------------------
SELECT product_category,
ROUND(AVG(Unit_Price),1) AS avg_unit_price
FROM online_sales
WHERE product_category = 'Apparel'
OR product_category LIKE 'NEST%'
GROUP BY product_category
ORDER BY avg_unit_price DESC;
-- Insight:
-- Smart devices have significantly higher average unit prices, ranging from $124 to $194.
-- Apparel has a much lower average unit price of approximately $19.8.
-- This explains why taxes have a greater absolute impact on smart devices, despite their lower tax rate (10%) compared to apparel (18%).
-- The higher base price of smart devices amplifies the tax amount, making tax the dominant factor in their final pricing