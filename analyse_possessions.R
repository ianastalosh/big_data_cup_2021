
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

match_possessions = data_clusters_xg_added %>%
  group_by(game_date, game_id, period, skater_situation, score_situation, possession_number) %>% 
  summarize(starting_time = max(seconds_remaining),
            ending_time = min(seconds_remaining),
            duration = starting_time - ending_time,
            first_event = first(event),
            last_event = last(event),
            first_x = first(x_coordinate),
            first_y = first(y_coordinate),
            started_in_offensive_zone = ifelse(x_coordinate > BLUE_LINE_2_X, 1, 0),
            final_x = last(x_coordinate),
            final_y = last(y_coordinate),
            zone_entry = sum(event %in% c('Zone Entry')),
            zone_entry_type = ifelse(zone_entry == 1, detail_1[event == 'Zone Entry'], NA),
            zone_entry_y = ifelse(zone_entry == 1, y_coordinate[event == 'Zone Entry'], NA),
            zone_entry_time = ifelse(zone_entry == 1, seconds_remaining[event == 'Zone Entry'], NA),
            zone_entry_time_to_end = zone_entry_time - ending_time,
            num_events = n(),
            num_passes = sum(event %in% c('Play', 'Incomplete Play')),
            num_shots = sum(event %in% c('Shot', 'Goal')),
            num_dumps = sum(event == 'Dump In/Out'),
            num_goals = sum(event == 'Goal'),
            num_passes_def = sum(cluster %in% clusters_originating_defensive_zone$cluster),
            num_passes_neutral = sum(cluster %in% clusters_originating_neutral_zone$cluster),
            num_passes_off = sum(cluster %in% clusters_originating_offensive_zone$cluster),
            shot_on_possession = ifelse(num_shots > 0, 1, 0),
            goal_on_possession = ifelse(num_goals > 0, 1, 0),
            shot_location_x = ifelse(num_shots > 0, max(x_coordinate, na.rm = TRUE), NA),
            shot_location_y = ifelse(num_shots > 0, max(y_coordinate, na.rm = TRUE), NA),
            shot_xg = ifelse(num_shots > 0, max(shot_xg, na.rm = TRUE), NA),
            pass_cluster_sequence = paste0(cluster[!is.na(cluster)], collapse = ',')) %>%
  arrange(possession_number) %>%
  mutate(pairs_list = map(pass_cluster_sequence, create_list_of_couplets)) %>%
  ungroup()


# What is the average starting point of possessions?
coord_plot = data_cluster_xg_added %>%
  group_by(possession_number) %>%
  mutate(is_start = ifelse(row_number() == 1, 1, 0)) %>%
  select(is_start, x_coordinate, y_coordinate)

gam_model = mgcv::gam(data = coord_plot, is_start ~ te(x_coordinate, y_coordinate), method = "REML", family = 'binomial')
plot(gam_model, scheme=2)

# How many passes are attempted per possession?
passes_per_possession = match_possessions %>%
  count(num_passes)

ggplot(match_possessions, aes(x = num_passes)) + 
  geom_histogram(binwidth = 0.5) + 
  labs(title = 'Number of Passes per Possession')

# How many possessions culminate in a shot?
outcome_shot = match_possessions %>%
  count(shot_on_possession)

# How many passes are on possessions that get a shot
pass_count = match_possessions %>%
  group_by(shot_on_possession, num_passes) %>%
  summarize(count = n()) %>%
  group_by(shot_on_possession) %>%
  mutate(perc = count/sum(count))

mean_passes = match_possessions %>%
  group_by(shot_on_possession) %>% 
  summarize(n = n(),
            mean_passes = mean(num_passes),
            median_passes = median(num_passes),
            sd_passes = sd(num_passes))

ggplot(match_possessions, aes(x = num_passes, y = ..prop..)) + 
  geom_bar(aes(fill = as.factor(shot_on_possession)), position = 'dodge') + 
  theme_minimal() + 
  labs(title = 'Number of Passes on Possession',
       subtitle = 'Shot on Possession or no shot')

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
