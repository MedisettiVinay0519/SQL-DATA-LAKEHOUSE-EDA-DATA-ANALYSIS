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

