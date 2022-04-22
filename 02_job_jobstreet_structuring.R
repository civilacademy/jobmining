library(rvest)
library(stringr)
suppressMessages(library(dplyr))

# you have to run previous script 01 to get object named joblist

if (new_job_availability) {
  
  # parameters
  sleep_time <- 2L
  message(paste0("Pause duration: ", sleep_time, " secs"))
  iter <- nrow(joblist)
  
  # function
  collect_jobdesc <- function(joblist, n){
    
    for (num in 1:n) {
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
          description = list(description),
          link = joblist$link[[num]]
        )
        
        if (num > 1) {
          jobdesc <- bind_rows(jobdesc, job)
        } else {
          jobdesc <- job
        }
        
        message(sprintf("Progress %s/%s", num, n))
        Sys.sleep(sleep_time)
      },
      error = function(e){
        message(paste0("Error data ", num, ": ", conditionMessage(e)))
      })
    }
    return(jobdesc)
  }
  
  message("Get job details...")
  jobraw <- collect_jobdesc(joblist, iter)
  jobraw <- distinct(jobraw)
  
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
  
}

# next step: saving jobdata to db using script 03
