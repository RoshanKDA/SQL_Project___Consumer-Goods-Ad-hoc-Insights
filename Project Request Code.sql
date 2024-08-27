-- Reqeust 1

SELECT

DISTINCT market
FROM dim_customer
WHERE
customer='Atliq Exclusive'
AND region='APAC';


-- _____________________________________________________________________________ --

-- Request 2


WITH product_count AS (
SELECT
(SELECT COUNT(DISTINCT product_code)
FROM fact_sales_monthly WHERE fiscal_year = 2020)
AS unique_products_2020,

(SELECT COUNT(DISTINCT product_code)
FROM fact_sales_monthly WHERE fiscal_year = 2021)
AS unique_products_2021
FROM fact_sales_monthly
LIMIT 1)

SELECT
unique_products_2020,
unique_products_2021,
ROUND((unique_products_2021 - unique_products_2020)*100/unique_products_2020,2)
AS percentage_chg
From product_count;

-- ______________________________________________________________________________________________ --

-- Request 3

Select segment,
   count(product_code) as Count_of_Product
from dim_product
group by segment;

-- ________________________________________________________________________________________________ --

-- Request 4
WITH CTE1 AS
(SELECT P.segment AS A , COUNT(DISTINCT(FS.product_code)) AS B
FROM dim_product P, fact_sales_monthly FS
WHERE P.product_code = FS.product_code
GROUP BY FS.fiscal_year, P.segment
HAVING FS.fiscal_year = "2020"),
CTE2 AS
(
SELECT P.segment AS C , COUNT(DISTINCT(FS.product_code)) AS D
FROM dim_product P, fact_sales_monthly FS
WHERE P.product_code = FS.product_code
GROUP BY FS.fiscal_year, P.segment
HAVING FS.fiscal_year = "2021"
)

SELECT CTE1.A AS segment, CTE1.B AS product_count_2020,
CTE2.D AS product_count_2021, (CTE2.D-CTE1.B) AS difference
FROM CTE1, CTE2
WHERE CTE1.A = CTE2.C ;

-- _______________________________________________________________________________________________ --

-- Request 5

SELECT F.product_code, P.product, F.manufacturing_cost
FROM fact_manufacturing_cost F JOIN dim_product P
ON F.product_code = P.product_code
WHERE manufacturing_cost
IN (
SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
UNION
SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost
)
ORDER BY manufacturing_cost DESC ;

-- ______________________________________________________________________________________________________ --

-- Request 6

WITH TBL1 AS
(SELECT customer_code AS A, AVG(pre_invoice_discount_pct) AS B
FROM fact_pre_invoice_deductions
WHERE fiscal_year = '2021'
GROUP BY customer_code),
TBL2 AS
(SELECT customer_code AS C, customer AS D FROM dim_customer
WHERE market = 'India')

SELECT TBL2.C AS customer_code, TBL2.D AS customer,
ROUND (TBL1.B, 4) AS average_discount_percentage
FROM TBL1 JOIN TBL2
ON TBL1.A = TBL2.C
ORDER BY average_discount_percentage DESC
LIMIT 5 ;

-- _________________________________________________________________________________________________________ --

-- Request 7

SELECT CONCAT (MONTHNAME (FS.date),
' (', YEAR(FS.date), ') ') AS 'Month', FS.fiscal_year,
ROUND(SUM(G.gross_price*FS.sold_quantity), 2)
AS Gross_sales_Amount
FROM fact_sales_monthly FS
JOIN dim_customer C ON FS.customer_code = C.customer_code
JOIN fact_gross_price G ON FS.product_code = G.product_code
WHERE C.customer = 'Atliq Exclusive'
GROUP BY Month, FS. fiscal_year
ORDER BY FS. fiscal_year ;

-- ____________________________________________________________________________________________________________ --

-- Request No. 8

SELECT
CASE
WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then "Q1"
WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then "Q2"
WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then "Q3"
WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then "Q4"
END AS Quarters,
SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC

-- _______________________________________________________________________________________________________ --

-- Request 9

WITH Output AS
(
SELECT C.channel,
ROUND(SUM(G.gross_price*FS.sold_quantity/1000000), 2)
AS Gross_sales_mln
FROM fact_sales_monthly FS
JOIN dim_customer C ON FS.customer_code = C.customer_code
JOIN fact_gross_price G ON FS.product_code = G.product_code
WHERE FS.fiscal_year = 2021
GROUP BY channel
)
SELECT channel, CONCAT(Gross_sales_mln,' M') AS Gross_sales_mln ,
CONCAT(ROUND(Gross_sales_mln*100/total, 2), ' %') AS percentage
FROM
(
(SELECT SUM(Gross_sales_mln) AS total FROM Output) A,
(SELECT * FROM Output) B)

ORDER BY percentage DESC

-- ___________________________________________________________________________________________________________ --

-- Request 10

with cte1 as
(Select p.division, s.product_code,p.product,
sum(sold_quantity) as total_sold_quantity
from dim_product p
join fact_sales_monthly s
using(product_code)
where s.fiscal_year=2021
group by p.division, s.product_code,p.product),

cte2 as

(Select *,
dense_rank() over (partition by division order by total_sold_quantity desc)
as Rank_Order from cte1)

Select * from cte2 where Rank_Order <=3

-- ________________________________________________________________________________________________________________ -- 