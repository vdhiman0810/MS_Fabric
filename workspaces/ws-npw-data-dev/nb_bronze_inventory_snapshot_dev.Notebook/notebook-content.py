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

landing_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/landing/inventory/snapshot/*.json"
bronze_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/bronze/inventory/inventory_snapshot"
silver_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/silver/inventory/inventory_snapshot"
gold_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/gold/inventory/inventory_summary"


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# MARKDOWN ********************

# - Bronze Layer

# CELL ********************

df_landing = spark.read.option("multiLine", True).json(landing_path)

df_bronze = (
    df_landing
    .withColumn("ingestion_timestamp", F.current_timestamp())
    .withColumn("source_system", F.lit("inventory"))
    .withColumn("dataset_name", F.lit("snapshot"))
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

# MARKDOWN ********************

# Silver Layer

# CELL ********************

df_bronze_read = spark.read.format("delta").load(bronze_output_path)

df_silver = (
    df_bronze_read
    .withColumn("snapshot_date", F.to_date("snapshot_date"))
    .withColumn("store_id", F.col("store_id").cast("int"))
    .withColumn("on_hand_quantity", F.col("on_hand_quantity").cast("int"))
    .withColumn("reorder_threshold", F.col("reorder_threshold").cast("int"))
    .filter(F.col("snapshot_date").isNotNull())
    .filter(F.col("store_id").isNotNull())
    .filter(F.col("product_id").isNotNull())
    .filter(F.col("on_hand_quantity").isNotNull())
    .filter(F.col("reorder_threshold").isNotNull())
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

# MARKDOWN ********************

# Gold Layer

# CELL ********************

df_silver_read = spark.read.format("delta").load(silver_output_path)

df_gold = (
    df_silver_read
    .groupBy("snapshot_date", "store_id")
    .agg(
        F.countDistinct("product_id").alias("distinct_product_count"),
        F.sum("on_hand_quantity").alias("total_on_hand_quantity"),
        F.avg("reorder_threshold").alias("avg_reorder_threshold")
    )
    .orderBy("snapshot_date", "store_id")
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
