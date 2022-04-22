# you have to run previous script 01 and 02 to obtain jobdata object
# run mongo container at first

if (new_job_availability) {
  library(mongolite)
  # save data to mongodb
  conn <- mongo(
    collection = "jobcollection", 
    db = "test", 
    url = sprintf("mongodb://%s:%s@localhost:%s", Sys.getenv("MONGO_USERNAME"), Sys.getenv("MONGO_PASSWORD"), Sys.getenv("MONGO_PORT")),
    verbose = TRUE
  )
  conn$insert(jobdata) # insert record
  message(paste0("Data imported to mongodb's collection"))
}
