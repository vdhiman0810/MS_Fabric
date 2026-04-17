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

landing_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/landing/pos/daily_sales/*.csv"
bronze_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/bronze/sales/pos_daily_sales"

df = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv(landing_path)
)

df_bronze = (
    df
    .withColumn("ingestion_timestamp", F.current_timestamp())
    .withColumn("source_system", F.lit("pos"))
    .withColumn("dataset_name", F.lit("daily_sales"))
    .withColumn("ingestion_date", F.to_date("sale_date"))
)

display(df_bronze)

(
    df_bronze.write
    .mode("overwrite")
    .format("delta")
    .save(bronze_output_path)
)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
