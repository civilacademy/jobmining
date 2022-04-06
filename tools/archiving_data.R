# using purrr

# archiving joblist
path <- "data/joblist/"
joblist_file <- list.files(path, pattern = "joblist.+csv")
joblist <- purrr::map_df(paste0(path, joblist_file), read.csv)
write.csv(joblist, "data/joblist/joblist_collection.csv")
if (!dir.exists("data/archived/joblist/")) dir.create("data/archived/joblist/")
file.copy(from = paste0(path, joblist_file[-1]), to = paste0("data/archived/joblist/", joblist_file[-1]))
file.remove(from = paste0(path, joblist_file[-1]))

# archiving jobdata
path <- "data/jobdata/"
jobdata_file <- list.files(path, pattern = "jobdata.+rds")
jobdata <- purrr::map_df(paste0(path, jobdata_file), readRDS)
saveRDS(jobdata, paste0(path, "jobdata.rds"))
if (!dir.exists("data/archived/jobdata/")) dir.create("data/archived/jobdata/")
file.copy(from = paste0(path, jobdata_file), to = paste0("data/archived/jobdata/", jobdata_file))
file.remove(from = paste0(path, jobdata_file))

# archiving jobraw
path <- "data/jobraw/"
jobraw_file <- list.files(path, pattern = "jobraw.+rds")
jobraw <- purrr::map_df(paste0(path, jobraw_file), readRDS)
saveRDS(jobraw, "data/jobraw/jobraw.rds")
if (!dir.exists("data/archived/jobraw")) dir.create("data/archived/jobraw")
file.copy(from = paste0(path, jobraw_file), to = paste0("data/archived/jobraw/", jobraw_file))
file.remove(from = paste0(path, jobraw_file))
