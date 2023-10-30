
## A. Pizza Metrics

**1. How many pizzas were ordered?**
```sql
select count(1) as total_pizzas
from customer_orders_cleaned;
```

**2. How many unique customer orders were made?**
```sql
with cte as(
select distinct customer_id, pizza_id from customer_orders_cleaned)
select count(1) as unique_customer_orders
from cte;
```

** 3. How many successful orders were delivered by each runner?**
```sql
select runner_id, count(order_id) as delivered_orders
from runner_orders_cleaned
where cancellation is null
group by runner_id;
```

**4. How many of each type of pizza was delivered?**
```sql
select cc.pizza_id,pn.pizza_name,count(rc.order_id) as total_pizzas
from runner_orders_cleaned as rc
inner join customer_orders_cleaned as cc on rc.order_id = cc.order_id
inner join pizza_names as pn on cc.pizza_id = pn.pizza_id
where cancellation is null
group by cc.pizza_id,pn.pizza_name;
```

**5. How many Vegetarian and Meatlovers were ordered by each customer?**
```sql
select customer_id,
sum(case when lower(pizza_name) = 'vegetarian' then 1 else 0 end) as vegeterian_pizza,
sum(case when lower(pizza_name) = 'meatlovers' then 1 else 0 end) as meatlovers_pizza
from customer_orders_cleaned as cc
inner join pizza_names as pn on cc.pizza_id = pn.pizza_id
group by customer_id;
```

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

**8. How many pizzas were delivered that had both exclusions and extras?**
```sql
select count(pizza_id) as total_pizzas
from customer_orders_cleaned as cc
inner join runner_orders_cleaned as rc on cc.order_id = rc.order_id
where cancellation is null and exclusions is not null and extras is not null;
```

**9. What was the total volume of pizzas ordered for each hour of the day?**
```sql
select datepart(hour,order_time) as hour_of_the_day, count(pizza_id) as total_pizzas
from customer_orders_cleaned
group by datepart(hour,order_time)
order by hour_of_the_day;
```

**10. What was the volume of orders for each day of the week?**
```sql
select datepart(weekday,order_time) as day_of_the_week, count(order_id) as total_orders
from customer_orders_cleaned
group by datepart(weekday,order_time)
order by day_of_the_week;
```


## B. Runner and Customer Experience


**1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)**
```sql
set datefirst 1;
select datepart(week, registration_date) as week, count(runner_id) as total_runners
from runners
group by datepart(week, registration_date);
```

**2. What was the average time in minutes it took for each runner to arrive at the PizzaRunner HQ to pickup the order?**
```sql
select runner_id, cast(round(avg(1.0*duration), 2) as varchar) + ' mins'  as avg_pickup_time
from runner_orders_cleaned
group by runner_id;
```

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

**4. What was the average distance travelled for each customer?**
```sql
select customer_id, cast(round(avg(distance),2) as varchar) + ' km' as average_distance 
from customer_orders_cleaned as cc
inner join runner_orders_cleaned as rc on cc.order_id=rc.order_id
where cancellation is null
group by customer_id;
```

**5. What was the difference between the longest and shortest delivery times for all orders?**
```sql
select order_id, dateadd(minute,duration, pickup_time) as delivery_time
from runner_orders_cleaned
where cancellation is null;
```

**6. What was the average speed for each runner for each delivery and do you notice any trend for these values?**
```sql
select runner_id , cast(round(avg(distance/duration),2) as varchar) + ' km/min' as average_speed
from runner_orders_cleaned
group by runner_id;
```

**7. What is the successful delivery percentage for each runner?**
```sql
select runner_id,
round(100.0*count(case when cancellation is null then order_id else null end)/count(order_id),2) as succesful_delivery_percent
from runner_orders_cleaned
group by runner_id;
```

## C. Ingredient Optimisation

**1. What are the standard ingredients for each pizza?**
```sql
select pr.pizza_id,pizza_name,string_agg(topping_name,',') as toppings
from pizza_recipes_modified pr
inner join pizza_toppings as pt on pr.topping_id = pt.topping_id
inner join pizza_names as pn on pn.pizza_id = pr. pizza_id
group by pr.pizza_id,pizza_name;
```

**2. What was the most commonly added extra?**
```sql
with cte as(
select extra_topping, topping_name,count(extra_topping) as frequency, dense_rank()over(order by count(extra_topping) desc) as drnk
from extras e 
group by extra_topping,topping_name)
select topping_name, frequency from cte 
where drnk =1;
```

**3. What was the most common exclusion?**
```sql
with cte as(
select exclusion_topping, topping_name,count(exclusion_topping) as frequency, dense_rank()over(order by count(exclusion_topping) desc) as drnk
from exclusions e 
group by exclusion_topping,topping_name)
select topping_name, frequency from cte 
where drnk =1;
```

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


**3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset? generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.**
```sql
drop table if exists runner_ratings
create table runner_ratings(id int,customer_id int,order_id int,runner_id int, ratings int check(ratings >=1 and ratings<=5));
insert into runner_ratings values(1,101,1,1,5),(2,101,2,1,5),(3,102,3,1,3),(4,103,4,2,4),(5,104,5,3,4),(6,105,7,2,4),(7,102,8,2,5),(9,104,10,1,3);
```

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

 ## Bonus Questions
**If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?**
```sql
insert into pizza_names values(3,'Supreme');
select * from pizza_names;
```
```sql
insert into pizza_recipes_modified values(3,1),(3,2),(3,3),(3,4),(3,5),(3,6),(3,7),(3,8),(3,9),(3,10),(3,11),(3,12);
select * from pizza_recipes_modified;
```



