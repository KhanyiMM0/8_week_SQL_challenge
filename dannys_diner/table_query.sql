/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	sales.customer_id, sum(menu.price) total_amount_spent
FROM dannys_diner.sales sales
JOIN dannys_diner.menu menu
	on sales.product_id = menu.product_id
GROUP BY 1
ORDER BY 1

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id, COUNT(DISTINCT order_date) number_of_days_visited
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 1

-- 3. What was the first item from the menu purchased by each customer?
WITH ranked_orders AS (
  SELECT
	sales.customer_id,
    menu.product_name,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, menu.product_id) RANK
  FROM dannys_diner.sales sales
  JOIN dannys_diner.menu menu
  	ON sales.product_id = menu.product_id)

 SELECT 
	customer_id,
    product_name
FROM ranked_orders
WHERE RANK = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
	menu.product_name,
    COUNT(s.product_id) number_of_times_purchased
FROM dannys_diner.menu menu
JOIN dannys_diner.sales sales
 	ON menu.product_id = sales.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

-- 5. Which item was the most popular for each customer?
WITH items_per_customer as (
  SELECT 
  	sales.customer_id,
  	menu.product_name,
  	COUNT(s.product_id) number_of_times_purchased,
  	Rank() OVER (PARTITION BY s.customer_id ORDER BY COUNT(sales.product_id) DESC) rank
  FROM dannys_diner.menu menu
  JOIN dannys_diner.sales sales
  	ON menu.product_id = sales.product_id
    GROUP BY 1,2)

SELECT 
	customer_id,
    product_name
FROM items_per_customer
WHERE RANK = 1