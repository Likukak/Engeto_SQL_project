-- Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

-- Pohled pro výpočet meziroční procentuální změny cen potravin a označení trendu.
CREATE OR REPLACE VIEW v_rb_food_price_trend_analysis AS
SELECT 
    year,
    food_category_code,
    food_name,
    ROUND(AVG(food_price), 2) AS avg_food_price,
    ROUND(LAG(AVG(food_price)) OVER (PARTITION BY food_category_code ORDER BY year), 2) AS prev_year_price,
    CASE 
        WHEN LAG(AVG(food_price)) OVER (PARTITION BY food_category_code ORDER BY year) IS NOT NULL 
            THEN ROUND(((AVG(food_price) - LAG(AVG(food_price)) OVER (PARTITION BY food_category_code ORDER BY year)) 
            / LAG(AVG(food_price)) OVER (PARTITION BY food_category_code ORDER BY year)) * 100, 2)
        ELSE NULL
    END AS percent_change,
    CASE 
        WHEN LAG(AVG(food_price)) OVER (PARTITION BY food_category_code ORDER BY year) IS NULL THEN NULL
        WHEN AVG(food_price) > LAG(AVG(food_price)) OVER (PARTITION BY food_category_code ORDER BY year) THEN 'increased'
        WHEN AVG(food_price) < LAG(AVG(food_price)) OVER (PARTITION BY food_category_code ORDER BY year) THEN 'decreased'
        ELSE 'no change'
    END AS trend
FROM t_romana_belohoubkova_project_sql_primary_final AS trbpspf
GROUP BY year, food_category_code, food_name
ORDER BY year, food_category_code;

-- Zjisti průměrnou meziroční procentuální změnu cen všech potravin.
SELECT 
    ROUND(AVG(percent_change), 2) AS avg_yearly_percent_change
FROM v_rb_food_price_trend_analysis AS vrfpta 
WHERE percent_change IS NOT NULL;

-- Zjisti jaký je u potravin průměrný meziroční procentuální nárůst za celé sledované období.
SELECT 
    food_name,
    ROUND(AVG(percent_change), 2) AS yearly_percent_change 
FROM v_rb_food_price_trend_analysis AS vrfpta 
WHERE percent_change IS NOT NULL
GROUP BY food_category_code, food_name
ORDER BY yearly_percent_change ASC;

-- Zjisti jaké potraviny nejvíce zlevnily a v kterém roce.
SELECT 
    year,
    food_name,
    ROUND(percent_change, 2) AS percent_change
FROM v_rb_food_price_trend_analysis AS vrfpta 
WHERE percent_change IS NOT NULL
AND percent_change < 0 
ORDER BY percent_change ASC;

-- Zjisti kolik let za sledované období ceny klesaly u konkrétních potravin.
SELECT 
    food_name,
    COUNT(year) AS years_with_decrease
FROM v_rb_food_price_trend_analysis AS vrfpta 
WHERE percent_change < 0
GROUP BY food_name
ORDER BY years_with_decrease DESC
LIMIT 5;

-- Zjisti, která potravina nejvíc zlevnila 2006 vs 2018.
SELECT 
    vrafppy.food_category_code,
    vrafppy.food_name,
    ROUND(vrafppy.avg_food_price, 2) AS price_2006,
    ROUND(vrafppy2.avg_food_price, 2) AS price_2018,
    ROUND(((vrafppy.avg_food_price - vrafppy2.avg_food_price) / vrafppy.avg_food_price) * 100, 2) AS percent_change
FROM v_rb_avg_food_price_per_year AS vrafppy 
JOIN v_rb_avg_food_price_per_year AS vrafppy2 
    ON vrafppy.food_category_code = vrafppy2.food_category_code
    AND vrafppy.food_name = vrafppy2.food_name
    AND vrafppy.year = 2006
    AND vrafppy2.year = 2018
WHERE vrafppy.avg_food_price IS NOT NULL
  AND vrafppy2.avg_food_price IS NOT NULL
ORDER BY percent_change DESC
LIMIT 5;





