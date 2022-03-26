library(readr)
library(dplyr)
library(tidyr)
library(tidytext)

stop_words_id <- "https://raw.githubusercontent.com/masdevid/ID-Stopwords/master/id.stopwords.02.01.2016.txt"
stop_words_id <- read_csv(stop_words_id, col_names = FALSE)
names(stop_words_id) <- "word"

joblist <- read_csv("data/joblist/joblist_collection.csv", col_types = cols(id = col_character()))
text_df <- tibble(line = 1:nrow(joblist), text = tolower(joblist$title))
word_tokens <- unnest_tokens(text_df, word, text)
jobtitle_unigram <- count(word_tokens, word, sort = TRUE)
jobtitle_bigrams <- text_df %>% 
  unnest_tokens(word, text, token = "ngrams", n = 2) %>% 
  separate(word, c("word1", "word2"), sep = " ") %>% 
  filter(!word1 %in% stop_words_id$word) %>% 
  filter(!word2 %in% stop_words_id$word) %>% 
  unite(word, word1, word2, sep = " ") %>% 
  count(word, sort = TRUE) %>% 
  filter(!word %in% "NA NA")
if(!dir.exists("output")) dir.create("output")
write_csv(jobtitle_bigrams, file = "output/job_position.csv")
