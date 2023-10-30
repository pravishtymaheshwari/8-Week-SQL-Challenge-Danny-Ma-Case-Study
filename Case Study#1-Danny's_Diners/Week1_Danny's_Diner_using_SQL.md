```sql
--1. What is the total amount each customer spent at the restaurant?
select sls.customer_id, concat('$',sum(price)) as total_amount_spent 
from members as mem
right join sales as sls on mem.customer_id = sls.customer_id
inner join menu as mnu on mnu.product_id = sls.product_id
group by sls.customer_id;

| customer_id | total_amount_spent |
|------------|-------------------|
| A          | $76               |
| B          | $74               |
| C          | $36               |


--2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as total_visits from sales group by customer_id;

customer_id	total_visits
A	4
B	6
C	2

--3. What was the first item from the menu purchased by each customer?
with cte as(
select customer_id, product_name, dense_rank()over(partition by customer_id order by order_date) as dnk
from sales sls join menu as mnu on sls.product_id = mnu.product_id)
select customer_id, string_agg(product_name,',') within group(order by product_name) as product_name from cte where dnk=1
group by customer_id;

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
with cte as(
select product_name , count(product_name) as total_count, dense_rank()over(order by count(product_name) desc) as dnk
from menu mnu join sales sls on mnu.product_id = sls.product_id
group by product_name)
select product_name, total_count from cte where dnk=1;

--5. Which item was the most popular for each customer?
with cte as(
select customer_id, product_name, dense_rank()over(partition by customer_id order by count(product_name) desc) as dnk
from menu mnu join sales sls on mnu.product_id = sls.product_id
group by customer_id, product_name)
select customer_id, string_agg(product_name,',') within group(order by product_name) as product_name from cte where dnk=1
group by customer_id;

--6. Which item was purchased first by the customer after they became a member?
with cte as(
select sls.customer_id, mnu.product_name, dense_rank()over(partition by sls.customer_id order by order_date) as dnk
from members as mem
inner join sales as sls on mem.customer_id = sls.customer_id
inner join menu as mnu on mnu.product_id = sls.product_id
where order_date >= join_date)
select customer_id, string_agg(product_name,',') within group(order by product_name) as product_name from cte where dnk=1
group by customer_id;

--7. Which item was purchased just before the customer became a member?
with cte as(
select sls.customer_id, mnu.product_name, dense_rank()over(partition by sls.customer_id order by order_date desc) as dnk
from members as mem
inner join sales as sls on mem.customer_id = sls.customer_id
inner join menu as mnu on mnu.product_id = sls.product_id
where order_date < join_date)
select customer_id, string_agg(product_name,',') within group(order by product_name) as product_name from cte where dnk=1
group by customer_id;

--8. What is the total items and amount spent for each member before they became a member?
select sls.customer_id, count(product_name)as total_products, concat('$',sum(price)) as total_spent from members as mem
right join sales as sls on mem.customer_id = sls.customer_id
inner join menu as mnu on mnu.product_id = sls.product_id
where order_date < join_date or join_date is null
group by sls.customer_id;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id, sum(case when lower(product_name) ='sushi' then 2*10*price else 10* price end) as total_points
from sales as sls inner join menu as mnu on sls.product_id = mnu.product_id
group by customer_id;

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
select sls.customer_id, 
sum(case 
    when lower(product_name)='sushi' then 2*10*price
	when order_date <= dateadd(day,6,join_date) and order_date >= join_date then 2*10*price else 10*price end) as total_points
from sales as sls inner join menu as mnu on sls.product_id = mnu.product_id
inner join members as mem on mem.customer_id = sls.customer_id
where order_date <= '2021-01-31'
group by sls.customer_id;

select * from sales;
select * from members;
select * from menu;

-- Bonus Questions
select s.customer_id,s.order_date,mu.product_name,mu.price,
case when order_date>=join_date then 'Y' else 'N' end as member
from menu as mu inner join sales as s on s.product_id = mu.product_id
left join members as m on s.customer_id = m.customer_id
order by s.customer_id, s.order_date,mu.product_name; 

-- Rank All the Things
with cte as(
select s.customer_id,s.order_date,mu.product_name,mu.price,
case when order_date>=join_date then 'Y' else 'N' end as member
from menu as mu inner join sales as s on s.product_id = mu.product_id
left join members as m on s.customer_id = m.customer_id)
select *, case when member = 'Y' then dense_rank()over(partition by customer_id,member order by order_date) else NULL end as ranking
from cte;