
# Build simple XG model

# Build features
shot_data = data %>%
  ungroup() %>%
  clean_names() %>%
  filter(event %in% c('Shot', 'Goal')) %>%
  mutate(goal = ifelse(event == 'Goal', 1, 0)) %>%
  select(x_coordinate, y_coordinate, distance_to_goal, angle_deg_to_goal, 
         time_difference, goal) %>%
  mutate(behind_goal = ifelse(x_coordinate > GOAL_LINE_2_X, 1, 0))
  
# Train model
xg_glm = glm(goal ~ ., data = shot_data, family = binomial)

# Plot image for sanity sake
test_data = expand.grid(x_coordinate = 125:200,
                        y_coordinate = 0:85) %>%
  mutate(distance_to_goal = sqrt((x_coordinate - GOAL_LOCATION_X)^2 + (y_coordinate - GOAL_LOCATION_Y)^2),
         gradient = abs(y_coordinate - GOAL_LOCATION_Y)/(x_coordinate - GOAL_LOCATION_X),
         angle_rad = atan(gradient),
         angle_deg_to_goal = (angle_rad * 180/pi),
         angle_deg_to_goal = ifelse(is.na(angle_deg_to_goal), 90, angle_deg_to_goal),
         score_difference = 0,
         skater_situation = 'even_strength',
         time_difference = 2,
         behind_goal = ifelse(x_coordinate > GOAL_LINE_2_X, 1, 0))

predicted = predict(xg_glm, test_data, 'response')

total = cbind(test_data, predicted)
ggplot(total, aes(x = x_coordinate, y = y_coordinate)) + 
  geom_tile(aes(fill = predicted)) + 
  custom_rink(0.003) + 
  xlim(c(125,200)) + 
  scale_fill_gradient2(high = '#0D0887FF', mid = '#CC4678FF', low = '#F0F921FF', midpoint = 0.15)

# Add xg information to total data frame
# Total with clusters added is 'data_cluster_added'
data_shots = data_cluster_added %>% filter(shot_attempt == 1) %>% mutate(behind_goal = ifelse(x_coordinate > GOAL_LINE_2_X, 1, 0))
data_no_shots = data_cluster_added %>% filter(shot_attempt == 0)

shots_xg = predict(xg_glm, data_shots, 'response') %>% as.data.frame() %>% set_names('shot_xg')
data_shots_with_xg = cbind(data_shots, shots_xg)

data_clusters_xg_added = data_no_shots %>% 
  bind_rows(data_shots_with_xg) %>% 
  arrange(event_number) %>%
  group_by(possession_number) %>%
  mutate(following_xg = lead(shot_xg),
         following_two_shot_xg = lead(shot_xg, n = 2),
         following_three_shot_xg = lead(shot_xg, n = 3))
