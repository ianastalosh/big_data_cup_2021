
# Packages
library(tidyverse)
library(janitor)
library(lubridate)

# Configs
WOMENS_DATA_STRING = 'data/hackathon_womens.csv'
NWHL_DATA_STRING = 'data/hackathon_nwhl.csv'
X_MAX = 200
Y_MAX = 85

GOAL_LINE_1_X = 11
BLUE_LINE_1_X = 11 + 64
CENTRE_X = 100
BLUE_LINE_2_X = 11 + 64 + 50
GOAL_LINE_2_X = 11 + 64 + 50 + 64

# Import data
data_womens = read_csv(WOMENS_DATA_STRING) 
data_nwhl = read_csv(NWHL_DATA_STRING)
data_raw = bind_rows(data_womens, data_nwhl)

# Extract team names to make codes
team_names = sort(unique(data_raw$`Home Team`)) 
team_codes = 1:length(team_names)
names(team_codes) = team_names

# TODO determine shot assists and goal assists
# Determine which plays occurred on the same 'possessions'

# Feature engineering
data = data_raw %>%
  clean_names() %>%
  mutate(home_team_code = team_codes[home_team],
         away_team_code = team_codes[away_team],
         game_id = paste(home_team_code, away_team_code, game_date, sep = '/'),
         y_coordinate = Y_MAX - y_coordinate,
         y_coordinate_2 = Y_MAX - y_coordinate_2,
         clock_minutes = hour(clock),
         clock_seconds = minute(clock),
         custom_time = ms(paste(clock_minutes, clock_seconds, sep = ':')),
         seconds_remaining = 60 * clock_minutes + clock_seconds,
         home_event = ifelse(team == home_team, 1, 0),
         opponent = ifelse(home_event == 1, away_team, home_team),
         score_difference = ifelse(home_event == 1, home_team_goals - away_team_goals, away_team_goals - home_team_goals),
         situation_skaters = paste(home_team_skaters, away_team_skaters, sep = '-'),
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
         previous_event_player = lag(player),
         previous_event_x = lag(x_coordinate),
         previous_event_y = lag(y_coordinate),
         previous_seconds_remaining = lag(seconds_remaining),
         time_difference = previous_seconds_remaining - seconds_remaining,
         following_event_type = lead(event),
         following_event_team = lead(team),
         following_event_player = lead(player),
         following_event_x = lead(x_coordinate),
         following_event_y = lead(y_coordinate),
         following_detail_1 = lead(detail_1),
         following_detail_2 = lead(detail_2),
         following_detail_3 = lead(detail_3),
         following_detail_4 = lead(detail_4),
         following_seconds_remaining = lead(seconds_remaining),
         time_to_next_event = seconds_remaining - following_seconds_remaining,
         shot_assist = ifelse(following_event_type == 'Shot', 1, 0),
         goal_assist = ifelse(following_event_type == 'Goal', 1, 0))


# Building possession features
#' assume that a possession ends with a shot or takeaway
#' create new feature 'giveaway

# Match results
womens_results = data %>% 
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
