# The result would be joblist
library(rvest)
library(stringr)
suppressMessages(library(readr))
suppressMessages(library(dplyr))

# function -----
collect_joblist <- function(page){
  title <- page %>% 
    html_elements(".sx2jih0 .zcydq8bm") %>% 
    html_element("h1") %>% 
    html_text()
  
  id <- page %>% 
    html_elements(".sx2jih0 .zcydq8bm") %>% 
    html_element("h1") %>% 
    html_element("a") %>% 
    html_attr("href") %>% 
    str_extract("jobstreet-id-job-\\d{7}") %>% 
    str_extract("\\d{7}")
  
  jobs <- tibble(id, title) %>% 
    na.omit() %>% 
    distinct() %>% 
    mutate(link = paste0(baseurl, "job/", id))
  
  return(jobs)
}

# scraping -----
baseurl <- "https://www.jobstreet.co.id/id/"
pagination <- 1
url <- paste0(baseurl, "job-search/building-construction-jobs/", pagination)

# parameter
sleep_time <- 3L
message(paste0("Pause duration: ", sleep_time, " secs"))

start_time <- Sys.time()

page <- read_html(url)

# counting iteration
count <- page %>% 
  html_elements(xpath = "/html/body/div[1]/div/div/div[2]/div[2]/div/div/div/div/div/div/div/div[1]/div[1]/div/span") %>% 
  html_text() %>% 
  str_extract("(\\d{1,2})?\\.(\\d{1,3})+") %>% 
  str_remove("\\.") %>% 
  as.integer()
count <- ceiling(count/30)

# crawling first page
joblist <- collect_joblist(page)
message(sprintf("Progress %s/%s", pagination, count))
Sys.sleep(sleep_time)

# crawling another pages
for (pagination in 2:count) {
  tryCatch({
    url <- paste0(baseurl, "job-search/building-construction-jobs/", pagination)
    page <- read_html(url)
    jobs <- collect_joblist(page)
    joblist <- bind_rows(joblist, jobs)
    message(sprintf("Progress %s/%s", pagination, count))
    Sys.sleep(sleep_time)
  }, 
  error = function(e){
    message(paste0("Error data ", pagination, ": ", conditionMessage(e)))
  })
}

end_time <- Sys.time()
duration <- end_time - start_time - succeed_crawl*(sleep_time/60)
duration <- as.numeric(duration)
message(paste0(
  "Scraping duration: ",
  floor(duration), " mins ", round((duration - floor(duration))*60), " secs"
))

# subset data -----
# load previous job collected
joblist_collection <- "data/joblist/joblist_collection.csv"
if(file.exists(joblist_collection)) {
  joblist_collection <- read_csv(joblist_collection, col_types = cols(id = col_character()))
}

joblist_older <- "data/joblist"
joblist_older <- list.files(joblist_older, "jobstreet.+csv", full.names = TRUE)
if(length(joblist_older) > 0) {
  joblist_older <- read_csv(joblist_older, col_types = cols(id = col_character()))
  joblist_older <- joblist_older[-4] %>% distinct()
  joblist_collection <- bind_rows(joblist_collection, joblist_older) %>% distinct()
}

# subset data
joblist <- anti_join(joblist, joblist_collection, by = "id") %>% distinct()

# save new data -----
if (nrow(joblist) > 0) {
  if(!dir.exists("data/joblist")) dir.create("data/joblist")
  joblist <- bind_cols(joblist, timestamp = end_time)
  write.csv(joblist, file = paste0("data/joblist/jobstreet_joblist_", as.character(Sys.Date()), ".csv"), row.names = FALSE)
  message(paste0(nrow(joblist), " new job link(s) stored"))
  new_job_availability <- TRUE
} else {
  message(paste0("There is no new job post yet."))
  new_job_availability <- FALSE
}

source("02_job_jobstreet_structuring.R")
source("03_job_jobstreet_db.R")
