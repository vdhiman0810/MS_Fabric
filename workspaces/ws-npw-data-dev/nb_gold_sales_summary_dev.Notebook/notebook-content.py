# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "3b185859-b957-4e42-ba87-371bddb46a72",
# META       "default_lakehouse_name": "lh_npw_data_dev",
# META       "default_lakehouse_workspace_id": "ddb1266a-7162-4d51-8991-e4f5ed806734",
# META       "known_lakehouses": [
# META         {
# META           "id": "3b185859-b957-4e42-ba87-371bddb46a72"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

from pyspark.sql import functions as F

silver_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/silver/sales/pos_daily_sales"
gold_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/gold/sales/daily_sales_summary"

df_silver = spark.read.format("delta").load(silver_path)

# Step 1: Build the curated daily sales summary.
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

print("Gold daily sales summary:")
display(df_gold)

# Step 2: Publish the curated gold dataset.
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
