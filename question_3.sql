-- Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)

-- Pohled průměrná cena potravin v letech.
CREATE OR REPLACE VIEW avg_food_price_per_year AS
SELECT 
    year,
    food_category_code,
    food_name,
    AVG(food_price) AS avg_food_price
FROM t_romana_belohoubkova_project_sql_primary_final AS trbpspf
GROUP BY food_category_code, food_name, year;

-- Pohled pro výpočet procentuální změny a označení trendu.
CREATE OR REPLACE VIEW food_price_trend_analysis AS
SELECT 
    year,
    food_category_code,
    food_name,
    avg_food_price,
    prev_year_price,
    CASE 
        WHEN prev_year_price IS NOT NULL THEN ROUND(((avg_food_price - prev_year_price) / prev_year_price) * 100, 2)
        ELSE NULL
    END AS percent_change,
    CASE 
        WHEN prev_year_price IS NULL THEN NULL
        WHEN avg_food_price > prev_year_price THEN 'increased'
        WHEN avg_food_price < prev_year_price THEN 'decreased'
        ELSE 'no change'
    END AS trend
FROM (
    SELECT 
        year,
        food_category_code,
        food_name,
        avg_food_price,
        LAG(avg_food_price) OVER (PARTITION BY food_category_code ORDER BY year) AS prev_year_price
    FROM avg_food_price_per_year
) AS afppy;


-- Zjisti jaký je u potravin meziroční percentuální nárůst za celé sledované období.
SELECT 
    food_category_code,
    food_name,
    ROUND(AVG(percent_change), 2) AS yearly_percent_change 
FROM food_price_trend_analysis AS fpta
WHERE percent_change IS NOT NULL
GROUP BY food_category_code, food_name
ORDER BY yearly_percent_change ASC;

-- Zjisti jaké potraviny nejvíce zlevnily a v kterém roce.
SELECT 
    year,
    food_name,
    ROUND(percent_change, 2) AS percent_change
FROM food_price_trend_analysis AS fpta
WHERE percent_change IS NOT NULL
AND percent_change < 0 
ORDER BY percent_change ASC;

-- Zjisti kolik let za sledované období ceny klesaly u konkrétních potravin.
SELECT 
    food_name,
    COUNT(year) AS years_with_decrease
FROM food_price_trend_analysis AS fpta
WHERE percent_change < 0
GROUP BY food_name
ORDER BY years_with_decrease DESC
LIMIT 3;

-- Zjisti, která potravina nejvíc zlevnila 2006 vs 2018.
SELECT 
    afppy.food_category_code,
    afppy.food_name,
    afppy.avg_food_price AS price_2006,
    afppy2.avg_food_price AS price_2018,
    ROUND(((afppy.avg_food_price - afppy2.avg_food_price) / afppy.avg_food_price) * 100, 2) AS percent_change
FROM avg_food_price_per_year AS afppy
JOIN avg_food_price_per_year AS afppy2
    ON afppy.food_category_code = afppy2.food_category_code
    AND afppy.food_name = afppy2.food_name
    AND afppy.year = 2006
    AND afppy2.year = 2018
WHERE afppy.avg_food_price IS NOT NULL
  AND afppy2.avg_food_price IS NOT NULL
ORDER BY percent_change DESC
LIMIT 3;





