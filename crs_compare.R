list.of.packages <- c("data.table", "tidyverse")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

setwd("~/git/sdl-mock-data")

donor_names = c(
  "Austria"
  ,"Belgium"
  ,"Denmark"
  ,"France"
  ,"Germany"
  ,"Italy"
  ,"Netherlands"
  ,"Norway"
  ,"Portugal"
  ,"Sweden"
  ,"Switzerland"
  ,"United Kingdom"
  ,"Finland"
  ,"Iceland"
  ,"Ireland"
  ,"Luxembourg"
  ,"Cyprus"
  ,"Greece"
  ,"Malta"
  ,"Spain"
  ,"Turkey"
  ,"Slovenia"
  ,"Croatia"
  ,"Czech Republic"
  ,"Slovak Republic"
  ,"Liechtenstein"
  ,"Bulgaria"
  ,"Hungary"
  ,"Poland"
  ,"Romania"
  ,"Estonia"
  ,"Latvia"
  ,"Lithuania"
  ,"Russia"
  ,"Canada"
  ,"United States"
  ,"Israel"
  ,"Kuwait"
  ,"Qatar"
  ,"Saudi Arabia"
  ,"United Arab Emirates"
  ,"Azerbaijan"
  ,"Kazakhstan"
  ,"Japan"
  ,"Chinese Taipei"
  ,"Korea"
  ,"Thailand"
  ,"Australia"
  ,"New Zealand"
  ,"EU Institutions"
)

crs = fread("crs_2019.csv",skip=1)
crs_totals = sapply(crs[,donor_names,with=F], sum, na.rm=T)
crs_tab = data.frame(DonorName=donor_names, crs_total=crs_totals)
crs_tab$crs_total = crs_tab$crs_total * 1000000

mapping = fread("iati_publishers.csv") %>% select(reporting_org_ref, country_or_org_name, org_type)
mapping = subset(mapping, org_type=="bilateral")
mapping_remapping = c(
  "Australia"="Australia",
  "Canada"="Canada",
  "Switzerland"="Switzerland",
  "Germany"="Germany",
  "Spain"="Spain",
  "Finland"="Finland",
  "France"="France",
  "UK"="United Kingdom",
  "Netherlands"="Netherlands",
  "Norway"="Norway",
  "New Zealand"="New Zealand",
  "Sweden"="Sweden",
  "US"="United States",
  "EC"="EU Institutions",
  "Belgium"="Belgium",
  "Denmark"="Denmark"
)
mapping$DonorName = mapping_remapping[mapping$country_or_org_name]
mapping = mapping %>% select(DonorName, reporting_org_ref)

iati_spend = fread(
  "~/git/IATI-results-framework-2021/output/total_spend_2019_by_publisher.csv"
  ) %>% select(reporting_org_ref, total.spend)
setnames(iati_spend, "total.spend", "iati_total")
iati_spend = merge(iati_spend, mapping, by=c("reporting_org_ref"))
iati_spend = iati_spend[,.(iati_total=sum(iati_total, na.rm=T)), by=.(DonorName)]

combined = merge(crs_tab, iati_spend, by="DonorName", all.x=T)
combined$iati_total[which(is.na(combined$iati_total))] = 0
combined$diff = combined$iati_total / combined$crs_total
combined$substantial = combined$diff > 0.5
combined = combined %>% select(DonorName, substantial)
combined = combined[order(-combined$substantial, combined$DonorName),]
setnames(combined, "substantial", "Does IATI have substantial data coverage of this donor in 2019?")
fwrite(combined, "CRS_exclusions_2019.csv")