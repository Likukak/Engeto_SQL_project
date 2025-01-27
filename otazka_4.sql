-- Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

-- Pohled pro porovnání procentuální změny cen potravin a procentuální změny růstu celonárodní průměrné mzdy.
CREATE OR REPLACE VIEW v_price_vs_payroll_comparison AS
WITH payroll_changes AS (
    SELECT 
        food_price_trend.year,
        ROUND(
            ((ROUND(AVG(payroll_trend.national_avg_payroll), 2) - LAG(ROUND(AVG(payroll_trend.national_avg_payroll), 2)) OVER (ORDER BY payroll_trend.year)) 
            / LAG(ROUND(AVG(payroll_trend.national_avg_payroll), 2)) OVER (ORDER BY payroll_trend.year)) * 100, 2
        ) AS national_payroll_percent_change
    FROM v_payroll_trend_analysis AS payroll_trend 
    JOIN v_food_price_trend_analysis AS food_price_trend
        ON food_price_trend.year = payroll_trend.year
    GROUP BY food_price_trend.year
)
SELECT 
    food_price_trend.year,
    food_price_trend.food_category_code,
    food_price_trend.food_name,
    food_price_trend.avg_food_price,  
    food_price_trend.percent_change AS food_price_percent_change,  
    ROUND(AVG(payroll_trend.national_avg_payroll), 2) AS national_avg_payroll,  
    payroll_changes.national_payroll_percent_change  
FROM v_food_price_trend_analysis AS food_price_trend
JOIN v_payroll_trend_analysis AS payroll_trend
    ON food_price_trend.year = payroll_trend.year
JOIN payroll_changes AS payroll_changes
    ON food_price_trend.year = payroll_changes.year  
GROUP BY food_price_trend.year, food_price_trend.food_category_code, food_price_trend.food_name
ORDER BY food_price_trend.year, food_price_trend.food_category_code;

-- Zjisti, kolik let a u kterých potravin byl nejčastěji rozdíl mezi zvýšením ceny potravin a zvýšením průměrné mzdy alespoň o 10%.
SELECT
    food_name,
    COUNT(year) AS years_with_price_above_payroll
FROM v_price_vs_payroll_comparison AS price_payroll 
WHERE food_price_percent_change > national_payroll_percent_change + 10
GROUP BY food_name
ORDER BY years_with_price_above_payroll DESC
LIMIT 5;

-- Zjisti, kdy a u kterých potravin byl největší rozdíl mezi zvýšením ceny potravin a zvýšením průměrné mzdy.
SELECT 
    year,
    food_name,
    food_price_percent_change,
    national_payroll_percent_change,
    (food_price_percent_change - national_payroll_percent_change) AS price_vs_payroll_percent_diff
FROM v_price_vs_payroll_comparison AS price_payroll 
WHERE food_price_percent_change > national_payroll_percent_change + 10
ORDER BY price_vs_payroll_percent_diff DESC
LIMIT 5;

-- Zjisti o kolik procent se ve sledovaných letech zvedala průměrná cena všech potravin oproti zvedání průměrné mzdy.
SELECT 
    price_payroll.year,
    ROUND(AVG(price_payroll.food_price_percent_change), 2) AS avg_food_price_percent_change, 
    MAX(price_payroll.national_payroll_percent_change) AS avg_national_payroll_percent_change, 
    ROUND(AVG(price_payroll.food_price_percent_change) - MAX(price_payroll.national_payroll_percent_change), 2) AS percent_difference
FROM v_price_vs_payroll_comparison AS price_payroll
GROUP BY price_payroll.year
ORDER BY percent_difference DESC;



