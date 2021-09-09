

-- list table names  (It's important to explore the data to understand what each table contains. You can do it either under the Browse Data tab or by writing some queries like the following
SELECT name
 FROM sqlite_schema
WHERE type='table'
ORDER BY name;
/*
TABLES
customers
employees
offices
orderdetails
orders
payments
productlines
products
*/

-- check number of rows for each TABLE
SELECT 'Customers' AS table_name, 
       13 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Customers
  
UNION ALL

SELECT 'Products' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Products

UNION ALL

SELECT 'ProductLines' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM ProductLines

UNION ALL

SELECT 'Orders' AS table_name, 
       7 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Orders

UNION ALL

SELECT 'OrderDetails' AS table_name, 
       5 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM OrderDetails

UNION ALL

SELECT 'Payments' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Payments

UNION ALL

SELECT 'Employees' AS table_name, 
       8 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Employees

UNION ALL

SELECT 'Offices' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Offices;
  
  /*
  Now that we know the database a little better,
  we can answer the first question: 
  which products should we order more of or less of? 
  This question refers to inventory reports, including low stock and product performance. 
  This will optimize the supply and the user experience by preventing the best-selling products from going out-of-stock.
  */
  
 ---- Low stock----
  SELECT productCode, 
       ROUND(SUM(quantityOrdered) *1.0/ (SELECT quantityInStock
                                             FROM products p
                                            WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock
 LIMIT 10;
   /*
 S18_1984	0.09
S24_3432	0.09
S12_2823	0.1
S12_3380	0.1
S18_1589	0.1
S18_2325	0.1
S18_2870	0.1
S18_3482	0.1
S32_2206	0.1
S700_2466	0.1
*/


  -- Product performance---
SELECT productCode, 
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 GROUP BY productCode 
 ORDER BY prod_perf  DESC
 LIMIT 10;

 /*
 OUTPUT
 S18_3232	276839.98
S12_1108	190755.86
S10_1949	190017.96
S10_4698	170686.0
S12_1099	161531.48
S12_3891	152543.02
S18_1662	144959.91
S18_2238	142530.63
S18_1749	140535.6
S12_2823	135767.03
*/
 /*
------  Conclusion-------
 Now that we know the database a little better, we can answer the first question: 
 which products should we order more of or less of? 
 This question refers to inventory reports, including low stock and product performance. 
 This will optimize the supply and the user experience by preventing the best-selling products from going out-of-stock.
 */
 --------Priority Products for restocking-------
 WITH 

low_stock_table AS (
SELECT productCode, 
       ROUND(SUM(quantityOrdered) * 1.0/(SELECT quantityInStock
                                           FROM products p
                                          WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock
 LIMIT 10
 
)
 
 SELECT productCode, 
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 WHERE productCode IN (SELECT productCode
                         FROM low_stock_table)
 GROUP BY productCode 
 ORDER BY prod_perf DESC
 LIMIT 10;
 
 
 /*
 In the first part of this project, we explored products. Now we'll explore customer information by answering the second question:
 how should we match marketing and communication strategies to customer behaviors?
 This involves categorizing customers: finding the VIP (very important person) customers and those who are less engaged.
 */
-----revenue by customer-----
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber;
 
 
 /*
 Finding VIP customers
 ------------------Creating CTE---------------
 */
 WITH 

money_in_by_customer_table AS (
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)

SELECT contactLastName, contactFirstName, city, country, mc.revenue
  FROM customers c
  JOIN money_in_by_customer_table as mc
    ON mc.customerNumber = c.customerNumber
 ORDER BY mc.revenue DESC
 LIMIT 5;
 
 with
 money_in_by_customer_table AS (
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)
SELECT contactLastName, contactFirstName, city, country, mc.revenue
  FROM customers c
  JOIN money_in_by_customer_table mc
    ON mc.customerNumber = c.customerNumber
 ORDER BY mc.revenue
 LIMIT 5;
 
 
 
 /*
 -------------average of customer profits---------------(using CTE)
 */
 
 WITH 

money_in_by_customer_table AS (
SELECT o.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS revenue
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
  JOIN orders o
    ON o.orderNumber = od.orderNumber
 GROUP BY o.customerNumber
)

SELECT AVG(mc.revenue) AS ltv
  FROM money_in_by_customer_table mc;
 
 
 
 
 /*
 let's find the number of new customers arriving each month. 
 That way we can check if it's worth spending money on acquiring new customers. 
 This query helps to find these numbers.
 */
 
 WITH 

payment_with_year_month_table AS (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
  FROM payments p
),

customers_by_month_table AS (
SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
  FROM payment_with_year_month_table p1
 GROUP BY p1.year_month
),

new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(*) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
 GROUP BY p1.year_month
)

SELECT year_month, 
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
  FROM new_customers_by_month_table;
 
 /*
 ----Output---
 200301	100.0	100.0
200302	100.0	100.0
200303	100.0	100.0
200304	100.0	100.0
200305	100.0	100.0
200306	100.0	100.0
200307	75.0	68.3
200308	66.0	54.2
200309	80.0	95.9
200310	69.0	69.3
200311	57.0	53.9
200312	60.0	54.9
200401	33.0	41.1
200402	33.0	26.5
200403	54.0	55.0
200404	40.0	40.3
200405	12.0	17.3
200406	33.0	43.9
200407	10.0	6.5
200408	18.0	26.2
200409	40.0	56.4
*/



/*
--------------CONCLUSION--------------
Here are the answers to our questions.

Question 1: Which products should we order more of or less of?
Classic cars are the priority for restocking. They sell frequently, and they are the highest-performance products.

productName	productLine
2002 Suzuki XREO	Motorcycles
1976 Ford Gran Torino	Classic Cars
1995 Honda Civic	Classic Cars
1932 Model A Ford J-Coupe	Vintage Cars
1965 Aston Martin DB5	Classic Cars
1999 Indy 500 Monte Carlo SS	Classic Cars
1968 Dodge Charger	Classic Cars
America West Airlines B757-200	Planes
2002 Chevy Corvette	Classic Cars
1982 Ducati 996 R	Motorcycles


Question 2: How should we match marketing and communication strategies to customer behaviors?

--------VIP customers---------

contactLastName--contactFirstName--city--country--profit
Freyre	Diego	Madrid	Spain	326519.66
Nelson	Susan	San Rafael	USA	236769.39
Young	Jeff	NYC	USA	72370.09
Ferguson	Peter	Melbourne	Australia	70311.07
Labrune	Janine	Nantes	France	60875.30

--------Least engaged customers----------

contactLastName--contactFirstName--city--country--profit
Young	Mary	Glendale	USA	2610.87
Taylor	Leslie	Brickhaven	USA	6586.02
Ricotti	Franco	Milan	Italy	9532.93
Schmitt	Carine	Nantes	France	10063.80
Smith	Thomas	London	UK	10868.04

Now that we have the most-important and least-committed customers, we can determine how to drive loyalty and attract more customers.

Question 3: How much can we spend on acquiring new customers?

ltv
39039.594388

LTV tells us how much profit an average customer generates during their lifetime with our store. 
We can use it to predict our future profit. So, if we get ten new customers next month, 
we'll earn 390,395 dollars, and we can decide based on this prediction how much we can spend on acquiring new customers.
  
 