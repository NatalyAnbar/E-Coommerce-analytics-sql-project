/*
File Purpose:
This script focuses on customer behavior analysis by combining transactional
and demographic data into a unified analytical view.

Key Objectives:
- Customer segmentation by gender and tenure
- Demand concentration across product categories
- Identification of high- and low-performing product groups
- Business-driven insights to support marketing and pricing decisions

Design Notes:
- A reusable SQL view is used to standardize joins and avoid query duplication
- Window functions are applied to rank behavioral patterns without details loss
*/


CREATE VIEW vw_customer_sales AS (
    SELECT *
    FROM online_sales
        INNER JOIN customersdata USING(customerID)
);


-------------------------------
-- Customer Gender Distribution
-------------------------------
SELECT Gender,
    COUNT(*) AS total_customers_per_gender,
    CONCAT(
        ROUND(
            COUNT(*) * 100.0 / (
                SELECT COUNT(*)
                FROM vw_customer_sales
            ),
            1
        ),
        '%'
    ) AS percentage
FROM vw_customer_sales
GROUP BY Gender
ORDER BY percentage DESC;
-- Insight: Females represent 62.4% of the customer base,
-- reflecting a higher commercial contribution and an opportunity for targeted marketing initiatives.



-------------------------------
-- Top Product Categories by Gender
-------------------------------
SELECT Gender,
    Product_Category,
    quantity_by_category,
    rn
FROM (
        SELECT Product_Category,
            Gender,
            quantity_by_category,
            ROW_NUMBER() OVER (
                PARTITION BY Gender
                ORDER BY quantity_by_category DESC
            ) AS rn
        FROM (
                SELECT Gender,
                    Product_Category,
                    SUM(Quantity) AS quantity_by_category
                FROM vw_customer_sales
                GROUP BY Gender,
                    Product_Category
                ORDER BY quantity_by_category DESC
            ) AS gender_category_summary
    ) AS ranked_categories
WHERE rn <= 3;
-- Insight: Both genders show similar demand patterns across Office Supplies, Apparel, and Drinkware, 
-- indicating that product category demand is driven by category characteristics rather than customer gender.



-------------------------------
-- Top Products by Gender
-------------------------------
SELECT Gender,
    Product_Description,
    quantity_by_description,
    rn
FROM (
        SELECT Product_Description,
            Gender,
            quantity_by_description,
            ROW_NUMBER() OVER (
                PARTITION BY Gender
                ORDER BY quantity_by_description DESC
            ) AS rn
        FROM (
                SELECT Gender,
                    Product_Description,
                    SUM(Quantity) AS quantity_by_description
                FROM vw_customer_sales
                GROUP BY Gender,
                    Product_Description
                ORDER BY quantity_by_description DESC
            ) AS gender_description_summary
    ) AS ranked_descriptions
WHERE rn <= 3;
-- Insight: Top products include Maze Pens, Sunglasses,
-- and Water Bottles—showing similar purchasing behavior across genders.



-------------------------------
-- Average Tenure by Gender
-------------------------------
SELECT Gender,
    ROUND(AVG(Tenure_Months), 2) AS avg_Tenure_Months
FROM vw_customer_sales
GROUP BY Gender;
-- Insight: No significant difference is observed in customer tenure across genders, 
-- supporting unified lifecycle strategies with limited visual or messaging customization.



-------------------------------
-- Top Product Categories by Customer Type
-------------------------------
SELECT *
FROM (
  SELECT 
    customer_category,
    Product_Category,
    SUM(Quantity) AS total_quantity,
    DENSE_RANK() OVER (
      PARTITION BY customer_category
      ORDER BY SUM(Quantity) DESC
    ) AS rank_customer
  FROM (
    SELECT *,
      CASE
        WHEN Tenure_Months >= 24 THEN 'Old Customer'
        ELSE 'New Customer'
      END AS customer_category
    FROM vw_customer_sales
  ) AS customer_classification
  GROUP BY Product_Category, customer_category
) AS ranked_categories
WHERE rank_customer <= 3;
-- Insight: Office Supplies, Apparel, and Drinkware are consistently 
-- the top categories for both new and old customers. This confirms their 
-- universal appeal across tenure and gender segments.
-- Recommendation:
-- These categories should be prioritized in promotions and
-- product placement due to their consistent demand across all customer types.



-------------------------------
-- Low-Demand Categories by Customer Type
-------------------------------
SELECT *
FROM (
  SELECT 
    customer_category,
    Product_Category,
    SUM(Quantity) AS total_quantity,
    DENSE_RANK() OVER (
      PARTITION BY customer_category
      ORDER BY SUM(Quantity) 
    ) AS rank_customer
  FROM (
    SELECT *,
      CASE
        WHEN Tenure_Months >= 24 THEN 'Old Customer'
        ELSE 'New Customer'
      END AS customer_category
    FROM vw_customer_sales
  ) AS customer_classification
  GROUP BY Product_Category, customer_category
) AS ranked_categories
WHERE rank_customer <= 3;
-- Insight: Android, Backpacks, and More Bags consistently exhibit low demand among both new and long-tenured customers,
-- suggesting a structural demand issue rather than a lifecycle-related effect.



-------------------------------
-- Discounts on Low-Demand Categories
-------------------------------
SELECT DISTINCT Product_Category,discount_pct FROM discount_coupon
WHERE Product_Category IN ('Android','Backpacks','More Bags');
-- Insight: Android has multiple discount tiers (10%, 20%, 30%), 
-- while Backpacks and More Bags have no discounts at all



-------------------------------
-- Price Range of Low-Demand Categories
-------------------------------
SELECT Product_Category,
MIN(Unit_Price) AS min_unit_price,
MAX(Unit_Price) AS max_unit_price
FROM online_sales
WHERE Product_Category IN ('Backpacks','More Bags')
GROUP BY Product_Category;
-- Insight: Backpacks range from $38 to $103, 
-- and More Bags from $17 to $32. Despite moderate-to-high pricing, no discounts are applied



-------------------------------
-- Tax Rates on Low-Demand Categories
-------------------------------
SELECT DISTINCT Product_Category,GST FROM tax_amount
WHERE Product_Category IN ('Android','Backpacks','More Bags');
-- Insight: Android has 10% GST but benefits from discounts. 
-- Backpacks also have 10% GST with no discounts, 
-- while More Bags face 18% GST and no discount support
-- Reflection: 
-- Tax rates may be externally controlled, 
-- but compensatory discounts could help mitigate their commercial impact



-------------------------------
-- Average Delivery Charges for Low-Demand Categories
-------------------------------
SELECT DISTINCT Product_Category,
ROUND(AVG(Delivery_Charges),1) AS avg_delivery
FROM online_sales
WHERE Product_Category IN ('Android','Backpacks','More Bags')
GROUP BY Product_Category;
-- Insight: Delivery charges range from $8 to $13, 
-- but apply to the entire invoice—not specifically to these products
-- Recommendation: Consider revising delivery pricing policies to 
-- reduce friction for high-tax, high-price items. For example:
-- Exclude these products from delivery charge calculations when bundled with other items.
-- Offer reduced delivery fees when these categories are present.





















