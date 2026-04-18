# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# CELL ********************

# Fabric notebook source

from pyspark.sql import functions as F

landing_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/landing/pos/daily_sales/*.csv"
bronze_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/bronze/sales/pos_daily_sales"

# Step 1: Read landing files and capture file metadata for tracking.
df_landing = (
    spark.read
    .option("header", True)
    .option("inferSchema", True)
    .csv(landing_path)
    .withColumn("source_file_path", F.input_file_name())
    .withColumn("source_file_name", F.regexp_extract(F.col("source_file_path"), r"([^/]+$)", 1))
)

# Step 2: Try to load existing bronze data so we know which files were already processed.
try:
    df_existing_bronze = spark.read.format("delta").load(bronze_output_path)
    processed_files_df = df_existing_bronze.select("source_file_name").distinct()
except Exception:
    df_existing_bronze = None
    processed_files_df = spark.createDataFrame([], "source_file_name string")

# Step 3: Keep only rows from new landing files.
df_new_files = (
    df_landing
    .join(processed_files_df, on="source_file_name", how="left_anti")
)

# Step 4: Add ingestion metadata to the new bronze rows.
df_bronze = (
    df_new_files
    .withColumn("ingestion_timestamp", F.current_timestamp())
    .withColumn("source_system", F.lit("pos"))
    .withColumn("dataset_name", F.lit("daily_sales"))
    .withColumn("ingestion_date", F.to_date("sale_date"))
)

print("Rows ready for bronze load:")
display(df_bronze)

# Step 5: First load creates the table, later loads append only new files.
if df_existing_bronze is None:
    write_mode = "overwrite"
else:
    write_mode = "append"

(
    df_bronze.write
    .mode(write_mode)
    .option("mergeSchema", "true")
    .format("delta")
    .save(bronze_output_path)
)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
