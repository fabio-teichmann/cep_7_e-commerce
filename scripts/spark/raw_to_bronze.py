from pyspark.sql import SparkSession
# # from pyspark.sql.functions import current_timestamp

# DATA_LAKE_BUCKET = ""
# KINESIS_LANDINGZONE = ""
# today = ""

# spark = SparkSession.builder\
#     .appName("BronzeIngestKinesis")\
#     .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")\
#     .config("spark.sql.catalog.bronze.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")\
#     .config("spark.sql.catalog.bronze.warehouse", f"s3://{DATA_LAKE_BUCKET}/bronze")\
#     .getOrCreate()

# from pyspark.sql.types import StructType, StringType, FloatType, TimestampType
# from pyspark.sql.functions import input_file_name

# schema = StructType() \
#     .add("id", StringType())\
#     .add("product_name", StringType())\
#     .add("price", FloatType())\
#     .add("description", StringType())\
#     .add("user_id", StringType()) \
#     .add("timestamp", TimestampType()) \
#     .add("noise", StringType()) 

# df = spark.read.schema(schema).json(f"s3a://{DATA_LAKE_BUCKET}/{KINESIS_LANDINGZONE}/{today}")



# # Step 1: List all files (via Spark or boto3)
# df = df.withColumn("source_file", input_file_name())

# # Step 2: Filter based on checkpoint
# processed_files_df = spark.read.parquet(f"s3a://checkpoint/processed_files/{today}")
# df_new = df.join(processed_files_df, "source_file", "left_anti")

# # Step 3: Write to Iceberg
# df_new.writeTo("glue_catalog.bronze.webshop_orders").append()

# # Step 4: Update checkpoint
# df_new.select("source_file").distinct().write.mode("append").parquet("s3a://checkpoint/processed_files/")


from pyspark.sql import SparkSession
from pyspark.sql.functions import input_file_name, col, expr
from pyspark.sql.types import StructType, StringType, FloatType, IntegerType

import uuid

# === Config ===
DATA_LAKE_BUCKET = "cep-7-data-lake-tl9bg4"
RAW_PREFIX = "kinesis-landing"
BRONZE_PREFIX = "bronze"
CHECKPOINT_PATH = f"s3a://{DATA_LAKE_BUCKET}/checkpoints/bronze_orders"
TODAY = "2025-05-12"  # This should be dynamic later

# === Initialize Spark with Iceberg + Glue Catalog ===
spark = SparkSession.builder \
    .appName("RawToBronzeWebshopOrders") \
    .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.glue_catalog.warehouse", f"s3://{DATA_LAKE_BUCKET}/{BRONZE_PREFIX}") \
    .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog") \
    .config("spark.sql.defaultCatalog", "glue_catalog") \
    .getOrCreate()

# === Define Schema for Raw Input ===
raw_schema = StructType() \
    .add("customer_id", IntegerType()) \
    .add("product_id", StringType()) \
    .add("product_name", StringType()) \
    .add("product_description", StringType()) \
    .add("price", FloatType()) \
    .add("category", StringType()) \
    .add("quantity", IntegerType()) \
    .add("timestamp", StringType())  # Could be cast to TimestampType if formatted

# === Load Raw Files from Landing Zone ===
raw_df = spark.read \
    .schema(raw_schema) \
    .json(f"s3a://{DATA_LAKE_BUCKET}/{RAW_PREFIX}/{TODAY}") \
    .withColumn("source_file", input_file_name())

# === Deduplication Check (Basic MVP: skip for now or later add) ===
# For now assume overwrite based on time partition or external dedupe logic

# === Add Order ID (UUID) ===
bronze_df = raw_df.withColumn("order_id", expr("uuid()"))

# === Write to Iceberg Bronze Table ===
bronze_df.writeTo("glue_catalog.bronze.webshop_orders").append()

# Optional: print schema for inspection
bronze_df.printSchema()
