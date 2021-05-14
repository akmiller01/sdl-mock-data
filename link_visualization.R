list.of.packages <- c("data.table", "dplyr", "tidyverse", "network", "visNetwork", "networkD3")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

setwd("~/git/sdl-mock-data")

dat = fread("organisation_links.csv")
names(dat) = make.names(names(dat))
dat = subset(dat, Organisation.2 %in% unique(Organisation.1))
sources = dat %>%
  distinct(Organisation.1) %>%
  rename(label = Organisation.1)
destinations = dat %>%
  distinct(Organisation.2) %>%
  rename(label = Organisation.2)
nodes = full_join(sources, destinations, by = "label")
nodes = nodes %>% rowid_to_column("id")
route = dat %>%
  group_by(Organisation.1, Organisation.2) %>%
  summarize(weight = n()) %>%
  ungroup()

edges = route %>%
  left_join(nodes, by = c("Organisation.1" = "label")) %>%
  rename(from = id)
edges = edges %>%
  left_join(nodes, by = c("Organisation.2" = "label")) %>%
  rename(to = id)
edges <- select(edges, from, to, weight)

# routes_network = network(edges, vertex.attr = nodes, matrix.type = "edgelist", ignore.eval=F)
# plot(routes_network)

nodes_d3 <- mutate(nodes, id = id - 1)
edges_d3 <- mutate(edges, from = from - 1, to = to - 1)
forceNetwork(Links = edges_d3, Nodes = nodes_d3, Source = "from", Target = "to", 
             NodeID = "label", Group = "id", Value = "weight", 
             opacity = 1, fontSize = 16, zoom = TRUE)
