-- Auto Generated (Do not modify) 346E77DEEF3A5C882934974B928B18A57EC4096B1C0366D6DC843A7919E2E354


CREATE   VIEW reporting.vw_gold_daily_sales_summary
AS
SELECT
    sale_date,
    store_id,
    transaction_count,
    total_quantity_sold,
    total_sales_amount,
    average_unit_price
FROM
    [lh_npw_data_dev].[dbo].[gold_daily_sales_summary];