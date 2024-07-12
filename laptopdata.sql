/***********************************************************DATA CLEANING**********************************************************************

/*S-1. Create Backup*/

CREATE TABLE laptopdata_backup LIKE projects.laptopdata;

INSERT INTO laptopdata_backup
SELECT * FROM projects.laptopdata;

/*S-2. Check number of rows*/

SELECT COUNT(*) FROM projects.laptopdata;

/*S-3. Check memory consumption for reference. */

SELECT * FROM information_schema.TABLE
WHERE TABLE_SCHEMA = 'projects'
AND TABLE_NAME = 'laptopdata';

/*S-4. Drop non-important columns.*/

SELECT * FROM projects.laptopdata;

ALTER TABLE projects.laptopdata DROP COLUMN `Unnamed: 0`;

/*S-5. DROP NULL VALUES */

DELETE FROM projects.laptopdata
WHERE ID IN (SELECT ID FROM projects.laptopdata
WHERE Company = ' ' AND TypeName = ' ' AND ScreenResolution = ' ' 
AND Cpu = ' ' AND Gpu = ' ' AND OpSys = ' ' 
AND Weight = ' ' AND Price = ' ' AND Inches = ' ');

/*S-6. DROP DUPLICATES*/

DELETE FROM projects.laptopdata
WHERE (Company, TypeName, Inches, ScreenResolution, Cpu, Ram, Memory, Gpu, OpSys, Weight, Price) 
NOT IN
(SELECT DISTINCTROW Company, TypeName, Inches, ScreenResolution, Cpu, Ram, Memory, Gpu, OpSys, Weight, Price FROM projects.laptopdata);

/*S-7 Clean RAM --> Change column data-type*/

/*1. Changing Data-type*/

SELECT * FROM projects.laptopdata;

/*Changing Ram DATA-TYPE from text to integer*/

/*REPLACE(string, to_be_replaced, to_replace_with)*/ 
SELECT REPLACE(Ram, "GB", " ") FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET Ram = (SELECT REPLACE(Ram, "GB", " ") FROM projects.laptopdata t2 WHERE t2.ID = t1.ID);

ALTER TABLE projects.laptopdata MODIFY COLUMN Ram INTEGER;

SELECT * FROM projects.laptopdata;

SELECT REPLACE(Weight, "kg", " ") FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET Weight = (SELECT REPLACE(Weight, "kg", " ") FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

ALTER TABLE projects.laptopdata MODIFY COLUMN Weight INTEGER;

SELECT * FROM projects.laptopdata;

/*Round Off price*/

SELECT ROUND(Price) FROM projects.laptopdata;

/*Updating price*/

UPDATE projects.laptopdata t1
SET Price = (SELECT ROUND(Price) FROM projects.laptopdata t2 WHERE t2.ID = t1.ID);

ALTER TABLE projects.laptopdata MODIFY COLUMN Price INTEGER;

SELECT * FROM projects.laptopdata;

/*Adding a column ---> OS_type*/

SELECT DISTINCT(OpSys) FROM projects.laptopdata;

SELECT OpSys,
CASE
	WHEN OpSys LIKE '%mac%' THEN 'Mac'
    WHEN OpSys LIKE 'No%' THEN 'N/A'
    WHEN OpSys LIKE 'Windows%' THEN 'Windows'
    WHEN OpSys = 'Linux' THEN 'Linux'
    ELSE 'Others'
END AS 'OS-Type'
FROM projects.laptopdata;

/*Updating OsSys to OS-Type*/

UPDATE projects.laptopdata
SET OpSys = CASE
	WHEN OpSys LIKE '%mac%' THEN 'Mac'
    WHEN OpSys LIKE 'No%' THEN 'N/A'
    WHEN OpSys LIKE 'Windows%' THEN 'Windows'
    WHEN OpSys = 'Linux' THEN 'Linux'
    ELSE 'Others'
END;

SELECT * FROM projects.laptopdata;

/*Gpu --> GpuBrand + GpuName*/

ALTER TABLE projects.laptopdata ADD COLUMN Gpu_brand VARCHAR(255) AFTER Gpu;
ALTER TABLE projects.laptopdata ADD COLUMN Gpu_name VARCHAR(255) AFTER Gpu_brand;

SELECT DISTINCT(Gpu) FROM projects.laptopdata;
 
UPDATE projects.laptopdata
SET Gpu_brand = CASE
	WHEN Gpu LIKE '%Intel%' THEN 'Intel'
    WHEN Gpu LIKE '%AMD%' THEN 'AMD'
    WHEN Gpu LIKE '%Nvidia%' THEN 'Nvidia'
    WHEN Gpu LIKE 'ARM%' THEN 'ARM'
END;

UPDATE projects.laptopdata
SET Gpu_name = CASE
	WHEN Gpu LIKE '%Intel%' THEN SUBSTR(Gpu, 6)
    WHEN Gpu LIKE '%AMD%' THEN SUBSTR(Gpu, 4)
    WHEN Gpu LIKE '%Nvidia%' THEN SUBSTR(Gpu, 7)
    WHEN Gpu LIKE 'ARM%' THEN SUBSTR(Gpu, 4)
END;

/*Other way of doing this --- using SUBSTRING_INDEX()*/

/*SUBSTRING_INDEX(string, splitting-char, occurence of splitting-char)*/

SELECT SUBSTRING_INDEX(Gpu, ' ', 1) FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET Gpu_brand = (SELECT SUBSTRING_INDEX(Gpu, ' ', 1) FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

SELECT REPLACE(Gpu, Gpu_brand, '') FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET Gpu_name = (SELECT REPLACE(Gpu, Gpu_brand, '') FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

ALTER TABLE projects.laptopdata DROP COLUMN Gpu;

/*Cpu ---> Cpu_brand + Cpu_Name + Processing_speed*/
SELECT DISTINCT(Cpu) FROM projects.laptopdata;

ALTER TABLE projects.laptopdata ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed VARCHAR(255) AFTER cpu_name;

SELECT Cpu, SUBSTRING_INDEX(Cpu, ' ', 1) AS 'cpu_brand' FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET cpu_brand = (SELECT SUBSTRING_INDEX(Cpu, ' ', 1) AS 'cpu_brand' FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

SELECT Cpu, SUBSTRING_INDEX(Cpu, ' ', -1) AS 'cpu_speed' FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET cpu_speed = (SELECT SUBSTRING_INDEX(Cpu, ' ', -1) AS 'cpu_speed' FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

SELECT Cpu, REPLACE(REPLACE(Cpu, cpu_brand, ''), cpu_speed, '') AS 'cpu_name' FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET cpu_name = (SELECT REPLACE(REPLACE(Cpu, cpu_brand, ''), cpu_speed, '') AS 'cpu_name' FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

SELECT CAST(REPLACE(cpu_speed, 'GHz', '') AS DECIMAL(10, 2)) FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET cpu_speed = (SELECT CAST(REPLACE(cpu_speed, 'GHz', '') AS DECIMAL(10, 2)) FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

ALTER TABLE projects.laptopdata MODIFY COLUMN cpu_speed DECIMAL(10, 2);
ALTER TABLE projects.laptopdata DROP COLUMN Cpu;

/*Screen Resolution --> Extracting Resolution width and Resolution Height
IMPORTANT --> Determine whether laptop is TouchScreen or not*/

ALTER TABLE projects.laptopdata ADD COLUMN resolution_width VARCHAR(255) AFTER ScreenResolution;
ALTER TABLE projects.laptopdata ADD COLUMN resolution_height INT AFTER resolution_width;
ALTER TABLE projects.laptopdata ADD COLUMN TouchScreen BOOLEAN AFTER resolution_height;

SELECT SUBSTRING_INDEX(ScreenResolution, 'x', -1) AS 'resolution_height' FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET resolution_height = (SELECT SUBSTRING_INDEX(ScreenResolution, 'x', -1) AS 'resolution_height' FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

SELECT SUBSTRING_INDEX(REPLACE(REPLACE(ScreenResolution, resolution_height, ''), 'x', ''), ' ', -1) AS 'resolution_width' FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET resolution_width = (SELECT SUBSTRING_INDEX(REPLACE(REPLACE(ScreenResolution, resolution_height, ''), 'x', ''), ' ', -1) AS 'resolution_width' FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

SELECT 
CASE 
	WHEN ScreenResolution LIKE "%TouchScreen%" THEN 1
    ELSE 0
END AS 'TouchScreen'
FROM projects.laptopdata;

UPDATE projects.laptopdata
SET TouchScreen = 
CASE 
	WHEN ScreenResolution LIKE "%TouchScreen%" THEN 1
    ELSE 0
END ;

ALTER TABLE projects.laptopdata DROP COLUMN ScreenResolution;

SELECT * FROM projects.laptopdata;

/*Memory ------> type + primary_memory + secondary_memory
type --->
1. hybrid = SDD + HDD
2. HDD
3. SDD*/

ALTER TABLE projects.laptopdata ADD COLUMN Memory_Type VARCHAR(255) AFTER Memory;
ALTER TABLE projects.laptopdata ADD COLUMN primary_memory VARCHAR(255) AFTER Memory_Type;
ALTER TABLE projects.laptopdata ADD COLUMN secondary_memory VARCHAR(255) AFTER primary_memory;

SELECT DISTINCT(Memory), 
CASE
	WHEN Memory LIKE '%Hybrid%' THEN 'hybrid'
    WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' AND NOT Memory LIKE '%Hybrid%' AND NOT  Memory LIKE '%Flash Storage%' THEN 'hybrid'
    WHEN Memory LIKE '%SSD%' AND NOT  Memory LIKE '%HDD%' AND NOT  Memory LIKE '%Hybrid%' AND NOT  Memory LIKE '%Flash Storage%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' AND NOT  Memory LIKE '%SSD%' AND NOT  Memory LIKE '%Hybrid%' AND NOT  Memory LIKE '%Flash Storage%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' AND NOT  Memory LIKE '%SSD%' AND NOT  Memory LIKE '%HDD%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%SDD%' THEN 'hybrid'
END AS 'Type'
FROM projects.laptopdata; 

SELECT DISTINCT(Memory), 
CASE
	WHEN Memory LIKE '%Hybrid%' THEN 'hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%SDD%' THEN 'hybrid'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    ELSE NULL
END AS 'Type'
FROM projects.laptopdata; 

UPDATE projects.laptopdata
SET Memory_Type = 
CASE
	WHEN Memory LIKE '%Hybrid%' THEN 'hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%SDD%' THEN 'hybrid'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    ELSE NULL
END;

SELECT  DISTINCT(Memory), SUBSTRING_INDEX(Memory, ' ', 1) AS 'primary_memory', 
CASE 
	WHEN Memory LIKE '%+%' THEN	SUBSTRING_INDEX(TRIM(SUBSTRING_INDEX(Memory, '+', -1)), ' ', 1) 
END AS 'secondary_memory'
FROM projects.laptopdata
;

UPDATE projects.laptopdata t1
SET primary_memory = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory, '+', 1), '[0-9]+');

UPDATE projects.laptopdata
SET secondary_memory = 
CASE 
	WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(TRIM(SUBSTRING_INDEX(Memory, '+', -1)), '[0-9]+')
    ELSE 0
END;

ALTER TABLE projects.laptopdata MODIFY COLUMN secondary_memory INT;

UPDATE projects.laptopdata
SET secondary_memory = 
CASE
	WHEN secondary_memory < 5 THEN secondary_memory*1024 
    ELSE secondary_memory*1
END;

ALTER TABLE projects.laptopdata MODIFY COLUMN primary_memory INT;

UPDATE projects.laptopdata
SET primary_memory = 
CASE
	WHEN primary_memory < 5 THEN primary_memory*1024 
    ELSE primary_memory*1
END;

ALTER TABLE projects.laptopdata DROP COLUMN Memory;

SELECT * FROM projects.laptopdata;

/*The most important thing while Data-Cleaning is --
	We must maintain GENERALITY in the data so that it can be used to make accurate predictions. 
    And for that reason we must avoid SPECIFIC & UNNECESSARY categories.
*/ 

/*
In CPU_name column there are different categories of same cpu_name that leads to specificity in the data ---> Replace them with a common name.
Ex. Core i5 7200U -> Core i5
*/

SELECT SUBSTRING_INDEX(TRIM(cpu_name), ' ', 2) FROM projects.laptopdata;

UPDATE projects.laptopdata t1
SET cpu_name = (SELECT SUBSTRING_INDEX(TRIM(cpu_name), ' ', 2) FROM projects.laptopdata t2 WHERE t1.ID = t2.ID);

/*Similar thing can be observed in GPU_name .i.e. too many categories and the column as a whole seems useless
if we predict the price of a laptop as it does not seems as a important factor in determining the price of a laptop

So a simple solution to avoid too many categories is to drop such column*/

ALTER TABLE projects.laptopdata DROP COLUMN Gpu_name;

SELECT * FROM projects.laptopdata;

/*****************************************************EDA ---> EXPLORATORY DATA ANALYSIS****************************************************/

-- All these steps are performed non-linearly.
-- 1. MISSING VALUE IMPUTATION
-- 2. FEATURE ENGINEERING
-- 3. UNIVARIATE ANALYSIS
-- 4. BIVARIATE ANALYSIS
-- 5. ONE-HOT ENCODING --> Converting a categorical column to numerical (for forecasting).

-- Since we have to forecast the price of a laptop so we have to perform EDA while focussing on price.

SELECT * FROM projects.laptopdata;

-- 1. head->tail->sample

-- head
SELECT * FROM projects.laptopdata
ORDER BY ID LIMIT 5;

-- tail
SELECT * FROM projects.laptopdata
ORDER BY ID DESC LIMIT 5;

-- sample
SELECT * FROM projects.laptopdata
ORDER BY rand() LIMIT 5;

-- 2. Univariate analysis - Analyzing numerical column

-- 8 number summary
-- count
-- min
-- max
-- mean
-- std
-- q1
-- q2
-- q3

-- for price column

SELECT COUNT(price) OVER(), 
MIN(price) OVER(), 
MAX(price) OVER(), 
AVG(price) OVER(), 
STD(price) OVER(), 
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY price) OVER() AS 'MEDIAN', 
PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY price) OVER() AS 'Q1', 
PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY price) OVER() AS 'Q3'
FROM projects.laptopdata
ORDER BY ID LIMIT 1;

-- MISSING VALUES

SELECT COUNT(*) FROM projects.laptopdata
WHERE price IS NULL;

-- OUTLIERS

SELECT * FROM (SELECT *,
PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY price) OVER() AS 'Q1',
PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY price) OVER() AS 'Q2',
PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY price) OVER() AS 'Q3'
FROM projects.laptopdata) t
WHERE price < (Q1 - 1.5*(Q3-Q1)) OR price > (Q3 + 1.5*(Q3-Q1));

-- horizontal/vertical histogram
-- In order to create histograms we need the number of bins and size of each bin.

-- bins can be created using segmentation of fixed size

SELECT bucket, COUNT(*), REPEAT('*',COUNT(*)/5) FROM (SELECT price,
CASE 
	WHEN price > 0 AND price <= 25000 THEN '0-25K'
    WHEN price <= 50000 THEN '25K-50K'
    WHEN price <= 75000 THEN '50K-75K'
    WHEN price <= 100000 THEN '75K-100K'
    ELSE '100K-350K'
END AS 'bucket'
FROM projects.laptopdata) t
GROUP BY bucket;

-- Q. Create a vertical histogram of binsize = 25000

WITH t AS (SELECT c1.`index`, `0K-25K`, `25K-50K`, `50K-75K`, `75K-100K`, `100K-350K` FROM (SELECT ROW_NUMBER() OVER(ORDER BY `0K-25K` DESC) AS 'index',
CASE WHEN Price BETWEEN 0 AND 25000 THEN '*' ELSE ' 'END AS '0K-25K' 
FROM projects.laptopdata
ORDER BY `0K-25K` DESC
) c1 
JOIN
(SELECT ROW_NUMBER() OVER(ORDER BY `25K-50K` DESC) AS 'index',
CASE WHEN Price BETWEEN 25001 AND 50000 THEN '*' ELSE ' 'END AS '25K-50K' 
FROM projects.laptopdata
ORDER BY `25K-50K` DESC) c2
ON c1.`index` = c2.`index` 
JOIN
(SELECT ROW_NUMBER() OVER(ORDER BY `50K-75K` DESC) AS 'index',
CASE WHEN Price BETWEEN 50000 AND 75000 THEN '*' ELSE ' 'END AS '50K-75K' 
FROM projects.laptopdata
ORDER BY `50K-75K` DESC) c3
ON c2.`index` = c3.`index`
JOIN 
(SELECT ROW_NUMBER() OVER(ORDER BY `75K-100K` DESC) AS 'index',
CASE WHEN Price BETWEEN 75001 AND 100000 THEN '*' ELSE ' 'END AS '75K-100K' 
FROM projects.laptopdata
ORDER BY `75K-100K` DESC) c4
ON c3.`index` = c4.`index`
JOIN
(SELECT ROW_NUMBER() OVER(ORDER BY `100K-350K` DESC) AS 'index',
CASE WHEN Price BETWEEN 100001 AND 350000 THEN '*' ELSE ' 'END AS '100K-350K' 
FROM projects.laptopdata
ORDER BY `100K-350K` DESC) c5
ON c4.`index` = c5.`index`)

SELECT `Numbers (X40)`, `0K-25K`, `25K-50K`, `50K-75K`, `75K-100K`, `100K-350K` FROM (SELECT *,
NTILE(10) OVER(ORDER BY `index`) AS 'Numbers (X40)'
FROM t
WHERE `0K-25K` = '*' OR `25K-50K` = '*' OR `50K-75K` = '*' OR `75K-100K` = '*' OR `100K-350K` = '*') t1
GROUP BY `Numbers (X40)`
ORDER BY `Numbers (X40)` DESC;

-- Categorical Data

-- value counts --> to konow how freqently a category is occuring in our data.(PIE Chart)
-- missing value 

-- Company 
SELECT Company, COUNT(*) AS 'products' FROM projects.laptopdata
GROUP BY Company;

-- INSIGHTS
-- Chinese Laptop-Manufacturer Lenovo has the biggest market share (22.8%)
-- Companies Trailing behind are Dell (22.5%) and HP(20.9%)   

-- inches

SELECT Inches, COUNT(*) AS 'products' FROM projects.laptopdata
WHERE Inches > 0
GROUP BY Inches;

-- Laptops with screen-size 15.6 inches are the most popular with 78.7% market capture.
-- And 17.3 inches laptop are the second-most popular with 19.9% market capture
  
-- Touchscreen Y/N

SELECT TouchScreen, COUNT(*) AS 'products' FROM projects.laptopdata
GROUP BY TouchScreen;

-- 85.5% Laptops are not Touchscreen. This emplies that Non-touch Laptops are more popular 

-- CPU supplier

SELECT cpu_brand, COUNT(*) AS 'products' FROM projects.laptopdata
GROUP BY cpu_brand;

-- intel has a monopoly over CPU market with 95.1% laptops using the same. 

-- RAM

SELECT Ram, COUNT(*) AS 'products' FROM projects.laptopdata
GROUP BY Ram;

-- Hi-Spec Laptops are more popular with laptops having 8GB Ram having 47.2% market capture

-- Memory_Type

SELECT Memory_Type, COUNT(*) AS 'products' FROM projects.laptopdata
WHERE Memory_Type IS NOT NULL
GROUP BY Memory_Type;

-- SSD is most popular, HDD and hybrid have a fair share and flash storage is the least popular. 

-- Processor

SELECT cpu_name, COUNT(*) AS 'products' FROM projects.laptopdata
GROUP BY cpu_name;

-- Core i7 is the most popular processor followed by Core i5 and Core i3

-- Primary memory

SELECT primary_memory, COUNT(*) AS 'products' FROM projects.laptopdata
GROUP BY primary_memory;

-- 128GB, 256GB, 512GB, 1024GB have a coin-name in the market
-- 256GB config is the most popular.

-- Gpu_brand

SELECT Gpu_brand, COUNT(*) AS 'products' FROM projects.laptopdata
GROUP BY Gpu_brand;

-- Intel and Nvidia are the main competitors in Gpu with AMD as a rising player.

-- OpSys

SELECT OpSys, COUNT(*) AS 'products' FROM projects.laptopdata
GROUP BY OpSys;

-- Windows OpSys are the most popular with 86.4% laptops equipped with Windows only.
 
-- Weight

SELECT Weight, COUNT(*) AS 'products' FROM projects.laptopdata
GROUP BY Weight;

-- With 48.4% laptops having 2kg of Weight implies laptops with hi-specs and sustainable weight are more preferred.

-- Bi-Variate Analysis

-- 1. Numerical-Numerical
-- 1.1. side by side 8 number analysis
-- 1.2. scatter plot
-- 1.3. correlation

-- 2. Categorical-categorical
-- 2.1. Contingency Table

-- Company V/S TouchScreen

WITH t AS(SELECT Company, TouchScreen, counts FROM (SELECT *, 
			COUNT(*) OVER(PARTITION BY Company, TouchScreen) AS 'counts',
			ROW_NUMBER() OVER(PARTITION BY Company, TouchScreen) AS 'index'
			FROM projects.laptopdata) t
			WHERE `index` = 1)

SELECT Company , SUM(Y) AS 'Touch', SUM(N) AS 'Non-Touch' FROM (SELECT *, 
CASE WHEN TouchScreen = 1 THEN counts ELSE 0 END AS 'Y',
CASE WHEN TouchScreen = 0 THEN counts ELSE 0 END AS 'N'
FROM t) t1
GROUP BY Company;

-- Optimized Approach

SELECT Company,
SUM(CASE WHEN TouchScreen = 1 THEN 1 ELSE 0 END) AS 'Touch',
SUM(CASE WHEN TouchScreen = 0 THEN 1 ELSE 0 END) AS 'Non-Touch'
FROM projects.laptopdata
GROUP BY Company;
--  Stacked Bar Chart

-- Company V/S Cpu 
-- Company V/S Cpu 
  
SELECT * FROM projects.laptopdata;

