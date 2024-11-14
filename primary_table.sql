CREATE TABLE t_romana_belohoubkova_project_SQL_primary_final AS trbpspf
SELECT 
	cp.payroll_year AS year, 
	cpib.name AS industry,
    cpib.code AS industry_code, 
    cp.value AS payroll,
    cpu.name AS currency,
    cpc.name AS food_name,
    cpc.code AS food_category_code, 
    cpr.value AS food_price 
FROM czechia_payroll AS cp 
JOIN czechia_payroll_industry_branch AS cpib 
		ON cp.industry_branch_code = cpib.code
JOIN czechia_payroll_calculation AS cpc2 
		ON cp.calculation_code = cpc2.code
JOIN czechia_payroll_unit AS cpu 
		ON cp.unit_code = cpu.code AND cpu.code = 200
JOIN czechia_payroll_value_type AS cpvt 
		ON cp.value_type_code = cpvt.code AND cpvt.code = 5958
JOIN czechia_price AS cpr
		ON cp.payroll_year BETWEEN YEAR (cpr.date_from) AND YEAR (cpr.date_to)
JOIN czechia_price_category AS cpc 
		ON cpr.category_code = cpc.code;
		
SELECT
	DISTINCT industry
FROM avg_industry_payroll_per_year AS aippy; 