library(arrow)
library(dplyr)
library(tictoc)
library(duckdb)

# to download this dataset (note 68GB)
# copy_files(
#   from = s3_bucket("ursa-labs-taxi-data-v2"),
#   to = "~/Datasets/nyc-taxi"
# )

ds <- open_dataset("~/Datasets/nyc-taxi/")

# See how many rows:
nrow(ds)

# printing the dataset gives some information + schema
ds

# this returns a query, we need to collect() it before it'll execute anything, 
# but we get helpful information like the end schema
ds |>
  filter(!is.na(pickup_location_id)) |>
  group_by(pickup_location_id) |>
  summarize(
    avg_tip = mean(tip_amount, na.rm = TRUE),
    avg_fare = mean(fare_amount, na.rm = TRUE),
    n = n()
  ) |>
  filter(n > 500) |>
  arrange(desc(avg_fare)) 

df <- ds |>
  filter(!is.na(pickup_location_id)) |>
  group_by(pickup_location_id) |>
  summarize(
    avg_tip = mean(tip_amount, na.rm = TRUE),
    avg_fare = mean(fare_amount, na.rm = TRUE),
    n = n()
  ) |>
  filter(n > 500) |>
  arrange(desc(avg_fare)) |>
  collect()


# Connecting to duckdb
library(duckdb)

# The same query above, we can send to duckdb without the serialization:
ds |>
  filter(!is.na(pickup_location_id)) |>
  to_duckdb() |>
  group_by(pickup_location_id) |>
  summarize(
    avg_tip = mean(tip_amount, na.rm = TRUE),
    avg_fare = mean(fare_amount, na.rm = TRUE),
    n = n()
  ) |>
  filter(n > 500) |>
  arrange(desc(avg_fare)) |>
  collect()

# We can even swap back and forth:
ds |>
  filter(!is.na(pickup_location_id)) |>
  to_duckdb() |>
  group_by(pickup_location_id) |>
  summarize(
    avg_tip = mean(tip_amount, na.rm = TRUE),
    avg_fare = mean(fare_amount, na.rm = TRUE),
    n = n()
  ) |>
  filter(n > 500) |>
  arrange(desc(avg_fare)) |>
  to_arrow() |>
  collect()

# Or if we want to use pure SQL
con <- dbConnect(duckdb())
ds |>
  filter(!is.na(pickup_location_id)) |>
  to_duckdb(con = con, table_name = "nyc_taxi")

dbGetQuery(con, paste(
  "SELECT pickup_location_id, AVG(tip_amount), AVG(fare_amount), count(*) AS n",
  "FROM nyc_taxi",
  # "WHERE pickup_location_id IS NOT NULL",
  "GROUP BY pickup_location_id"
))
dbDisconnect(con)