# Executive Ad-Hoc SQL Analysis (Consumer Goods Domain)
  ![image](https://github.com/user-attachments/assets/566bfc22-25ed-4d53-b885-38052101a2b4)

## Table of Contents :
- [Background/Context](#backgroundcontext)
- [Company Details](#company-details)
- [Data Model](#data-model)
- [Ad-Hoc Requests and Results](#ad-hoc-requests-and-results)
## Background/Context 
- Atliq Hardware is one of India's major computer hardware
manufacturers, with a strong presence in other nations.
- The management noticed that they do not get enough insights to
make prompt, quick, and smart data-informed decisions. So they plan to expand the data analytics team by adding several
junior data analysts.
- For that, the Director plans to conduct a SQL challenge to evaluate
the skills.
- The company seeks insights for 10 ad-hoc requests.
- Also, company's fiscal years starts from September to August ( like- September/2019 to August/2020)

## Company Details
  ![Screenshot (34)](https://github.com/user-attachments/assets/0658a907-ecd3-43a5-ab78-d81b17965f2b)
  ![Screenshot (35)](https://github.com/user-attachments/assets/5a2abe9c-2b1e-4402-aff8-f1a7b8d4bae7)

## Data Model
  ![Data Model](https://github.com/user-attachments/assets/96b685bd-ddf4-489d-b99b-c5fec629225f)

## Ad-Hoc Requests and Results 

1) Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region. 
```
SELECT 
    market
FROM
    dim_customer
WHERE
    region = 'APAC'
        AND customer = 'Atliq Exclusive'
        group by market;
```
 Result :

![Request-1](https://github.com/user-attachments/assets/18465758-bc7b-42f8-9439-238865468621)

2) What is the percentage of unique product increase in 2021 vs. 2020?
```
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
```
Result :

![Request-2](https://github.com/user-attachments/assets/4b0e5bbe-78a2-4006-affa-df4fbe3aee5f)

3) Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
```
SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;
```
Result :

![Request-3](https://github.com/user-attachments/assets/6ab100bd-e4ba-4de3-8322-9d2335549258)

4) Which segment had the most increase in unique products in 2021 vs 2020? 
```
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
```
Result :

![Request-4](https://github.com/user-attachments/assets/4378d124-7b60-41e1-987e-753ee1170b4c)

5) Get the products that have the highest and lowest manufacturing costs.
```
SELECT 
    fmc.product_code, dp.product, fmc.manufacturing_cost
FROM
    fact_manufacturing_cost fmc
        JOIN  dim_product dp ON fmc.product_code = dp.product_code
WHERE
    manufacturing_cost = (SELECT MIN(manufacturing_cost)
        FROM fact_manufacturing_cost)
        OR manufacturing_cost = (SELECT MAX(manufacturing_cost)
        FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;
```
Result :

![Request-5](https://github.com/user-attachments/assets/2de3f33e-2b38-463d-8ab9-5fc1cac656c9)

6) Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.  
```
SELECT 
    pd.customer_code,
    dc.customer,
    ROUND(AVG(pre_invoice_discount_pct), 4) AS average_discount_percentage
FROM    fact_pre_invoice_deductions pd
        JOIN  dim_customer dc ON pd.customer_code = dc.customer_code
WHERE
    pd.fiscal_year = 2021 AND dc.market = 'India'
GROUP BY pd.customer_code , dc.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;
```
Result :

![Request-6](https://github.com/user-attachments/assets/8cfb60dd-7aaf-480c-9af9-029d88f3bc44)

7) Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.  
```
SELECT 
    MONTHNAME(fsm.date) AS `Month`,
    YEAR(fsm.date) AS `Year`,
    ROUND(SUM(gp.gross_price * fsm.sold_quantity),2) AS `Gross Sales Amount`
FROM   fact_sales_monthly fsm
        JOIN  fact_gross_price gp ON fsm.product_code = gp.product_code
        JOIN  dim_customer dc ON fsm.customer_code = dc.customer_code
        AND dc.customer = 'Atliq Exclusive'
GROUP BY MONTHNAME(fsm.date) , YEAR(fsm.date);
```
Result :

![Request-7(1)](https://github.com/user-attachments/assets/0498ea51-6a9f-4c04-b846-bbe3f8a1134a)
![Request-7(2)](https://github.com/user-attachments/assets/76591363-abea-417e-9db2-4e11f3fd1a8f)

8) In which quarter of 2020, got the maximum total_sold_quantity? In Atliq Hardware, Financial year starts from September!!
```
with cte as (
select monthname(date) as A , sold_quantity, fiscal_year 
from fact_sales_monthly )
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
```
Result :

![Request-8](https://github.com/user-attachments/assets/d9c5b605-4c57-4a34-8545-c4344350cf1e)

9) Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
```
WITH CTE AS  (
SELECT  dc.channel,
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
```
Result :

![Request-9](https://github.com/user-attachments/assets/b5d27abf-a0e6-4164-b08c-34eb020426c2)

10) Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021 
```
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
```
Result :

![Request-10](https://github.com/user-attachments/assets/39c7fa28-5957-44ae-b847-419a9c70d374)

## Thank You !!
