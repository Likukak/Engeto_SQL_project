/* 
Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem? 
*/

-- Pohled pro výpočet procentuálních změn HDP, mezd a cen potravin pro každý rok
CREATE OR REPLACE VIEW hdp_vs_national_payroll_vs_food_price AS
SELECT
    gdp.year,
    gdp.gdp,
    gdp.gdp_percent_change,
    npyr.national_avg_payroll,
    npyr.national_payroll_percent_change,
    fpta.food_category_code,
    fpta.food_name,
    fpta.avg_food_price,
    fpta.percent_change AS food_price_percent_change,
    CASE
        WHEN fpta.percent_change > gdp.gdp_percent_change THEN 1
        ELSE 0
    END AS food_price_increase_above_gdp,
    CASE
        WHEN npyr.national_payroll_percent_change > gdp.gdp_percent_change THEN 1
        ELSE 0
    END AS payroll_increase_above_gdp 
FROM (
    SELECT 
        e.year,
        e.gdp,
        ROUND(((e.gdp - LAG(e.gdp) OVER (PARTITION BY e.country ORDER BY e.year)) / 
        LAG(e.gdp) OVER (PARTITION BY e.country ORDER BY e.year)) * 100, 2) AS gdp_percent_change
    FROM economies AS e
    WHERE e.country = 'Czech Republic'
) AS gdp
JOIN national_payroll_yearly_change AS npyr
    ON gdp.year = npyr.year
JOIN food_price_trend_analysis AS fpta
    ON gdp.year = fpta.year
ORDER BY gdp.year, fpta.food_category_code;








