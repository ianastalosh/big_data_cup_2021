
# Packages
library(plyr) # mapvalues, to use the cluster number
library(tidyverse) # duh
library(janitor) # clean variable names to snakecase
library(lubridate) # date time formatting
library(zoo) # Mainly for na.locf and creating rolling functions
library(factoextra) # kmeans

# Load scripts
source('configs.R')
source('utils.R')
source('custom_rink_function.R')

# Define the events which signal the end of a possession
POSSESSION_ENDING_EVENTS = c('Shot', 'Goal', 'Incomplete Play', 'Penalty Taken', 'Dump In/Out')
POSSESSION_STARTING_EVENTS = c('Takeaway', 'Faceoff Win') # also dump outs that are lost

# Import data
data_womens = read_csv(WOMENS_DATA_STRING) 
data_nwhl = read_csv(NWHL_DATA_STRING)
data_raw = bind_rows(data_womens, data_nwhl)

# Extract team names to make codes
team_names = sort(unique(data_raw$`Home Team`)) 
team_codes = 1:length(team_names)
names(team_codes) = team_names

# Engineer features that may be useful
data = data_raw %>%
  clean_names() %>%
  mutate(event_number = row_number(),
         home_team_code = team_codes[home_team],
         away_team_code = team_codes[away_team],
         game_id = paste(home_team_code, away_team_code, game_date, sep = '/'),
         y_coordinate = Y_MAX - y_coordinate,
         y_coordinate_2 = Y_MAX - y_coordinate_2,
         x_diff_to_goal = GOAL_LOCATION_X - x_coordinate,
         y_diff_to_goal = GOAL_LOCATION_Y - y_coordinate,
         distance_to_goal = sqrt(x_diff_to_goal^2 + y_diff_to_goal^2),
         gradient_to_goal = abs(y_diff_to_goal)/x_diff_to_goal,
         angle_rad_to_goal = atan(gradient_to_goal),
         angle_deg_to_goal = (angle_rad_to_goal * 180/pi),
         clock_minutes = hour(clock),
         clock_seconds = minute(clock),
         custom_time = ms(paste(clock_minutes, clock_seconds, sep = ':')),
         seconds_remaining = 60 * clock_minutes + clock_seconds,
         home_event = ifelse(team == home_team, 1, 0),
         opponent = ifelse(home_event == 1, away_team, home_team),
         score_difference = ifelse(home_event == 1, home_team_goals - away_team_goals, away_team_goals - home_team_goals),
         score_situation = case_when(score_difference > 0 ~ 'winning',
                                     score_difference == 0 ~ 'tie',
                                     score_difference < 0 ~ 'losing'),
         situation_skaters = paste(home_team_skaters, away_team_skaters, sep = '-'),
         woman_advantage = ifelse(home_event == 1, home_team_skaters - away_team_skaters, away_team_skaters - home_team_skaters),
         skater_situation = case_when(woman_advantage > 0 ~ 'powerplay',
                                      woman_advantage == 0 ~ 'even_strength',
                                      woman_advantage < 0 ~ 'shorthanded'),
         home_pulled_goalie = ifelse(home_team_skaters == 6, 1, 0),
         away_pulled_goalie = ifelse(away_team_skaters == 6, 1, 0),
         team_pulled_goalie = case_when(home_pulled_goalie == 0 ~ 0,
                                        away_pulled_goalie == 0 ~ 0,
                                        home_event == 1 & home_pulled_goalie == 1 ~ 1,
                                        home_event == 0 & away_pulled_goalie == 1 ~ 1),
         opponent_pulled_goalie = case_when(home_pulled_goalie == 0 ~ 0,
                                            away_pulled_goalie == 0 ~ 0,
                                            home_event == 1 & away_pulled_goalie == 1 ~ 1,
                                            home_event == 0 & home_pulled_goalie == 1 ~ 1),
         skater_advantage = ifelse(home_event, home_team_skaters - away_team_skaters, away_team_skaters - home_team_skaters)) %>%
  group_by(game_id, period) %>%
  mutate(previous_event_type = lag(event),
         previous_event_team = lag(team),
         possession_changed = ifelse(previous_event_team != team, 1, 0),
         previous_event_player = lag(player),
         previous_event_x = lag(x_coordinate),
         previous_event_y = lag(y_coordinate),
         previous_seconds_remaining = lag(seconds_remaining),
         time_difference = previous_seconds_remaining - seconds_remaining,
         following_event_type = lead(event),
         following_event_type = ifelse(is.na(following_event_type), "end_of_period", following_event_type),
         following_event_team = lead(team),
         possession_changes_after = ifelse(team != following_event_team, 1, 0),
         following_event_player = lead(player),
         following_event_x = lead(x_coordinate),
         following_event_y = lead(y_coordinate),
         following_detail_1 = lead(detail_1),
         following_detail_2 = lead(detail_2),
         following_detail_3 = lead(detail_3),
         following_detail_4 = lead(detail_4),
         following_seconds_remaining = lead(seconds_remaining),
         time_to_next_event = seconds_remaining - following_seconds_remaining,
         shot_assist = ifelse(following_event_type %in% c('Shot', 'Goal'), 1, 0),
         goal_assist = ifelse(following_event_type == 'Goal', 1, 0)) %>%
  # Add features indicating which events occurred on the same possession
  group_by(game_id, period) %>%
  mutate(is_first_event_of_possession = case_when(possession_changed == 1 ~ 1,
                                                  event %in% POSSESSION_STARTING_EVENTS ~ 1,
                                                  previous_event_type %in% c('Shot', 'Goal') ~ 1,
                                                  row_number() == 1 ~ 1,
                                                  TRUE ~ 0)) %>%
  ungroup(game_id, period) %>% 
  mutate(event_possession_number = cumsum(coalesce(is_first_event_of_possession, 0)) + is_first_event_of_possession*0,
         possession_number = na.locf(event_possession_number, na.rm = FALSE, fromLast = TRUE),
         is_first_event_of_possession = ifelse(is.na(is_first_event_of_possession), 0, is_first_event_of_possession)) %>%
  group_by(game_id, period, possession_number) %>% 
  mutate(is_last_event_of_possession = ifelse(row_number() == n(), 1, 0))
         
# Create data frame that contains the match listing and final scores for ease of lookup if needed
# Also include how many goals were scored by each team on powerplay/shorthand
womens_match_results = data %>% 
  group_by(game_id, game_date, home_team, away_team) %>%
  summarize(home_score = max(home_team_goals),
            away_score = max(away_team_goals),
            home_goals_minus2 = sum(event == 'Goal' & home_event == 1 & skater_advantage == -2),
            home_goals_minus1 = sum(event == 'Goal' & home_event == 1 & skater_advantage == -1),
            home_goals_0 = sum(event == 'Goal' & home_event == 1 & skater_advantage == 0),
            home_goals_plus1 = sum(event == 'Goal' & home_event == 1 & skater_advantage == 1),
            home_goals_plus2 = sum(event == 'Goal' & home_event == 1 & skater_advantage == 2),
            away_goals_minus2 = sum(event == 'Goal' & home_event == 0 & skater_advantage == -2),
            away_goals_minus1 = sum(event == 'Goal' & home_event == 0 & skater_advantage == -1),
            away_goals_0 = sum(event == 'Goal' & home_event == 0 & skater_advantage == 0),
            away_goals_plus1 = sum(event == 'Goal' & home_event == 0 & skater_advantage == 1),
            away_goals_plus2 = sum(event == 'Goal' & home_event == 0 & skater_advantage == 2))

