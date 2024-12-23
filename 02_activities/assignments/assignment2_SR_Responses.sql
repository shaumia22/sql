Prompt 3
The store wants to keep customer addresses. Propose two architectures for the CUSTOMER_ADDRESS table, one that will retain changes, and another that will overwrite. Which is type 1, which is type 2?

HINT: search type 1 vs type 2 slowly changing dimensions.

Type 1 will overwrite the existing address when new data is inputted.
Type 2 will add a new row when a new address is inputted for an existing customer.

Section 2:
You can start this section following session 4.

Steps to complete this part of the assignment:

Open the assignment2.sql file in DB Browser for SQLite:
from Github
or, from your local forked repository
Complete each question
Write SQL
COALESCE
Our favourite manager wants a detailed long list of products, but is afraid of tables! We tell them, no problem! We can produce a list with all of the appropriate details.
Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || coalesce(product_size, '')|| ' (' || coalesce(product_qty_type, 'unit') || ')'
FROM product
But wait! The product table has some bad data (a few NULL values). Find the NULLs and then using COALESCE, replace the NULL with a blank for the first problem, and 'unit' for the second problem.

HINT: keep the syntax the same, but edited the correct components with the string. The || values concatenate the columns into strings. Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. All the other rows will remain the same.

-
Windowed Functions
Write a query that selects from the customer_purchases table and numbers each customer’s visits to the farmer’s market (labeling each market date with a different number). Each customer’s first visit is labeled 1, second visit is labeled 2, etc.
You can either display all rows in the customer_purchases table, with the counter changing on each new market date for each customer, or select only the unique market dates per customer (without purchase details) and number those visits.

HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK().

SELECT *
,row_number() OVER (PARTITION BY customer_id) as [row_number]
FROM customer_purchases


Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, then write another query that uses this one as a subquery (or temp table) and filters the results to only the customer’s most recent visit.

SELECT *
,row_number() OVER (PARTITION BY customer_id ORDER BY market_date DESC, transaction_time DESC) as row_number
FROM customer_purchases

CREATE TEMP TABLE customer_rankedbymarketdate AS

SELECT *
,row_number() OVER (PARTITION BY customer_id ORDER BY market_date DESC, transaction_time DESC) as row_number
FROM customer_purchases

SELECT *
FROM customer_rankedbymarketdate
WHERE row_number = 1
GROUP by customer_id

Using a COUNT() window function, include a value along with each row of the customer_purchases table that indicates how many different times that customer has purchased that product_id.



SELECT product_id, customer_id
,COUNT(product_id) AS product_id_count
FROM customer_purchases
GROUP by customer_id, product_id


-
String manipulations
Some product names in the product table have descriptions like "Jar" or "Organic". These are separated from the product name with a hyphen. Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. Remove any trailing or leading whitespaces. Don't just use a case statement for each product!
product_name	description
Habanero Peppers - Organic	Organic
HINT: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column.

SELECT *
,CASE 
	WHEN instr(product_name,'-') > 0
	THEN RTRIM(LTRIM(substr(product_name,INSTR(product_name,'-')+1)))
	ELSE NULL
	END as newcolumn
FROM product;

-
UNION
Using a UNION, write a query that displays the market dates with the highest and lowest total sales.
HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 1) Create a CTE/Temp Table to find sales values grouped dates; 2) Create another CTE/Temp table with a rank windowed function on the previous query to create "best day" and "worst day"; 3) Query the second temp table twice, once for the best day, once for the worst day, with a UNION binding them.

CREATE TEMP TABLE total_sales AS


SELECT *
,SUM(quantity*cost_to_customer_per_qty) as total_sales
FROM customer_purchases
GROUP BY market_date




WITH RankedSalesTop AS (
	SELECT *
	,row_number() OVER (ORDER by total_sales DESC) as row_number_top
	FROM total_sales
)
,RankedSalesLast AS (
	SELECT *
	,row_number() OVER (ORDER by total_sales ASC) as row_number_last
	FROM total_sales
)
SELECT *
FROM RankedSalestop
WHERE row_number_top = 1

UNION ALL
SELECT * 
FROM RankedSaleslast
WHERE row_number_last = 1

Section 3:
You can start this section following session 5.

Steps to complete this part of the assignment:

Open the assignment2.sql file in DB Browser for SQLite:
from Github
or, from your local forked repository
Complete each question
Write SQL
Cross Join
Suppose every vendor in the vendor_inventory table had 5 of each of their products to sell to every customer on record. How much money would each vendor make per product? Show this by vendor_name and product name, rather than using the IDs.
HINT: Be sure you select only relevant columns and rows. Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. Think a bit about the row counts: how many distinct vendors, product names are there (x)? How many customers are there (y). Before your final group by you should have the product of those two queries (x*y).

SELECT DISTINCT
	vendor_id,
	product.product_id,
	product_name
FROM vendor_inventory
INNER JOIN product
ON product.product_id = vendor_inventory.product_id
CROSS JOIN customer


-
INSERT
Create a new table "product_units". This table will contain only products where the product_qty_type = 'unit'. It should use all of the columns from the product table, as well as a new column for the CURRENT_TIMESTAMP. Name the timestamp column snapshot_timestamp.

Using INSERT, add a new row to the product_unit table (with an updated timestamp). This can be any product you desire (e.g. add another record for Apple Pie).

CREATE TEMP TABLE product_units AS

SELECT *
FROM product
WHERE product_qty_type = 'unit'

ALTER TABLE product_units
ADD snapshot_timestamp timestamp


INSERT INTO product_units
VALUES(100, 'Gingerbread', '1.4 lbs', 200, 'unit', '2022-04-22 12:30:57')
-
DELETE
Delete the older record for the whatever product you added.
HINT: If you don't specify a WHERE clause, you are going to have a bad time.

DELETE FROM product_units
WHERE product_id = 100

-
UPDATE
We want to add the current_quantity to the product_units table. First, add a new column, current_quantity to the table using the following syntax.
ALTER TABLE product_units
ADD current_quantity INT;
Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. First, determine how to get the "last" quantity per product. Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. Finally, make sure you have a WHERE statement to update the right row, you'll need to use product_units.product_id to refer to the correct row within the product_units table. When you have all of these components, you can run the update statement.


WITH LastQuantity AS (
	SELECT vendor_id
	,quantity
FROM (
	SELECT *
	,row_number() OVER (PARTITION by market_date ORDER BY quantity ASC) AS rank
	FROM
	vendor_inventory)

WHERE rank = 1