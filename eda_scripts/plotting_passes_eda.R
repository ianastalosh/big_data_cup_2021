
source('custom_rink_function.R')

# Passes eda

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
         y_coordinate_2_sym = ifelse(y_coordinate < Y_MAX/2, y_coordinate_2, Y_MAX - y_coordinate_2))

# Where do passes originate:
ggplot(passes, aes(x = x_coordinate, y = y_coordinate)) + 
  geom_point(alpha = 0.2) + 
  custom_rink() + 
  labs(title = 'Origin of Passes')

# Where do passes end?
ggplot(passes, aes(x = x_coordinate_2, y = y_coordinate_2)) + 
  geom_point(alpha = 0.2) + 
  custom_rink() + 
  labs(title = 'Conclusion of Passes')

passes_subset = passes[1:20, ]

ggplot(passes_subset, aes(x = x_coordinate, y = y_coordinate)) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = event),
               arrow = arrow(length = unit(0.2, "cm"))) + 
  facet_wrap(~pass_origin, ncol = 1)

ggplot(passes_subset, aes(x = x_coordinate, y = y_coordinate_sym)) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2_sym, colour = event),
               arrow = arrow(length = unit(0.2, "cm"))) + 
  facet_wrap(~pass_origin, ncol = 1)

ggplot(passes, aes(x = x_coordinate_2, y = y_coordinate_2_sym)) + 
  geom_point(alpha = 0.2)

ggplot(passes, aes(x = x_coordinate_2, y = y_coordinate_2)) + 
  geom_point(alpha = 0.2)

ggplot(passes, aes(x = x_coordinate, y = y_coordinate_sym)) + 
  geom_point(alpha = 0.2) + 
  xlim(c(0,200)) + 
  ylim(c(0,85))

# Passes grouped by advantage
passes %>% 
  group_by(skater_advantage) %>% 
  summarize(count = n())


# Passes that led to shots:
shot_assists = passes %>%
  filter(shot_assist == 1)

ggplot(shot_assists, aes(x = x_coordinate, y = y_coordinate)) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = event),
               arrow = arrow(length = unit(0.2, "cm")), alpha = 0.2)

# Passes that led to one timers
one_timer_assists = shot_assists %>%
  filter(following_detail_4 == TRUE)

ggplot(one_timer_assists, aes(x = x_coordinate, y = y_coordinate)) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = event),
               arrow = arrow(length = unit(0.2, "cm")), alpha = 0.4, size = 1.5)


goal_assists = passes %>%
  filter(goal_assist == 1)

ggplot(goal_assists, aes(x = x_coordinate, y = y_coordinate)) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = event),
               arrow = arrow(length = unit(0.2, "cm"))) + 
  xlim(c(0,200)) + 
  ylim(c(0, 85))


# Every pass plotted
all_passes_grouped_zone = passes %>%
  filter(event == 'Play') %>%
  group_by(x_coordinate, y_coordinate) %>% 
  summarize(num_passes = n(),
            avg_x_loc = mean(x_coordinate_2),
            avg_y_loc = mean(y_coordinate_2))

ggplot(all_passes_grouped_zone, aes(x = x_coordinate, y = y_coordinate)) + 
  geom_segment(aes(xend = avg_x_loc, yend = avg_y_loc, colour = num_passes),
               arrow = arrow(length = unit(0.2, "cm"))) + 
  xlim(c(0,200)) + 
  ylim(c(0, 85)) + 
  scale_colour_gradient(low = '#301934', high = '#FFD700')

# 2x2 groups
twobytwo_groups = passes %>% 
  ungroup() %>% 
  filter(event == 'Play') %>%
  mutate(x_zone = cut(x_coordinate, breaks = seq(0,200,2)),
         y_zone = cut(y_coordinate, breaks = seq(0,85,2))) %>%
  group_by(x_zone, y_zone) %>% 
  summarize(num_passes = n(),
            avg_x = mean(x_coordinate),
            avg_y = mean(y_coordinate),
            avg_x_loc = mean(x_coordinate_2),
            avg_y_loc = mean(y_coordinate_2)) %>%
  mutate(alpha_var = (num_passes - min(num_passes, na.rm = TRUE))/(max(num_passes, na.rm = TRUE) - min(num_passes, na.rm = TRUE)) + 0.1) %>%
  arrange(num_passes)


ggplot(twobytwo_groups, aes(x = avg_x, y = avg_y)) + 
  geom_segment(aes(xend = avg_x_loc, yend = avg_y_loc, colour = num_passes, alpha = alpha_var),
               arrow = arrow(length = unit(0.2, "cm")), size = 0.5) + 
  xlim(c(0,200)) + 
  ylim(c(0, 85)) + 
  scale_colour_gradient2(low = '#03001e', mid = '#ec38bc', high = '#fdeff9', midpoint = 30) + 
  custom_rink()
  #theme(panel.background = element_rect(fill = 'black'))

# First attempt at kmeans
library(factoextra)

passes_kmeans_data = passes %>% 
  mutate(is_wall_pass = ifelse(detail_1 == 'Direct', 0, 1)) %>%
  ungroup() %>%
  select(x_coordinate, y_coordinate_sym, x_coordinate_2, y_coordinate_2_sym, pass_length)

clusters_60 = kmeans(passes_kmeans_data, 60, iter.max = 100)

number_of_clusters = 1:100
result = matrix(0, ncol = 2, nrow = 100, dimnames = list(NULL, c('number', 'wss')))
for (clusters in number_of_clusters) {
  
  kmeans_object = kmeans(passes_kmeans_data, clusters, iter.max = 100)
  result[clusters, 1] = clusters
  result[clusters, 2] = kmeans_object$tot.withinss
  
}

result_df = as.data.frame(result)
ggplot(result_df, aes(x = number, y = wss)) + 
  geom_point() + 
  geom_line() + 
  labs(title = 'Elbow plot for number of clusters', 
       x = 'Number of clusters',
       y = 'Total Within Cluster sum of squares')


clusters_ten = kmeans(passes_kmeans_data, 25, iter.max = 100)

passes_with_clusters = passes %>%
  ungroup() %>%
  mutate(cluster = clusters_ten$cluster)

ggplot(passes_with_clusters, aes(x = x_coordinate, y = y_coordinate_sym)) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2_sym, colour = event),
               arrow = arrow(length = unit(0.2, "cm"))) + 
  facet_wrap(~cluster, ncol = 5)

cluster_centers = clusters_ten$centers %>%
  as.data.frame() %>%
  mutate(number = row_number(),
         size = clusters_ten$size)

ggplot(cluster_centers, aes(x = x_coordinate, y = y_coordinate_sym, label = size)) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2_sym, colour = as.factor(number)),
               size = 1.5, arrow = arrow(length = unit(0.2, "cm"))) + 
  #geom_label(aes(label = size)) + 
  xlim(c(0,200)) + 
  ylim(c(0,85)) #+ 
  #custom_rink()

# pass accuracy
passes_with_clusters %>%
  group_by(cluster) %>% 
  summarize(games = n(), 
            accuracy_percentage = mean(event == 'Play')) %>%
  arrange(desc(accuracy_percentage))

passes_added_cluster = passes %>%
  ungroup() %>%
  mutate(raw_cluster = clusters_ten$cluster,
         cluster = ifelse(y_coordinate == y_coordinate_sym, raw_cluster, raw_cluster + max(raw_cluster)))

ggplot(passes_added_cluster, aes(x = x_coordinate, y = y_coordinate)) + 
  geom_segment(aes(xend = x_coordinate_2, yend = y_coordinate_2, colour = event),
               arrow = arrow(length = unit(0.2, "cm"))) + 
  xlim(c(0,200)) + 
  ylim(c(0,85)) + 
  facet_wrap(~cluster, ncol = 10)

# Pass stats:
pass_summaries = passes_added_cluster %>%
  group_by(cluster) %>% 
  summarize(num_passes = n(),
            pass_accuracy = mean(event == 'Play'),
            shot_assist = mean(shot_assist, na.rm = TRUE))

ggplot(passes_added_cluster %>% filter(cluster == 42), aes(x = x_coordinate, y = y_coordinate)) + 
  geom_point(alpha = 0.2) + 
  geom_point(data = passes_added_cluster %>% filter(cluster == 42), aes(x = x_coordinate_2, y = y_coordinate_2), colour = 'red', alpha = 0.2) + 
  xlim(c(0,200)) + 
  ylim(c(0,85))

ggplot(passes_added_cluster %>% filter(cluster == 47), aes(x = x_coordinate, y = y_coordinate)) + 
  geom_point(alpha = 0.2) + 
  geom_point(data = passes_added_cluster %>% filter(cluster == 47), aes(x = x_coordinate_2, y = y_coordinate_2), colour = 'red', alpha = 0.2) + 
  xlim(c(0,200)) + 
  ylim(c(0,85))

