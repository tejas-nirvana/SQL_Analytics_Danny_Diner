----------------------------------
-- CASE STUDY #1: DANNY'S DINER --
----------------------------------

-- Author: Tejas Chaudhari
-- Date: 20/04/2023
-- Tool used: MySQL Server
---------------------------------
-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS total_sales 
FROM sales JOIN menu 
USING (product_id)
GROUP BY customer_id
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id,COUNT(DISTINCT order_date) AS visit_count 
FROM SALES 
GROUP BY customer_id; 

-- 3. What was the first item from the menu purchased by each customer?
WITH cte1 AS (
		SELECT customer_id, product_name, order_date,
		ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS item_rank
		FROM sales 
        JOIN menu USING (product_id))
SELECT * FROM cte1 WHERE item_rank=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?    
SELECT product_name,COUNT(product_name) AS most_purchased_item 
FROM sales 
JOIN menu USING (product_id)
GROUP BY product_name 
ORDER BY most_purchased_item DESC LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH cte1 AS(
		SELECT customer_id,product_name,
        COUNT(product_name) AS number_of_times_purchased,
		DENSE_RANK() OVER(PARTITION BY customer_id
		ORDER BY COUNT(product_name) DESC) AS rank_num
		FROM sales JOIN menu USING (product_id)
		GROUP BY customer_id,product_name)
SELECT * FROM CTE1 WHERE rank_num = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH cte1 AS(
	SELECT product_name,s.customer_id,order_date,join_date,me.product_id,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS item_rank
	FROM sales s 
    JOIN members m USING (customer_id) 
	JOIN menu me USING (product_id) 
    WHERE order_date>=join_date)
SELECT customer_id, product_name, order_date FROM cte1 WHERE item_rank=1;

-- 7. Which item was purchased just before the customer became a member?
WITH product_before_member AS(
		SELECT product_name, s.customer_id, order_date, join_date, m.product_id,
		DENSE_RANK() OVER(PARTITION BY s.customer_id
		ORDER BY s.order_date DESC) AS item_rank
		FROM menu m 
        JOIN sales s USING (product_id)
		JOIN members me USING (customer_id)
		WHERE order_date < join_date )
SELECT customer_id, product_name, order_date, join_date
FROM product_before_member WHERE item_rank=1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, 
	 COUNT(product_name) AS total_items, 
     SUM(price) AS amount_spent
FROM menu m
JOIN sales s USING (product_id)
JOIN members me USING (customer_id)
WHERE order_date < join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, 
		SUM(CASE
               WHEN product_name = 'sushi' THEN price*20
               ELSE price*10
		END) AS customer_points
FROM menu m JOIN sales s USING (product_id)
GROUP BY customer_id ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH cte1 AS(
		  SELECT join_date, DATE_ADD(join_date, INTERVAL 7 DAY) AS program_last_date,
          customer_id FROM members)
SELECT s.customer_id,
       SUM(CASE
               WHEN order_date BETWEEN join_date AND program_last_date THEN price*20
               WHEN order_date NOT BETWEEN join_date AND program_last_date 
					AND product_name = 'sushi' THEN price*20
               WHEN order_date NOT BETWEEN join_date AND program_last_date
                    AND product_name != 'sushi' THEN price*10
           END) AS customer_points
FROM menu m JOIN sales s USING (product_id)
JOIN cte1 ON cte1.customer_id = s.customer_id
AND order_date<='2021-01-31' AND order_date >=join_date
GROUP BY s.customer_id ORDER BY s.customer_id;

-- BONUS QUESTION JOIN ALL THINGS
SELECT customer_id,order_date,product_name,price,
	CASE WHEN join_date IS NULL THEN 'N'
		 WHEN join_date > order_date THEN 'N'
         ELSE 'Y'
	END AS member
FROM menu m
LEFT JOIN sales s USING (product_id)
LEFT JOIN members me USING (customer_id)
ORDER BY customer_id, order_date;

-- BONUS QUESTION RANK ALL THE THINGS
WITH cte1 AS(SELECT customer_id,order_date,product_name,price,
	CASE WHEN join_date IS NULL THEN 'N'
		 WHEN join_date > order_date THEN 'N'
         ELSE 'Y'
	END AS member
FROM menu m
LEFT JOIN sales s USING (product_id)
LEFT JOIN members me USING (customer_id)
ORDER BY customer_id, order_date)
SELECT *, 
	CASE WHEN member != 'N' THEN 
		DENSE_RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)
        ELSE NULL
	END AS ranklist
FROM cte1;