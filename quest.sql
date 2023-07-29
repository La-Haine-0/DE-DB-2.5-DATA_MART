-- Создаем временные таблицы для хранения агрегированных данных
CREATE TEMP TABLE tmp_sales_fact AS
SELECT
    sh.shop_id,
    pr.product_id,
    SUM(sd.sales_cnt) AS sales_fact
FROM
    public.shop AS sh
    CROSS JOIN public.products AS pr
    LEFT JOIN public.shop_dns AS sd ON sh.shop_id = sd.shop_id AND pr.product_id = sd.product_id
GROUP BY
    sh.shop_id, pr.product_id;

CREATE TEMP TABLE tmp_sales_plan AS
SELECT
    sh.shop_id,
    pr.product_id,
    SUM(pn.plan_cnt) AS sales_plan
FROM
    public.shop AS sh
    CROSS JOIN public.products AS pr
    LEFT JOIN public.plan AS pn ON sh.shop_id = pn.shop_id AND pr.product_id = pn.product_id
GROUP BY
    sh.shop_id, pr.product_id;

CREATE TEMP TABLE tmp_income_fact AS
SELECT
    sh.shop_id,
    pr.product_id,
    SUM(sd.sales_cnt * pr.price) AS income_fact
FROM
    public.shop AS sh
    CROSS JOIN public.products AS pr
    LEFT JOIN public.shop_dns AS sd ON sh.shop_id = sd.shop_id AND pr.product_id = sd.product_id
    LEFT JOIN public.products AS pr ON pr.product_id = pr.product_id
GROUP BY
    sh.shop_id, pr.product_id;

CREATE TEMP TABLE tmp_income_plan AS
SELECT
    sh.shop_id,
    pr.product_id,
    SUM(pn.plan_cnt * pr.price) AS income_plan
FROM
    public.shop AS sh
    CROSS JOIN public.products AS pr
    LEFT JOIN public.plan AS pn ON sh.shop_id = pn.shop_id AND pr.product_id = pn.product_id
    LEFT JOIN public.products AS pr ON pr.product_id = pr.product_id
GROUP BY
    sh.shop_id, pr.product_id;

-- Создаем основную витрину, объединяя все агрегированные данные
SELECT
    sh.shop_name,
    pr.product_name,
    COALESCE(sf.sales_fact, 0) AS sales_fact,
    COALESCE(sp.sales_plan, 0) AS sales_plan,
    CASE
        WHEN COALESCE(sp.sales_plan, 0) > 0 THEN COALESCE(sf.sales_fact, 0) / COALESCE(sp.sales_plan, 0)
        ELSE 0
    END AS sales_fact_to_plan,
    COALESCE(if.income_fact, 0) AS income_fact,
    COALESCE(ip.income_plan, 0) AS income_plan,
    CASE
        WHEN COALESCE(ip.income_plan, 0) > 0 THEN COALESCE(if.income_fact, 0) / COALESCE(ip.income_plan, 0)
        ELSE 0
    END AS income_fact_to_plan
FROM
    public.shop AS sh
    CROSS JOIN public.products AS pr
    LEFT JOIN tmp_sales_fact AS sf ON sh.shop_id = sf.shop_id AND pr.product_id = sf.product_id
    LEFT JOIN tmp_sales_plan AS sp ON sh.shop_id = sp.shop_id AND pr.product_id = sp.product_id
    LEFT JOIN tmp_income_fact AS if ON sh.shop_id = if.shop_id AND pr.product_id = if.product_id
    LEFT JOIN tmp_income_plan AS ip ON sh.shop_id = ip.shop_id AND pr.product_id = ip.product_id;
