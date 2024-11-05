-- Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
-- Pohled průměrná cena potravin v letech.
CREATE OR REPLACE VIEW avg_food_price_per_year AS
SELECT 
	`year`,
	food_category_code,
	food_name,
	round(avg(food_price), 2) AS avg_food_price
FROM t_romana_belohoubkova_project_sql_primary_final AS trbpspf
GROUP BY food_name, food_category_code, `year` 
ORDER BY `year`;

-- Pohled přidání předchozích cen pomocí LAG.
CREATE OR REPLACE VIEW food_price_yearly_change AS
SELECT
	year,
	food_category_code,
	food_name,
	avg_food_price,
	LAG(avg_food_price) OVER(PARTITION BY food_category_code ORDER BY year) AS prev_year_price
FROM avg_food_price_per_year AS afppy 
GROUP BY YEAR, food_name;

-- Pohled pro výpočet procentuální změny a označení trendu.
CREATE OR REPLACE VIEW price_trend_analysis AS
SELECT 
    year,
    food_category_code,
    food_name,
    avg_food_price,
    prev_year_price,
    CASE 
        WHEN prev_year_price IS NOT NULL THEN ROUND(((avg_food_price - prev_year_price) / prev_year_price) * 100, 1)
        ELSE NULL
    END AS percent_change,
    CASE 
	    WHEN prev_year_price IS NULL THEN NULL
        WHEN avg_food_price > prev_year_price THEN 'increased'
        WHEN avg_food_price < prev_year_price THEN 'decreased'
        ELSE 'no change'
    END AS trend
FROM food_price_yearly_change AS fpyc;

-- Dotaz - Jaký je u potravin meziroční percentuální nárůst za celé sledované období?
SELECT 
    food_category_code,
    food_name,
    ROUND(AVG(percent_change), 2) AS yearly_percent_change 
FROM price_trend_analysis AS pta
WHERE percent_change IS NOT NULL
GROUP BY food_category_code, food_name
ORDER BY yearly_percent_change ASC;
