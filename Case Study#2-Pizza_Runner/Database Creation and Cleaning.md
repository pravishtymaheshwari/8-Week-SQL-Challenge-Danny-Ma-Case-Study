## Database Tables
**runners**
```sql
DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');
```
**customer_orders**
```sql
DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" datetime
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');
```
**runner_orders**
```sql
DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');
```
**pizza_names**
```sql
DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');
```

**pizza_recipes**
```sql
DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');
```
**pizza_toppings**
```sql
DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
```

## DATA CLEANING 

**customer_orders : replace all the values which are blank/'null' by NULL in the exclusions and extras columns.**
```sql
select 
order_id, 
customer_id,
pizza_id, 
case when exclusions in ('null','') then NULL else exclusions end as exclusions,
case when extras in ('null','') then NULL else extras end as extras,
order_time 
into customer_orders_cleaned
from customer_orders;
```

| order_id | customer_id | pizza_id | exclusions | extras | order_time            |
|--------- |------------ |--------- |------------ |------- |---------------------- |
| 1        | 101         | 1        | NULL       | NULL   | 2020-01-01 18:05:02.000 |
| 2        | 101         | 1        | NULL       | NULL   | 2020-01-01 19:00:52.000 |
| 3        | 102         | 1        | NULL       | NULL   | 2020-01-02 23:51:23.000 |
| 3        | 102         | 2        | NULL       | NULL   | 2020-01-02 23:51:23.000 |
| 4        | 103         | 1        | 4          | NULL   | 2020-01-04 13:23:46.000 |
| 4        | 103         | 1        | 4          | NULL   | 2020-01-04 13:23:46.000 |
| 4        | 103         | 2        | 4          | NULL   | 2020-01-04 13:23:46.000 |
| 5        | 104         | 1        | NULL       | 1      | 2020-01-08 21:00:29.000 |
| 6        | 101         | 2        | NULL       | NULL   | 2020-01-08 21:03:13.000 |
| 7        | 105         | 2        | NULL       | 1      | 2020-01-08 21:20:29.000 |
| 8        | 102         | 1        | NULL       | NULL   | 2020-01-09 23:54:33.000 |
| 9        | 103         | 1        | 4          | 1, 5   | 2020-01-10 11:22:59.000 |
| 10       | 104         | 1        | NULL       | NULL   | 2020-01-11 18:34:49.000 |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2020-01-11 18:34:49.000 | 

**runners_orders: replace all the values which are blank/null by NULL in the distance, cancellation,pickup and distance columns; eliminate the unnecessary information from the distance and duration columns such as km and minutes.** 
```sql
select 
order_id,
runner_id,
case when pickup_time = 'null' then NULL else pickup_time end as pickup_time,
case when distance = 'null' then NULL else replace(distance,'km','') end as distance,
case when duration = 'null' then NULL else substring(duration, 1,2) end as duration,
case when cancellation in ('null','') then NULL else cancellation end as cancellation
into runner_orders_cleaned
from runner_orders;
 ```
| order_id | runner_id | pickup_time            | distance | duration | cancellation            |
|--------- |---------- |------------------------ |--------- |--------- |------------------------- |
| 1        | 1         | 2020-01-01 18:15:34.000 | 20       | 32       | NULL                    |
| 2        | 1         | 2020-01-01 19:10:54.000 | 20       | 27       | NULL                    |
| 3        | 1         | 2020-01-03 00:12:37.000 | 13.4     | 20       | NULL                    |
| 4        | 2         | 2020-01-04 13:53:03.000 | 23.4     | 40       | NULL                    |
| 5        | 3         | 2020-01-08 21:10:57.000 | 10       | 15       | NULL                    |
| 6        | 3         | NULL                   | NULL     | NULL     | Restaurant Cancellation |
| 7        | 2         | 2020-01-08 21:30:45.000 | 25       | 25       | NULL                    |
| 8        | 2         | 2020-01-10 00:15:02.000 | 23.4     | 15       | NULL                    |
| 9        | 2         | NULL                   | NULL     | NULL     | Customer Cancellation   |
| 10       | 1         | 2020-01-11 18:50:20.000 | 10       | 10       | NULL                    |

**Separating the comma separated columns in pizza_recipes table to individual rows for easy analysis**
```sql
DROP TABLE IF EXISTS pizza_recipes_modified;
select pizza_id,value as topping_id
into pizza_recipes_modified
from pizza_recipes
cross apply string_split(toppings,',');
```
| pizza_id | topping_id |
|--------- |------------ |
| 1        | 1           |
| 1        | 2           |
| 1        | 3           |
| 1        | 4           |
| 1        | 5           |
| 1        | 6           |
| 1        | 8           |
| 1        | 10          |
| 2        | 4           |
| 2        | 6           |
| 2        | 7           |
| 2        | 9           |
| 2        | 11          |
| 2        | 12          |

**extras table**
```sql
drop table if exists extras
select order_id,pizza_id,value as extra_topping ,topping_name
into extras 
from customer_orders_cleaned
cross apply string_split(extras,',')
inner join pizza_toppings as pt on pt.topping_id = value
```

| order_id | pizza_id | extra_topping | topping_name |
|--------- |--------- |-------------- |------------- |
| 5        | 1        | 1             | Bacon        |
| 7        | 2        | 1             | Bacon        |
| 9        | 1        | 1             | Bacon        |
| 9        | 1        | 5             | Chicken      |
| 10       | 1        | 1             | Bacon        |
| 10       | 1        | 4             | Cheese       |

**exclusions table**
```sql
drop table if exists exclusions
select order_id,pizza_id,value as exclusion_topping,topping_name
into exclusions
from customer_orders_cleaned
cross apply string_split(exclusions,',')
inner join pizza_toppings as pt on pt.topping_id = value
```
| order_id | pizza_id | exclusion_topping | topping_name |
|--------- |--------- |------------------ |------------- |
| 4        | 1        | 4                | Cheese       |
| 4        | 1        | 4                | Cheese       |
| 4        | 2        | 4                | Cheese       |
| 9        | 1        | 4                | Cheese       |
| 10       | 1        | 2                | BBQ Sauce    |
| 10       | 1        | 6                | Mushrooms    |


**Now change the datatype of distance to float, duration to integer, pickup_time to datetime and pizza_name to varchar since text datatypes cannot be grouped/sorted**

```sql
alter table runner_orders_cleaned
alter column distance float;

alter table runner_orders_cleaned
alter column duration int;

alter table runner_orders_cleaned
alter column pickup_time datetime;

alter table pizza_names
alter column pizza_name varchar(10);

alter table pizza_toppings
alter column topping_name varchar(40);

alter table pizza_recipes
alter column toppings varchar(30);
```



