
# EDA intoo possession stats and dataviz
events_per_possession = data_test %>%
  group_by(game_id, period, possession_number) %>%
  summarize(num_events = n(),
            num_passes = sum(event == 'Play') + sum(event == 'Incomplete Play'))

possessions_per_period = data_test %>%
  group_by(game_id, period) %>% 
  summarize(possessions_per_period = max(possession_number))

ggplot(possessions_per_period, aes(x = possessions_per_period)) + geom_density()
ggplot(possessions_per_period, aes(x = possessions_per_period)) + geom_histogram()

ggplot(possessions_per_period, aes(x = possessions_per_period, group = period)) + geom_density(aes(fill = as.factor(period)), alpha = 0.3)
