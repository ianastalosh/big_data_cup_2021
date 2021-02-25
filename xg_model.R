
# Build simple XG model

GOAL_LOCATION_X = 189
GOAL_LOCATION_Y = 85/2

# Build features
shot_data = data %>%
  ungroup() %>%
  filter(event %in% c('Shot', 'Goal')) %>%
  mutate(goal = ifelse(event == 'Goal', 1, 0)) %>%
  select(x_coordinate, y_coordinate, distance_to_goal, angle_deg_to_goal, 
         home_event, score_difference, skater_situation, time_difference, goal)
  
# Train model
xg_glm = glm(goal ~ ., data = shot_data, family = binomial)

# Plot image for sanity sake
test_data = expand.grid(x_coordinate = 125:200,
                        y_coordinate = 0:85) %>%
  mutate(distance_to_goal = sqrt((x_coordinate - GOAL_LOCATION_X)^2 + (y_coordinate - GOAL_LOCATION_Y)^2),
         gradient = abs(y_coordinate - GOAL_LOCATION_Y)/(x_coordinate - GOAL_LOCATION_X),
         angle_rad = atan(gradient),
         angle_deg_to_goal = (angle_rad * 180/pi),
         home_event = 1,
         score_difference = 0,
         skater_situation = 'even_strength',
         time_difference = 2)

predicted = predict(xg_glm, test_data, 'response')

total = cbind(test_data, predicted)
ggplot(total, aes(x = x_coordinate, y = y_coordinate)) + 
  geom_tile(aes(fill = predicted)) + 
  custom_rink() + xlim(c(125,200))
