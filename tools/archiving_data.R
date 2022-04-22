#' Archiving Job Data
#' 
#' Archiving jobraw and jobdata. Archiving joblist: tools/joblist_collection.R
# Using purrr

tag <- "jobraw" # c("jobdata", "jobraw")

jobarchive <- function(tag) {
  path <- paste0("data/", tag, "/")
  data_file <- list.files(path, pattern = paste0(tag, ".+rds"))
  if (length(data_file) == 1) { stop("There is no update to be archived", call. = FALSE) }
  data_obj <- purrr::map_df(paste0(path, data_file), readRDS)
  data_obj <- unique(data_obj)
  saveRDS(data_obj, paste0(path, paste0(tag, ".rds")))
  if (!dir.exists(sprintf("data/archived/%s/", tag))) dir.create(sprintf("data/archived/%s/", tag))
  data_file <- list.files(path, pattern = sprintf("*%s_.+rds", tag))
  file.copy(from = paste0(path, data_file), to = paste0(sprintf("data/archived/%s/", tag), data_file))
  file.remove(from = paste0(path, data_file))
  message("Done!")
}

jobarchive(tag)
