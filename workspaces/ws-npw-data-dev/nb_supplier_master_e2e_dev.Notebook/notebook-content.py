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

landing_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/landing/suppliers/master/*.json"
bronze_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/bronze/suppliers/suppliers_master"
silver_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/silver/suppliers/suppliers_master"
gold_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/gold/suppliers/active_suppliers"


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

df_landing = spark.read.option("multiLine", True).json(landing_path)

df_bronze = (
    df_landing
    .withColumn("ingestion_timestamp", F.current_timestamp())
    .withColumn("source_system", F.lit("suppliers"))
    .withColumn("dataset_name", F.lit("master"))
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

# CELL ********************

df_bronze_read = spark.read.format("delta").load(bronze_output_path)

df_silver = (
    df_bronze_read
    .withColumn("supplier_id", F.col("supplier_id").cast("string"))
    .withColumn("supplier_name", F.trim(F.col("supplier_name")))
    .withColumn("supplier_tier", F.upper(F.col("supplier_tier")))
    .withColumn("country_code", F.upper(F.col("country_code")))
    .withColumn("currency_code", F.upper(F.col("currency_code")))
    .withColumn("lead_time_days", F.col("lead_time_days").cast("int"))
    .filter(F.col("supplier_id").isNotNull())
    .filter(F.col("supplier_name").isNotNull())
    .dropDuplicates(["supplier_id"])
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

# CELL ********************

df_silver_read = spark.read.format("delta").load(silver_output_path)

df_gold = (
    df_silver_read
    .filter(F.col("active_flag") == True)
    .select(
        "supplier_id",
        "supplier_name",
        "supplier_tier",
        "country_code",
        "currency_code",
        "lead_time_days"
    )
    .orderBy("supplier_id")
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
