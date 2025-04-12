-- 1) Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region
SELECT 
    market
FROM
    dim_customer
WHERE
    region = 'APAC'
        AND customer = 'Atliq Exclusive'
        group by market;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020?  
SELECT 
    C1 AS unique_products_2020,
    C2 AS unique_products_2021,
    ROUND((C2 - C1) * 100 / C1, 2) AS percentage_chg
FROM 
    ((SELECT 
        COUNT(DISTINCT product_code) AS C1
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020) A, 
    (SELECT 
        COUNT(DISTINCT product_code) AS C2
    FROM fact_sales_monthly
    WHERE fiscal_year = 2021) B);

-- 3) Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- 4) Which segment had the most increase in unique products in 2021 vs 2020? 
With cte1 as (
select dp.segment as A, count(distinct fsm.product_code) as B 
from dim_product dp, fact_sales_monthly fsm
where dp.product_code = fsm.product_code 
group by fsm.fiscal_year, dp.segment 
having fsm.fiscal_year = 2020 ),
cte2 as (
select dp.segment as C, count(distinct fsm.product_code) as D 
from dim_product dp, fact_sales_monthly fsm
where dp.product_code = fsm.product_code 
group by fsm.fiscal_year, dp.segment 
having fsm.fiscal_year = 2021)

select cte1.A as segment, 
	   cte1.B as product_count_2020, 
       cte2.D as product_count_2021,
       (cte2.D-cte1.B)as difference
from cte1,cte2 
where cte1.a = cte2.c
order by difference desc;

-- 5) Get the products that have the highest and lowest manufacturing costs.
SELECT 
    fmc.product_code, dp.product, fmc.manufacturing_cost
FROM
    fact_manufacturing_cost fmc
        JOIN
    dim_product dp ON fmc.product_code = dp.product_code
WHERE
    manufacturing_cost = (SELECT MIN(manufacturing_cost)
        FROM fact_manufacturing_cost)
        OR manufacturing_cost = (SELECT MAX(manufacturing_cost)
        FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

-- 6) Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.  
SELECT 
    pd.customer_code,
    dc.customer,
    ROUND(AVG(pre_invoice_discount_pct), 4) AS average_discount_percentage
FROM
    fact_pre_invoice_deductions pd
        JOIN
    dim_customer dc ON pd.customer_code = dc.customer_code
WHERE
    pd.fiscal_year = 2021
        AND dc.market = 'India'
GROUP BY pd.customer_code , dc.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

-- 7) Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.  
SELECT 
    MONTHNAME(fsm.date) AS `Month`,
    YEAR(fsm.date) AS `Year`,
    ROUND(SUM(gp.gross_price * fsm.sold_quantity),2) AS `Gross Sales Amount`
FROM
    fact_sales_monthly fsm
        JOIN
    fact_gross_price gp ON fsm.product_code = gp.product_code
        JOIN
    dim_customer dc ON fsm.customer_code = dc.customer_code
        AND dc.customer = 'Atliq Exclusive'
GROUP BY MONTHNAME(fsm.date) , YEAR(fsm.date);

-- 8) In which quarter of 2020, got the maximum total_sold_quantity? In Atliq Hardware, Financial year starts from September!!
with cte as (
select monthname(date) as A , sold_quantity, fiscal_year 
from fact_sales_monthly
)
select 
	case 
    when cte.A in ('September','October','November') then 'Q1'
    when cte.A in ('December','January','February') then 'Q2'
    when cte.A in ('March','April','May') then 'Q3'
    when cte.A in ('June','July','August') then 'Q4'
    end as `Quarter` ,
    sum(sold_quantity) AS Total_sold_quantity
FROM
    cte  
    where fiscal_year = 2020
   group by `Quarter` order by Total_sold_quantity desc ;

-- 9) Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
WITH CTE AS  ( SELECT 
    dc.channel,
    ROUND(SUM(fsm.sold_quantity * gp.gross_price) / 1000000,2) AS gross_sales_million
FROM  fact_sales_monthly fsm
        JOIN fact_gross_price gp ON fsm.product_code = gp.product_code
        JOIN dim_customer dc ON fsm.customer_code = dc.customer_code
WHERE
    fsm.fiscal_year = 2021
GROUP BY dc.channel
ORDER BY gross_sales_million DESC )
SELECT 
	channel, 
    gross_sales_million, 
    round(gross_sales_million/(sum(gross_sales_million) over())*100,2) as percentage_contribution
from CTE ;

-- 10) Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021 
with cte as (
SELECT 
	dp.division, dp.product_code, 
	concat(dp.product,'(',dp.variant,')') as product, 
	sum(fsm.sold_quantity) as total_sold_quantity,
	rank() over(partition by dp.division order by sum(fsm.sold_quantity) desc) as rank_order 
FROM fact_sales_monthly fsm 
join dim_product dp on fsm.product_code = dp.product_code 
where fsm.fiscal_year = 2021
group by dp.division, dp.product_code, concat(dp.product,'(',dp.variant,')')
order by total_sold_quantity desc )
select * from cte
where rank_order in (1,2,3) ;
