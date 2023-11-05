
------------------------------------------------- A. Customer Journey -----------------------------------------------------------

select * from subscriptions;
select * from plans;

-- Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
--Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

--  The customer_id provided in the sample subscriptions table are 1,2,11,13,15,16,18,19
select customer_id,s.plan_id,plan_name,price,start_date from subscriptions s
inner join plans p on s.plan_id = p.plan_id and customer_id in (1,2,11,13,15,16,18,19)
order by customer_id, start_date;

/*
Customer id 1 started with the trial plan on August 01,2020 and continued with the basic monthly plan after the trial period, i.e.,from August 08,2020.
Customer id 2 started with the trial plan on September 20,2020 and continued with the pro annual plan after the trial period, i.e., from September 27,2020.
Customer id 11 started with the trial plan on November 19,2020 but ended the subscription after the trial period on November 26,2020.
Customer id 13 started with the trial plan on December 15,2020 then continued with the basic monthly plan after the trial period, i.e. from December 22,2020 and
then upgraded to pro monthly plan from March 29,2021.
Customer id 15 started with the trial plan on March 17,2020, continued with the pro monthly plan from March 24,2020 and then canceled the service on April 29,2020.
Customer id 16 started with the trial plan on May 31,2020, continued with the basic monthly plan from June 07,2020 and then upgraded to pro annual plan on October 21,2020.
Customer id 18 started with the trial plan on July 06,2020 and then continued with the pro monthly plan from July 13,2020.
Customer id 19 started with the trial plan on June 29,2020, continued with the pro monthly plan from June 29,2020 and then upgraded to pro annual on August 29,2020.
*/

------------------------------------------------- B. Data Analysis Questions ----------------------------------------------------
--1. How many customers has Foodie-Fi ever had?
select count(distinct customer_id) as customers_count from subscriptions;

--2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select datepart(month,start_date) as month, count(s.plan_id) as monthly_distribution_of_trial_plan from subscriptions s
inner join plans as p on s.plan_id = p.plan_id
where lower(plan_name) like 'trial%'
group by datepart(month,start_date)
order by month;

--3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select plan_name, count(s.plan_id) as plan_count from plans as p
inner join subscriptions as s on p.plan_id = s.plan_id
where datepart(year,start_date) >= 2020
group by plan_name
order by plan_count desc;

--4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select count(distinct customer_id) as customer_count, round(100.0*count(customer_id) / (select count(distinct customer_id) from subscriptions),1) as prct_od_customers_churned
from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where lower(plan_name) like 'churn%';

--5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with cte as(
select customer_id,datediff(day,start_date,lead(start_date) over(partition by customer_id order by start_date)) as dt  from subscriptions s
inner join plans as p on s.plan_id = p.plan_id
where plan_name in ('trial','churn'))
select count(distinct customer_id) as customer_count, round(100.0*count(distinct customer_id) / (select count(distinct customer_id) from subscriptions),0) as prct_customers 
from cte
where dt=7;

--6. What is the number and percentage of customer plans after their initial free trial?
select 
plan_name, count(customer_id) as plan_count, 
round(100.0*count(customer_id) / (select count(customer_id) from subscriptions s inner join plans p on s.plan_id = p.plan_id),2) as prct_plans
from subscriptions s 
inner join plans p on p.plan_id = s.plan_id
where plan_name not like 'trial%'
group by plan_name;

--7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
select plan_name, 
count(customer_id) as customer_count,
round(100.0*count(customer_id) / (select count(customer_id) from subscriptions where start_date <= '2020-12-31'),2) as prct_customer
from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where start_date <='2020-12-31' --and customer_id not in (select customer_id from subscriptions s inner join plans p on s.plan_id = p.plan_id where plan_name like 'churn%')
group by plan_name;

--8. How many customers have upgraded to an annual plan in 2020?
with cte as(
select customer_id, plan_name, lead(plan_name) over(partition by customer_id order by start_date) as upgraded_plan,
lead(start_date)over(partition by customer_id order by start_date) as upgraded_plan_start_date from subscriptions s
inner join plans p on p.plan_id = s.plan_id)
select count(customer_id) as customer_count from cte
where upgraded_plan like '%annual%' and datepart(year,upgraded_plan_start_date) = 2020;

--9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with cte as(
select customer_id, datediff(day, start_date , lead(start_date) over(partition by customer_id order by start_date)) as days_for_upgrade
from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where plan_name like 'trial%' or plan_name like '%annual%')
select round(avg(1.0*days_for_upgrade),0) as avg_days_for_upgrade from cte where days_for_upgrade is not null;

--10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

--11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with cte as(
select customer_id, plan_name, lead(plan_name) over(partition by customer_id order by start_date) as next_plan,
lead(start_date) over(partition by customer_id order by start_date) as next_plan_date from subscriptions s
inner join plans p on s.plan_id = p.plan_id
where plan_name like 'pro monthly' or plan_name like 'basic monthly')
select count(customer_id) as customer_count from cte 
where plan_name like 'pro monthly' and next_plan like 'basic monthly' and datepart(year, next_plan_date) = 2020;

----------------------------------- C. Challenge Payment Question
/* The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the 
following requirements:
monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments*/


select customer_id, plan_idfrom subscriptions 
where customer_id in (1,2,13,15,16,18,19);

select 
			s.customer_id,
			s.plan_id,
			p.plan_name,
			s.start_date payment_date,
			s.start_date,
			LEAD(s.start_date, 1) OVER(PARTITION BY s.customer_id ORDER BY s.start_date, s.plan_id) next_date,
			p.price amount
		from subscriptions s
		left join plans p on p.plan_id = s.plan_id