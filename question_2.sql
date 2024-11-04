-- Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
CREATE OR REPLACE VIEW avg_number_of_pieces_per_industry AS
SELECT 
		year,
		food_category_code,
		food_name,
		round(avg(food_price), 1) AS food_price,
		industry, 
		payroll,
		round(payroll/avg(food_price)) AS number_of_pieces
FROM t_romana_belohoubkova_project_sql_primary_final AS trbpspf 
where food_category_code = 114201 
	OR food_category_code = 111301
GROUP BY `year`, industry, food_name
ORDER BY `year`;

-- Kolik kusů mléka/chleba si lze koupit za výplatu konkrétního odvětví v konkrétním roce.
SELECT *
FROM avg_number_of_pieces_per_industry AS anoppi
WHERE food_category_code = 114201  -- 111301 (chléb)
	AND `year` = 2006
ORDER BY number_of_pieces DESC;

-- Kolik kusů mléka/chleba si lze koupit za průmeřnou výplatu v konkrétním roce.
SELECT 
	aippy.`year`,
	anoppi.food_category_code,
	anoppi.food_name,
	anoppi.food_price,
	aippy.avg_payroll,
	round(aippy.avg_payroll / anoppi.food_price) AS number_of_pieces
FROM avg_industry_payroll_per_year AS aippy 
JOIN avg_number_of_pieces_per_industry AS anoppi 
	ON aippy.`year` = anoppi.`year` 
GROUP BY `year`, food_name
ORDER BY `year`;