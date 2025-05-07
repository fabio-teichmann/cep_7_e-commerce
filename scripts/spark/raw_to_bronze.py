from pyspark.sql import SparkSession
# from pyspark.sql.functions import current_timestamp

DATA_LAKE_BUCKET = ""
KINESIS_LANDINGZONE = ""
today = ""

spark = SparkSession.builder\
    .appName("BronzeIngestKinesis")\
    .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")\
    .config("spark.sql.catalog.bronze.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")\
    .config("spark.sql.catalog.bronze.warehouse", f"s3://{DATA_LAKE_BUCKET}/bronze")\
    .getOrCreate()

from pyspark.sql.types import StructType, StringType, FloatType, TimestampType
from pyspark.sql.functions import input_file_name

schema = StructType() \
    .add("id", StringType())\
    .add("product_name", StringType())\
    .add("price", FloatType())\
    .add("description", StringType())\
    .add("user_id", StringType()) \
    .add("timestamp", TimestampType()) \
    .add("noise", StringType()) 

df = spark.read.schema(schema).json(f"s3a://{DATA_LAKE_BUCKET}/{KINESIS_LANDINGZONE}/{today}")



# Step 1: List all files (via Spark or boto3)
df = df.withColumn("source_file", input_file_name())

# Step 2: Filter based on checkpoint
processed_files_df = spark.read.parquet(f"s3a://checkpoint/processed_files/{today}")
df_new = df.join(processed_files_df, "source_file", "left_anti")

# Step 3: Write to Iceberg
df_new.writeTo("glue_catalog.bronze.webshop_orders").append()

# Step 4: Update checkpoint
df_new.select("source_file").distinct().write.mode("append").parquet("s3a://checkpoint/processed_files/")
