library(rvest)
library(stringr)
library(mongolite)
suppressMessages(library(dplyr))

# you have to import previous data from script 01 named joblist
source("01_job_jobstreet_crawler.R")

if (new_job_availability) {
  
  # parameters
  sleep_time <- 3L
  message(paste0("Pause duration: ", sleep_time, " secs"))
  iter <- ceiling(nrow(joblist)/10)
  # iter <- floor(nrow(joblist)/10)
  # last_iter_item <- nrow(joblist) %% 10
  
  # function
  collect_jobdesc <- function(joblist, n0, n1){
    
    for (num in n0:n1) {
      tryCatch({
        page <- read_html(joblist$link[[num]])
        
        title <- page %>% 
          html_element("h1") %>% 
          html_text()
        
        company <- page %>% 
          html_element(xpath = "/html/body/div[1]/div/div/div[2]/div/div[1]/div[1]/div[1]/div/div/div[1]/div/div/div[2]/div/div/div/div[2]/span") %>% 
          html_text()
        
        location <- page %>% 
          html_element(xpath = "/html/body/div[1]/div/div/div[2]/div/div[1]/div[1]/div[1]/div/div/div[2]/div/div/div/div[1]/div/span") %>% 
          html_text()
        
        metadata <- page %>% 
          html_elements(".sx2jih0 .zcydq86a") %>% 
          html_text() %>% 
          as_tibble() %>% 
          filter(value != "") %>%
          .[[1]]
        
        description <- page %>% 
          html_element(xpath = "/html/body/div[1]/div/div/div[2]/div/div[2]/div/div[1]/div") %>% 
          html_children()
        while (!("h4" %in% html_name(description))) {
          description <- description %>% html_children()
        }
        
        job <- tibble(
          id = joblist$id[[num]], 
          title, 
          company, 
          location,
          metadata = list(metadata),
          # published, 
          description = list(description),
          link = joblist$link[[num]]
        )
        
        if (num > n0) {
          jobdesc <- bind_rows(jobdesc, job)
        } else {
          jobdesc <- job
        }
        
        message(sprintf("Progress %s/%s", num-n0+1, n1-n0+1))
        Sys.sleep(sleep_time)
      },
      error = function(e){
        message(paste0("Error data ", num, ": ", conditionMessage(e)))
      })
    }
    return(jobdesc)
  }
  
  # looping
  for (i in 1:iter) {
    message(paste0("LOOP ", i, "/", iter))
    jobdesc <- collect_jobdesc(joblist, i*10-9, i*10)
    if (i > 1) {
      jobraw <- bind_rows(jobraw, jobdesc)
    } else {
      jobraw <- jobdesc
    }
  }
  
  jobraw <- jobraw %>% distinct()
  
  # save raw data to rds
  if(!dir.exists("data/jobraw")) dir.create("data/jobraw")
  store_name <- paste0("data/jobraw/jobstreet_jobraw_", as.character(Sys.Date()), ".rds")
  saveRDS(jobraw, store_name)
  message(paste0("Raw data saved to ", store_name))
  
  # structural transformation
  jobdata <- jobraw
  jobdata$description <- lapply(jobdata$description, function(row) {
    # tahap 1
    description <- lapply(row, function(node){
      if ("div" %in% html_name(node)) {
        node <- html_children(node)
      } else {
        node <- node
      }
    })
    indent <- 5
    i <- 1
    # tahap 2: loop ekstrak indentasi
    for (i in 1:indent) {
      description <- lapply(description, function(node){
        if ("div" %in% html_name(node) | ("span" %in% html_name(node))) {
          node <- html_children(node)
        } else {
          node <- node
        }
      })
      i <- i + 1
    }
    # tahap 3: jadikan character
    description <- lapply(description, function(node){
      if ("div" %in% html_name(node)) {
        node <- html_children(node)
      } else if ("ul" %in% html_name(node) | "ol" %in% html_name(node)) {
        node <- html_children(node) %>% html_text()
      } else if ("h4" %in% html_name(node) | 
                 "p" %in% html_name(node) | 
                 "li" %in% html_name(node) | 
                 "span" %in% html_name(node)) {
        node <- html_text(node)
      } else {
        node <- node
      }
    })
    # tahap 4: tanda baca
    description <- lapply(description, function(node){
      node <- node %>% 
        str_remove_all("•") %>% 
        str_remove_all("·") %>% 
        str_remove_all("\\.") %>% 
        str_replace_all("-", " ") %>% 
        str_replace_all("–", " ") %>% 
        str_replace_all("▪", " ") %>% 
        str_replace_all(":", " ") %>% 
        str_replace_all(",", " ") %>% 
        str_replace_all(";", " ") %>% 
        str_replace_all("\\/", " ") %>% 
        str_replace_all("\\(", " ") %>% 
        str_replace_all("\\)", " ") %>% 
        str_squish()
    })
  })
  
  # save data to rds
  if(!dir.exists("data/jobdata")) dir.create("data/jobdata")
  store_name <- paste0("data/jobdata/jobstreet_jobdata_", as.character(Sys.Date()), ".rds")
  saveRDS(jobdata, store_name)
  message(paste0("Data saved to ", store_name))
  
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
