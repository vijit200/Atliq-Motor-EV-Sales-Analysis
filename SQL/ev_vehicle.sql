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

SELECT 
    state,
    SUM(state_sales) AS EV_Sale,
    (SUM(State_sales) / SUM(Total_vehicle_sold)) * 100 AS Penetration
FROM
    evData
WHERE
    (State = 'Delhi' OR State = 'Karnataka') AND Fiscal_year = 2024
GROUP BY State;

-- 6. List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.

WITH EvSale AS(
SELECT 
    maker, fiscal_year, SUM(maker_sales) AS Total_EvSales
FROM
    evData
WHERE Vehicle_category = "4-Wheelers" AND
    Fiscal_year IN (2022 , 2023, 2024)
GROUP BY Fiscal_year , maker),
Sale AS (
SELECT Maker ,MAX(CASE WHEN fiscal_year = 2022 THEN Total_EvSales ELSE 0 END ) AS Sale_2022 ,
MAX(CASE WHEN fiscal_year = 2024 THEN Total_EvSales ELSE 0 END  ) AS Sale_2024 FROM EvSale GROUP BY Maker)
SELECT 
    Maker,
    (Sale_2022 + Sale_2024) AS TOTAL_EV_SOLD,
    ROUND((POWER(Sale_2024 / Sale_2022, 1 / 2) - 1) * 100,2) AS CAGR
FROM
    Sale
WHERE
    Sale_2022 > 0
ORDER BY (Sale_2022 + Sale_2024) DESC
LIMIT 5;

-- 7. List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.

WITH EVSales AS (
SELECT 
    state, fiscal_year, SUM(total_vehicle_sold) AS total_sales
FROM
    evData
WHERE
    FISCAL_YEAR IN (2022 , 2023, 2024
    )
GROUP BY state , fiscal_year
),
Sales AS (
SELECT 
    State,
    MAX(CASE
        WHEN fiscal_year = 2022 THEN total_sales
        ELSE 0
    END) AS Sale_2022,
    MAX(CASE
        WHEN fiscal_year = 2024 THEN total_sales
        ELSE 0
    END) AS Sale_2024
FROM
    EVSales
GROUP BY State)
SELECT 
	State,
    (Sale_2022 + Sale_2024) AS TOTAL_EV_SOLD,
    ROUND((POWER(Sale_2024 / Sale_2022, 1 / 2) - 1) * 100,2) AS CAGR
FROM Sales WHERE Sale_2022 > 0 ORDER BY CAGR DESC  LIMIT 10;


-- 8. What are the peak and low season months for EV sales based on the data from 2022 to 2024? 
SELECT * FROM evData;
    
WITH MonthlySales AS (
    SELECT 
        MONTHNAME(date) AS `year_month`,
        SUM(total_vehicle_sold) AS total_sales
    FROM evData 
    WHERE YEAR(date) BETWEEN 2022 AND 2024
    GROUP BY `year_month`
)
SELECT 
    (SELECT `year_month` AS `Month` FROM MonthlySales ORDER BY total_sales DESC LIMIT 1) AS peak_month,
    (SELECT total_sales FROM MonthlySales ORDER BY total_sales DESC LIMIT 1) AS peak_sales,
    (SELECT `year_month` FROM MonthlySales ORDER BY total_sales ASC LIMIT 1) AS low_month,
    (SELECT total_sales FROM MonthlySales ORDER BY total_sales ASC LIMIT 1) AS low_sales;
    
-- 9.	What is the projected number of EV sales (including 2-wheelers and 4-wheelers) for the top 10 states by penetration rate in 2030,
--  based on the compounded annual growth rate (CAGR) from previous years? 


WITH newData AS(
SELECT 
	State,
   ( SUM(State_sales) / SUM(Total_vehicle_sold) ) * 100 AS Penetration_rate
FROM
    evData
GROUP BY  State ORDER BY Penetration_rate DESC LIMIT 10), newCte AS (
SELECT e.Fiscal_year , e.State ,  e.state_sales , c.Penetration_rate FROM evData e JOIN newData c ON e.state = c.state ), CTE AS(
SELECT Fiscal_year , State , SUM(state_sales) AS Total_sales FROM newCte GROUP BY State,Fiscal_year ),
CAGR AS(
SELECT 
    State,
    MIN(Fiscal_year) AS Initial_year,
    MAX(Fiscal_year) AS Final_year,
	SUM(CASE WHEN Fiscal_year = 2022 THEN total_sales ELSE 0 END) AS initial_sales,
    SUM(CASE WHEN Fiscal_year = 2024 THEN total_sales ELSE 0 END) AS final_sales
FROM
    CTE
GROUP BY State)
SELECT 
    State,
    Initial_year,
    Final_year,
    (final_sales + initial_sales) AS Total_ev_sales,
ROUND((POW(final_sales / NULLIF(initial_sales, 0), 1.0 / NULLIF(final_year - initial_year, 0)) - 1) *100, 2) AS CAGR,
-- Projected Sales=Latest Sales×(1+CAGR) ^ years to 2030
ROUND(final_sales * POW(1 + (ROUND(POW(final_sales / NULLIF(initial_sales, 0), 1.0 / NULLIF(final_year - initial_year, 0)) - 1, 6)), (2030 - final_year)),2) AS projected_2030_sales
FROM
    CAGR
ORDER BY projected_2030_sales DESC
LIMIT 10;

-- 10.	Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price

WITH revenue_data AS (
    SELECT 
        Fiscal_year,
        vehicle_category,
        SUM(state_sales) AS total_units_sold,
        CASE 
            WHEN vehicle_category = '2-Wheelers' THEN SUM(state_sales) * 120000
            WHEN vehicle_category = '4-Wheelers' THEN SUM(state_sales) * 1500000
            ELSE 0
        END AS revenue
    FROM evData
    WHERE Fiscal_year IN (2022, 2023, 2024)
    GROUP BY Fiscal_year, vehicle_category
),
growth_calculations AS (
    SELECT 
        rd1.vehicle_category,
        rd1.Fiscal_year AS year_1,
        rd2.Fiscal_year AS year_2,
        rd1.revenue AS revenue_year_1,
        rd2.revenue AS revenue_year_2,
        ((rd2.revenue - rd1.revenue) / rd1.revenue) * 100 AS growth_rate
    FROM revenue_data rd1
    JOIN revenue_data rd2 
        ON rd1.vehicle_category = rd2.vehicle_category 
        AND rd2.Fiscal_year = rd1.Fiscal_year + 2  -- For 2022-2024
    UNION ALL
    SELECT 
        rd1.vehicle_category,
        rd1.Fiscal_year AS year_1,
        rd2.Fiscal_year AS year_2,
        rd1.revenue AS revenue_year_1,
        rd2.revenue AS revenue_year_2,
        ((rd2.revenue - rd1.revenue) / rd1.revenue) * 100 AS growth_rate
    FROM revenue_data rd1
    JOIN revenue_data rd2 
        ON rd1.vehicle_category = rd2.vehicle_category 
        AND rd2.Fiscal_year = rd1.Fiscal_year + 1  -- For 2023-2024
)
SELECT * FROM growth_calculations WHERE year_1 in (2022,2023) AND year_2 = 2024;





-- -----------------------------------------------------------------------------------


WITH MonthlySales AS (
    SELECT 
        MONTHNAME(date) AS `year_month`,
        SUM(total_vehicle_sold) AS total_sales
    FROM evData 
    WHERE YEAR(date) BETWEEN 2022 AND 2024
    GROUP BY `year_month`
)
SELECT * FROM MonthlySales;






WITH CTE AS (
SELECT 
    State,
    vehicle_category,
    SUM(State_sales) AS Electric_Vehicle_Sold,
    SUM(Total_vehicle_sold) AS Total_vechile_sold,
    (SUM(State_sales)/SUM(Total_vehicle_sold))*100 As Penetration,
    DENSE_RANK() OVER(ORDER BY (SUM(State_sales)/SUM(Total_vehicle_sold))*100 DESC ) AS penetration_rnk
FROM
    evData 
GROUP BY State , Vehicle_category) 
SELECT AVG(Penetration),Vehicle_category As Avg_Penetration From CTE Group by Vehicle_Category;


WITH CTE AS (
SELECT 
    State,
    SUM(State_sales) AS Electric_Vehicle_Sold,
    SUM(Total_vehicle_sold) AS Total_vechile_sold,
    (SUM(State_sales)/SUM(Total_vehicle_sold))*100 As Penetration,
    DENSE_RANK() OVER(ORDER BY (SUM(State_sales)/SUM(Total_vehicle_sold))*100 DESC ) AS penetration_rnk
FROM
    evData
GROUP BY State),
last_year AS (SELECT 
    State,
    SUM(State_sales) AS Electric_Vehicle_Sold,
    SUM(Total_vehicle_sold) AS Total_vechile_sold,
    (SUM(State_sales)/SUM(Total_vehicle_sold))*100 As Penetration_lY,
    DENSE_RANK() OVER(ORDER BY (SUM(State_sales)/SUM(Total_vehicle_sold))*100 DESC ) AS penetration_rnk
FROM
    evData WHERE Fiscal_year = 2024
GROUP BY State),
diff_year AS (SELECT c.State , c.Penetration , ls.Penetration_ly , (ls.Penetration_ly - c.Penetration) AS Diff_penetration  FROM CTE AS c JOIN last_year ls ON c.State = ls.State)
SELECT * from diff_year; 

SELECT State , Sum(State_sales) As total_Sales from evData Where (State = "Karnataka" or State = "Delhi") GROUP BY State;


 --  CAGR OF TOP 10 MAKER
WITH EvSale AS(
SELECT 
    maker, fiscal_year,vehicle_category, SUM(maker_sales) AS Total_EvSales
FROM
    evData
WHERE 
    Fiscal_year IN (2022 , 2023, 2024)
GROUP BY Fiscal_year , maker,vehicle_category),
Sale AS (
SELECT Maker,vehicle_category ,MAX(CASE WHEN fiscal_year = 2022 THEN Total_EvSales ELSE 0 END ) AS Sale_2022 ,
MAX(CASE WHEN fiscal_year = 2024 THEN Total_EvSales ELSE 0 END  ) AS Sale_2024 FROM EvSale GROUP BY Maker,vehicle_category)
SELECT 
    Maker,vehicle_category,
    (Sale_2022 + Sale_2024) AS TOTAL_EV_SOLD,
    ROUND((POWER(Sale_2024 / Sale_2022, 1 / 2) - 1) * 100,2) AS CAGR
FROM
    Sale
WHERE
    Sale_2022 > 0
ORDER BY CAGR DESC;


WITH EvSale AS(
SELECT 
    state, fiscal_year, SUM(state_sales) AS Total_EvSales
FROM
    evData
WHERE 
    Fiscal_year IN (2022 , 2023, 2024)
GROUP BY Fiscal_year , state),
Sale AS (
SELECT state ,MAX(CASE WHEN fiscal_year = 2022 THEN Total_EvSales ELSE 0 END ) AS Sale_2022 ,
MAX(CASE WHEN fiscal_year = 2024 THEN Total_EvSales ELSE 0 END  ) AS Sale_2024 FROM EvSale GROUP BY state)
SELECT 
    state,
    (Sale_2022 + Sale_2024) AS TOTAL_EV_SOLD,
    ROUND((POWER(Sale_2024 / Sale_2022, 1 / 2) - 1) * 100,2) AS CAGR
FROM
    Sale
WHERE
    Sale_2022 > 0
ORDER BY CAGR DESC
LIMIT 10;


SELECT 
    maker,vehicle_category,
    SUM(
        CASE 
            WHEN vehicle_category = '2-Wheelers' THEN Maker_sales * 120000
            WHEN vehicle_category = '4-Wheelers' THEN Maker_sales * 1500000
            ELSE 0
        END
    ) AS revenue
FROM evData
GROUP BY maker,vehicle_category
ORDER BY revenue DESC;

SELECT SUM(total_vehicle_sold) AS total_electric_vehicles_sold
FROM (
    SELECT DISTINCT date, state, vehicle_category, total_vehicle_sold
    FROM evData
) AS unique_sales;

select sum(total_vehicle_sold) from evData;
select * from evData;
SELECT SUM(maker_sales) AS total_electric_vehicles_sold
FROM (
    SELECT DISTINCT date, maker, vehicle_category, maker_sales
    FROM evData
) AS unique_sales;


WITH CTE AS
(SELECT 
    maker,vehicle_category,
    SUM(maker_sales) AS Total_2Wheeler_Sales
FROM
    evData
GROUP BY maker,vehicle_category) 
SELECT  Maker ,vehicle_category, Total_2Wheeler_Sales  FROM CTE order by Total_2Wheeler_Sales ASC;



SELECT 
    (SUM(State_sales) * 1.0 / SUM(total_vehicle_sold)) * 100 AS avg_ev_penetration_rate
FROM 
    evData; 
    
WITH newData AS(
SELECT 
	State,
   ( SUM(State_sales) / SUM(Total_vehicle_sold) ) * 100 AS Penetration_rate
FROM
    evData
GROUP BY  State ORDER BY Penetration_rate DESC LIMIT 10), newCte AS (
SELECT e.Fiscal_year , e.State ,e.vehicle_category,  e.state_sales , c.Penetration_rate FROM evData e JOIN newData c ON e.state = c.state ), CTE AS(
SELECT Fiscal_year , State ,vehicle_category, SUM(state_sales) AS Total_sales FROM newCte GROUP BY State,Fiscal_year,vehicle_category ),
CAGR AS(
SELECT 
    State,
    MIN(Fiscal_year) AS Initial_year,
    MAX(Fiscal_year) AS Final_year,
	SUM(CASE WHEN Fiscal_year = 2022 THEN total_sales ELSE 0 END) AS initial_sales,
    SUM(CASE WHEN Fiscal_year = 2024 THEN total_sales ELSE 0 END) AS final_sales
FROM
    CTE
GROUP BY State),Pr_sale AS (
SELECT 
    State,
    Initial_year,
    Final_year,
    (final_sales + initial_sales) AS Total_ev_sales,
ROUND((POW(final_sales / NULLIF(initial_sales, 0), 1.0 / NULLIF(final_year - initial_year, 0)) - 1) *100, 2) AS CAGR,
-- Projected Sales=Latest Sales×(1+CAGR) ^ years to 2030
ROUND(final_sales * POW(1 + (ROUND(POW(final_sales / NULLIF(initial_sales, 0), 1.0 / NULLIF(final_year - initial_year, 0)) - 1, 6)), (2030 - final_year)),2) AS projected_2030_sales
FROM
    CAGR
ORDER BY projected_2030_sales DESC)
SELECT SUM(projected_2030_sales) FROM Pr_sale;

SELECT State , vehicle_category ,fiscal_year, Sum(State_sales) As total_Sales from evData Where (State = "Karnataka" or State = "Delhi") GROUP BY State, vehicle_category,fiscal_year;

SELECT 
    state,
    SUM(state_sales) AS EV_Sale,
    (SUM(State_sales) / SUM(Total_vehicle_sold)) * 100 AS Penetration
FROM
    evData
WHERE
    (State = 'Delhi' OR State = 'Karnataka')
GROUP BY State;




WITH newData AS(
SELECT 
	Maker,
   ( SUM(maker_sales) / SUM(Total_vehicle_sold) ) * 100 AS Penetration_rate
FROM
    evData
GROUP BY  Maker ORDER BY Penetration_rate DESC LIMIT 10), newCte AS (
SELECT e.Fiscal_year , e.Maker ,e.vehicle_category,  e.maker_saless , c.Penetration_rate FROM evData e JOIN newData c ON e.Maker = c.Maker ), CTE AS(
SELECT Fiscal_year , Maker ,vehicle_category, SUM(maker_sales) AS Total_sales FROM newCte GROUP BY Maker,Fiscal_year,vehicle_category ),
CAGR AS(
SELECT 
    Maker,
    MIN(Fiscal_year) AS Initial_year,
    MAX(Fiscal_year) AS Final_year,
	SUM(CASE WHEN Fiscal_year = 2022 THEN total_sales ELSE 0 END) AS initial_sales,
    SUM(CASE WHEN Fiscal_year = 2024 THEN total_sales ELSE 0 END) AS final_sales
FROM
    CTE
GROUP BY Maker),Pr_sale AS (
SELECT 
    Maker,
    Initial_year,
    Final_year,
    (final_sales + initial_sales) AS Total_ev_sales,
ROUND((POW(final_sales / NULLIF(initial_sales, 0), 1.0 / NULLIF(final_year - initial_year, 0)) - 1) *100, 2) AS CAGR,
-- Projected Sales=Latest Sales×(1+CAGR) ^ years to 2030
ROUND(final_sales * POW(1 + (ROUND(POW(final_sales / NULLIF(initial_sales, 0), 1.0 / NULLIF(final_year - initial_year, 0)) - 1, 6)), (2030 - final_year)),2) AS projected_2030_sales
FROM
    CAGR
ORDER BY projected_2030_sales DESC)
SELECT SUM(projected_2030_sales) FROM Pr_sale;


WITH EvSale AS(
SELECT 
    maker,vehicle_category, fiscal_year, SUM(maker_sales) AS Total_EvSales
FROM
    evData
WHERE
    Fiscal_year IN (2022 , 2023, 2024)
GROUP BY Fiscal_year , maker,vehicle_category),
Sale AS (
SELECT Maker ,vehicle_category,MAX(CASE WHEN fiscal_year = 2022 THEN Total_EvSales ELSE 0 END ) AS Sale_2022 ,
MAX(CASE WHEN fiscal_year = 2024 THEN Total_EvSales ELSE 0 END  ) AS Sale_2024 FROM EvSale GROUP BY Maker,vehicle_category)
SELECT 
    Maker,vehicle_category,
    (Sale_2022 + Sale_2024) AS TOTAL_EV_SOLD,
    ROUND((POWER(Sale_2024 / Sale_2022, 1 / 2) - 1) * 100,2) AS CAGR
FROM
    Sale
WHERE
    Sale_2022 > 0
ORDER BY (Sale_2022 + Sale_2024) DESC;