-- Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?

-- Pohled na porovnání cen chleba, mléka a mezd v odvětví i celonárodní průměrné mzdy.
CREATE OR REPLACE VIEW bread_milk_price_vs_payroll AS
SELECT 
    pta.year,
    pta.industry,
    pta.industry_code,
    AVG(pta.avg_payroll) AS avg_payroll,
    AVG(pta.prev_year_payroll) AS prev_year_payroll,
    AVG(pta.national_avg_payroll) AS national_avg_payroll,
    ROUND(AVG(pta.percent_change), 2) AS percent_change,
    pta.trend,
    trbpspf.food_category_code,  -- Přidání food_category_code
    trbpspf.food_name,  -- Přidání food_name
    AVG(trbpspf.food_price) AS food_price,
    ROUND((AVG(pta.avg_payroll) / AVG(trbpspf.food_price)), 2) AS number_of_pieces,
    ROUND((AVG(pta.national_avg_payroll) / AVG(trbpspf.food_price)), 2) AS national_number_of_pieces
FROM payroll_trend_analysis AS pta 
JOIN t_romana_belohoubkova_project_SQL_primary_final AS trbpspf
    ON trbpspf.year = pta.year
WHERE trbpspf.food_category_code IN (114201, 111301) -- 114201: mléko, 111301: chléb
GROUP BY pta.year, pta.industry, pta.industry_code, pta.trend, trbpspf.food_category_code, trbpspf.food_name;

-- Pohled na porovnání cen mléka a chleba v průběhu let.
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
FROM (
    SELECT 
        year,
        food_category_code,
        food_name,
        AVG(food_price) AS avg_price,
        LAG(AVG(food_price), 1) OVER (PARTITION BY food_category_code ORDER BY year) AS prev_year_price
    FROM t_romana_belohoubkova_project_sql_primary_final AS trbpspf
    WHERE food_category_code IN (114201, 111301) -- 114201: mléko, 111301: chléb
    GROUP BY year, food_category_code, food_name
) AS bread_milk_yearly_change
ORDER BY year, food_category_code;

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
FROM bread_milk_price_trend_analysis AS bmpta
GROUP BY food_name
ORDER BY total_percent_change DESC;

-- Zjisti největší meziroční procentuální nárust ceny mléka a chleba.
SELECT
    `year`, 
    food_name,
    MAX(percent_change) AS max_percent_change
FROM bread_milk_price_trend_analysis AS bmpta 
WHERE percent_change IS NOT NULL
    AND food_category_code = 114201  -- Mléko
GROUP BY `year`, food_name 
ORDER BY max_percent_change DESC
LIMIT 1;

SELECT
    `year`, 
    food_name,
    MAX(percent_change) AS max_percent_change
FROM bread_milk_price_trend_analysis AS bmpta 
WHERE percent_change IS NOT NULL
    AND food_category_code = 111301  -- Chléb
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
	AND food_category_code = 114201 -- Mléko
GROUP BY `year`, food_name 
ORDER BY min_percent_change ASC 
LIMIT 1;

SELECT
	`year`, 
	food_name,
	MIN(percent_change) AS min_percent_change
FROM bread_milk_price_trend_analysis AS bmpta 
WHERE percent_change IS NOT NULL
	AND food_category_code = 111301 -- Chléb
GROUP BY `year`, food_name 
ORDER BY min_percent_change ASC
LIMIT 1;

-- Zjisti kolik bylo možno koupit chleba a mléka za průměrnou mzdu v roce 2006 a 2018.
SELECT DISTINCT 
    `year`,
    food_name,
    national_number_of_pieces 
FROM bread_milk_price_vs_payroll AS bmpvp
WHERE `year` IN (2006, 2018)
ORDER BY `year`, food_name, number_of_pieces;

-- Zjisti, které odvětví si mohlo dovolit koupit nejvíce a nejméně mléka a chleba v roce 2006.
SELECT 
    bmpvp.year,
    bmpvp.industry,
    bmpvp.food_name,
    ROUND(bmpvp.number_of_pieces, 2) AS number_of_pieces
FROM bread_milk_price_vs_payroll AS bmpvp
WHERE bmpvp.year = 2006
ORDER BY number_of_pieces ASC, bmpvp.year, bmpvp.industry, bmpvp.food_name;

-- Zjisti, které odvětví si mohlo dovolit koupit nejvíce a nejméně mléka a chleba v roce 2018.
SELECT 
    bmpvp.year,
    bmpvp.industry,
    bmpvp.food_name,
    ROUND(bmpvp.number_of_pieces, 2) AS number_of_pieces
FROM bread_milk_price_vs_payroll AS bmpvp
WHERE bmpvp.year = 2018
ORDER BY number_of_pieces ASC, bmpvp.year, bmpvp.industry, bmpvp.food_name;







