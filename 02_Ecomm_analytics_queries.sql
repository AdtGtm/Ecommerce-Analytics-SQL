-- E-COMMERCE ANALYTICS: BUSINESS PROBLEM SOLVING
use Ecommerce_Analytics;

# Data Integration (Using JOIN) & Reusable View
-- Q1: How can we build a single master view that combines customer, order, product, and payment details for simplified reporting?
create or replace view CustomerInfo AS select 
c.customer_id, c.customer_name, o.order_id, 
o.order_date, ca.category_name, p.product_name, p.price, 
i.quantity as quantity_of_products_ordered, 
o.total_amount as total_amount_paid, py.payment_method, o.order_status
from customers c 
left join orders o on c.customer_id=o.customer_id
left join order_items i on o.order_id=i.order_id
left join products p on i.product_id=p.product_id
left join payments py on o.order_id=py.order_id
left join categories ca on p.category_id=ca.category_id;

-- Q2: Get customer names with their order details
select c.customer_name, o.order_id, i.order_item_id, o.order_date
from customers c 
left join orders o on c.customer_id=o.customer_id
left join order_items i on o.order_id=i.order_id;

-- Q3:Get products with their categories 
select product_name, category_name from products p
join categories c on p.category_id=c.category_id;

-- Q4: Get order details with product names 
select o.order_id, o.order_date,p.product_name
from products p 
left join order_items i on p.product_id=i.product_id
join orders o on i.order_id=o.order_id;

# SALES & REVENUE INSIGHTS (aggregate findings)  
-- Q6: Overall business performance in terms of total sales revenue and total order count
select count(*)as Total_orders, sum(total_amount) as Total_revenue from orders;

-- Q7: What is the average item value per order?
select order_id, avg(price) as value_pr_orders from order_items
group by 1;

-- Q8: Revenue by category and which prod. category generates highest revenue
select category_name, sum(quantity_of_products_ordered * price) as TotRevenue 
from customerInfo
where order_status= 'Delivered'
group by category_name
order by TotRevenue desc; 

-- Q9. What is the monthly sales trend, and how is revenue progressing month-over-month?
select  date_format(order_date, '%Y-%m') as sales_month, 
count(order_id) as total_orders, sum(total_amount) as monthly_revenue
from  orders
where order_status= 'Delivered'
group by 1
order by sales_month asc;

-- -- Q10: Which products are frequently bought (most popular items by order frequency and quantity)?
select p.product_id, p.product_name, c.category_name,
    count(i.order_id) as times_ordered,
    sum(i.quantity) as total_units_sold,
    sum(i.quantity * i.price) as total_revenue_gen
from products p
join order_items i on p.product_id = i.product_id
join categories c on p.category_id = c.category_id
join orders o on i.order_id = o.order_id
where o.order_status = 'Delivered'
group by p.product_id, p.product_name, c.category_name
order by times_ordered desc, total_units_sold desc;

# Customer behaviour & segmentation (WINDOW function-rank)
-- Q11: Who are our top-spending customers, and how do they rank overall?
select customer_id, sum(total_amount) as total_spentbycstmrs, 
dense_rank() over(order by sum(total_amount) desc) as rankings
from orders
group by customer_id;

#CASE-WHEN USAGE 
-- Q12: How can we segment customers into value tiers (High, Medium, Low) based on spending?
select customer_id,
sum(total_amount) as total_spent,
case 
    when sum(total_amount) > 50000 then 'High Value'
    when sum(total_amount) > 10000 then 'Medium Value'
    when sum(total_amount) > 1000 then 'Fine Value' 
    else 'Low Value'
end as customer_segment
from orders
group by customer_id;

-- Q13:Which top-ranked customers qualify for special discount rewards?
select customer_id,
sum(total_amount) as total_spent, dense_rank() over(order by sum(total_amount) desc) as rankings,
case 
    when dense_rank() over(order by sum(total_amount) desc)<=5 then '50% discount'
    when dense_rank() over(order by sum(total_amount) desc)<=8 then '10% discount'
    else 'no discount'
end as Discount_worthy
from orders
group by customer_id;

-- Q14: Which payment methods are preferred by customers, and what is their status breakdown? 
select distinct order_id, payment_method from CustomerInfo;

# Operational order insights
-- Q15: What percentage of orders get cancelled, and what is the friction rate?
select 
count(case when order_status ='Cancelled' then 1 end) as cancelled_orders,
count(*) as total_orders, 
round ((count(case when order_status='Cancelled' then 1 end)/count(*))*100,2) as cancel_rate_percent
from orders;