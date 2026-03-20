create database Swiggy;
select * from swiggy_data;

-- Data Validation & Cleaning
select Order_Date from swiggy_data;

ALTER TABLE swiggy_data 
RENAME COLUMN `Rating Count` TO `Rating_Count`;

select sum(case when State is null then 1 else 0 end) as null_state,
sum(case when City is null then 1 else 0 end) as null_city,
sum(case when Order_Date is null then 1 else 0 end) as null_state,
sum(case when Restaurant_Name is null then 1 else 0 end) as null_restaurent,
sum(case when Location is null then 1 else 0 end) as null_location,
sum(case when Category is null then 1 else 0 end) as null_Category,
sum(case when Dish_Name is null then 1 else 0 end) as null_Dish,
sum(case when Price_INR is null then 1 else 0 end) as null_price,
sum(case when Rating is null then 1 else 0 end) as null_rating,
sum(case when Rating_Count is null then 1 else 0 end) as null_rating_count
from swiggy_data;


-- Blanks or Empty Strings
select * from swiggy_data where state='' or
City='' or Restaurant_Name='' or Location= '' or Category='' or Dish_Name=''or Price_INR='' or Rating='' or Rating_Count='' ;


-- Duplicate Detection
select state ,city,order_date,Restaurant_Name,location,category,dish_name,price_inr,rating,rating_count, count(*) as CNT from swiggy_data group by
state ,city,order_date,Restaurant_Name,location,category,dish_name,price_inr,rating,rating_count having count(*)>=1;

-- Delete Duplicates
DELETE FROM swiggy_data
WHERE id NOT IN (
    SELECT min_id FROM (
        SELECT MIN(id) AS min_id
        FROM swiggy_data
        GROUP BY state, city, order_date, Restaurant_Name, 
                 location, category, dish_name, price_inr, 
                 rating, rating_count
    ) AS temp
);
ALTER TABLE swiggy_data 
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY FIRST;
DELETE FROM swiggy_data
WHERE id NOT IN (
    SELECT min_id FROM (
        SELECT MIN(id) AS min_id
        FROM swiggy_data
        GROUP BY state, city, order_date, Restaurant_Name, 
                 location, category, dish_name, price_inr, 
                 rating, rating_count
    ) AS temp
);
SET SQL_SAFE_UPDATES = 0;




-- CREATING SCHEMA
-- DIMENSION TABLES
-- DATE TABLE

CREATE TABLE dim_date (
    date_id INT AUTO_INCREMENT PRIMARY KEY,
    Full_Date DATE,
    Year INT,
    Month INT,
    Month_Name VARCHAR(20),
    Quarter INT,
    Day INT,
    Week INT
);
select * from dim_date;

-- dim location
create table dim_location(
location_id int auto_increment primary key,
state varchar(100),
City varchar(100),
Location varchar(200)

);

-- dim_restaurant

CREATE TABLE dim_restaurant (
restaurant_id INT auto_increment PRIMARY KEY,
Restaurant_Name VARCHAR (200));

-- dim_category
CREATE TABLE dim_category (
category_id INT auto_increment PRIMARY KEY,
Category VARCHAR(200)
);

-- dim dish

CREATE TABLE dim_dish (
dish_id INT  auto_increment PRIMARY KEY,

Dish_Name VARCHAR(200));



-- FACT TABLE

CREATE TABLE fact_swiggy_orders (
order_id INT auto_increment PRIMARY KEY,
date_id INT,
Price_INR DECIMAL (10,2),
Rating DECIMAL(4,2),
Rating_Count INT,
location_id INT,
restaurant_id INT,
category_id INT,
dish_id INT,
FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id), 
FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);
select * from fact_swiggy_orders;


-- INSERT DATA IN TABLES
-- dim date

INSERT INTO dim_date (Full_Date, Year, Month, Month_Name, Quarter, Day, Week)
SELECT DISTINCT
    STR_TO_DATE(Order_Date, '%d-%m-%Y'),
    YEAR(STR_TO_DATE(Order_Date, '%d-%m-%Y')),
    MONTH(STR_TO_DATE(Order_Date, '%d-%m-%Y')),
    MONTHNAME(STR_TO_DATE(Order_Date, '%d-%m-%Y')),
    QUARTER(STR_TO_DATE(Order_Date, '%d-%m-%Y')),
    DAY(STR_TO_DATE(Order_Date, '%d-%m-%Y')),
    WEEK(STR_TO_DATE(Order_Date, '%d-%m-%Y'))
FROM swiggy_data
WHERE Order_Date IS NOT NULL;


select * from dim_location;


-- dim_location
insert into dim_location(state,city,location)
select distinct state,city,location from swiggy_data;

-- dim_restaurant
INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
Restaurant_Name
FROM swiggy_data;

-- dim_category
INSERT INTO dim_category (Category)
SELECT DISTINCT
Category
FROM swiggy_data;

-- dim_dish
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
Dish_Name
FROM swiggy_data;


-- Fact Table

INSERT INTO fact_swiggy_orders
(date_id, Price_INR, Rating, Rating_Count, location_id, restaurant_id, category_id, dish_id)
SELECT
    dd.date_id,
    s.Price_INR,
    s.Rating,
    s.Rating_Count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM swiggy_data s
JOIN dim_date dd
    ON dd.Full_Date = STR_TO_DATE(s.Order_Date, '%d-%m-%Y')   -- ✅ fix here
JOIN dim_location dl
    ON dl.State = s.State
    AND dl.City = s.City
    AND dl.Location = s.Location
JOIN dim_restaurant dr
    ON dr.Restaurant_Name = s.Restaurant_Name
JOIN dim_category dc
    ON dc.Category = s.Category
JOIN dim_dish dsh
    ON dsh.Dish_Name = s.Dish_Name;
    
    
select * from fact_swiggy_orders;




SELECT *  FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish di ON f.dish_id = di.dish_id;


-- KPI's
-- Total Orders
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders;

-- Total Revenue (INR Million)
SELECT
    CONCAT(FORMAT(SUM(Price_INR) / 1000000, 2), ' INR Million')
    AS `Total Revenue`
FROM fact_swiggy_orders;

-- AVg Dish Price
SELECT
    CONCAT(FORMAT(AVG(Price_INR), 2), ' INR')
    AS `Total Revenue`
FROM fact_swiggy_orders;

-- Avg Rating
select * from swiggy_data;
select avg(rating) as Avg_Rating from fact_swiggy_orders;


-- Monthly ordersSELECT
select
    d.Year,
    d.Month,
    d.Month_Name,
    COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year, d.Month, d.Month_Name
ORDER BY d.Year, d.Month;


select
    d.Year,
    d.Month,
    d.Month_Name,
    sum(Price_INR) AS Total_Revenue
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year, d.Month, d.Month_Name
ORDER BY d.Year, d.Month;

-- Quaterly Trend
SELECT
    d.Year,
    d.Quarter,
    COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year, d.Quarter
ORDER BY count(*) DESC;


-- Yearly Trend
SELECT
    d.Year,
    COUNT(*) AS Total_Orders,
    SUM(f.Price_INR) AS Total_Revenue
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year
ORDER BY d.Year ASC;

-- orders by day of week(Mon-Sun)
SELECT
    d.Day,
    DAYNAME(d.Full_Date) AS Day_Name,
    COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Day, DAYNAME(d.Full_Date)
ORDER BY d.Day ASC;



-- Top 10 citys orders volume
SELECT
    dl.Location,
    dl.City,
    COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_location dl ON f.location_id = dl.location_id
GROUP BY dl.Location, dl.City
ORDER BY Total_Orders DESC
LIMIT 10;



-- Top 10 restaurant by orders
SELECT
    dr.Restaurant_Name,
    COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_restaurant dr ON f.restaurant_id = dr.restaurant_id
GROUP BY dr.Restaurant_Name
ORDER BY Total_Orders DESC
LIMIT 10;



-- Top Orders Chinese or Indian
SELECT
    dc.Category,
    COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_category dc ON f.category_id = dc.category_id
GROUP BY dc.Category
ORDER BY Total_Orders DESC;

-- Most ordered Dish
SELECT
    dsh.Dish_Name,
    COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_dish dsh ON f.dish_id = dsh.dish_id
GROUP BY dsh.Dish_Name
ORDER BY Total_Orders DESC
LIMIT 10;