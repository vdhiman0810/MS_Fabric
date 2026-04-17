# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# CELL ********************

from pyspark.sql import functions as F

silver_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/silver/sales/pos_daily_sales"
gold_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/gold/sales/daily_sales_summary"

df_silver = spark.read.format("delta").load(silver_path)

df_gold = (
    df_silver
    .groupBy("sale_date", "store_id")
    .agg(
        F.count("*").alias("transaction_count"),
        F.sum("quantity").alias("total_quantity_sold"),
        F.sum("total_amount").alias("total_sales_amount"),
        F.avg("unit_price").alias("average_unit_price")
    )
    .orderBy("sale_date", "store_id")
)

display(df_gold)

(
    df_gold.write
    .mode("overwrite")
    .format("delta")
    .save(gold_output_path)
)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
