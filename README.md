
# 📊 Customer & Product Profit Analysis using SQL
## 📝 Project Overview
This project involves a comprehensive analysis of a retail company's sales data using SQL. The goal is to uncover key insights into customer behavior, product performance, and regional profitability. The project demonstrates in-depth data preprocessing, cleaning, enrichment, and the use of advanced SQL queries to generate actionable business intelligence.

## 📂 Dataset Description
The superstore_sales table includes the following key columns:

Order Info: Order_ID, Order_Date, Ship_Date, Ship_Mode

Customer Info: Customer_Name, Segment, Region, Province, City

Product Info: Product_ID, Category, Sub_Category, Product_Name

Financials: Sales, Profit, Discount, Quantity

## ⚙️ SQL Operations Performed

🔧 Preprocessing & Enrichment

Data Cleaning: Trimmed whitespace from text fields and corrected typos to ensure data consistency.

Duplicate Removal: Identified and removed duplicate order records.

Derived Columns: Added new columns for deeper analysis, such as Profit_Ratio, Year_Qtr (Year-Quarter), and Discount_Band.

## 📊 Analysis Queries

General Stats

Calculated total number of records.

Performed a NULL value audit on critical columns like Sales and Profit.

Performance Analysis

Regional Performance: Aggregated sales and profit by Region to find the most and least profitable areas.

Monthly Trends: Analyzed sales and profit over time to spot seasonal trends.

Year-over-Year Growth: Calculated the growth rate of sales and profit by region.

Customer Insights

Profitability Analysis: Identified the top 10 most profitable customers and also listed customers who were unprofitable.

Segment Performance: Grouped customers by Segment (e.g., Consumer, Corporate) to analyze the profitability of each.

Product Insights

Top Sub-Categories: Ranked product Sub_Category by total sales and profit.

Loss-Making Products: Identified products and sub-categories that are losing money.

Basket Analysis: Found pairs of products that are frequently bought together in the same order.

## 📈 Sample Insights

Which regions and customer segments are the most profitable?

What are the top-selling and most profitable product sub-categories?

Which specific products are consistently losing money?

Is there a correlation between the discount given and the profit margin?

## 🛠️ Tools Used

MySQL for data processing and query execution.

SQL for all data cleaning, transformation, and analysis.
