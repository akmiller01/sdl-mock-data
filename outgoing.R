list.of.packages <- c("data.table", "tidyverse")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

setwd("~/git/sdl-mock-data")

dat = fread("sdl_outgoing.csv")

ids = unique(dat$`IATI Identifier`)[c(1:500)]

base_query = 'https://iatidatastore.iatistandard.org/search/activity?q=(iati_identifier:"xxxyyyzzz")&fl=description_narrative_text,location_name_narrative_text,policy_marker_code&wt=csv&rows=50'

for(id in ids){
  location_names = paste(fread(gsub("xxxyyyzzz", id, base_query))$location_name_narrative_text, collapse="|")
  if(location_names != "NA"){
    dat$`Location Name`[which(dat$`IATI Identifier`==id)] = location_names
  }
}

dat = subset(dat, `IATI Identifier` %in% ids)

sig_map = c(
  "0" = "Not targeted",
  "1" = "Significant objective",
  "2" = "Principal objective",
  "3" = "Principal objective and in support of an action programme",
  "4" = "Explicit primary objective"
)

markers = dat$`Policy Marker`
sigs = dat$`Policy Marker Significance`

for(i in 1:nrow(dat)){
  marker = markers[i]
  sig = sigs[i]
  if(marker!=""){
    marker_split = unlist(strsplit(marker,split="\\|"))
    sig_split = unlist(strsplit(sig,split="\\|"))
    for(j in 1:length(marker_split)){
      if(marker_split[j] == "1"){
        dat$Gender[i] = "TRUE"
        dat$`Gender Significance`[i] = sig_map[[sig_split[j]]]
      }
    }
  }
}

sectors = fread("Sector.csv") %>% select(code, name) %>% rename("Sector Code" = code, "Sector Name" = name)
dat = merge(dat, sectors, by="Sector Code", all.x=T, sort=F)
dat = subset(dat, select=c(2:14, 1, 25, 23, 15:22, 24))

fwrite(dat, "sdl_outgoing_formatted.csv")
