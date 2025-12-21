(SQL Project)

## 📌 Project Overview
This project focuses on advanced SQL-based customer analytics for an e-commerce business.
The analysis combines transactional, demographic, pricing, delivery, and tax data to uncover
business-driven insights related to customer behavior and product performance.

---

## 🎯 Business Objectives
- Assess data quality before analysis
- Understand customer behavior across gender and tenure
- Identify high- and low-performing product categories
- Analyze delivery charges, tax impact, and pricing anomalies
- Support pricing and promotion strategy decisions

---

## 🛠️ Tools & Technologies
- SQL (CTEs, Window Functions, Views, Nested Subqueries, Joins, Aggregations)
- Relational Database Concepts
- Business-Oriented Analytical Design

---

## Project Structure
```
.
├── sql/
│   ├── 00_data_quality_assessment.sql
│   ├── 01_customer_behavior_analysis.sql
│   ├── 02_delivery_mechanics_analysis.sql
│   ├── 03_unit_price_anomalies.sql
│   └── 04_invoice_pricing_view.sql
│
└── report/
    └── E-Commerce_Analytics_Report.pdf
```

---

## How to Use
1. Run the data quality assessment script first.
2. Execute analytical scripts in numerical order.
3. Review the PDF report for summarized insights and recommendations.
   
---

## SQL Scripts Overview

### 00_data_quality_assessment.sql
Performs an initial data quality check including:
- Missing values detection
- Duplicate checks
- Basic integrity validation

### 01_customer_behavior_analysis.sql
Analyzes customer behavior by:
- Gender distribution
- Product category preferences
- Customer tenure segmentation

### 02_delivery_mechanics_analysis.sql
Evaluates delivery-related factors such as:
- Average delivery charges
- Delivery impact on low-demand products

### 03_unit_price_anomalies.sql
Identifies unusual unit price patterns that may indicate:
- Pricing inconsistencies
- Data or operational issues

### 04_invoice_pricing_view.sql
Creates a consolidated pricing view to support
invoice-level analysis and downstream reporting.

---

## Analytical Report

The full business analysis and insights are documented in:
- **E-Commerce_Analytics_Report.pdf**
The report summarizes key findings and provides business-oriented recommendations
based on the SQL analysis.

---

## Notes

This project focuses on analytical logic and business insights.
No BI dashboards are included, as the results were highly consistent
and better communicated through structured analysis and reporting.
