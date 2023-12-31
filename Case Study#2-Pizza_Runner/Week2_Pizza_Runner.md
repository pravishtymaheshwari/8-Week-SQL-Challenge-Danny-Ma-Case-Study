
## A. Pizza Metrics

**1. How many pizzas were ordered?**
```sql
select count(1) as total_pizzas
from customer_orders_cleaned;
```
| Total Pizzas |
|--------------|
| 14           |

**2. How many unique customer orders were made?**
```sql
with cte as(
select distinct customer_id, pizza_id from customer_orders_cleaned)
select count(1) as unique_customer_orders
from cte;
```
| Unique Customer Orders |
|------------------------|
| 8                      |

** 3. How many successful orders were delivered by each runner?**
```sql
select runner_id, count(order_id) as delivered_orders
from runner_orders_cleaned
where cancellation is null
group by runner_id;
```
| runner_id | delivered_orders |
|-----------|------------------|
| 1         | 4                |
| 2         | 3                |
| 3         | 1                |

**4. How many of each type of pizza was delivered?**
```sql
select cc.pizza_id,pn.pizza_name,count(rc.order_id) as total_pizzas
from runner_orders_cleaned as rc
inner join customer_orders_cleaned as cc on rc.order_id = cc.order_id
inner join pizza_names as pn on cc.pizza_id = pn.pizza_id
where cancellation is null
group by cc.pizza_id,pn.pizza_name;
```
| pizza_id | pizza_name   | total_pizzas |
|----------|--------------|--------------|
| 1        | Meatlovers   | 9            |
| 2        | Vegetarian   | 3            |

**5. How many Vegetarian and Meatlovers were ordered by each customer?**
```sql
select customer_id,
sum(case when lower(pizza_name) = 'vegetarian' then 1 else 0 end) as vegeterian_pizza,
sum(case when lower(pizza_name) = 'meatlovers' then 1 else 0 end) as meatlovers_pizza
from customer_orders_cleaned as cc
inner join pizza_names as pn on cc.pizza_id = pn.pizza_id
group by customer_id;
```
| customer_id | vegetarian_pizza | meatlovers_pizza |
|------------|------------------|------------------|
| 101        | 1                | 2                |
| 102        | 1                | 2                |
| 103        | 1                | 3                |
| 104        | 0                | 3                |
| 105        | 1                | 0                |

**6. What was the maximum number of pizzas delivered in a single order?**
```sql
with cte as (
select order_id, count(pizza_id) as total_pizzas, dense_rank()over(order by count(pizza_id) desc) as drnk
from customer_orders_cleaned 
group by order_id)
select total_pizzas
from cte 
where drnk=1;
```
| total_pizzas |
|--------------|
| 3            |

**7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?**
```sql
select customer_id,
sum(case when exclusions is not null or extras is not null then 1 else 0 end) as pizza_with_changes,
sum(case when exclusions is null and extras is null then 1 else 0 end) as pizza_without_changes
from customer_orders_cleaned as cc
inner join runner_orders_cleaned as rc on cc.order_id = rc.order_id
where cancellation is null
group by customer_id;
```
| customer_id | pizza_with_changes | pizza_without_changes |
|------------|--------------------|-----------------------|
| 101        | 0                  | 2                     |
| 102        | 0                  | 3                     |
| 103        | 3                  | 0                     |
| 104        | 2                  | 1                     |
| 105        | 1                  | 0                     |

**8. How many pizzas were delivered that had both exclusions and extras?**
```sql
select count(pizza_id) as total_pizzas
from customer_orders_cleaned as cc
inner join runner_orders_cleaned as rc on cc.order_id = rc.order_id
where cancellation is null and exclusions is not null and extras is not null;
```
| total_pizzas |
|--------------|
| 1            |

**9. What was the total volume of pizzas ordered for each hour of the day?**
```sql
select datepart(hour,order_time) as hour_of_the_day, count(pizza_id) as total_pizzas
from customer_orders_cleaned
group by datepart(hour,order_time)
order by hour_of_the_day;
```
| hour_of_the_day | total_pizzas |
|-----------------|--------------|
| 11              | 1            |
| 13              | 3            |
| 18              | 3            |
| 19              | 1            |
| 21              | 3            |
| 23              | 3            |

**10. What was the volume of orders for each day of the week?**
```sql
select datepart(weekday,order_time) as day_of_the_week, count(order_id) as total_orders
from customer_orders_cleaned
group by datepart(weekday,order_time)
order by day_of_the_week;
```
| day_of_the_week | total_orders |
|-----------------|--------------|
| 4               | 5            |
| 5               | 3            |
| 6               | 1            |
| 7               | 5            |


## B. Runner and Customer Experience


**1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)**
```sql
set datefirst 1;
select datepart(week, registration_date) as week, count(runner_id) as total_runners
from runners
group by datepart(week, registration_date);
```
| week | total_runners |
|------|--------------|
| 1    | 2            |
| 2    | 1            |
| 3    | 1            |


**2. What was the average time in minutes it took for each runner to arrive at the PizzaRunner HQ to pickup the order?**
```sql
select runner_id, cast(round(avg(1.0*duration), 2) as varchar) + ' mins'  as avg_pickup_time
from runner_orders_cleaned
group by runner_id;
```
| runner_id | avg_pickup_time  |
|-----------|-------------------|
| 1         | 22.250000 mins   |
| 2         | 26.670000 mins   |
| 3         | 15.000000 mins   |

**3. Is there any relationship between the number of pizzas and how long the order takes to prepare?**
```sql
with cte as(
select order_id,order_time, count(pizza_id) as total_pizzas 
from customer_orders_cleaned
group by order_id, order_time)
select cte.order_id, total_pizzas, datediff(MINUTE,order_time,pickup_time) as prep_time
from runner_orders_cleaned as rc
inner join cte on rc.order_id = cte.order_id
where cancellation is null;
```
| order_id | total_pizzas | prep_time |
|----------|--------------|-----------|
| 1        | 1            | 10        |
| 2        | 1            | 10        |
| 3        | 2            | 21        |
| 4        | 3            | 30        |
| 5        | 1            | 10        |
| 7        | 1            | 10        |
| 8        | 1            | 21        |
| 10       | 2            | 16        |

**4. What was the average distance travelled for each customer?**
```sql
select customer_id, cast(round(avg(distance),2) as varchar) + ' km' as average_distance 
from customer_orders_cleaned as cc
inner join runner_orders_cleaned as rc on cc.order_id=rc.order_id
where cancellation is null
group by customer_id;
```
| customer_id | average_distance |
|------------|------------------|
| 101        | 20 km            |
| 102        | 16.73 km         |
| 103        | 23.4 km          |
| 104        | 10 km            |
| 105        | 25 km            |

**5. What was the difference between the longest and shortest delivery times for all orders?**
```sql
select order_id, dateadd(minute,duration, pickup_time) as delivery_time
from runner_orders_cleaned
where cancellation is null;
```

| order_id | delivery_time           |
|--------- |------------------------- |
| 1        | 2020-01-01 18:47:34.000 |
| 2        | 2020-01-01 19:37:54.000 |
| 3        | 2020-01-03 00:32:37.000 |
| 4        | 2020-01-04 14:33:03.000 |
| 5        | 2020-01-08 21:25:57.000 |
| 7        | 2020-01-08 21:55:45.000 |
| 8        | 2020-01-10 00:30:02.000 |
| 10       | 2020-01-11 19:00:20.000 |

**6. What was the average speed for each runner for each delivery and do you notice any trend for these values?**
```sql
select runner_id , cast(round(avg(distance/duration),2) as varchar) + ' km/min' as average_speed
from runner_orders_cleaned
group by runner_id;
```
| runner_id | average_speed   |
|---------  |---------------   |
| 1         | 0.76 km/min     |
| 2         | 1.05 km/min     |
| 3         | 0.67 km/min     |

**7. What is the successful delivery percentage for each runner?**
```sql
select runner_id,
round(100.0*count(case when cancellation is null then order_id else null end)/count(order_id),2) as succesful_delivery_percent
from runner_orders_cleaned
group by runner_id;
```
| runner_id | successful_delivery_percent   |
|---------  |-----------------------------  |
| 1         | 100.000000000000             |
| 2         | 75.000000000000              |
| 3         | 50.000000000000              |

## C. Ingredient Optimisation

**1. What are the standard ingredients for each pizza?**
```sql
select pr.pizza_id,pizza_name,string_agg(topping_name,',') as toppings
from pizza_recipes_modified pr
inner join pizza_toppings as pt on pr.topping_id = pt.topping_id
inner join pizza_names as pn on pn.pizza_id = pr. pizza_id
group by pr.pizza_id,pizza_name;
```
| pizza_id | pizza_name   | toppings                                      |
|---------  |------------  |---------------------------------------------  |
| 1         | Meatlovers   | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2         | Vegetarian   | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce           |


**2. What was the most commonly added extra?**
```sql
with cte as(
select extra_topping, topping_name,count(extra_topping) as frequency, dense_rank()over(order by count(extra_topping) desc) as drnk
from extras e 
group by extra_topping,topping_name)
select topping_name, frequency from cte 
where drnk =1;
```
| topping_name | frequency |
|------------- |----------- |
| Bacon        | 4         |

**3. What was the most common exclusion?**
```sql
with cte as(
select exclusion_topping, topping_name,count(exclusion_topping) as frequency, dense_rank()over(order by count(exclusion_topping) desc) as drnk
from exclusions e 
group by exclusion_topping,topping_name)
select topping_name, frequency from cte 
where drnk =1;
```
| topping_name | frequency |
|------------- |----------- |
| Cheese       | 4         |


**4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers**


**5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients. For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"**


**6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?**


## D. Pricing and Ratings

**1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?**
```sql 
select '$' + cast(sum(case when lower(pizza_name) = 'meatlovers' then 12 else 10 end) as varchar) as total_money_earned
from customer_orders_cleaned as cc 
inner join pizza_names as pn on cc.pizza_id = pn.pizza_id
inner join runner_orders_cleaned as rc on cc. order_id = rc.order_id
where cancellation is null;
```
| total_money_earned |
|------------------ |
| $138             |

**2. What if there was an additional $1 charge for any pizza extras?Add cheese is $1 extra.**
```sql
with cte as(
select cc.order_id,sum(case when lower(pizza_name) = 'meatlovers' then 12 else 10 end) as pizza_charges
from pizza_names as pn
inner join customer_orders_cleaned as cc  on pn.pizza_id = cc.pizza_id
group by order_id)
,cte1 as(select cc.order_id,
sum(case when extra_topping is not null then 1 else 0 end )as topping_charges
from customer_orders_cleaned as cc
left join extras as e on e.order_id = cc.order_id and cc.extras is not null
group by cc.order_id)
select sum(pizza_charges + topping_charges) as total_money_earned
from cte
inner join cte1 on cte.order_id = cte1.order_id;
```
| total_money_earned |
|------------------ |
| $166             |


**3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset? generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.**
```sql
drop table if exists runner_ratings
create table runner_ratings(id int,customer_id int,order_id int,runner_id int, ratings int check(ratings >=1 and ratings<=5));
insert into runner_ratings values(1,101,1,1,5),(2,101,2,1,5),(3,102,3,1,3),(4,103,4,2,4),(5,104,5,3,4),(6,105,7,2,4),(7,102,8,2,5),(9,104,10,1,3);
```
| id | customer_id | order_id | runner_id | ratings |
|----|------------ |--------- |---------- |-------- |
| 1  | 101         | 1        | 1         | 5       |
| 2  | 101         | 2        | 1         | 5       |
| 3  | 102         | 3        | 1         | 3       |
| 4  | 103         | 4        | 2         | 4       |
| 5  | 104         | 5        | 3         | 4       |
| 6  | 105         | 7        | 2         | 4       |
| 7  | 102         | 8        | 2         | 5       |
| 9  | 104         | 10       | 1         | 3       |

**4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?customer_id; order_id; runner_id; rating; order_time; pickup_time; Time between order and pickup; Delivery duration; Average speed; Total number of pizzas**
```sql
select cc.customer_id,cc.order_id,rr.runner_id,ratings,order_time,pickup_time, cast(datediff(minute,order_time,pickup_time) as varchar) + ' mins' as prep_time,
cast(duration as varchar) + ' mins' as duration,cast(round(avg(distance/duration),2) as varchar) + ' km/min' as average_speed,
count(pizza_id) as total_pizza
from customer_orders_cleaned as cc
join runner_ratings as rrs on cc.order_id = rrs.order_id
join runner_orders_cleaned as rr on rr.order_id = cc.order_id
group by cc.order_id,cc.customer_id,rr.runner_id,ratings,order_time,pickup_time,duration
order by cc.customer_id;
```
| customer_id | order_id | runner_id | ratings | order_time             | pickup_time            | prep_time | duration | average_speed | total_pizza |
|------------ |--------- |---------- |-------- |----------------------- |----------------------- |---------- |---------- |-------------- |------------ |
| 101         | 1        | 1         | 5      | 2020-01-01 18:05:02.000 | 2020-01-01 18:15:34.000 | 10 mins  | 32 mins  | 0.63 km/min  | 1          |
| 101         | 2        | 1         | 5      | 2020-01-01 19:00:52.000 | 2020-01-01 19:10:54.000 | 10 mins  | 27 mins  | 0.74 km/min  | 1          |
| 102         | 3        | 1         | 3      | 2020-01-02 23:51:23.000 | 2020-01-03 00:12:37.000 | 21 mins  | 20 mins  | 0.67 km/min  | 2          |
| 102         | 8        | 2         | 5      | 2020-01-09 23:54:33.000 | 2020-01-10 00:15:02.000 | 21 mins  | 15 mins  | 1.56 km/min  | 1          |
| 103         | 4        | 2         | 4      | 2020-01-04 13:23:46.000 | 2020-01-04 13:53:03.000 | 30 mins  | 40 mins  | 0.58 km/min  | 3          |
| 104         | 5        | 3         | 4      | 2020-01-08 21:00:29.000 | 2020-01-08 21:10:57.000 | 10 mins  | 15 mins  | 0.67 km/min  | 1          |
| 104         | 10       | 1         | 3      | 2020-01-11 18:34:49.000 | 2020-01-11 18:50:20.000 | 16 mins  | 10 mins  | 1 km/min     | 2          |
| 105         | 7        | 2         | 4      | 2020-01-08 21:20:29.000 | 2020-01-08 21:30:45.000 | 10 mins  | 25 mins  | 1 km/min     | 1          |

**5.If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?**
```sql
with cte as(
select cc.order_id, sum(case when lower(pizza_name) = 'meatlovers' then 12 else 10 end) as pizza_cost, distance*0.3 as runners_pay
from customer_orders_cleaned as cc
inner join runner_orders_cleaned as rc on cc.order_id = rc.order_id
inner join pizza_names as pn on pn.pizza_id = cc.pizza_id
where cancellation is null
group by cc.order_id,distance)
select sum(pizza_cost - runners_pay) as pizza_runner_profit from cte;
```
| pizza_runner_profit |
|-------------------- |
| $94.44              |

 ## Bonus Questions
**If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?**
```sql
insert into pizza_names values(3,'Supreme');
select * from pizza_names;
```
| pizza_id | pizza_name  |
|--------- |------------ |
| 1        | Meatlovers  |
| 2        | Vegetarian  |
| 3        | Supreme     |

```sql
insert into pizza_recipes_modified values(3,1),(3,2),(3,3),(3,4),(3,5),(3,6),(3,7),(3,8),(3,9),(3,10),(3,11),(3,12);
select * from pizza_recipes_modified;
```
| pizza_id | topping_id |
|--------- |------------ |
| 1        | 1          |
| 1        | 2          |
| 1        | 3          |
| 1        | 4          |
| 1        | 5          |
| 1        | 6          |
| 1        | 8          |
| 1        | 10         |
| 2        | 4          |
| 2        | 6          |
| 2        | 7          |
| 2        | 9          |
| 2        | 11         |
| 2        | 12         |
| 3        | 1          |
| 3        | 2          |
| 3        | 3          |
| 3        | 4          |
| 3        | 5          |
| 3        | 6          |
| 3        | 7          |
| 3        | 8          |
| 3        | 9          |
| 3        | 10         |
| 3        | 11         |
| 3        | 12         |