----Loading data in coffee sales
select * from coffeesales;

---checking for duplicates
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id, transaction_date, transaction_time, transaction_qty, store_id, 
                         store_location, product_id, unit_price, product_category, product_type
            ORDER BY transaction_id
        ) AS row_num
    FROM 
        coffeesales
) AS duplicates
WHERE 
    row_num > 1;

--- delete the duplicates
WITH duplicates AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id, transaction_date, transaction_time, transaction_qty, store_id, 
                         store_location, product_id, unit_price, product_category, product_type
            ORDER BY transaction_id  -- Adjust the ordering as needed
        ) AS row_num
    FROM 
        coffeesales
)
DELETE FROM duplicates
WHERE row_num > 1;

----Handling missing value
SELECT 
    (COUNT(CASE WHEN transaction_id IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_transaction_id,
    (COUNT(CASE WHEN transaction_date IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_transaction_date,
    (COUNT(CASE WHEN transaction_time IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_transaction_time,
    (COUNT(CASE WHEN transaction_qty IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_transaction_qty,
    (COUNT(CASE WHEN store_id IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_store_id,
    (COUNT(CASE WHEN store_location IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_store_location,
    (COUNT(CASE WHEN product_id IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_product_id,
    (COUNT(CASE WHEN unit_price IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_unit_price,
    (COUNT(CASE WHEN product_category IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_product_category,
    (COUNT(CASE WHEN product_type IS NULL THEN 1 END) * 100.0 / COUNT(*)) AS percent_null_product_type
FROM 
    coffeesales;

---No null Values
----Standardised the Text
UPDATE coffeesales
SET product_type = UPPER(LEFT(product_type, 1)) + LOWER(SUBSTRING(product_type, 2, LEN(product_type) - 1));
----Data extraction
select * from coffeesales
---updating Datatype
UPDATE coffeesales
SET unit_price = ROUND(unit_price, 2);
---EDA
---1. Total Sales
SELECT 
    SUM(transaction_qty * unit_price) AS Total_Sales
FROM coffeesales;
----2. Total Sales Month on Month
SELECT 
    MONTH(transaction_date) AS Sales_Month,
    SUM(transaction_qty * unit_price) AS Total_Sales
FROM coffeesales
GROUP BY MONTH(transaction_date);
----3. Getting Monthname
SELECT 
    FORMAT(transaction_date, 'MMMM') AS Sales_Month,
    SUM(transaction_qty * unit_price) AS Total_Sales
FROM coffeesales
GROUP BY FORMAT(transaction_date, 'MMMM'), MONTH(transaction_date)
ORDER BY MONTH(transaction_date);
-----4. TOP 10 ITEM AND ITS CONTRIBUTION
SELECT TOP 5 
    product_type,
    SUM(transaction_qty * unit_price) AS product_Sales
FROM coffeesales
GROUP BY product_type
ORDER BY product_Sales DESC
----Contribution
SELECT 
    TOP 5 product_type,
    SUM(transaction_qty * unit_price) AS product_Sales,
    (SUM(transaction_qty * unit_price) * 100.0 / (SELECT SUM(transaction_qty * unit_price) FROM coffeesales)) AS Percentage_Contribution
FROM coffeesales
GROUP BY product_type
ORDER BY product_Sales DESC;
----Top Product Cateegory
SELECT 
    TOP 5 product_category,
    SUM(transaction_qty * unit_price) AS product_Sales,
    (SUM(transaction_qty * unit_price) * 100.0 / (SELECT SUM(transaction_qty * unit_price) FROM coffeesales)) AS Percentage_Contribution
FROM coffeesales
GROUP BY product_category
ORDER BY product_Sales DESC;
----Sales of May
SELECT ROUND(SUM(unit_price * transaction_qty), 2) AS may_sales 
FROM coffeesales  
WHERE MONTH(transaction_date) = 5; -- for month of May

----Quantity Sold in May
SELECT SUM(transaction_qty) AS total_quantity_sold 
FROM coffeesales  
WHERE MONTH(transaction_date) = 5; -- for may month 

---SALES TREND OVER May 
SELECT AVG(total_sales) AS average_sales 
FROM ( 
SELECT SUM(unit_price * transaction_qty) AS total_sales 
 FROM coffeesales 
WHERE MONTH(transaction_date) = 5  -- Filter for May 
GROUP BY transaction_date 
) AS internal_query;

---- MAY SALES ANALYSIS BY WEEKDAYS AND WEEKENDS 
SELECT  
    CASE 
        WHEN DATEPART(WEEKDAY, transaction_date) IN (1, 7) THEN 'weekends' 
        ELSE 'weekdays' 
    END AS day_type, 
    ROUND(SUM(unit_price * transaction_qty) / 1000.0, 1) AS Total_sales 
FROM coffeesales 
WHERE MONTH(transaction_date) = 5 -- For month of May
GROUP BY  
    CASE 
        WHEN DATEPART(WEEKDAY, transaction_date) IN (1, 7) THEN 'weekends' 
        ELSE 'weekdays' 
    END;

----DAILY SALES FOR MONTH SELECTED -- May
SELECT 
    DAY(transaction_date) AS day_of_month, 
    ROUND(SUM(unit_price * transaction_qty) , 3)  AS Daily_Sales
FROM coffeesales 
WHERE MONTH(transaction_date) = 5 -- For month of May
GROUP BY DAY(transaction_date) 
ORDER BY DAY(transaction_date);

-----COMPARING DAILY SALES WITH AVERAGE SALES – IF GREATER THAN “ABOVE AVERAGE” and LESSER THAN “BELOW AVERAGE” 
SELECT 
    day_of_month, 
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average' 
        WHEN total_sales < avg_sales THEN 'Below Average' 
        ELSE 'Equal to Average' 
    END AS sales_status, 
    total_sales 
FROM ( 
    SELECT 
        DAY(transaction_date) AS day_of_month, 
        ROUND(SUM(unit_price * transaction_qty) / 1000.0, 1) AS total_sales,
        AVG(ROUND(SUM(unit_price * transaction_qty) / 1000.0, 1)) OVER() AS avg_sales 
    FROM coffeesales 
    WHERE MONTH(transaction_date) = 5 -- For month of May
    GROUP BY DAY(transaction_date) 
) AS sales_data 
ORDER BY day_of_month;

----SALES BY DAY | HOUR 
SELECT 
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000.0, 1), 'K') AS total_sales, 
    SUM(transaction_qty) AS total_qty_sold, 
    COUNT(*) AS total_orders 
FROM coffeesales 
WHERE MONTH(transaction_date) = 5 -- May month 
AND DATEPART(WEEKDAY, transaction_date) = 2 -- Monday (1 = Sunday, 2 = Monday, etc.)
AND DATEPART(HOUR, transaction_time) = 8; -- 8 AM

----TO GET SALES FOR ALL HOURS FOR MONTH OF MAY 
SELECT 
    DATEPART(HOUR, transaction_time) AS transaction_hour, 
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000.0, 1), 'K') AS total_sales 
FROM coffeesales 
WHERE MONTH(transaction_date) = 5 -- For the month of May
GROUP BY DATEPART(HOUR, transaction_time) 
ORDER BY transaction_hour ASC;

----TO GET SALES FROM MONDAY TO SUNDAY FOR MONTH OF MAY 
SELECT  
    CASE  
        WHEN DATEPART(WEEKDAY, transaction_date) = 1 THEN 'Sunday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 2 THEN 'Monday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 3 THEN 'Tuesday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 4 THEN 'Wednesday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 5 THEN 'Thursday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 6 THEN 'Friday' 
        ELSE 'Saturday' 
    END AS Day_of_Week, 
    ROUND(SUM(unit_price * transaction_qty),3) AS total_sales 
FROM coffeesales 
WHERE MONTH(transaction_date) = 5 -- Filter for May (month number 5) 
GROUP BY  
    CASE  
        WHEN DATEPART(WEEKDAY, transaction_date) = 1 THEN 'Sunday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 2 THEN 'Monday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 3 THEN 'Tuesday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 4 THEN 'Wednesday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 5 THEN 'Thursday' 
        WHEN DATEPART(WEEKDAY, transaction_date) = 6 THEN 'Friday' 
        ELSE 'Saturday' 
    END;















