source("01_job_jobstreet_crawler.R")
library(rvest)
library(stringr)
library(mongolite)
suppressMessages(library(dplyr))

# joblist <- readRDS("data/jobstreet_joblist_2022-02-06.rds") # cari yang terakhir

if (new_job_availability) {
  
  sleep_time <- 4L
  
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
        message(paste0("Error data ", num, ": ",conditionMessage(e)))
      })
    }
    return(jobdesc)
  }
  
  iter <- ceiling(nrow(joblist)/10)
  
  for (i in 1:iter) {
    message(paste0("LOOP ", i, "/", iter))
    jobdesc <- collect_jobdesc(joblist, i*10-9, i*10) # joblist object is from script 01
    if (i > 1) {
      jobraw <- bind_rows(jobraw, jobdesc)
    } else {
      jobraw <- jobdesc
    }
    if (i < iter) {
      message(sprintf("%s second pause", sleep_time))
      Sys.sleep(sleep_time)
    }
  }
  
  jobraw <- jobraw %>% distinct()
  
  saveRDS(jobraw, paste0("data/jobstreet_jobraw_", as.character(Sys.Date()), ".rds"))
  
  jobraw_backup <- jobraw
  # jobraw <- jobraw_backup
  
  jobraw$description <- lapply(jobraw$description, function(row) {
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
  
  # store data to rds
  store_name <- paste0("data/jobstreet_jobdata_", as.character(Sys.Date()), ".rds")
  saveRDS(jobraw, store_name)
  message(paste0("Data saved to ", store_name))
  
  # store data to mongodb
  conn <- mongo(
    collection = "jobcollection", 
    db = "test", 
    url = paste0("mongodb://", Sys.getenv("MONGO_USERNAME"), ":", Sys.getenv("MONGO_PASSWORD"), "@", "localhost:", Sys.getenv("MONGO_PORT")), 
    verbose = TRUE
  )
  conn$insert(jobraw) # insert record
  message(paste0("Data inserted to mongodb's collection"))
  
}
