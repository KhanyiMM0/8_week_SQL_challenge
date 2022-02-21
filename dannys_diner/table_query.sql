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

-- 6. Which item was purchased first by the customer after they became a member?
WITH customer_orders_after_joining AS (
  SELECT
	sales.customer_id,
    menu.product_name,
  	join_date,
  	order_date,
    rank() OVER (PARTITION BY sales.customer_id ORDER BY order_date) rank
FROM dannys_diner.menu menu
JOIN dannys_diner.sales sales
	ON menu.product_id = sales.product_id
JOIN dannys_diner.members members
  	ON sales.customer_id = members.customer_id
WHERE sales.order_date >= members.join_date)

SELECT 
  customer_id,
  product_name,
  join_date,
  order_date
FROM customer_orders_after_joining
WHERE rank = 1

-- 7. Which item was purchased just before the customer became a member?
WITH customer_orders_before_joining AS (
  SELECT
	sales.customer_id,
    menu.product_name,
  	join_date,
  	order_date,
    rank() OVER (PARTITION BY sales.customer_id ORDER BY order_date) rank
FROM dannys_diner.menu menu
JOIN dannys_diner.sales sales
	ON menu.product_id = sales.product_id
JOIN dannys_diner.members members
  	ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date)

SELECT
  customer_id,
  product_name,
  join_date,
  order_date
FROM customer_orders_before_joining
WHERE rank = 1

-- 8. What is the total items and amount spent for each member before they became a member?
WITH items_bought_and_amount_before_memebership AS (
  SELECT
	sales.customer_id,
    menu.product_name,
  	join_date,
  	order_date,
  	price
FROM dannys_diner.menu menu
JOIN dannys_diner.sales sales
	ON menu.product_id = sales.product_id
JOIN dannys_diner.members members
  	ON sales.customer_id = members.customer_id
WHERE sales.order_date < members.join_date
ORDER BY sales.customer_id)

SELECT
  customer_id,
  COUNT(product_name) total_items,
  SUM(price) total_amount
FROM items_bought_and_amount_before_memebership
GROUP BY 1

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_per_item AS (
  SELECT
  	customer_id,
    product_name,
  	price,
  	(CASE
    	WHEN product_name = 'sushi' THEN price * 20
     	ELSE price * 10
        END) AS points
  FROM dannys_diner.menu menu
  JOIN dannys_diner.sales	sales
	ON menu.product_id = sales.product_id)

SELECT
    customer_id,
    SUM(points) total_points
FROM points_per_item
GROUP BY 1
ORDER BY 1

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Bonus Questions --
--Join All The Things
--The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.

--Recreate the following table output using the available data:

-- customer_id	order_date	product_name	price	member
-- A	2021-01-01	curry	15	N
-- A	2021-01-01	sushi	10	N
-- A	2021-01-07	curry	15	Y
-- A	2021-01-10	ramen	12	Y
-- A	2021-01-11	ramen	12	Y
-- A	2021-01-11	ramen	12	Y
-- B	2021-01-01	curry	15	N
-- B	2021-01-02	curry	15	N
-- B	2021-01-04	sushi	10	N
-- B	2021-01-11	sushi	10	Y
-- B	2021-01-16	ramen	12	Y
-- B	2021-02-01	ramen	12	Y
-- C	2021-01-01	ramen	12	N
-- C	2021-01-01	ramen	12	N
-- C	2021-01-07	ramen	12	N

SELECT
	sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
	CASE
    	WHEN order_date < join_date THEN 'N'
        WHEN order_date >= join_date THEN 'Y'
        ELSE 'N'
        END AS membership
FROM dannys_diner.sales sales
LEFT JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
LEFT JOIN dannys_diner.members 
	ON sales.customer_id = members.customer_id
ORDER BY 1, 2

-- Rank All The Things --
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

-- customer_id	order_date	product_name	price	member	ranking
-- A	2021-01-01	curry	15	N	null
-- A	2021-01-01	sushi	10	N	null
-- A	2021-01-07	curry	15	Y	1
-- A	2021-01-10	ramen	12	Y	2
-- A	2021-01-11	ramen	12	Y	3
-- A	2021-01-11	ramen	12	Y	3
-- B	2021-01-01	curry	15	N	null
-- B	2021-01-02	curry	15	N	null
-- B	2021-01-04	sushi	10	N	null
-- B	2021-01-11	sushi	10	Y	1
-- B	2021-01-16	ramen	12	Y	2
-- B	2021-02-01	ramen	12	Y	3
-- C	2021-01-01	ramen	12	N	null
-- C	2021-01-01	ramen	12	N	null
-- C	2021-01-07	ramen	12	N	null

WITH membership_status AS(
  SELECT
	sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
	CASE
    	WHEN order_date < join_date THEN 'N'
        WHEN order_date >= join_date THEN 'Y'
        ELSE 'N'
        END AS member
FROM dannys_diner.sales sales
LEFT JOIN dannys_diner.menu
	on sales.product_id = menu.product_id
LEFT JOIN dannys_diner.members 
	ON sales.customer_id = members.customer_id)

SELECT 
	*,
    CASE
    	WHEN member = 'N' THEN NULL
        ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
     END AS rankings
FROM membership_status