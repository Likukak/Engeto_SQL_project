-- Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

-- Pohled pro roční průměrné ceny mléka a chleba
CREATE OR REPLACE VIEW avg_bread_milk_prices_per_year AS
SELECT 
    year,
    food_category_code,
    food_name,
    ROUND(AVG(food_price), 2) AS avg_price
FROM t_romana_belohoubkova_project_sql_primary_final AS trbpspf
WHERE food_category_code IN (114201, 111301) -- 114201: mléko, 111301: chléb
GROUP BY year, food_category_code, food_name
ORDER BY YEAR, food_category_code;

-- Pohled pro roční průměrnou mzdu napříč všemi odvětvími (celonárodní průměr).
CREATE OR REPLACE VIEW avg_national_payroll_per_year AS
SELECT 
    year,
    ROUND(AVG(avg_payroll), 1) AS avg_national_payroll
FROM avg_industry_payroll_per_year AS aippy 
GROUP BY year
ORDER BY year;

-- Pohled pro počet kusů mléka a chleba, které lze koupit za průměrnou celonárodní mzdu v jednotlivých letech.
CREATE OR REPLACE VIEW avg_number_of_pieces_national AS
SELECT 
    anppy.year,
    anppy.avg_national_payroll,
    abmppy.food_category_code,
    abmppy.food_name,
    abmppy.avg_price,
    ROUND(anppy.avg_national_payroll / abmppy.avg_price, 2) AS number_of_pieces
FROM avg_national_payroll_per_year AS anppy
JOIN avg_bread_milk_prices_per_year AS abmppy
ON anppy.year = abmppy.year
ORDER BY anppy.year, abmppy.food_category_code;

-- Pohled, který nám ukáže kolik kusů chleba a mléka lze koupit v průběhu let za výplaty v různých odvětvých.
CREATE OR REPLACE VIEW avg_number_of_pieces_per_industry AS
SELECT 
    aippy.year,
    aippy.industry,
    aippy.industry_code,
    aippy.avg_payroll,
    abmppy.food_category_code,
    abmppy.food_name,
    abmppy.avg_price,
    ROUND(aippy.avg_payroll / abmppy.avg_price) AS number_of_pieces
FROM avg_industry_payroll_per_year AS aippy 
JOIN avg_bread_milk_prices_per_year AS abmppy 
	ON aippy.year = abmppy.year
ORDER BY aippy.year, aippy.industry_code, abmppy.food_category_code;

-- Pohled pro přidání ceny mléka a chleba z předchozího roku pomocí LAG
CREATE OR REPLACE VIEW bread_milk_yearly_change AS
SELECT 
    year,
    food_category_code,
    food_name,
    avg_price,
    LAG(avg_price) OVER (PARTITION BY food_category_code ORDER BY year) AS prev_year_price
FROM avg_bread_milk_prices_per_year AS abmppy
ORDER BY year, food_category_code;

-- Pohled pro výpočet procentuální meziroční změny a trendu cen mléka a chleba.
CREATE OR REPLACE VIEW bread_milk_price_trend_analysis AS
SELECT 
    year,
    food_name,
    food_category_code,
    avg_price,
    prev_year_price,
    CASE 
        WHEN prev_year_price IS NULL THEN NULL
        ELSE ROUND(((avg_price - prev_year_price) / prev_year_price) * 100, 2)
    END AS percent_change,
    CASE 
        WHEN prev_year_price IS NULL THEN NULL
        WHEN avg_price > prev_year_price THEN 'increased'
        WHEN avg_price < prev_year_price THEN 'decreased'
        ELSE 'no change'
    END AS trend
FROM bread_milk_yearly_change AS bmyc 
ORDER BY year;

-- Zjisti v kolika letech ceny rostly.
SELECT 
	food_name, 
	COUNT(*) AS growth_years
FROM bread_milk_price_trend_analysis AS bmpta
WHERE trend = 'increased'
GROUP BY food_name 
ORDER BY growth_years DESC;

-- Zjisti v kolika letech ceny klesaly.
SELECT 
	food_name, 
	COUNT(*) AS declining_years
FROM bread_milk_price_trend_analysis AS bmpta
WHERE trend = 'decreased'
GROUP BY food_name 
ORDER BY declining_years DESC;

-- Zjisti průměrný meziroční procentuální růst cen pro chléb a mléko.
SELECT 
    food_name,
    ROUND(AVG(percent_change), 2) AS avg_growth
FROM bread_milk_price_trend_analysis AS bmpta
WHERE trend IS NOT NULL 
  	AND percent_change IS NOT NULL 
GROUP BY food_name 
ORDER BY avg_growth DESC;

-- Zjisti procentuální změnu ceny chleba a mléka mezi prvním a posledním rokem.
SELECT 
    food_name,
    ROUND(((MAX(avg_price) - MIN(avg_price)) / MIN(avg_price)) * 100, 2) AS total_percent_change
FROM bread_milk_yearly_change AS bmyc 
GROUP BY food_name
ORDER BY total_percent_change DESC;

-- Zjisti největší meziroční procentuální nárust ceny mléka a chleba.
SELECT
	`year`, 
	food_name,
	MAX(percent_change) AS max_percent_change
FROM bread_milk_price_trend_analysis AS bmpta 
WHERE percent_change IS NOT NULL
	AND food_category_code = 114201
GROUP BY `year`, food_name 
ORDER BY max_percent_change DESC
LIMIT 1;

SELECT
	`year`, 
	food_name,
	MAX(percent_change) AS max_percent_change
FROM bread_milk_price_trend_analysis AS bmpta 
WHERE percent_change IS NOT NULL
	AND food_category_code = 111301
GROUP BY `year`, food_name 
ORDER BY max_percent_change DESC
LIMIT 1;

-- Zjisti největší meziroční procentuální pokles ceny mléka a chleba.
SELECT
	`year`, 
	food_name,
	MIN(percent_change) AS min_percent_change
FROM bread_milk_price_trend_analysis AS bmpta 
WHERE percent_change IS NOT NULL
	AND food_category_code = 114201
GROUP BY `year`, food_name 
ORDER BY min_percent_change ASC 
LIMIT 1;

SELECT
	`year`, 
	food_name,
	MIN(percent_change) AS min_percent_change
FROM bread_milk_price_trend_analysis AS bmpta 
WHERE percent_change IS NOT NULL
	AND food_category_code = 111301
GROUP BY `year`, food_name 
ORDER BY min_percent_change ASC
LIMIT 1;

-- Zjisti kolik bylo možno koupit chleba a mléka za průměrnou mzdu v roce 2006 a 2018.
SELECT 
	`year`,
	food_name,
	number_of_pieces 
FROM avg_number_of_pieces_national AS anopn
WHERE `year` IN (2006,2018)
ORDER BY YEAR, food_name, number_of_pieces;

-- Zjisti, které odvětví si mohlo dovolit koupit nejvíce a nejméně mléka a chleba v roce 2006.
SELECT 
    anppy.year,
    anppy.industry,
    abmppy.food_name,
    ROUND(anppy.avg_payroll / abmppy.avg_price, 2) AS number_of_pieces
FROM avg_industry_payroll_per_year AS anppy
JOIN avg_bread_milk_prices_per_year AS abmppy
    ON anppy.year = abmppy.year
WHERE anppy.year = 2006
    AND abmppy.food_category_code IN (114201, 111301)
ORDER BY number_of_pieces ASC, anppy.year, anppy.industry, abmppy.food_name;

-- Zjisti, které odvětví si mohlo dovolit koupit nejvíce a nejméně mléka a chleba v roce 2018.
SELECT 
    anppy.year,
    anppy.industry,
    abmppy.food_name,
    ROUND(anppy.avg_payroll / abmppy.avg_price, 2) AS number_of_pieces
FROM avg_industry_payroll_per_year AS anppy
JOIN avg_bread_milk_prices_per_year AS abmppy
    ON anppy.year = abmppy.year
WHERE anppy.year = 2018
    AND abmppy.food_category_code IN (114201, 111301)
ORDER BY number_of_pieces ASC, anppy.year, anppy.industry, abmppy.food_name;






