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

bronze_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/bronze/sales/pos_daily_sales"
silver_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/silver/sales/pos_daily_sales"

df_bronze = spark.read.format("delta").load(bronze_path)

df_silver = (
    df_bronze
    .withColumn("sale_date", F.to_date("sale_date"))
    .withColumn("store_id", F.col("store_id").cast("int"))
    .withColumn("quantity", F.col("quantity").cast("int"))
    .withColumn("unit_price", F.col("unit_price").cast("double"))
    .withColumn("total_amount", F.col("total_amount").cast("double"))
    .filter(F.col("sale_date").isNotNull())
    .filter(F.col("store_id").isNotNull())
    .filter(F.col("product_id").isNotNull())
    .filter(F.col("quantity") > 0)
    .filter(F.col("unit_price") > 0)
    .filter(F.col("total_amount") >= 0)
    .dropDuplicates()
)

display(df_silver)

(
    df_silver.write
    .mode("overwrite")
    .format("delta")
    .save(silver_output_path)
)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
