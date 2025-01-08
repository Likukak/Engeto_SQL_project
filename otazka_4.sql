-- Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

-- Pohled pro porovnání procentuální změny cen potravin a procentuální změny růstu celonárodní průměrné mzdy.
CREATE OR REPLACE VIEW v_rb_price_vs_payroll_comparison AS
WITH payroll_changes AS (
    SELECT 
        vrfpta.year,
        ROUND(
            ((ROUND(AVG(vrpta.national_avg_payroll), 2) - LAG(ROUND(AVG(vrpta.national_avg_payroll), 2)) OVER (ORDER BY vrpta.year)) 
            / LAG(ROUND(AVG(vrpta.national_avg_payroll), 2)) OVER (ORDER BY vrpta.year)) * 100, 2
        ) AS national_payroll_percent_change
    FROM v_rb_payroll_trend_analysis AS vrpta
    JOIN v_rb_food_price_trend_analysis AS vrfpta 
        ON vrfpta.year = vrpta.year
    GROUP BY vrfpta.year
)
SELECT 
    vrfpta.year,
    vrfpta.food_category_code,
    vrfpta.food_name,
    vrfpta.avg_food_price,  
    vrfpta.percent_change AS food_price_percent_change,  
    ROUND(AVG(vrpta.national_avg_payroll), 2) AS national_avg_payroll,  
    pcn.national_payroll_percent_change  
FROM v_rb_food_price_trend_analysis AS vrfpta
JOIN v_rb_payroll_trend_analysis AS vrpta 
    ON vrfpta.year = vrpta.year
JOIN payroll_changes AS pcn
    ON vrfpta.year = pcn.year  
GROUP BY vrfpta.year, vrfpta.food_category_code, vrfpta.food_name
ORDER BY vrfpta.year, vrfpta.food_category_code;

-- Zjisti, kolik let a u kterých potravin byl nejčastěji rozdíl mezi zvýšením ceny potravin a zvýšením průměrné mzdy alespoň o 10%.
SELECT
    food_name,
    COUNT(year) AS years_with_price_above_payroll
FROM v_rb_price_vs_payroll_comparison AS vrpvpc 
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
FROM v_rb_price_vs_payroll_comparison AS vrpvpc 
WHERE food_price_percent_change > national_payroll_percent_change + 10
ORDER BY price_vs_payroll_percent_diff DESC
LIMIT 5;

-- Zjisti o kolik procent se ve sledovaných letech zvedala průměrná cena všech potravin oproti zvedání průměrné mzdy.
SELECT 
    vrpvpc.year,
    ROUND(AVG(vrpvpc.food_price_percent_change), 2) AS avg_food_price_percent_change, 
    MAX(vrpvpc.national_payroll_percent_change) AS avg_national_payroll_percent_change, 
    ROUND(AVG(vrpvpc.food_price_percent_change) - MAX(vrpvpc.national_payroll_percent_change), 2) AS percent_difference
FROM v_rb_price_vs_payroll_comparison AS vrpvpc
GROUP BY vrpvpc.year
ORDER BY percent_difference DESC;



