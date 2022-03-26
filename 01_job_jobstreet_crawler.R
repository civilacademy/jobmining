library(rvest)
library(stringr)
suppressMessages(library(dplyr))

baseurl <- "https://www.jobstreet.co.id/id/"
pagination <- 1
url <- paste0(
  baseurl, "job-search/building-construction-jobs/", pagination
)

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

sleep_time <- 4L
start_time <- Sys.time()

page <- read_html(url)

count <- page %>% 
  html_elements(xpath = "/html/body/div[1]/div/div/div[2]/div[2]/div/div/div/div/div/div/div/div[1]/div[1]/div/span") %>% 
  html_text() %>% 
  str_extract("(\\d{1,2})?\\.(\\d{1,3})+") %>% 
  str_remove("\\.") %>% 
  as.integer()
count <- ceiling(count/30)

joblist <- collect_joblist(page)
message(sprintf("Progress %s/%s", pagination, count))
Sys.sleep(sleep_time)

for (pagination in 2:count) {
  url <- paste0(
    baseurl, "job-search/building-construction-jobs/", pagination
  )
  page <- read_html(url)
  jobs <- collect_joblist(page)
  joblist <- bind_rows(joblist, jobs)
  message(sprintf("Progress %s/%s", pagination, count))
  Sys.sleep(sleep_time)
  succeed_crawl <- pagination
}

end_time <- Sys.time()
duration <- end_time - start_time - succeed_crawl*(sleep_time/60)
message(duration)

joblist_prev <- lapply(list.files("data", "joblist_.+rds", full.names = TRUE), function(f){
  joblist_file <- readRDS(f)
})

joblist_older <- joblist_prev[[1]]
for (i in 2:length(joblist_prev)) {
  joblist_older <- bind_rows(joblist_older, joblist_prev[[i]])
  joblist_older <- distinct(joblist_older)
}

joblist <- joblist %>% anti_join(joblist_older, by = "id") %>% distinct()

if (nrow(joblist) > 0) {
  saveRDS(joblist, file = paste0("data/jobstreet_joblist_", as.character(Sys.Date()), ".rds"))
  joblist <- bind_cols(joblist, timestamp = end_time)
  write.csv(joblist, file = paste0("data/jobstreet_joblist_", as.character(Sys.Date()), ".csv"), row.names = FALSE)
  message(paste0(nrow(joblist), " new job post(s)."))
  new_job_availability <- TRUE
} else {
  message(paste0("There is no new job post yet."))
  new_job_availability <- FALSE
}
