-- 1.1  Create a dedicated schema
CREATE DATABASE IF NOT EXISTS superstore;
USE superstore;

-- 1.2  (Optional) start clean if you re-run the script
DROP TABLE IF EXISTS superstore_sales;

-- 2. Table design
CREATE TABLE superstore_sales (
    Row_ID              INT            PRIMARY KEY,          -- unique row number
    Order_ID            VARCHAR(20)    NOT NULL,
    Order_Date          DATE           NOT NULL,
    Ship_Date           DATE           NOT NULL,
    Ship_Mode           VARCHAR(20)    NOT NULL,
    Customer_ID         VARCHAR(15)    NOT NULL,
    Customer_Name       VARCHAR(100)   NOT NULL,
    Segment             VARCHAR(20)    NOT NULL,
    Country             VARCHAR(40)    NOT NULL,
    City                VARCHAR(50)    NOT NULL,
    Province            VARCHAR(50)    NOT NULL,
    Postal_Code         VARCHAR(10),
    Region              VARCHAR(20)    NOT NULL,
    Product_ID          VARCHAR(15)    NOT NULL,
    Category            VARCHAR(30)    NOT NULL,
    Sub_Category        VARCHAR(30)    NOT NULL,
    Product_Name        VARCHAR(150)   NOT NULL,
    Sales               DECIMAL(12,2)  NOT NULL,
    Quantity            SMALLINT       NOT NULL,
    Discount            DECIMAL(4,2)   NOT NULL,
    Profit              DECIMAL(12,2)  NOT NULL,

    -- Helpful derived columns
    Order_YYYY_MM       CHAR(7)        AS (DATE_FORMAT(Order_Date,'%Y-%m')) STORED,
    Year                INT            AS (YEAR(Order_Date)) STORED,
    Month               TINYINT        AS (MONTH(Order_Date)) STORED,

    -- Performance helpers
    INDEX idx_region (Region),
    INDEX idx_customer (Customer_ID),
    INDEX idx_product (Product_ID),
    INDEX idx_dates   (Order_Date)
);

-- 3 Data loading
LOAD DATA INFILE '/path/to/Superstore.csv'
INTO TABLE superstore_sales
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 4. Basic data quality checks
-- 4.1  Preview
SELECT * FROM superstore_sales LIMIT 5;

-- 4.2  Row count
SELECT COUNT(*) AS total_records FROM superstore_sales;

-- 4.3  Null audit
SELECT
    SUM(Order_ID     IS NULL) AS null_order_id,
    SUM(Order_Date   IS NULL) AS null_order_date,
    SUM(Sales        IS NULL) AS null_sales,
    SUM(Profit       IS NULL) AS null_profit
FROM superstore_sales;

-- 4.4  Duplicate finder (same order/customer/product/date)
SELECT
    Order_ID, Customer_ID, Order_Date, Sub_Category,
    COUNT(*) AS dup_count
FROM superstore_sales
GROUP BY 1,2,3,4
HAVING dup_count > 1;

-- 5.Core business queries
SELECT
    Region,
    ROUND(SUM(Sales),2)  AS total_sales,
    ROUND(SUM(Profit),2) AS total_profit
FROM superstore_sales
GROUP BY Region
ORDER BY total_profit DESC;

-- 5.1 Regional performance
SELECT
    Region,
    ROUND(SUM(Sales),2)  AS total_sales,
    ROUND(SUM(Profit),2) AS total_profit
FROM superstore_sales
GROUP BY Region
ORDER BY total_profit DESC;
-- 5.2 Monthly trend
SELECT
    Order_YYYY_MM                                    AS month,
    ROUND(SUM(Sales),2)                              AS total_sales,
    ROUND(SUM(Profit),2)                             AS total_profit
FROM superstore_sales
GROUP BY month
ORDER BY month;

-- 5.3 Customer profitability
-- Top 10 customers
SELECT Customer_Name,
       ROUND(SUM(Profit),2) AS total_profit
FROM superstore_sales
GROUP BY Customer_Name
ORDER BY total_profit DESC
LIMIT 10;
-- Loss-making customers
SELECT Customer_Name,
       ROUND(SUM(Profit),2) AS total_profit
FROM superstore_sales
GROUP BY Customer_Name
HAVING total_profit < 0
ORDER BY total_profit;

-- 5.4 Product insights
-- Top 10 sub-categories by revenue
SELECT Sub_Category,
       ROUND(SUM(Sales),2) AS total_sales
FROM superstore_sales
GROUP BY Sub_Category
ORDER BY total_sales DESC
LIMIT 10;
-- Sub-categories that lose money
SELECT Sub_Category,
       ROUND(SUM(Profit),2) AS total_loss
FROM superstore_sales
GROUP BY Sub_Category
HAVING total_loss < 0
ORDER BY total_loss;

-- 5.5 Shipping & segment analysis
-- Shipment modes
SELECT Ship_Mode,
       COUNT(*)           AS orders,
       ROUND(SUM(Sales),2)  AS total_sales,
       ROUND(SUM(Profit),2) AS total_profit
FROM superstore_sales
GROUP BY Ship_Mode
ORDER BY total_sales DESC;

-- Customer segments
SELECT Segment,
       ROUND(SUM(Sales),2)  AS total_sales,
       ROUND(SUM(Profit),2) AS total_profit
FROM superstore_sales
GROUP BY Segment
ORDER BY total_profit DESC;

-- 5.6 Province drill-down + descriptive stats
-- Profitability ranking
SELECT Province,
       ROUND(SUM(Sales),2)  AS total_sales,
       ROUND(SUM(Profit),2) AS total_profit
FROM superstore_sales
GROUP BY Province
ORDER BY total_profit DESC;

-- Spread of sales within each region
SELECT Region,
       ROUND(AVG(Sales),2) AS avg_sales,
       ROUND(MIN(Sales),2) AS min_sales,
       ROUND(MAX(Sales),2) AS max_sales
FROM superstore_sales
GROUP BY Region;

-- 5.7 Correlation proxy (average sales vs. average profit)
SELECT Sub_Category,
       ROUND(AVG(Sales),2)  AS avg_sales,
       ROUND(AVG(Profit),2) AS avg_profit
FROM superstore_sales
GROUP BY Sub_Category
ORDER BY avg_profit DESC;

-- 6. Next steps & best practices
CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT Order_YYYY_MM, SUM(Sales) AS sales, SUM(Profit) AS profit
FROM superstore_sales
GROUP BY Order_YYYY_MM;


-- 1 Data-quality refinements
/* 1.1  Trim whitespace that often appears in CSV exports */
UPDATE superstore_sales
SET
    Customer_Name = TRIM(Customer_Name),
    City          = TRIM(City),
    Province      = TRIM(Province),
    Region        = TRIM(Region),
    Category      = TRIM(Category),
    Sub_Category  = TRIM(Sub_Category),
    Ship_Mode     = TRIM(Ship_Mode);

/* 1.2  Replace obvious typos in Region names */
UPDATE superstore_sales
SET Region = 'West'
WHERE Region IN ('We st', 'Wes', 'Wset');

/* 1.3  Remove duplicate physical rows (if any slipped past CHECK constraints) */
DELETE s1
FROM superstore_sales s1
JOIN superstore_sales s2
  ON s1.Order_ID      = s2.Order_ID
 AND s1.Product_ID    = s2.Product_ID
 AND s1.Row_ID       <> s2.Row_ID
WHERE s1.Row_ID > s2.Row_ID;      -- keeps the first occurrence

-- 2 Enrichment columns
/* 2.1  Profit ratio: helpful KPI for margin analysis */
ALTER TABLE superstore_sales
ADD COLUMN Profit_Ratio DECIMAL(6,4) AS (Profit / NULLIF(Sales,0)) STORED;

/* 2.2  Year-quarter dimension for cleaner time series */
ALTER TABLE superstore_sales
ADD COLUMN Year_Qtr CHAR(6) AS (CONCAT(YEAR(Order_Date), '-Q', QUARTER(Order_Date))) STORED;

/* 2.3  Discount bucket makes dashboards simpler */
ALTER TABLE superstore_sales
ADD COLUMN Discount_Band VARCHAR(15) AS (
  CASE
    WHEN Discount = 0              THEN '0%'
    WHEN Discount BETWEEN 0 AND .1 THEN '0–10%'
    WHEN Discount BETWEEN .1 AND .2 THEN '10–20%'
    WHEN Discount BETWEEN .2 AND .4 THEN '20–40%'
    ELSE '40%+'
  END
) STORED;

-- 3 Advanced insight queries
-- 3.1 Profit ratio heat-map (Category × Discount band)
SELECT
    Category,
    Discount_Band,
    ROUND(SUM(Profit) / NULLIF(SUM(Sales),0), 3) AS profit_ratio
FROM superstore_sales
GROUP BY Category, Discount_Band
ORDER BY Category, Discount_Band;
-- 3.2 Cohort of repeat customers (≥4 orders)
WITH customer_orders AS (
    SELECT Customer_ID, COUNT(DISTINCT Order_ID) AS order_count
    FROM superstore_sales
    GROUP BY Customer_ID
)
SELECT
    c.Customer_ID,
    c.Customer_Name,
    o.order_count,
    ROUND(SUM(sales),2)  AS lifetime_sales,
    ROUND(SUM(profit),2) AS lifetime_profit
FROM superstore_sales s
JOIN customer_orders o USING (Customer_ID)
JOIN superstore_sales c USING (Customer_ID)
WHERE o.order_count >= 4
GROUP BY c.Customer_ID, c.Customer_Name, o.order_count
ORDER BY lifetime_profit DESC;
-- 3.3 “Bleeding” products—high sales but net loss
SELECT
    Product_ID,
    Product_Name,
    ROUND(SUM(Sales),2)  AS sales,
    ROUND(SUM(Profit),2) AS profit
FROM superstore_sales
GROUP BY Product_ID, Product_Name
HAVING sales > 5000        -- adjust threshold to taste
   AND profit < 0
ORDER BY profit;
-- 3.4 Year-over-year growth by region
WITH yearly AS (
  SELECT Year,
         Region,
         SUM(Sales)  AS sales,
         SUM(Profit) AS profit
  FROM superstore_sales
  GROUP BY Year, Region
)
SELECT
    cur.Region,
    cur.Year,
    ROUND(cur.sales   - prev.sales ,2) AS sales_diff,
    ROUND(cur.sales   / NULLIF(prev.sales,0)  - 1,3) AS sales_growth,
    ROUND(cur.profit  - prev.profit,2) AS profit_diff,
    ROUND(cur.profit  / NULLIF(prev.profit,0) - 1,3) AS profit_growth
FROM yearly cur
LEFT JOIN yearly prev
  ON cur.Region = prev.Region
 AND cur.Year   = prev.Year + 1
ORDER BY cur.Region, cur.Year;
-- 3.5 Basket analysis starter (top 20 pairs)
-- Build an order-product list
CREATE TEMPORARY TABLE t_order_products AS
SELECT Order_ID, Product_ID
FROM superstore_sales
GROUP BY Order_ID, Product_ID;          -- removes duplicates within an order

/* Self-join to get pairs (A,B) where A<B prevents dupes & reversals */
SELECT
    a.Product_ID           AS item_A,
    b.Product_ID           AS item_B,
    COUNT(*)               AS together_cnt,
    ROUND(COUNT(*) / t1.order_total,4) AS support
FROM t_order_products a
JOIN t_order_products b
  ON a.Order_ID = b.Order_ID
 AND a.Product_ID < b.Product_ID
JOIN (SELECT COUNT(DISTINCT Order_ID) AS order_total FROM superstore_sales) t1
GROUP BY item_A, item_B, order_total
ORDER BY together_cnt DESC
LIMIT 20;
-- 4 Performance touches
/* 4.1  Composite index for most-used dashboard filters */
CREATE INDEX idx_region_month ON superstore_sales (Region, Order_YYYY_MM);

/* 4.2  Materialized summary for BI tools */
CREATE TABLE fact_month_region AS
SELECT
    Order_YYYY_MM       AS month,
    Region,
    SUM(Sales)  AS sales,
    SUM(Profit) AS profit,
    SUM(Quantity) AS units
FROM superstore_sales
GROUP BY Order_YYYY_MM, Region;
