
create_list_of_couplets = function(string) {
  
  vector = strsplit(string, split = ',') %>% unlist() %>% as.numeric()
  
  if (length(vector) <= 1) {
    return(NA)
  }
  
  led_vector = lead(vector)
  
  num_passes = length(vector)
  num_pairs = num_passes - 1
  
  pairs = paste(vector[1:num_pairs], led_vector[1:num_pairs], sep = ',')
  
  return(as.list(pairs))
}

create_pairs_vectors = function(vector) {
  
  outcome = lappy(vector, create_list_of_couplets)
  return(outcome)
  
}


# Get stats describing what happened on each possession

# Add XG model to data
source('xg_model.R')

data_shots = data_cluster_added %>% 
  ungroup() %>%
  filter(event %in% c('Shot', 'Goal'))

shot_xg = predict(xg_glm, data_shots, 'response')
data_shots_xg = cbind(data_shots, shot_xg)

data_no_shots = data_cluster_added %>%
  ungroup() %>%
  filter(event %!in% c('Shot', 'Goal'))

data_cluster_xg_added = bind_rows(data_no_shots, data_shots_xg) %>% 
  arrange(event_number)

match_possessions = data_cluster_xg_added %>%
  group_by(game_date, game_id, period, skater_situation, score_situation, possession_number) %>% 
  summarize(starting_time = max(seconds_remaining),
            ending_time = min(seconds_remaining),
            first_event = first(event),
            last_event = last(event),
            first_x = first(x_coordinate),
            first_y = first(y_coordinate),
            num_events = n(),
            num_passes = sum(event %in% c('Play', 'Incomplete Play')),
            num_shots = sum(event %in% c('Shot', 'Goal')),
            num_dumps = sum(event == 'Dump In/Out'),
            num_goals = sum(event == 'Goal'),
            shot_location_x = ifelse(num_shots > 0, max(x_coordinate, na.rm = TRUE), NA),
            shot_location_y = ifelse(num_shots > 0, max(y_coordinate, na.rm = TRUE), NA),
            shot_xg = ifelse(num_shots > 0, max(shot_xg, na.rm = TRUE), NA),
            pass_cluster_sequence = paste0(cluster[!is.na(cluster)], collapse = ',')) %>%
  arrange(possession_number) %>%
  mutate(pairs_list = map(pass_cluster_sequence, create_list_of_couplets))

num_passes_frequency = match_possessions %>%
  group_by(skater_situation, num_passes) %>% 
  summarize(frequency = n()) %>%
  group_by(skater_situation) %>%
  mutate(percentage = frequency/sum(frequency))

ggplot(num_passes_frequency, aes(x = num_passes, y = percentage)) + 
  geom_col(aes(fill = skater_situation), position = 'dodge')

match_possessions %>%
  group_by(skater_situation) %>%
  summarize(mean_passes = mean(num_passes),
            median_passes = median(num_passes))

individual_passes = match_possessions %>%
  unnest(pairs_list) %>%
  separate(col = pairs_list, into = c('pass1', 'pass2'), sep = ',')

individual_passes %>% 
  group_by(pass1, pass2) %>% 
  summarize(count = n())

# Number of possessions with more than two passes
sum(match_possessions$num_passes >= 2)
sum(match_possessions$num_passes >= 3)

mean(match_possessions$num_passes >= 2)

# What we're looking for is passes that are more/less accurate based on the pass that came before
# Shots that are higher quality based on the pass that came before
