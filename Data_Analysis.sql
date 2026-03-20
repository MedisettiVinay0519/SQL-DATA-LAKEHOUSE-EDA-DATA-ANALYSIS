--PER DAY DAY SALES DETAILS
SELECT order_date,
SUM(sales_amount) AS TOTAL_SALES 
FROM gold.fact_sales
where order_date IS NOT NULL
GROUP BY ORDER_DATE
ORDER BY order_date ASC;

--PER YEAR SALES  DETAILS
SELECT YEAR(order_date) as order_year,
SUM(sales_amount) as TOTAL_SALES,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
where YEAR(order_date) IS NOT NULL
GROUP BY YEAR(order_date) 
ORDER BY YEAR(order_date) ASC;

--PER MONTH OF EACH YEAR SALES DETAILS 
SELECT YEAR(order_date) as order_year,
MONTH(order_date) as order_month,
SUM(sales_amount) as TOTAL_SALES,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
where YEAR(order_date) IS NOT NULL and month(order_date) is not null
GROUP BY YEAR(order_date) , month(order_date) 
ORDER BY YEAR(order_date) , month(order_date);

--PER MONTH SALES ANALYSIS
SELECT MONTH(order_date) as order_month,
SUM(sales_amount) as TOTAL_SALES,
COUNT(DISTINCT customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM gold.fact_sales
where MONTH(order_date) IS NOT NULL
GROUP BY MONTH(order_date) 
ORDER BY MONTH(order_date) ASC;


--CALCULATE THE TOTAL SALES PER MONTH
--AND RUNNING TOTAL OF SALES OVER TIME

WITH MONTHLY_SALES AS(
SELECT 
YEAR(ORDER_DATE) AS ORDER_YEAR,
MONTH(ORDER_DATE) AS ORDER_MONTH,
       SUM(SALES_AMOUNT) AS TOTAL_SALES
       FROM gold.fact_sales
       WHERE ORDER_DATE IS NOT NULL
       GROUP BY YEAR(ORDER_DATE),MONTH(ORDER_DATE) 
       )


 SELECT * ,
 SUM(TOTAL_SALES) OVER (ORDER BY ORDER_YEAR,ORDER_MONTH) as RUNNING_TOTAL
 FROM MONTHLY_SALES;


 --CALCULATE THE TOTAL SALES PER YEAR 
 -- AND THE RUNNING TOTAL OVER TIME
WITH YEARLY_SALES AS(
SELECT 
YEAR(ORDER_DATE) AS ORDER_YEAR,
       SUM(SALES_AMOUNT) AS TOTAL_SALES
       FROM gold.fact_sales
       WHERE ORDER_DATE IS NOT NULL
       GROUP BY YEAR(ORDER_DATE) 
       )


 SELECT * ,
 SUM(TOTAL_SALES) OVER (ORDER BY ORDER_YEAR) as RUNNING_TOTAL
 FROM YEARLY_SALES;


 --CALCULATE THE TOTAL SALES PER YEAR 
 --AND THE MOVING AVERGAE OVER TIME
 WITH YEARLY_SALES_AVG AS(
SELECT 
YEAR(ORDER_DATE) AS ORDER_YEAR,
       SUM(SALES_AMOUNT) AS TOTAL_SALES
       FROM gold.fact_sales
       WHERE ORDER_DATE IS NOT NULL
       GROUP BY YEAR(ORDER_DATE) 
       )


 SELECT * ,
 AVG(TOTAL_SALES) OVER (ORDER BY ORDER_YEAR) as MOVING_AVG
 FROM YEARLY_SALES_AVG
 ORDER BY ORDER_YEAR;


 --CALCULATE THE TOTAL SALES PER MONTH
 --AND THE MOVING AVG OVER TIME PER MONTH
WITH YEARLY_SALES_AVG1 AS(
SELECT 
YEAR(ORDER_DATE) AS ORDER_YEAR,
MONTH(ORDER_DATE) AS ORDER_MONTH,
       SUM(SALES_AMOUNT) AS TOTAL_SALES
       FROM gold.fact_sales
       WHERE ORDER_DATE IS NOT NULL
       GROUP BY YEAR(ORDER_DATE),MONTH(ORDER_DATE) 
       )


 SELECT * ,
 AVG(TOTAL_SALES) OVER (ORDER BY ORDER_YEAR,ORDER_MONTH) as MOVING_AVG
 FROM YEARLY_SALES_AVG1
 ORDER BY ORDER_YEAR,ORDER_MONTH;

/*Analyse the yearly performance of products by comparing their sales
to both avergae sales performance of the product and previous year's sales*/

WITH yearly_product_sales AS (
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY 
        YEAR(f.order_date),
        p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,
    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
    CASE 
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,
    -- Year-over-Year Analysis
    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
    current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
    CASE 
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS py_change
FROM yearly_product_sales
ORDER BY product_name, order_year;


--which categories contribute the most to overall sales?
WITH category_sales AS (
SELECT
category,
SUM(sales_amount) as total_sales
FROM gold.fact_sales as f
LEFT JOIN gold.dim_products as p
on p.product_key = f.product_key
GROUP BY category
)

SELECT category,total_sales,
       SUM(total_sales) OVER() as overall_sales,
   CONCAT( ROUND( (CAST (total_sales as FLOAT)/SUM(total_sales) OVER())*100,2),'%') as percent_contribution
FROM category_sales
ORDER BY total_sales DESC;

/* Segment products into cost rnages and 
count how many products fall into each segment*/

WITH PROD_SEGMENT AS (
SELECT product_key,
product_name,
cost,
CASE WHEN cost<100 THEN 'Below 100'
     WHEN cost between 100 AND 500 THEN '100-200'
     WHEN COST between 500 and 1000 then '500-1000'
     ELSE 'Above 1000'
END as cost_range
FROM gold.dim_products
)
SELECT cost_range,
COUNT(product_key) as Total_Products 
FROM PROD_SEGMENT
GROUP BY cost_range
ORDER BY Total_Products DESC ;



/* GROUP CUSTOMERS INTO THREE SEGEMENTS BASED ON THEIR SPENDING BEHAVIOUR
--VIP : AT LEAST 12 MONTHS OF HSITORY AND SPENDING MORE THAN 5000
--Regular:  AT LEAST 12 MONTHS OF HSITORY AND SPENDING LESS THAN 5000
--NEW:LIFESPAN LES THAN 12 MONTHS 
*/
--AND FIND THE TOTAL NUMBBER OF CUSTOMERS BY EACH GROUP


WITH customer_spending AS (
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_customers c
        ON f.customer_key = c.customer_key
    GROUP BY c.customer_key
),


segmented_customers as (
    SELECT 
        customer_key,
        CASE 
            WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
)


SELECT 
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM segmented_customers 
GROUP BY customer_segment
ORDER BY total_customers DESC;

/*
===============================================================================
Customer Report
===============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
	2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
	   - total orders
	   - total sales
	   - total quantity purchased
	   - total products
	   - lifespan (in months)
    4. Calculates valuable KPIs:
	    - recency (months since last order)
		- average order value
		- average monthly spend
===============================================================================
*/

-- =============================================================================
-- Create Report: gold.report_customers
-- =============================================================================
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

WITH base_query AS(
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
---------------------------------------------------------------------------*/
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)

, customer_aggregation AS (
/*---------------------------------------------------------------------------
2) Customer Aggregations: Summarizes key metrics at the customer level
---------------------------------------------------------------------------*/
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) AS total_orders,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_quantity,
	COUNT(DISTINCT product_key) AS total_products,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
	customer_key,
	customer_number,
	customer_name,
	age
)
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
	 WHEN age < 20 THEN 'Under 20'
	 WHEN age between 20 and 29 THEN '20-29'
	 WHEN age between 30 and 39 THEN '30-39'
	 WHEN age between 40 and 49 THEN '40-49'
	 ELSE '50 and above'
END AS age_group,
CASE 
    WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
    WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
    ELSE 'New'
END AS customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) AS recency,
total_orders,
total_sales,
total_quantity,
total_products
lifespan,
-- Compuate average order value (AVO)
CASE WHEN total_sales = 0 THEN 0
	 ELSE total_sales / total_orders
END AS avg_order_value,
-- Compuate average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
     ELSE total_sales / lifespan
END AS avg_monthly_spend
FROM customer_aggregation

/*
===============================================================================
Product Report
===============================================================================
Purpose:
    - This report consolidates key product metrics and behaviors.

Highlights:
    1. Gathers essential fields such as product name, category, subcategory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
       - total orders
       - total sales
       - total quantity sold
       - total customers (unique)
       - lifespan (in months)
    4. Calculates valuable KPIs:
       - recency (months since last sale)
       - average order revenue (AOR)
       - average monthly revenue
===============================================================================
*/
-- =============================================================================
-- Create Report: gold.report_products
-- =============================================================================
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS

WITH base_query AS (
/*---------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
---------------------------------------------------------------------------*/
    SELECT
	    f.order_number,
        f.order_date,
		f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales f
    LEFT JOIN gold.dim_products p
        ON f.product_key = p.product_key
    WHERE order_date IS NOT NULL  -- only consider valid sales dates
),

product_aggregations AS (
/*---------------------------------------------------------------------------
2) Product Aggregations: Summarizes key metrics at the product level
---------------------------------------------------------------------------*/
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan,
    MAX(order_date) AS last_sale_date,
    COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
    SUM(sales_amount) AS total_sales,
    SUM(quantity) AS total_quantity,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price
FROM base_query

GROUP BY
    product_key,
    product_name,
    category,
    subcategory,
    cost
)

/*---------------------------------------------------------------------------
  3) Final Query: Combines all product results into one output
---------------------------------------------------------------------------*/
SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
	CASE
		WHEN total_sales > 50000 THEN 'High-Performer'
		WHEN total_sales >= 10000 THEN 'Mid-Range'
		ELSE 'Low-Performer'
	END AS product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue (AOR)
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales / total_orders
	END AS avg_order_revenue,

	-- Average Monthly Revenue
	CASE
		WHEN lifespan = 0 THEN total_sales
		ELSE total_sales / lifespan
	END AS avg_monthly_revenue

FROM product_aggregations 






