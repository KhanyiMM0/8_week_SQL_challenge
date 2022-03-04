--- clean data ---

-- Customer orders table:
-- Exclusions - Replace empty cells and NULL values with empty string
-- Extras - Replace empty cells and NULL values with empty string

UPDATE pizza_runner.customer_orders
SET exclusions = CASE
    WHEN exclusions = 'null' THEN NULL
    ELSE exclusions
END,
extras = CASE
    WHEN extras = 'null' THEN NULL
    ELSE extras
END;

-- Runner orders table:
-- Pickup time - Replace 'null' with NULL values
-- Distance - Replace 'null' with NULL values, remove the 'km' from each distance
-- Duration - Replace 'null' with NULL values, remove 'mins', 'minute' and 'minutes'
-- Cancellation - Replace 'null' with NULL values

UPDATE pizza_runner.runner_orders
SET pickup_time = CASE
	WHEN pickup_time = 'null' THEN NULL
    ELSE pickup_time
END,
distance = CASE
     WHEN distance = 'null' THEN NULL
     WHEN distance ilike '%km' THEN trim('km' FROM distance)
     ELSE distance
END,
duration = CASE
      WHEN duration = 'null' THEN NULL
      WHEN duration ilike '%mins' THEN trim('mins' FROM duration)
      WHEN duration ilike '%minute' THEN trim('minute' FROM duration)
      WHEN duration ilike '%minutes' THEN trim('minutes' FROM duration)
      ELSE duration
END,
cancellation = CASE
      WHEN cancellation = 'null' THEN NULL
      ELSE cancellation
END;

-- Converting data types:
-- Pickup time - DATE
-- Distance - DOUBLE PRECISION
-- Duration - INTEGER
ALTER TABLE pizza_runner.runner_orders
ALTER COLUMN pickup_time TYPE TIMESTAMP USING (pickup_time::TIMESTAMP),
ALTER COLUMN distance TYPE DOUBLE PRECISION USING (distance::DOUBLE PRECISION), 
ALTER COLUMN duration TYPE INTEGER USING (duration::INTEGER);

----------- QUESTIONS ------------------

----------- A. Pizza Metrics ------------------


-- 1. How many pizzas were ordered?
SELECT 
	COUNT(*) total_orders
FROM pizza_runner.customer_orders;

-- 2. How many unique customer orders were made?
SELECT
	COUNT(DISTINCT customer_id) total_unique_orders
FROM pizza_runner.customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT
	runner_id,
    COUNT(*) total_successful_orders
FROM pizza_runner.runner_orders
WHERE distance IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- 4. How many of each type of pizza was delivered?
SELECT
    p.pizza_name,
    COUNT(p.pizza_id) delivered_order_count
FROM pizza_runner.pizza_names p
JOIN pizza_runner.customer_orders c
	ON p.pizza_id = c.pizza_id
JOIN pizza_runner.runner_orders R
	ON c.order_id = R.order_id
WHERE distance IS NOT NULL
GROUP BY 1;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT
    c.customer_id,
    p.pizza_name,
    COUNT(p.pizza_name) order_count
FROM pizza_runner.customer_orders c
JOIN pizza_runner.pizza_names p
 ON c.pizza_id = p.pizza_id
GROUP BY 1, 2
ORDER BY 1;

-- 6. What was the maximum number of pizzas delivered in a single order?
WITH delivered_orders AS(
  SELECT
  	c.order_id,
  	COUNT(c.pizza_id) total_orders
 FROM pizza_runner.customer_orders c
 JOIN pizza_runner.runner_orders r
  	ON c.order_id = r.order_id
 WHERE r.distance IS NOT NULL
 GROUP BY c.order_id
 ORDER BY 1)
 
SELECT MAX(total_orders) highest_total_order
FROM delivered_orders;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
    c.customer_id,
    SUM(
        CASE 
            WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 1
            ELSE 0
        END) single_change,
    SUM(
        CASE 
            WHEN c.exclusions = '' AND c.extras = '' THEN 1 
            ELSE 0
        END) no_changes
FROM pizza_runner.customer_orders c
JOIN pizza_runner.runner_orders r
 ON c.order_id = r.order_id
WHERE r.distance != 0
GROUP BY 1
ORDER BY 1;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT  
 SUM(
   CASE
  	WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1
  	ELSE 0
  END) total_pizza_with_changes
FROM pizza_runner.customer_orders c
JOIN pizza_runner.runner_orders r
 ON c.order_id = r.order_id
WHERE r.distance IS NOT NULL AND exclusions != '' AND extras != '';

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT
	DATE_PART('hour', order_time) hour_of_day,
    COUNT(*) total_orders
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 1

-- 10. What was the volume of orders for each day of the week?
SELECT
	TO_CHAR(order_time, 'Dy') day_of_week,
    COUNT(*) total_orders
FROM pizza_runner.customer_orders
GROUP BY 1
ORDER BY 2

----------- A. Runner and Customer Experience ------------------

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT
	TO_CHAR(registration_date, 'WW')::INTEGER registration_week,
	COUNT(*) total_registered_runners
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select
	runner_id,
    ROUND(AVG(EXTRACT('minute' FROM pickup_time)),1) average_pickup_time
from pizza_runner.runner_orders
GROUP BY 1
ORDER BY 2

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- 4. What was the average distance travelled for each customer?
-- 5. What was the difference between the longest and shortest delivery times for all orders?
-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
-- 7. What is the successful delivery percentage for each runner?