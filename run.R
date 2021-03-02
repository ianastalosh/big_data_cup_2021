
# Run file to source all scripts and save into rda at the end, so can be imported nicely into the markdown

# Packages
library(plyr) # mapvalues, to use the cluster number
library(tidyverse) # duh
library(janitor) # clean variable names to snakecase
library(lubridate) # date time formatting
library(zoo) # Mainly for na.locf and creating rolling functions
library(factoextra) # kmeans

# Load configs and utils
source('configs.R')
source('utils.R')
source('custom_rink_function.R')

# Import data
source('import_and_engineer_data.R')
source('create_clusters.R')
source('xg_model.R')
source('analyse_possessions.R')

# Save environment to output
save.image(file = 'data/envir_image.RData')