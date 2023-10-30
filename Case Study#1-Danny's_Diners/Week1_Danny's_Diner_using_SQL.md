
<b>1. What is the total amount each customer spent at the restaurant?</b>
```sql
select sls.customer_id, concat('$',sum(price)) as total_amount_spent 
from members as mem
right join sales as sls on mem.customer_id = sls.customer_id
inner join menu as mnu on mnu.product_id = sls.product_id
group by sls.customer_id;
```

| customer_id | total_amount_spent |
|------------|-------------------|
| A          | $76               |
| B          | $74               |
| C          | $36               |

**2. How many days has each customer visited the restaurant?**
```sql
select customer_id, count(distinct order_date) as total_visits from sales group by customer_id;
```
| customer_id | total_visits |
|------------|-------------|
| A          | 4           |
| B          | 6           |
| C          | 2           |

**3. What was the first item from the menu purchased by each customer?**
```sql
with cte as(
select customer_id, product_name, dense_rank()over(partition by customer_id order by order_date) as dnk
from sales sls join menu as mnu on sls.product_id = mnu.product_id)
select customer_id, string_agg(product_name,',') within group(order by product_name) as product_name from cte where dnk=1
group by customer_id;
```
| customer_id | product_name     |
|------------|------------------|
| A          | curry, sushi     |
| B          | curry            |
| C          | ramen, ramen     |

**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**
```sql
with cte as(
select product_name , count(product_name) as total_count, dense_rank()over(order by count(product_name) desc) as dnk
from menu mnu join sales sls on mnu.product_id = sls.product_id
group by product_name)
select product_name, total_count from cte where dnk=1;
```
| product_name | total_count |
|--------------|------------|
| ramen        | 8          |

**5. Which item was the most popular for each customer?**
```sql
with cte as(
select customer_id, product_name, dense_rank()over(partition by customer_id order by count(product_name) desc) as dnk
from menu mnu join sales sls on mnu.product_id = sls.product_id
group by customer_id, product_name)
select customer_id, string_agg(product_name,',') within group(order by product_name) as product_name from cte where dnk=1
group by customer_id;
```
| customer_id | product_name |
|------------|--------------|
| A          | ramen        |
| B          | curry, ramen, sushi |
| C          | ramen        |

**6. Which item was purchased first by the customer after they became a member?**
```sql
with cte as(
select sls.customer_id, mnu.product_name, dense_rank()over(partition by sls.customer_id order by order_date) as dnk
from members as mem
inner join sales as sls on mem.customer_id = sls.customer_id
inner join menu as mnu on mnu.product_id = sls.product_id
where order_date >= join_date)
select customer_id, string_agg(product_name,',') within group(order by product_name) as product_name from cte where dnk=1
group by customer_id;
```
| customer_id | product_name |
|------------|--------------|
| A          | curry        |
| B          | sushi        |

**7. Which item was purchased just before the customer became a member?**
```sql
with cte as(
select sls.customer_id, mnu.product_name, dense_rank()over(partition by sls.customer_id order by order_date desc) as dnk
from members as mem
inner join sales as sls on mem.customer_id = sls.customer_id
inner join menu as mnu on mnu.product_id = sls.product_id
where order_date < join_date)
select customer_id, string_agg(product_name,',') within group(order by product_name) as product_name from cte where dnk=1
group by customer_id;
```
| customer_id | product_name     |
|------------|------------------|
| A          | curry, sushi     |
| B          | sushi            |

**8. What is the total items and amount spent for each member before they became a member?**
```sql
select sls.customer_id, count(product_name)as total_products, concat('$',sum(price)) as total_spent from members as mem
right join sales as sls on mem.customer_id = sls.customer_id
inner join menu as mnu on mnu.product_id = sls.product_id
where order_date < join_date or join_date is null
group by sls.customer_id;
```

| customer_id | total_products | total_spent |
|------------|---------------|------------|
| A          | 2             | $25        |
| B          | 3             | $40        |
| C          | 3             | $36        |

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**
```sql
select customer_id, sum(case when lower(product_name) ='sushi' then 2*10*price else 10* price end) as total_points
from sales as sls inner join menu as mnu on sls.product_id = mnu.product_id
group by customer_id;
```

| customer_id | total_points |
|------------|--------------|
| A          | 860          |
| B          | 940          |
| C          | 360          |

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**
```sql
select sls.customer_id, 
sum(case 
    when lower(product_name)='sushi' then 2*10*price
	when order_date <= dateadd(day,6,join_date) and order_date >= join_date then 2*10*price else 10*price end) as total_points
from sales as sls inner join menu as mnu on sls.product_id = mnu.product_id
inner join members as mem on mem.customer_id = sls.customer_id
where order_date <= '2021-01-31'
group by sls.customer_id;
```

| customer_id | total_points |
|------------|--------------|
| A          | 1370         |
| B          | 820          |

**Bonus Questions: Recreate the following table output using the available data:**
```sql
select s.customer_id,s.order_date,mu.product_name,mu.price,
case when order_date>=join_date then 'Y' else 'N' end as member
from menu as mu inner join sales as s on s.product_id = mu.product_id
left join members as m on s.customer_id = m.customer_id
order by s.customer_id, s.order_date,mu.product_name; 
```

| customer_id | order_date | product_name | price | member |
|------------|------------|--------------|-------|--------|
| A          | 2021-01-01 | curry        | 15    | N      |
| A          | 2021-01-01 | sushi        | 10    | N      |
| A          | 2021-01-07 | curry        | 15    | Y      |
| A          | 2021-01-10 | ramen        | 12    | Y      |
| A          | 2021-01-11 | ramen        | 12    | Y      |
| A          | 2021-01-11 | ramen        | 12    | Y      |
| B          | 2021-01-01 | curry        | 15    | N      |
| B          | 2021-01-02 | curry        | 15    | N      |
| B          | 2021-01-04 | sushi        | 10    | N      |
| B          | 2021-01-11 | sushi        | 10    | Y      |
| B          | 2021-01-16 | ramen        | 12    | Y      |
| B          | 2021-02-01 | ramen        | 12    | Y      |
| C          | 2021-01-01 | ramen        | 12    | N      |
| C          | 2021-01-01 | ramen        | 12    | N      |
| C          | 2021-01-07 | ramen        | 12    | N      |

**Rank All the Things: Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.**
```sql
with cte as(
select s.customer_id,s.order_date,mu.product_name,mu.price,
case when order_date>=join_date then 'Y' else 'N' end as member
from menu as mu inner join sales as s on s.product_id = mu.product_id
left join members as m on s.customer_id = m.customer_id)
select *, case when member = 'Y' then dense_rank()over(partition by customer_id,member order by order_date) else NULL end as ranking
from cte;
```
| customer_id | order_date | product_name | price | member | ranking |
|------------|------------|--------------|-------|--------|---------|
| A          | 2021-01-01 | sushi        | 10    | N      | NULL    |
| A          | 2021-01-01 | curry        | 15    | N      | NULL    |
| A          | 2021-01-07 | curry        | 15    | Y      | 1       |
| A          | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A          | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A          | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B          | 2021-01-01 | curry        | 15    | N      | NULL    |
| B          | 2021-01-02 | curry        | 15    | N      | NULL    |
| B          | 2021-01-04 | sushi        | 10    | N      | NULL    |
| B          | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B          | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B          | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C          | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C          | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C          | 2021-01-07 | ramen        | 12    | N      | NULL    |