-- Auto Generated (Do not modify) 7A8637441B376E19E4A3D18D97B72535B4F588A5FC3394C8B84B406A6BE76A3E
CREATE   VIEW reporting.vw_gold_daily_sales_by_store
AS
SELECT
    store_id,
    SUM(transaction_count) AS total_transactions,
    SUM(total_quantity_sold) AS total_quantity_sold,
    SUM(total_sales_amount) AS total_sales_amount,
    AVG(average_unit_price) AS avg_unit_price
FROM reporting.vw_gold_daily_sales_summary
GROUP BY store_id;