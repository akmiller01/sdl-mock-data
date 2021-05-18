list.of.packages <- c("data.table", "tidyverse")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

setwd("~/git/sdl-mock-data")

gender_marker = function(policy_marker_str){
  if(is.na(policy_marker_str)){return(NA)}
  return("1" %in% unlist(strsplit(policy_marker_str, split=",")))
}

dat = fread("sdl_incoming.csv")

ids = unique(dat$`IATI Identifier`)[c(1:500)]

base_query = 'https://iatidatastore.iatistandard.org/search/activity?q=(iati_identifier:"xxxyyyzzz")&fl=iati_identifier,description_narrative_text,location_name_narrative_text,policy_marker_code&wt=csv&rows=50'

additions_list = list()
additions_index = 1

for(id in ids){
  adds = fread(gsub("xxxyyyzzz", id, base_query))
  additions_list[[additions_index]] = adds
  additions_index = additions_index + 1
}

additions = rbindlist(additions_list)
additions$Gender = sapply(additions$policy_marker_code, gender_marker)
additions = additions %>% select(iati_identifier, description_narrative_text, location_name_narrative_text, Gender) %>%
  rename(
  "IATI Identifier" = iati_identifier,
  "Activity Description" = description_narrative_text,
  "Location Name" = location_name_narrative_text
  )

dat = subset(dat, select=which(!names(dat) %in% c("Activity Description", "Location Name", "Gender")))
dat = merge(dat, additions, by="IATI Identifier")
dat = subset(dat, select=c(1,2,21,3:8,22,9:16,23,17:20))

fwrite(dat, "sdl_incoming_formatted.csv")
