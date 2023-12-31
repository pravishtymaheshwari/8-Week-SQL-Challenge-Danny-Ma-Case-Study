
## A. Customer Journey 

**1. Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.**

- The customer_id provided in the sample subscriptions table are 1, 2, 11, 13, 15, 16, 18, 19.

- Customer id 1:
  - Started with the trial plan on August 01, 2020.
  - Continued with the basic monthly plan after the trial period, starting from August 08, 2020.

- Customer id 2:
  - Started with the trial plan on September 20, 2020.
  - Continued with the pro annual plan after the trial period, starting from September 27, 2020.

- Customer id 11:
  - Started with the trial plan on November 19, 2020.
  - Ended the subscription after the trial period on November 26, 2020.

- Customer id 13:
  - Started with the trial plan on December 15, 2020.
  - Continued with the basic monthly plan after the trial period, starting from December 22, 2020.
  - Upgraded to the pro monthly plan from March 29, 2021.

- Customer id 15:
  - Started with the trial plan on March 17, 2020.
  - Continued with the pro monthly plan from March 24, 2020.
  - Canceled the service on April 29, 2020.

- Customer id 16:
  - Started with the trial plan on May 31, 2020.
  - Continued with the basic monthly plan from June 07, 2020.
  - Upgraded to the pro annual plan on October 21, 2020.

- Customer id 18:
  - Started with the trial plan on July 06, 2020.
  - Continued with the pro monthly plan from July 13, 2020.

- Customer id 19:
  - Started with the trial plan on June 29, 2020.
  - Continued with the pro monthly plan from June 29, 2020.
  - Upgraded to the pro annual plan on August 29, 2020.

## B. Data Analysis Questions 
**1. How many customers has Foodie-Fi ever had?**
```sql
select count(distinct customer_id) as customers_count from subscriptions;
```

| customers_count |
| --------------- |
| 1000            |


**2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value**
```sql
select datepart(month,start_date) as month, count(s.plan_id) as monthly_distribution_of_trial_plan from subscriptions s
inner join plans as p on s.plan_id = p.plan_id
where lower(plan_name) like 'trial%'
group by datepart(month,start_date)
order by month;
```
| month | monthly_distribution_of_trial_plan |
| ----- | ---------------------------------- |
| 1     | 88                               |
| 2     | 68                               |
| 3     | 94                               |
| 4     | 81                               |
| 5     | 88                               |
| 6     | 79                               |
| 7     | 89                               |
| 8     | 88                               |
| 9     | 87                               |
| 10    | 79                               |
| 11    | 75                               |
| 12    | 84                               |

**3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name**
```sql
select plan_name, count(s.plan_id) as plan_count from plans as p
inner join subscriptions as s on p.plan_id = s.plan_id
where datepart(year,start_date) >= 2020
group by plan_name
order by plan_count desc;
```
| plan_name       | plan_count |
| --------------- | ---------- |
| trial           | 1000       |
| basic monthly   | 546        |
| pro monthly     | 539        |
| churn           | 307        |
| pro annual      | 258        |

**4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?**
```sql
select count(distinct customer_id) as customer_count, round(100.0*count(customer_id) / (select count(distinct customer_id) from subscriptions),1) as prct_od_customers_churned
from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where lower(plan_name) like 'churn%';
```
| customer_count | prct_of_customers_churned |
| -------------- | -------------------------- |
| 307            | 30.70                      |

**5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?**
```sql
with cte as(
select customer_id,datediff(day,start_date,lead(start_date) over(partition by customer_id order by start_date)) as dt  from subscriptions s
inner join plans as p on s.plan_id = p.plan_id
where plan_name in ('trial','churn'))
select count(distinct customer_id) as customer_count, round(100.0*count(distinct customer_id) / (select count(distinct customer_id) from subscriptions),0) as prct_customers 
from cte
where dt=7;
```
| customer_count | prct_customers  |
| -------------- | --------------- |
| 92            | 9.00           |


**6. What is the number and percentage of customer plans after their initial free trial?**
```sql
select 
plan_name, count(customer_id) as plan_count, 
round(100.0*count(customer_id) / (select count(customer_id) from subscriptions s inner join plans p on s.plan_id = p.plan_id),2) as prct_plans
from subscriptions s 
inner join plans p on p.plan_id = s.plan_id
where plan_name not like 'trial%'
group by plan_name;
```
| plan_name       | plan_count | prct_plans    |
| --------------- | ---------- | ------------- |
| basic monthly   | 546        | 20.60         |
| churn           | 307        | 11.58         |
| pro annual      | 258        | 9.74          |
| pro monthly     | 539        | 20.34         |

**7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?**
```sql
select plan_name, 
count(customer_id) as customer_count,
round(100.0*count(customer_id) / (select count(customer_id) from subscriptions where start_date <= '2020-12-31'),2) as prct_customer
from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where start_date <='2020-12-31' --and customer_id not in (select customer_id from subscriptions s inner join plans p on s.plan_id = p.plan_id where plan_name like 'churn%')
group by plan_name;
```
| plan_name       | customer_count | prct_customer |
| --------------- | -------------- | ------------- |
| basic monthly   | 538            | 21.98         |
| churn           | 236            | 9.64          |
| pro annual      | 195            | 7.97          |
| pro monthly     | 479            | 19.57         |
| trial           | 1000           | 40.85         |

**8. How many customers have upgraded to an annual plan in 2020?**
```sql
with cte as(
select customer_id, plan_name, lead(plan_name) over(partition by customer_id order by start_date) as upgraded_plan,
lead(start_date)over(partition by customer_id order by start_date) as upgraded_plan_start_date from subscriptions s
inner join plans p on p.plan_id = s.plan_id)
select count(customer_id) as customer_count from cte
where upgraded_plan like '%annual%' and datepart(year,upgraded_plan_start_date) = 2020;
```
| customer_count |
| -------------- |
| 195            |

**9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?**
```sql
with cte as(
select customer_id, datediff(day, start_date , lead(start_date) over(partition by customer_id order by start_date)) as days_for_upgrade
from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where plan_name like 'trial%' or plan_name like '%annual%')
select round(avg(1.0*days_for_upgrade),0) as avg_days_for_upgrade from cte where days_for_upgrade is not null;
```
| avg_days_for_upgrade |
| -------------------- |
| 105.000              |


**10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)**

**11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?**
```sql
with cte as(
select customer_id, plan_name, lead(plan_name) over(partition by customer_id order by start_date) as next_plan,
lead(start_date) over(partition by customer_id order by start_date) as next_plan_date from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where plan_name like 'pro monthly' or plan_name like 'basic monthly')
select count(customer_id) as customer_count from cte 
where plan_name like 'pro monthly' and next_plan like 'basic monthly' and datepart(year, next_plan_date) = 2020;
```
| customer_count |
| -------------- |
| 0              |
