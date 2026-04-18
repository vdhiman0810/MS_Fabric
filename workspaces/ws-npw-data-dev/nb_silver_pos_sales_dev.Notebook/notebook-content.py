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
from pyspark.sql.window import Window

bronze_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/bronze/sales/pos_daily_sales"
silver_output_path = "abfss://ws-npw-data-dev@onelake.dfs.fabric.microsoft.com/lh_npw_data_dev.Lakehouse/Files/silver/sales/pos_daily_sales"

df_bronze = spark.read.format("delta").load(bronze_path)

# Step 1: Standardize datatypes.
df_typed = (
    df_bronze
    .withColumn("sale_date", F.to_date("sale_date"))
    .withColumn("store_id", F.col("store_id").cast("int"))
    .withColumn("quantity", F.col("quantity").cast("int"))
    .withColumn("unit_price", F.col("unit_price").cast("double"))
    .withColumn("total_amount", F.col("total_amount").cast("double"))
)

# Step 2: Apply validation rules.
df_validated = (
    df_typed
    .withColumn(
        "is_valid_record",
        (
            F.col("sale_date").isNotNull() &
            F.col("store_id").isNotNull() &
            F.col("product_id").isNotNull() &
            (F.col("quantity") > 0) &
            (F.col("unit_price") > 0) &
            (F.col("total_amount") >= 0)
        )
    )
)

# Step 3: Detect duplicates by business key and keep the latest ingested row.
duplicate_key = [
    "sale_date",
    "store_id",
    "product_id",
    "quantity",
    "unit_price",
    "total_amount"
]

window_spec = Window.partitionBy(*duplicate_key).orderBy(F.col("ingestion_timestamp").desc())

df_ranked = (
    df_validated
    .withColumn("row_rank", F.row_number().over(window_spec))
    .withColumn("is_duplicate_record", F.col("row_rank") > 1)
)

# Step 4: Split accepted and rejected rows.
df_rejected = (
    df_ranked
    .filter((~F.col("is_valid_record")) | F.col("is_duplicate_record"))
    .withColumn(
        "rejection_reason",
        F.when(F.col("sale_date").isNull(), F.lit("Missing sale_date"))
         .when(F.col("store_id").isNull(), F.lit("Missing store_id"))
         .when(F.col("product_id").isNull(), F.lit("Missing product_id"))
         .when(F.col("quantity") <= 0, F.lit("Invalid quantity"))
         .when(F.col("unit_price") <= 0, F.lit("Invalid unit_price"))
         .when(F.col("total_amount") < 0, F.lit("Invalid total_amount"))
         .when(F.col("is_duplicate_record"), F.lit("Duplicate business record"))
         .otherwise(F.lit("Unknown validation issue"))
    )
)

df_silver = (
    df_ranked
    .filter(F.col("is_valid_record") & (~F.col("is_duplicate_record")))
    .drop("is_valid_record", "row_rank", "is_duplicate_record")
)

print("Accepted silver rows:")
display(df_silver)

print("Rejected rows:")
display(df_rejected)

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
