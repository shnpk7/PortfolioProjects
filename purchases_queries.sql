-- ***********
-- DATA IMPORT
-- ***********

CREATE TABLE purchases (
    "Order date" TEXT,
	"Purchase price per unit" TEXT,
	"Quantity" TEXT,
	"Shipping address state" TEXT,
	"Title" TEXT,
	"ASIN_ISBN (Product Code)" TEXT,
	"Category" TEXT,
	"Survey ResponseID" TEXT
);

COPY purchases (
    "Order date",
	"Purchase price per unit",
	"Quantity",
	"Shipping address state",
	"Title",
	"ASIN_ISBN (Product Code)",
	"Category",
	"Survey ResponseID"
)
FROM '/private/tmp/amazon-purchases.csv'
DELIMITER ','
CSV HEADER;

-- Create a staging table
CREATE TABLE purchases_clean (LIKE purchases INCLUDING ALL);

INSERT INTO purchases_clean
SELECT * FROM purchases;



-- **************
-- DATA CLEANING
-- **************

-- STEP 1: CLARIFY THE DATA

-- Standardize date format
ALTER TABLE purchases_clean 
ALTER COLUMN "Order date" TYPE DATE 
USING TO_DATE("Order date", 'YYYY-MM-DD');

-- Standardize price format
ALTER TABLE purchases_clean
ALTER COLUMN "Purchase price per unit" TYPE NUMERIC(10,2) USING "Purchase price per unit"::NUMERIC(10,2);

-- Standardize quantity format  
ALTER TABLE purchases_clean
ALTER COLUMN "Quantity" TYPE INTEGER USING "Quantity"::FLOAT::INTEGER;

-- Remove non-critical rows, as dataset is limited to Oct 2022
SELECT 
	DATE_TRUNC('month', "Order date")::DATE AS order_date,
	SUM("Purchase price per unit" * "Quantity") AS revenue
FROM purchases_clean
GROUP BY 1
ORDER BY 1

DELETE FROM purchases_clean
WHERE DATE_PART('year', "Order date") BETWEEN 2023 AND 2024;


-- STEP 2: LOCATE SOLVABLE ISSUES

-- Remove rows unrelated to actual product sales
DELETE FROM purchases_clean
WHERE "Title" ILIKE '%gift card%'
   OR "Title" ILIKE '%gift code%'
   OR "Title" ILIKE '%Amazon reload%'
   

-- STEP 3: EVALUATE UNSOLVABLE ISSUES

-- Check null values
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN "Order date" IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN "Purchase price per unit" IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN "Quantity" IS NULL THEN 1 ELSE 0 END) AS null_qty,
    SUM(CASE WHEN "Shipping address state" IS NULL THEN 1 ELSE 0 END) AS null_address,
    SUM(CASE WHEN "Title" IS NULL THEN 1 ELSE 0 END) AS null_title,
    SUM(CASE WHEN "ASIN_ISBN (Product Code)" IS NULL THEN 1 ELSE 0 END) AS null_product_code,
    SUM(CASE WHEN "Category" IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN "Survey ResponseID" IS NULL THEN 1 ELSE 0 END) AS null_user_id
FROM purchases_clean;

/* There are some null values in the address, title, product code, and category columns.
Since the % of missing values is small (<5% in all columns), we’ll keep the data as is
and exclude them in data visualization */


-- STEP 4: AUGMENT THE DATA 

-- Add revenue column for cleaner code
ALTER TABLE purchases_clean
ADD COLUMN revenue NUMERIC;

UPDATE purchases_clean
SET revenue = "Purchase price per unit" * "Quantity"



-- ****************
-- DATA EXPLORATION
-- ****************

-- Overview: Yearly revenue & YoY growth rate
WITH yearly_revenue AS (
    SELECT 
        DATE_PART('year', "Order date") AS order_year,
        SUM(revenue) AS total_revenue
    FROM purchases_clean
    WHERE DATE_PART('year', "Order date") BETWEEN 2018 AND 2021
    GROUP BY 1
)
SELECT 
    order_year,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY order_year) AS prev_year_revenue,
    (total_revenue / LAG(total_revenue) OVER (ORDER BY order_year) - 1) * 100 AS yoy_growth
FROM yearly_revenue
ORDER BY 1;

-- Seasonality: Revenue by time
SELECT
	DATE_PART('month', "Order date") AS month_number,
	TO_CHAR("Order date", 'Month') AS month_name,
	SUM(CASE WHEN DATE_PART('year', "Order date") = 2018 THEN revenue END) AS revenue_2018,
	SUM(CASE WHEN DATE_PART('year', "Order date") = 2019 THEN revenue END) AS revenue_2019,
	SUM(CASE WHEN DATE_PART('year', "Order date") = 2020 THEN revenue END) AS revenue_2020,
	SUM(CASE WHEN DATE_PART('year', "Order date") = 2021 THEN revenue END) AS revenue_2021
FROM purchases_clean
WHERE DATE_PART('year', "Order date") BETWEEN 2018 AND 2021
GROUP BY 1,2
ORDER BY 1

-- Dimenstional segmentation: (i) Revenue by category
SELECT 
	"Category",
    	SUM(revenue) AS revenue
FROM purchases_clean
WHERE DATE_PART('year', "Order date") = 2021
GROUP BY 1
ORDER BY 4 DESC

-- Dimenstional segmentation: (ii) Revenue by top 5 categories 
SELECT 
    DATE_PART('month', "Order date") AS month_number,
	TO_CHAR("Order date", 'Month') AS month_name,
    SUM(CASE WHEN "Category" = 'ABIS_BOOK' THEN revenue ELSE 0 END) AS book,
    SUM(CASE WHEN "Category" = 'PET_FOOD' THEN revenue ELSE 0 END) AS pet_food,
    SUM(CASE WHEN "Category" = 'NOTEBOOK_COMPUTER' THEN revenue ELSE 0 END) AS nb_computer,
    SUM(CASE WHEN "Category" = 'NUTRITIONAL_SUPPLEMENT' THEN revenue ELSE 0 END) AS nutrition_supplement,
    SUM(CASE WHEN "Category" = 'SHOES' THEN revenue ELSE 0 END) AS shoes
FROM purchases_clean
WHERE DATE_PART('year', "Order date") = 2021
GROUP BY 1,2
ORDER BY 1;

-- Calculating growth levers in book category
-- (i) By distinct users, purchases, revenue
SELECT 
	DATE_PART('year', "Order date") AS order_year,
	"Category",
	COUNT(DISTINCT "Survey ResponseID") AS distinct_making_purchases,
	COUNT("Quantity") AS no_of_purchases,
    SUM(revenue) AS revenue
FROM purchases_clean
WHERE DATE_PART('year', "Order date") IN (2018, 2019, 2020,2021) AND "Category" = 'ABIS_BOOK'
GROUP BY 1,2
ORDER BY 1, 4 DESC

-- (ii) By average selling price
SELECT
"Category",
AVG("Purchase price per unit") AS avg_price,
DATE_PART('year', "Order date") AS order_year
FROM purchases_clean
WHERE "Category" = 'ABIS_BOOK'
GROUP BY 1,3

-- Calculating growth levers in computer category
-- (i) By distinct users, purchases, revenue
SELECT 
	DATE_PART('year', "Order date") AS order_year,
	"Category",
	COUNT(DISTINCT "Survey ResponseID") AS distinct_making_purchases,
	COUNT("Quantity") AS no_of_purchases,
    SUM(revenue) AS revenue
FROM purchases_clean
WHERE DATE_PART('year', "Order date") IN (2018, 2019,2020,2021) AND "Category" = 'NOTEBOOK_COMPUTER'
GROUP BY 1,2
ORDER BY 1, 4 DESC

-- (ii) By average selling price
SELECT
"Category",
AVG("Purchase price per unit") AS avg_price,
DATE_PART('year', "Order date") AS order_year
FROM purchases_clean
WHERE "Category" = 'NOTEBOOK_COMPUTER'
GROUP BY 1,3
