
# Script that creates pass clusters and produces plots and tables describing the clusters themselves

# Script configs
NUM_CLUSTERS = 25
KMEANS_ITER_MAX = 100
CLUSTER_DIAGRAM_DIR = 'cluster_images/'

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
         pass_gradient = (y_coordinate_2 - y_coordinate) / (x_coordinate_2 - x_coordinate),
         pass_angle = atan(pass_gradient) * 180 / pi,
         y_coordinate_sym = ifelse(y_coordinate < Y_MAX/2, y_coordinate, Y_MAX - y_coordinate),
         y_coordinate_2_sym = ifelse(y_coordinate < Y_MAX/2, y_coordinate_2, Y_MAX - y_coordinate_2)) %>%
  ungroup()

# Format data to only contain features that will be used in kmeans
# Using symmetrical passes, so all passes as if they were originating at bottom of screen.
passes_kmeans_data = passes %>% 
  select(x_coordinate, y_coordinate_sym, x_coordinate_2, y_coordinate_2_sym, pass_length)

# Perform clustering
pass_clusters = kmeans(passes_kmeans_data, NUM_CLUSTERS, iter.max = KMEANS_ITER_MAX)

cluster_means = pass_clusters$centers %>%
  as.data.frame() %>%
  mutate(original_cluster = row_number()) %>%
  arrange(x_coordinate) %>%
  mutate(new_cluster = row_number() * 2 - 1)

row_clusters = mapvalues(pass_clusters$cluster, from = cluster_means$original_cluster, to = cluster_means$new_cluster)

# Add these clusters to the passes dataframe
passes_added_cluster = passes %>%
  mutate(raw_cluster = row_clusters,
         cluster = ifelse(y_coordinate == y_coordinate_sym, raw_cluster, raw_cluster + 1))

cluster_summaries = passes_added_cluster %>%
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

# Add the cluster information to full data
data_no_passes = data %>%
  filter(event_number %!in% passes_added_cluster$event_number)

data_cluster_added = data_no_passes %>%
  bind_rows(passes_added_cluster)

# Plot showing clusters
ggplot(passes_added_cluster %>% filter(cluster %% 2 == 1), aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = event),
               arrow = arrow(length = unit(0.2, "cm"))) + 
  facet_wrap(~cluster, ncol = 5) + 
  labs(title = 'Pass Clusters',
       subtitle = 'Pass Clusters originating in bottom half of ice only, remaining are symmetrical',
       x = "",
       y = "")

ggplot(passes_added_cluster %>% filter(cluster %% 2 == 0), aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = event),
               arrow = arrow(length = unit(0.2, "cm"))) + 
  facet_wrap(~cluster, ncol = 5) + 
  labs(title = 'Pass Clusters',
       subtitle = 'Pass Clusters originating in top half of ice only, remaining are symmetrical',
       x = "",
       y = "")


# Plot showing centres only
ggplot(cluster_summaries %>% filter(cluster %% 2 == 1), aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster)),
               arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
  facet_wrap(~cluster, ncol = 5) + 
  labs(title = 'Pass Clusters Centres',
       subtitle = 'Pass Clusters originating in bottom half of ice only, remaining are symmetrical',
       x = "",
       y = "") + 
  guides(colour = FALSE)

ggplot(cluster_summaries %>% filter(cluster %% 2 == 0), aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster)),
               arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
  facet_wrap(~cluster, ncol = 5) + 
  labs(title = 'Pass Clusters Centres',
       subtitle = 'Pass Clusters originating in top half of ice only, remaining are symmetrical',
       x = "",
       y = "") + 
  guides(colour = FALSE)

# Save images containing only a specific cluster mean
# TODO rewrite this using walk
for (cl in 1:(NUM_CLUSTERS*2)) {
  
  plot = ggplot(cluster_summaries %>% filter(cluster == cl), aes(x = x_coordinate, y = y_coordinate)) + 
    custom_rink() + 
    geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2),
                 arrow = arrow(length = unit(0.8, "cm")), size = 6) + 
    theme(axis.title.x = element_blank(),
          axis.title.y = element_blank())

  title = paste0(CLUSTER_DIAGRAM_DIR, 'cluster_', cl, '.png')
  ggsave(title, plot, height = 8, width = 10)
  
}

# Plot showing all pass clusters simultaneously
ggplot(cluster_summaries, aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster)),
               arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
  labs(title = 'All Pass Clusters',
       subtitle = 'Team Attacking Right Goal',
       x = "",
       y = "") + 
  guides(colour = FALSE)

# Pass clusters with frequency
ggplot(cluster_summaries, aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = passes),
               arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
  labs(title = 'All Pass Clusters, weighted by Frequency',
       subtitle = 'Team Attacking Right Goal',
       x = "",
       y = "") + 
  guides(colour = FALSE)

# Pass clusters with accuracy
ggplot(cluster_summaries, aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = accuracy),
               arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
  labs(title = 'All Pass Clusters, weighted by Accuracy',
       subtitle = 'Team Attacking Right Goal',
       x = "",
       y = "") + 
  guides(colour = FALSE)

# Pass clusters that are shot assists
ggplot(cluster_summaries, aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = shot_assist),
               arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
  labs(title = 'All Pass Clusters, weighted by Shot Assists',
       subtitle = 'Team Attacking Right Goal',
       x = "",
       y = "") + 
  guides(colour = FALSE)

# Pass clusters that are goal assists
ggplot(cluster_summaries, aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = goal_assist),
               arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
  labs(title = 'All Pass Clusters, weighted by Goal Assists',
       subtitle = 'Team Attacking Right Goal',
       x = "",
       y = "") + 
  guides(colour = FALSE)

# Pass clusters that are the last pass in the possession (either because they are incomplete or lead to turnovers)
ggplot(cluster_summaries, aes(x = x_coordinate, y = y_coordinate)) + 
  custom_rink() + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = as.factor(cluster), alpha = is_last_event_of_possession),
               arrow = arrow(length = unit(0.5, "cm")), size = 2) + 
  labs(title = 'All Pass Clusters, weighted by Is Last Event of Possession',
       subtitle = 'Team Attacking Right Goal',
       x = "",
       y = "") + 
  guides(colour = FALSE)

# Observations:
#' horizontal and backwards passes appear to be high accuracy
#' passese in defensive third much more frequent than attacking

# Exploring pass accuracy
ggplot(cluster_summaries, aes(x = pas))