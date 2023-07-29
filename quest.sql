CREATE TEMP TABLE sales_total AS
SELECT product_id, sales_date, sales_cnt, (SELECT shop_id FROM public.shop WHERE shop_name = 'DNS') AS shop_id
FROM public.shop_dns
UNION ALL
SELECT product_id, sales_date, sales_cnt, (SELECT shop_id FROM public.shop WHERE shop_name = 'М.Видео') AS shop_id
FROM public.shop_mvideo
UNION ALL
SELECT product_id, sales_date, sales_cnt, (SELECT shop_id FROM public.shop WHERE shop_name = 'Ситилинк') AS shop_id
FROM public.shop_citilink;

WITH tmp_sales_fact AS (
    SELECT
        s.shop_id,
        p.product_id,
        SUM(COALESCE(st.sales_cnt, 0)) AS sales_fact
    FROM
        public.shop s
        CROSS JOIN public.products p
        LEFT JOIN sales_total st ON s.shop_id = st.shop_id AND p.product_id = st.product_id
    GROUP BY
        s.shop_id, p.product_id
),
tmp_sales_plan AS (
    SELECT
        s.shop_id,
        p.product_id,
        SUM(COALESCE(pn.plan_cnt, 0)) AS sales_plan
    FROM
        public.shop s
        CROSS JOIN public.products p
        LEFT JOIN public.plan pn ON s.shop_id = pn.shop_id AND p.product_id = pn.product_id
    GROUP BY
        s.shop_id, p.product_id
),
tmp_income_fact AS (
    SELECT
        s.shop_id,
        p.product_id,
        SUM(COALESCE(st.sales_cnt, 0) * COALESCE(pr.price, 0)) AS income_fact
    FROM
        public.shop s
        CROSS JOIN public.products p
        LEFT JOIN sales_total st ON s.shop_id = st.shop_id AND p.product_id = st.product_id
        LEFT JOIN public.products pr ON p.product_id = pr.product_id
    GROUP BY
        s.shop_id, p.product_id
),
tmp_income_plan AS (
    SELECT
        s.shop_id,
        p.product_id,
        SUM(COALESCE(pn.plan_cnt, 0) * COALESCE(pr.price, 0)) AS income_plan
    FROM
        public.shop s
        CROSS JOIN public.products p
        LEFT JOIN public.plan pn ON s.shop_id = pn.shop_id AND p.product_id = pn.product_id
        LEFT JOIN public.products pr ON p.product_id = pr.product_id
    GROUP BY
        s.shop_id, p.product_id
)
SELECT
    s.shop_name,
    p.product_name,
    COALESCE(sf.sales_fact, 0) AS sales_fact,
    COALESCE(sp.sales_plan, 0) AS sales_plan,
    CASE
        WHEN COALESCE(sp.sales_plan, 0) > 0 THEN COALESCE(sf.sales_fact, 0) / COALESCE(sp.sales_plan, 0)
        ELSE 0
    END AS "sales_fact/sales_plan",
    COALESCE(if.income_fact, 0) AS income_fact,
    COALESCE(ip.income_plan, 0) AS income_plan,
    CASE
        WHEN COALESCE(ip.income_plan, 0) > 0 THEN COALESCE(if.income_fact, 0) / COALESCE(ip.income_plan, 0)
        ELSE 0
    END AS "income_fact/sales_plan"
FROM
    public.shop s
    CROSS JOIN public.products p
    LEFT JOIN tmp_sales_fact sf ON s.shop_id = sf.shop_id AND p.product_id = sf.product_id
    LEFT JOIN tmp_sales_plan sp ON s.shop_id = sp.shop_id AND p.product_id = sp.product_id
    LEFT JOIN tmp_income_fact if ON s.shop_id = if.shop_id AND p.product_id = if.product_id
    LEFT JOIN tmp_income_plan ip ON s.shop_id = ip.shop_id AND p.product_id = ip.product_id;
