CREATE DATABASE ELECTRIC_VEHICLE;

USE ELECTRIC_VEHICLE;

CREATE TABLE electric_vehicles_sales_by_state(
date date,
state varchar(50),
vehicle_category varchar(20),
electric_vehicle_sold int,
total_vehicle_sold int
);
drop table electric_vehicles_sales_by_makers;

CREATE TABLE electric_vehicles_sales_by_makers(
date date,
vehicle_category varchar(20),
maker varchar(25),
electric_vehicle_sold int
);

CREATE TABLE dim_date(
date date,
fiscal_year int,
quater varchar(5)
);


SELECT * FROM electric_vehicles_sales_by_state;
SELECT * FROM electric_vehicles_sales_by_makers;
SELECT * FROM dim_date;

-- date ,  vehicle category
CREATE VIEW evData AS(
SELECT 
    s.date,
    d.Fiscal_year,
    d.Quater,
    s.state,
    s.vehicle_category,
    m.maker,
    s.electric_vehicle_sold as state_sales,
    m.electric_vehicle_sold as Maker_sales,
    s.total_vehicle_sold
FROM
    electric_vehicles_sales_by_state AS s
        INNER JOIN
    electric_vehicles_sales_by_makers AS m ON s.date = m.date
        AND s.vehicle_category = m.vehicle_category
        
        INNER JOIN dim_date as d ON d.date = s.date);
        
select * from evData limit 27000;

drop view evData;

-- 1.	List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold. 

-- 2 wheeler sale in fiscal year 2023 & 2024

-- top 3 2024,2023 maker sale 
WITH CTE AS
(SELECT 
    Fiscal_year,
    maker,
    SUM(maker_sales) AS Total_2Wheeler_Sales,
    DENSE_RANK() OVER(PARTITION BY(Fiscal_year) ORDER BY SUM(maker_sales) DESC) AS Maker_rnk
FROM
    evData
WHERE
    vehicle_category = '2-Wheelers'
        AND (Fiscal_year = 2023
        OR Fiscal_year = 2024)
GROUP BY Fiscal_year,maker) 
SELECT Fiscal_year ,Maker , Total_2Wheeler_Sales , Maker_rnk FROM CTE WHERE Maker_rnk <=3;

-- bottom 3 2023 , 2024 maker sale 

WITH CTE AS
(SELECT 
    Fiscal_year,
    maker,
    SUM(maker_sales) AS Total_2Wheeler_Sales,
    DENSE_RANK() OVER(PARTITION BY(Fiscal_year) ORDER BY SUM(maker_sales)ASC) AS Maker_rnk
FROM
    evData
WHERE
    vehicle_category = '2-Wheelers'
        AND (Fiscal_year = 2023
        OR Fiscal_year = 2024)
GROUP BY Fiscal_year,maker) 
SELECT Fiscal_year ,Maker , Total_2Wheeler_Sales , Maker_rnk FROM CTE WHERE Maker_rnk <=3;


-- 2.	Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024. 

WITH CTE AS (
SELECT 
    State,
    Vehicle_category,
    SUM(State_sales) AS Electric_Vehicle_Sold,
    SUM(Total_vehicle_sold) AS Total_vechile_sold,
    (SUM(State_sales)/SUM(Total_vehicle_sold))*100 As Penetration,
    DENSE_RANK() OVER(PARTITION BY Vehicle_category ORDER BY (SUM(State_sales)/SUM(Total_vehicle_sold))*100 DESC ) AS penetration_rnk
FROM
    evData
WHERE
    Fiscal_year = 2024
GROUP BY State , Vehicle_category) 
SELECT State, Vehicle_category, Penetration, penetration_rnk FROM CTE WHERE penetration_rnk <= 5;


-- penetration rate combine 2-wheeler and 4-wheeler
WITH CTE AS (
SELECT 
    State,
    SUM(State_sales) AS Electric_Vehicle_Sold,
    SUM(Total_vehicle_sold) AS Total_vechile_sold,
    (SUM(State_sales)/SUM(Total_vehicle_sold))*100 As Penetration,
    DENSE_RANK() OVER(ORDER BY (SUM(State_sales)/SUM(Total_vehicle_sold))*100 DESC ) AS penetration_rnk
FROM
    evData
WHERE
    Fiscal_year = 2024
GROUP BY State) 
SELECT State, Penetration, penetration_rnk FROM CTE WHERE penetration_rnk <= 5;


-- 3.	List the states with negative penetration (decline) in EV sales from 2022 to 2024? 

WITH Penetration_rate as(
SELECT 
    Fiscal_year,
    State,
    SUM(State_sales) Electric_Vehicle_Sold,
    SUM(total_vehicle_sold) Total_vechile_sold,
    (SUM(State_sales) / SUM(Total_vehicle_sold)) * 100 AS Penetration
FROM
    evData
WHERE
    Fiscal_year = 2022 OR Fiscal_year = 2024
GROUP BY State , Fiscal_year) ,
penetration_comperison as (
SELECT 
	p1.state,
    p1.Fiscal_year AS Fiscal_year_2022,
    p1.Penetration AS Penetration_2022 ,
    p2.Fiscal_year AS Fiscal_year_2024,  
    p2.Penetration AS Penetration_2024 
FROM Penetration_rate as p1 
JOIN Penetration_rate As p2 
ON p1.state = p2.state 
WHERE p1.fiscal_year = 2022 and p2.fiscal_year = 2024)
SELECT State , Penetration_2022 ,Penetration_2024  FROM penetration_comperison WHERE Penetration_2024<Penetration_2022;


-- 4. What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?

WITH CTE AS(
SELECT 
    maker, SUM(Maker_sales) AS Total_maker_sales
FROM
    evData
WHERE
    Vehicle_category = '4-wheelers'
GROUP BY maker
ORDER BY Total_maker_sales DESC
LIMIT 5)
SELECT 
  s.Fiscal_year,
  s.Quater,
  s.maker,
  SUM(s.Maker_sales) AS quarterly_sales
FROM evData s
JOIN CTE t ON s.maker = t.maker
WHERE s.vehicle_category = '4-Wheelers'
  AND s.Fiscal_year BETWEEN 2022 AND 2024
GROUP BY s.Fiscal_year, s.Quater, s.maker
ORDER BY s.Fiscal_year, s.Quater, quarterly_sales DESC;

-- 5. How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024?

SELECT * FROM evData;


