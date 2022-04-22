#' Joblist Collection Generator
#' 
#' Create joblist collection and archive joblist

suppressPackageStartupMessages(library(dplyr))
library(readr)

path <- "data/joblist"
if (!dir.exists(path)) stop(sprintf("No path named '%s'", path))

joblist <- list.files(path, "joblist.+csv", full.names = TRUE)

if (length(joblist) == 1) {
  stop("No update found", call. = FALSE)
} else {
  joblist <- purrr::map_df(joblist, read_csv, col_types = cols(id = col_character()))
}

# joblist <- joblist[!duplicated(joblist),]

if (nrow(joblist) != nrow(distinct(joblist[,1:2]))) {
  stop("Duplicated record with different times detected")
} else {
  write_csv(joblist, file = paste0(path, "/joblist_collection.csv"))
}

joblist_archiving <- list.files(path, "joblist_(\\d{2,4}\\-?){3}\\.csv")

if (length(joblist_archiving) == 0) {
  stop("No update found")
} else {
  if (!dir.exists("data/archived/joblist")) dir.create("data/archived/joblist")
  file.copy(
    from = paste0(path, "/", joblist_archiving), 
    to = paste0("data/archived/joblist/", joblist_archiving)
  )
  file.remove(from = paste0(path, "/", joblist_archiving))
}
