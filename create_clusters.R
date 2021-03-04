
# Script that creates pass clusters and produces plots and tables describing the clusters themselves

# Script configs
NUM_CLUSTERS = 25
KMEANS_ITER_MAX = 100
CLUSTER_DIAGRAM_DIR = 'cluster_images/'
GENERATE_CLUSTER_IMAGES = TRUE

# Creating pass clusters:
passes = data %>%
  filter(event %in% c('Play', 'Incomplete Play')) %>%
  mutate(pass_id = row_number(),
         pass_origin = case_when(x_coordinate < GOAL_LINE_1_X ~ 'behind_defensive_goal',
                                 x_coordinate >= GOAL_LINE_1_X  & x_coordinate < BLUE_LINE_1_X ~ 'defensive_zone',
                                 x_coordinate >= BLUE_LINE_1_X & x_coordinate <= BLUE_LINE_2_X ~ 'neutral_zone',
                                 x_coordinate > BLUE_LINE_2_X & x_coordinate <= GOAL_LINE_2_X ~ 'offensive_zone',
                                 x_coordinate > GOAL_LINE_2_X ~ 'behind_offensive_goal'),
         pass_length = sqrt((x_coordinate - x_coordinate_2)^2 + (y_coordinate - y_coordinate_2)^2),
         dist_x_forward = x_coordinate_2 - x_coordinate,
         dist_y_up = y_coordinate_2 - y_coordinate, 
         pass_gradient = abs(dist_y_up)/abs(dist_x_forward),
         pass_angle_rad = case_when(dist_x_forward > 0 & dist_y_up > 0 ~ atan(pass_gradient),
                                    dist_x_forward < 0 & dist_y_up > 0 ~ pi - atan(pass_gradient),
                                    dist_x_forward < 0 & dist_y_up < 0 ~ pi + atan(pass_gradient),
                                    dist_x_forward > 0 & dist_y_up < 0 ~ 2*pi - atan(pass_gradient),
                                    dist_x_forward == 0 & dist_y_up > 0 ~ pi/2,
                                    dist_x_forward < 0 & dist_y_up == 0 ~ pi,
                                    dist_x_forward == 0 & dist_y_up < 0 ~ 3/2 * pi,
                                    dist_x_forward > 0 & dist_y_up == 0 ~ 0,
                                    dist_x_forward == 0 & dist_y_up == 0 ~ 0),
         pass_angle = 180/pi * pass_angle_rad,
         y_coordinate_sym = ifelse(y_coordinate > Y_MAX/2, y_coordinate, Y_MAX - y_coordinate),
         y_coordinate_2_sym = ifelse(y_coordinate >  Y_MAX/2, y_coordinate_2, Y_MAX - y_coordinate_2),
         dist_y_up_sym = abs(dist_y_up),
         pass_angle_sym = ifelse(y_coordinate < Y_MAX/2, pass_angle, 360 - pass_angle),
         y_end_dist_from_centre = abs(y_coordinate_2 - Y_MAX/2)) %>%
  ungroup()

# Format data to only contain features that will be used in kmeans
# Using symmetrical passes, so all passes as if they were originating at bottom of screen.
passes_kmeans_data = passes %>% 
  mutate(attacking_zone = ifelse(x_coordinate >= BLUE_LINE_2_X, 1, 0)) %>%
  select(x_coordinate, y_coordinate_sym, x_coordinate_2, y_coordinate_2_sym, 
         pass_length, pass_angle_sym, dist_x_forward, dist_y_up_sym, attacking_zone, y_end_dist_from_centre) 

# Perform clustering
pass_clusters = kmeans(passes_kmeans_data, NUM_CLUSTERS, iter.max = KMEANS_ITER_MAX)

cluster_means = pass_clusters$centers %>%
  as.data.frame() %>%
  mutate(original_cluster = row_number()) %>%
  arrange(x_coordinate) %>%
  mutate(new_cluster = row_number())

row_clusters = mapvalues(pass_clusters$cluster, from = cluster_means$original_cluster, to = cluster_means$new_cluster)

# Add these clusters to the passes dataframe
passes_added_cluster = passes %>%
  mutate(cluster = row_clusters,
         side_cluster = ifelse(y_coordinate == y_coordinate_sym, "Left", "Right"),
         total_cluster = paste(cluster, side_cluster, sep = '-'))

cluster_summaries = cluster_summaries_side = passes_added_cluster %>%
  group_by(cluster) %>%
  summarize(passes = n(),
            x_coordinate = mean(x_coordinate),
            y_coordinate = mean(y_coordinate),
            x_coordinate_2 = mean(x_coordinate_2),
            y_coordinate_2 = mean(y_coordinate_2),
            avg_length = mean(sqrt((x_coordinate - x_coordinate_2)^2 + (y_coordinate - y_coordinate_2)^2)),
            accuracy = mean(event == 'Play'),
            shot_assist = mean(shot_assist),
            goal_assist = mean(goal_assist),
            is_last_event_of_possession = mean(is_last_event_of_possession),
            is_wall_pass = mean(detail_1 == 'Indirect')
  )

cluster_summaries_side = passes_added_cluster %>%
  group_by(cluster, side_cluster) %>%
  summarize(passes = n(),
            x_coordinate = mean(x_coordinate),
            y_coordinate = mean(y_coordinate),
            x_coordinate_2 = mean(x_coordinate_2),
            y_coordinate_2 = mean(y_coordinate_2),
            avg_length = mean(sqrt((x_coordinate - x_coordinate_2)^2 + (y_coordinate - y_coordinate_2)^2)),
            accuracy = mean(event == 'Play'),
            shot_assist = mean(shot_assist),
            goal_assist = mean(goal_assist),
            is_last_event_of_possession = mean(is_last_event_of_possession),
            is_wall_pass = mean(detail_1 == 'Indirect')
  )

# Add the cluster information to full data
data_no_passes = data %>%
  filter(event_number %!in% passes_added_cluster$event_number)

data_cluster_added = data_no_passes %>%
  bind_rows(passes_added_cluster) %>%
  arrange(event_number) %>%
  group_by(possession_number) %>%
  mutate(previous_cluster = lag(cluster),
         following_cluster = lead(cluster))

# Create plot showing pairs

ggplot(cluster_summaries_side, aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink(0.002) +
  geom_segment(data = passes_added_cluster, aes(xend = x_coordinate_2, yend = y_coordinate_2),
               arrow = arrow(length = unit(0.2, "cm")), alpha = 0.05, colour = 'gray') + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = passes),
               arrow = arrow(length = unit(0.1, "cm")), size = 1.5) + 
  labs(title = "Pass Clusters in Women's Hockey",
       subtitle = 'The odd numbered cluster has the higher starting y-value. Shadows represent each pass in that cluster.',
       x = '',
       y = '',
       colour = 'Frequency') + 
  facet_wrap(~cluster, ncol = 5) + 
  scale_colour_gradient2(high = '#0D0887FF', mid = '#CC4678FF', low = '#F0F921FF', midpoint = 300)


if (GENERATE_CLUSTER_IMAGES) { 
  
  for (cl in 1:NUM_CLUSTERS) {
    
    plot = ggplot(cluster_summaries_side %>% filter(cluster == cl), aes(x = x_coordinate, y = y_coordinate)) + 
      custom_rink(0.002) +
      geom_segment(data = passes_added_cluster %>% filter(cluster == cl), aes(xend = x_coordinate_2, yend = y_coordinate_2),
                   arrow = arrow(length = unit(0.2, "cm")), alpha = 0.1, colour = 'gray') + 
      geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2),
                   arrow = arrow(length = unit(0.3, "cm")), size = 1.5, colour = 'purple') + 
      labs(title = paste("Cluster", cl),
           x = '',
           y = '')
    
  
    file_path = paste0('cluster_images/cluster_', cl, '.png')
    ggsave(file_path, plot, height = 8, width = 10)
    
  }
  
}

# Plot showing all pass clusters simultaneously
ggplot(passes_added_cluster, aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink(0.003) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2),
               arrow = arrow(length = unit(0.5, "cm")), alpha = 0.01, colour = 'black') +
  labs(title = 'All passes',
       subtitle = 'Team Attacking ----->',
       x = "",
       y = "") + 
  guides(colour = FALSE)

ggplot(cluster_summaries_side, aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink(0.003) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster)),
               arrow = arrow(length = unit(0.5, "cm")), size = 2) +
  labs(title = 'All Pass Clusters',
       subtitle = 'Team Attacking ----->',
       x = "",
       y = "") + 
  guides(colour = FALSE)

clusters_originating_defensive_zone = cluster_summaries %>% filter(x_coordinate <= BLUE_LINE_1_X)
clusters_originating_neutral_zone = cluster_summaries %>% filter(x_coordinate > BLUE_LINE_1_X & x_coordinate <= BLUE_LINE_2_X)
clusters_originating_offensive_zone = cluster_summaries %>% filter(x_coordinate > BLUE_LINE_2_X)


# Pass clusters with frequency
# ggplot(cluster_summaries_side, aes(x = x_coordinate, y = y_coordinate)) + 
#   custom_rink(0.003) + 
#   geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = passes),
#                arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
#   labs(title = 'All Pass Clusters, weighted by Frequency',
#        subtitle = 'Team Attacking Right Goal',
#        x = "",
#        y = "") + 
#   guides(colour = FALSE)
# 
# ggplot(cluster_summaries_side, aes(x = x_coordinate, y = y_coordinate)) + 
#   custom_rink(0.003) + 
#   geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = passes, alpha = passes),
#                arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
#   labs(title = 'All Pass Clusters, weighted by Frequency',
#        subtitle = 'Team Attacking Right Goal',
#        x = "",
#        y = "") + 
#   scale_colour_gradient2(low = '#ffaf7b', mid = '#d76d77', high = '#3a1c71', midpoint = 500)
# 
# # Pass clusters with accuracy
# ggplot(cluster_summaries, aes(x = x_coordinate, y = y_coordinate)) + 
#   custom_rink(0.003) + 
#   geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = accuracy),
#                arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
#   labs(title = 'All Pass Clusters, weighted by Accuracy',
#        subtitle = 'Team Attacking Right Goal',
#        x = "",
#        y = "") + 
#   guides(colour = FALSE)
# 
#   # Pass clusters that are shot assists
# ggplot(cluster_summaries_side, aes(x = x_coordinate, y = y_coordinate)) + 
#   custom_rink(0.003) + 
#   geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = shot_assist),
#                arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
#   labs(title = 'All Pass Clusters, weighted by Shot Assists',
#        subtitle = 'Team Attacking Right Goal',
#        x = "",
#        y = "") + 
#   guides(colour = FALSE)
# 
# # Pass clusters that are goal assists
# ggplot(cluster_summaries_side, aes(x = x_coordinate, y = y_coordinate)) + 
#   custom_rink(0.003) + 
#   geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = goal_assist),
#                arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
#   labs(title = 'All Pass Clusters, weighted by Goal Assists',
#        subtitle = 'Team Attacking Right Goal',
#        x = "",
#        y = "") + 
#   guides(colour = FALSE)
# 
# # Pass clusters that are the last pass in the possession (either because they are incomplete or lead to turnovers)
# ggplot(cluster_summaries_side, aes(x = x_coordinate, y = y_coordinate)) + 
#   custom_rink(0.003) + 
#   geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = is_last_event_of_possession),
#                arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
#   labs(title = 'All Pass Clusters, weighted by Is Last Event of Possession',
#        subtitle = 'Team Attacking Right Goal',
#        x = "",
#        y = "") + 
#   guides(colour = FALSE)

# Observations:
#' horizontal and backwards passes appear to be high accuracy
#' passese in defensive third much more frequent than attacking
