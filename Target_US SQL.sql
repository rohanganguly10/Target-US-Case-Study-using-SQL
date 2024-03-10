## 1. Get the time range between which the orders were placed.
select min(date(order_purchase_timestamp)) as first_order, max(date(order_purchase_timestamp)) as last_order
from `target-us-416106.target_US.orders`

## 2. Count the Cities & States of customers who ordered during the given period.
select count(distinct customer_city) as cities_count, count(distinct customer_state) as states_count 
from `target_US.customers`

## 3. Is there a growing trend in the no. of orders placed over the past years?
select format_date('%Y-%m', o.order_purchase_timestamp) as month, count(c.customer_unique_id) as customer_count,
count(*) as total_orders, round(sum(oi.price),2) as total_price
from `target_US.customers` c join `target_US.orders` o on c.customer_id = o.customer_id 
join `target_US.order_items` oi on o.order_id = oi.order_id
group by month
order by month asc

## 4. Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
select format_date('%m-%B', order_purchase_timestamp) as month,  
count(*) as total_orders
from `target_US.orders` 
group by month 
order by total_orders desc

## 5. During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
# 0-6 hrs : Dawn
# 7-12 hrs : Mornings
# 13-18 hrs : Afternoon
# 19-23 hrs : Night

select countif(time(order_purchase_timestamp) >='00:0:00' and time(order_purchase_timestamp)<='06:0:00') as Dawn_order_count, 
countif(time(order_purchase_timestamp) >='07:0:00' and time(order_purchase_timestamp)<='12:0:00') as Morning_order_count,
countif(time(order_purchase_timestamp) >='13:0:00' and time(order_purchase_timestamp)<='18:0:00') as Afternoon_order_count,
countif(time(order_purchase_timestamp) >='19:0:00' and time(order_purchase_timestamp)<='23:0:00') as Night_order_count
from `target_US.orders`

## 6. Get the month on month no. of orders placed in each state.
select c.customer_state,format_date("%Y", order_purchase_timestamp) as year,
format_date("%m-%B", order_purchase_timestamp) as month, 
count(o.order_id) as order_count,
round(sum(p.payment_value),2) as total_payment
from `target_US.customers` c join `target_US.orders` o 
on c.customer_id = o.customer_id 
join `target_US.payments` p on o.order_id = p.order_id
group by year, month,c.customer_state
order by year,month, c.customer_state

## 7. How are the customers distributed across all the states?
select c.customer_state, c.customer_city, count(o.order_id) as order_count, round(sum(p.payment_value)) as total_payment
from `target_US.customers` c join `target_US.orders` o on c.customer_id = o.customer_id 
join `target_US.payments` p on o.order_id = p.order_id
group by c.customer_state, c.customer_city
order by total_payment desc, order_count desc

## 8. Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
with payment_2017 as
(select round(sum(p.payment_value),2) total_payment_2017
from `target_US.orders` o join `target_US.payments` p
on o.order_id = p.order_id
where o.order_status = 'delivered' and
(extract(year from o.order_purchase_timestamp) = 2017 ) and
extract(month from o.order_purchase_timestamp) between 1 and 8),
payment_2018 as
(select round(sum(p.payment_value),2) total_payment_2018
from `target_US.orders` o join `target_US.payments` p
on o.order_id = p.order_id
where o.order_status = 'delivered' and
(extract(year from o.order_purchase_timestamp) = 2018) and
extract(month from o.order_purchase_timestamp) between 1 and 8)

select total_payment_2017, total_payment_2018, round(((total_payment_2018 -total_payment_2017)/total_payment_2017) * 100,2) as perc_change from payment_2017 p17 cross join payment_2018 p18 

## 9. Calculate the Total & Average value of order price for each state.
select c.customer_state, concat('$ ', round(sum(oi.price),2)) as total_price, 
concat('$ ',round(avg(oi.price),2)) as avg_price
from `target_US.customers` c join `target_US.orders` o
on c.customer_id = o.customer_id 
join `target_US.order_items` oi on o.order_id = oi.order_id
group by c.customer_state

## 10. Calculate the Total & Average value of order freight for each state.
select c.customer_state, concat('$ ', round(sum(oi.freight_value),2)) as total_freight_value, 
concat('$ ',round(avg(oi.freight_value),2)) as avg_freight_value
from `target_US.customers` c join `target_US.orders` o
on c.customer_id = o.customer_id 
join `target_US.order_items` oi on o.order_id = oi.order_id
group by c.customer_state

## 11. Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
select c.customer_state, round(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp, day)),2) as time_to_deliver, 
round(avg(date_diff(order_estimated_delivery_date,order_delivered_customer_date , day)),2) as diff_estimated_delivery
from `target_US.customers` c join `target_US.orders` o on c.customer_id = o.customer_id
group by c.customer_state

## 12. Find out the top 5 states with the highest & lowest average freight value.
(select 'top 5 states with the highest average freight value' as title,
c.customer_state, round(avg(oi.freight_value))as avg_freight_value from `target_US.customers` c join `target_US.orders` o 
on c.customer_id = o.customer_id join `target_US.order_items` oi on o.order_id = oi.order_id
group by c.customer_state
order by avg_freight_value desc
limit 5)
union all
(select 'top 5 states with the lowest average freight value' as title,
c.customer_state, round(avg(oi.freight_value))as avg_freight_value from `target_US.customers` c join `target_US.orders` o 
on c.customer_id = o.customer_id join `target_US.order_items` oi on o.order_id = oi.order_id
group by c.customer_state
order by avg_freight_value
limit 5)

## 13. Find out the top 5 states with the highest & lowest average delivery time.
(select 'top 5 states with the highest delivery time' as title,
c.customer_state, round(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp, day)),2) as delivery_time
from `target_US.customers` c join `target_US.orders` o on c.customer_id = o.customer_id
group by c.customer_state order by delivery_time desc limit 5 )
union all
(select 'top 5 states with the lowest delivery time' as title,
c.customer_state, round(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp, day)),2) as delivery_time
from `target_US.customers` c join `target_US.orders` o on c.customer_id = o.customer_id
group by c.customer_state order by delivery_time limit 5)

## 14. Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery. You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state.
with cte as
(select c.customer_state, round(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp, day)),2) as time_to_deliver, 
round(avg(date_diff(order_estimated_delivery_date,order_delivered_customer_date , day)),2) as diff_estimated_delivery
from `target_US.customers` c join `target_US.orders` o on c.customer_id = o.customer_id
group by c.customer_state)

select customer_state, time_to_deliver, diff_estimated_delivery from cte where time_to_deliver > diff_estimated_delivery

## 15. Find the month on month no. of orders placed using different payment types.
select format_date('%m-%B', o.order_purchase_timestamp) as month, p.payment_type, count(o.order_id) as order_count
from `target_US.orders` o join `target_US.payments` p on o.order_id = p.order_id
group by month, p.payment_type
order by order_count desc

## 16. Find the no. of orders placed on the basis of the payment installments that have been paid.
select p.payment_installments, count(o.order_id) as order_count from
`target_US.payments` p join `target_US.orders` o on p.order_id = o.order_id
group by p.payment_installments
order by p.payment_installments