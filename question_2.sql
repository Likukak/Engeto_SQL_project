-- Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
CREATE OR REPLACE VIEW avg_number_of_pieces_per_industry AS
SELECT 
    year,
    food_category_code,
    food_name,
    round(avg(food_price), 1) AS food_price,
    industry, 
    payroll,
    round(payroll / avg(food_price)) AS number_of_pieces
FROM t_romana_belohoubkova_project_sql_primary_final AS trbpspf 
WHERE food_category_code IN (114201, 111301)  -- 114201: mléko, 111301: chléb
GROUP BY year, industry, food_category_code, food_name
ORDER BY year;

-- Průměrná cena chléb pro každý rok.
CREATE OR REPLACE VIEW avg_bread_price_per_year AS
SELECT 
    year,
    round(avg(food_price), 2) AS avg_bread_price
FROM t_romana_belohoubkova_project_sql_primary_final
WHERE food_category_code = 111301
GROUP BY year
ORDER BY year;

-- Průměrná cena mléka pro každý rok.
CREATE OR REPLACE VIEW avg_milk_price_per_year AS
SELECT 
    year,
    round(avg(food_price), 2) AS avg_milk_price
FROM t_romana_belohoubkova_project_sql_primary_final AS trbpspf
WHERE food_category_code = 114201
GROUP BY year
ORDER BY year;

-- Kolik kusů mléka/chleba si lze koupit za výplatu konkrétního odvětví v konkrétním roce.
SELECT *
FROM avg_number_of_pieces_per_industry AS anofppi
WHERE food_category_code IN (114201, 111301)  -- 114201: mléko, 111301: chléb
    AND year = 2006
ORDER BY number_of_pieces DESC;

-- Kolik kusů mléka/chleba si lze koupit za průmeřnou výplatu v konkrétním roce.
WITH avg_payroll_all_industries AS (
SELECT 
    year,
    ROUND(AVG(avg_payroll), 2) AS avg_payroll_all_industries
    FROM avg_industry_payroll_per_year
    GROUP BY YEAR
)
SELECT 
    apai.`year`,
    apai.avg_payroll_all_industries,
    amp.avg_milk_price AS milk_price,
    ROUND(apai.avg_payroll_all_industries / amp.avg_milk_price) AS milk_pieces,
    abp.avg_bread_price AS bread_price,
    ROUND(apai.avg_payroll_all_industries / abp.avg_bread_price) AS bread_pieces
FROM avg_payroll_all_industries AS apai
JOIN avg_milk_price_per_year AS amp 
	ON apai.year = amp.year
JOIN avg_bread_price_per_year AS abp 
	ON apai.year = abp.year
ORDER BY apai.year;

SELECT * FROM avg_milk_price_per_year AS amppy ;

-- Procentuální změna ceny mléka a chleba oproti předchozímu roku.
WITH avg_payroll_all_industries AS (
SELECT 
    year,
    ROUND(AVG(avg_payroll), 2) AS avg_payroll_all_industries
    FROM avg_industry_payroll_per_year
    GROUP BY year
),
milk_and_bread_prices AS (
	SELECT 
    	amp.year,
     	apai.avg_payroll_all_industries,
     	amp.avg_milk_price AS milk_price,
     	ROUND(apai.avg_payroll_all_industries / amp.avg_milk_price) AS milk_pieces,
     	abp.avg_bread_price AS bread_price,
     	ROUND(apai.avg_payroll_all_industries / abp.avg_bread_price) AS bread_pieces
 	FROM avg_payroll_all_industries AS apai
    JOIN avg_milk_price_per_year AS amp 
        ON apai.year = amp.year
    JOIN avg_bread_price_per_year AS abp 
        ON apai.year = abp.year
)
SELECT 
    year,
    avg_payroll_all_industries,
    milk_price,
    ROUND((milk_price - LAG(milk_price) OVER (ORDER BY year)) / LAG(milk_price) OVER (ORDER BY year) * 100, 2) AS milk_percent_change,
    bread_price,
    ROUND((bread_price - LAG(bread_price) OVER (ORDER BY year)) / LAG(bread_price) OVER (ORDER BY year) * 100, 2) AS bread_percent_change,
    milk_pieces,
    bread_pieces
FROM milk_and_bread_prices
ORDER BY year;







