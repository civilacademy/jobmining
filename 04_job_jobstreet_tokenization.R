library(tidytext)
library(stringr)
suppressMessages(library(dplyr))
library(tidyr)
library(tidytext)

jobdata <- lapply(list.files("data", "jobdata_.+rds", full.names = TRUE), function(f){
  joblist_file <- readRDS(f)
})

jobdata_i <- jobdata[[1]]
for (i in 2:length(jobdata)) {
  jobdata_i <- bind_rows(jobdata_i, jobdata[[i]])
  jobdata_i <- distinct(jobdata_i)
}

# c("coordinator", "koordinator")
# c("manager", "manajer", "management")
# c("supervisor", "spv", "pelaksana", "inspector", "pengawas", "control", "qc", "qa")
# c("engineer", "insinyur")
# c("surveyor", "survey")
# c("estimator")
# c("tenaga ahli")
# c("officer")
# c("drafter")
# c("designer", "desainer", "architect", "arsitek")

jobdata_i <- jobdata_i %>% 
  mutate(class_desc = sapply(jobdata_i$description, class))

jobdata_i <- filter(jobdata_i, !class_desc == "xml_nodeset")

text <- unlist(jobdata_i$description)
text <- tibble(text = text) %>% 
  filter(
    !(text %in% c("Deskripsi Pekerjaan",
                  "Job Description",
                  "Informasi Tambahan",
                  "Additional Information",
                  "Tingkat Pekerjaan",
                  "Career Level",
                  "Kualifikasi",
                  "Qualifications",
                  "Pengalaman Kerja",
                  "Years of Experience",
                  "Jenis Pekerjaan",
                  "Job Type",
                  "Spesialisasi Pekerjaan",
                  "Job Specializations",
                  "Main Responsibilities",
                  "Requirement",
                  "Requirements",
                  "Job descriptions",
                  "Job description",
                  "Descriptions",
                  "Description"))
  ) %>% 
  .[[1]]

text_df <- tibble(line = 1:length(text), text = text)
word_tokens <- unnest_tokens(text_df, word, text)

# create stop words data
stop_words_id <- read.csv("~/Documents/id_.stopwords.txt", header = FALSE)
stop_words_id <- tibble(stop_words_id, lexicon = "ID")
names(stop_words_id) <- c("word", "lexicon")
stop_words_id <- bind_rows(stop_words_id, stop_words)
stop_words_id <- filter(stop_words_id, !word == "up")

word_tokens <- anti_join(word_tokens, stop_words_id, by = "word")
word_unigram <- count(word_tokens, word, sort = TRUE)
write.csv(word_unigram, "output/jobstreet_unigram.csv")

word_bigrams <- text_df %>% 
  unnest_tokens(word, text, token = "ngrams", n = 2) %>% 
  separate(word, c("word1", "word2"), sep = " ") %>% 
  filter(!word1 %in% stop_words_id$word) %>% 
  filter(!word2 %in% stop_words_id$word) %>% 
  unite(word, word1, word2, sep = " ") %>% 
  count(word, sort = TRUE)

# word_bigrams %>% arrange(word) %>% View()

software <- c("2d",
              "3d",
              "3dmax",
              "3dsmax",
              "adobe",
              # "archicad",
              "auto",
              "cad",
              "corel",
              "csi",
              "etab",
              "excel",
              "gis",
              "illustrator",
              "lumion",
              "midas",
              "primavera",
              "revit",
              "sap",
              "2000",
              "photoshop",
              "plaxis",
              "rhino",
              "sketch up",
              "sketchup",
              "skechup",
              "skecthup",
              "skp",
              "solidwork",
              "staad",
              "stad",
              "tekla")

software_count <- lapply(software, function(x){
  filter(word_bigrams, grepl(x, word_bigrams$word))
})

join_list_df <- function(listdf) {
  df_result <- listdf[[1]]
  for (i in 2:length(listdf)) {
    df_result <- bind_rows(df_result, listdf[[i]])
    df_result <- distinct(df_result)
  }
  return(df_result)
}

software <- software_count[[1]]
for (i in 2:length(software_count)) {
  software <- bind_rows(software, software_count[[i]])
  software <- distinct(software)
}

# autocad
autocad <- c("auto ", "cad")
autocad <- lapply(autocad, function(x){
  filter(software, grepl(x, software$word))
})
autocad <- join_list_df(autocad) %>% distinct()
exception <- c("archicad", "watercad", "cadang", "facade", "auto level", "auto card")
exception <- lapply(exception, function(x){
  filter(autocad, grepl(x, autocad$word))
})
exception <- join_list_df(exception) %>% distinct()
autocad <- filter(autocad, !word %in% exception$word)
autocad <- sum(autocad$n)

word_unigram %>% filter(word %in% c("autocad", "cad"))

# sap2000
sap2000 <- c("sap", "2000")
sap2000 <- lapply(sap2000, function(x){
  filter(software, grepl(x, software$word))
})
sap2000 <- join_list_df(sap2000) %>% distinct()
exception <- c("asap mid", "company’s sap", "control sap", "current sap", "daging sapi", "memperisapkan", "whatsapp", "iso", "22000", "200000")
exception <- lapply(exception, function(x){
  filter(sap2000, grepl(x, sap2000$word))
})
exception <- join_list_df(exception) %>% distinct()
sap2000 <- filter(sap2000, !word %in% exception$word)
sap2000 <- sum(sap2000$n)

word_unigram %>% filter(word %in% c("sap2000", "sap"))

# sketch up
sketchup <- c("sketch up", "sketchup", "skechup", "skecthup", "skp")
sketchup <- lapply(sketchup, function(x){
  filter(software, grepl(x, software$word))
})
sketchup <- join_list_df(sketchup) %>% distinct()
sketchup <- sum(sketchup$n)

word_unigram %>% filter(word %in% c("sketchup", "sketch"))

# etabs
etabs <- c("etab", "etabs")
etabs <- lapply(etabs, function(x){
  filter(software, grepl(x, software$word))
})
etabs <- join_list_df(etabs) %>% distinct()
exception <- c("jabodetabek", "forgetable", "timetable")
exception <- lapply(exception, function(x){
  filter(etabs, grepl(x, etabs$word))
})
exception <- join_list_df(exception) %>% distinct()
etabs <- filter(etabs, !word %in% exception$word)
etabs <- sum(etabs$n)

word_unigram %>% filter(word %in% c("etabs", "etab"))

# revit
revit <- c("revit")
revit <- lapply(revit, function(x){
  filter(software, grepl(x, software$word))
})
revit <- revit[[1]]
revit <- sum(revit$n)

word_unigram %>% filter(word %in% c("revit"))

# solidworks
solidworks <- c("solidwork", "solidworks")
solidworks <- lapply(solidworks, function(x){
  filter(software, grepl(x, software$word))
})
solidworks <- join_list_df(solidworks) %>% distinct()
solidworks <- sum(solidworks$n)

word_unigram %>% filter(word %in% c("solidwork", "solidworks"))

# staad pro
staadpro <- c("staad", "stad")
staadpro <- lapply(staadpro, function(x){
  filter(software, grepl(x, software$word))
})
staadpro <- join_list_df(staadpro) %>% distinct()
staadpro <- sum(staadpro$n)

word_unigram %>% filter(word %in% c("staad", "stad"))

# plaxis
plaxis <- c("plaxis")
plaxis <- lapply(plaxis, function(x){
  filter(software, grepl(x, software$word))
})
plaxis <- plaxis[[1]]
plaxis <- sum(plaxis$n)
word_unigram %>% filter(word %in% c("plaxis"))

# tekla
tekla <- c("tekla")
tekla <- lapply(tekla, function(x){
  filter(software, grepl(x, software$word))
})
tekla <- tekla[[1]]
tekla <- sum(tekla$n)
word_unigram %>% filter(word %in% c("tekla"))

# primavera
primavera <- c("primavera")
primavera <- lapply(primavera, function(x){
  filter(software, grepl(x, software$word))
})
primavera <- primavera[[1]]
primavera <- sum(primavera$n)
word_unigram %>% filter(word %in% c("primavera"))

# midas
midas <- c("midas")
midas <- lapply(midas, function(x){
  filter(software, grepl(x, software$word))
})
midas <- midas[[1]]
midas <- sum(midas$n)
word_unigram %>% filter(word %in% c("midas"))

# 
autocad
sap2000
sketchup
etabs
revit
solidworks
staadpro
plaxis
tekla
primavera
midas

software_list <- tibble(autocad,
       sap2000,
       sketchup,
       etabs,
       revit,
       solidworks,
       staadpro,
       plaxis,
       tekla,
       primavera,
       midas) %>% 
  pivot_longer(cols = everything(), names_to = "software", values_to = "n_bigrams")


software_l_bigrams <- tibble(
  software = software_list[[1]],
  n_unigram = c(
    word_unigram %>% filter(word %in% c("autocad", "cad")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("sap2000", "sap")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("sketchup", "sketch")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("etabs", "etab")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("revit")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("solidwork", "solidworks")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("staad", "stad")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("plaxis")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("tekla")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("primavera")) %>% .[[2]] %>% sum(),
    word_unigram %>% filter(word %in% c("midas")) %>% .[[2]] %>% sum()
  )
)

software_list <- left_join(software_list, software_l_bigrams, by = "software")
software_list <- software_list %>% 
  mutate(diff = n_bigrams - n_unigram)
software_list <- software_list %>% 
  arrange(desc(n_bigrams))
print(software_list)
(lm(formula = n_bigrams ~ n_unigram, data = software_list))
# library(ggplot2)
 # ggplot(software_list, aes(n_unigram, n_bigrams)) +
 #  geom_point() + 
 #  coord_fixed(ratio = 1) +
 #  stat_smooth(method = lm)
