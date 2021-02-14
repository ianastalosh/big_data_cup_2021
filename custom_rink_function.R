
## GG RINK FUNCTION

library(ggforce)

# TODO write a function to plot the outside of the rink
# Specs 
X_MAX = 200
Y_MAX = 85

GOAL_LINE_1_X = 11
BLUE_LINE_1_X = 11 + 64
CENTRE_X = 100
BLUE_LINE_2_X = 11 + 64 + 50
GOAL_LINE_2_X = 11 + 64 + 50 + 64

CURVE_START_X_1 = 28
CURVE_START_X_2 = X_MAX - 28

circleFun <- function(center = c(0,0),diameter = 1, npoints = 100){
  r = diameter / 2
  tt <- seq(0,2*pi,length.out = npoints)
  xx <- center[1] + r * cos(tt)
  yy <- center[2] + r * sin(tt)
  return(data.frame(x = xx, y = yy))
}

bottom_left = circleFun(center = c(28,28), diameter = 56) %>% filter(x <= 28, y <= 28)
top_left = circleFun(center = c(28,57), diameter = 56) %>% filter(x <= 28, y >= 57)
bottom_right = circleFun(center = c(172,28), diameter = 56) %>% filter(x >= 172, y <= 28)
top_right = circleFun(center = c(172,57), diameter = 56) %>% filter(x >= 172, y >= 57)

sample_data = data.frame(x = runif(1000, min = 0, max = X_MAX),
                         y = runif(1000, min = 0, max = Y_MAX))

ggplot(sample_data, aes(x = x, y = y)) + 
  geom_point(alpha = 0.1) + 
  # Draw zone lines
  geom_segment(x = GOAL_LINE_1_X, y = 5.5, xend = GOAL_LINE_1_X, yend = Y_MAX - 5.5, size = 1, colour = 'red') + 
  geom_segment(x = BLUE_LINE_1_X, y = 0, xend = BLUE_LINE_1_X, yend = Y_MAX, size = 2, colour = 'blue') + 
  geom_segment(x = CENTRE_X, y = 0, xend = CENTRE_X, yend = Y_MAX, size = 2, colour = 'red') + 
  geom_segment(x = BLUE_LINE_2_X, y = 0, xend = BLUE_LINE_2_X, yend = Y_MAX, size = 2, colour = 'blue') + 
  geom_segment(x = GOAL_LINE_2_X, y = 5.5, xend = GOAL_LINE_2_X, yend = Y_MAX - 5.5, size = 1, colour = 'red') +
  # Draw outside of rink
  geom_segment(x = CURVE_START_X_1 -1, y = 0, xend = CURVE_START_X_2 + 1, yend = 0, size = 1) + 
  geom_segment(x = CURVE_START_X_1 -1 , y = Y_MAX, xend = CURVE_START_X_2+1, yend = Y_MAX, size = 1) + 
  geom_line(data = bottom_left, aes(x = x, y = y), size = 1) + 
  geom_line(data = bottom_right, aes(x = x, y = y), size = 1) + 
  geom_line(data = top_left, aes(x = x, y = y), size = 1) + 
  geom_line(data = top_right, aes(x = x, y = y), size = 1) +
  geom_segment(x = 0, xend = 0, y = 27, yend = 58, size = 1) + 
  geom_segment(x = 200, xend = 200, y = 28, yend = 57, size = 1)

# Things to pass to ggplot
custom_rink = function() {
  list(
    theme_minimal(),
    geom_segment(x = GOAL_LINE_1_X, y = 5.5, xend = GOAL_LINE_1_X, yend = Y_MAX - 5.5, size = 1, colour = 'red'), 
    geom_segment(x = BLUE_LINE_1_X, y = 0, xend = BLUE_LINE_1_X, yend = Y_MAX, size = 2, colour = 'blue'),
    geom_segment(x = CENTRE_X, y = 0, xend = CENTRE_X, yend = Y_MAX, size = 2, colour = 'red'),
    geom_segment(x = BLUE_LINE_2_X, y = 0, xend = BLUE_LINE_2_X, yend = Y_MAX, size = 2, colour = 'blue'), 
    geom_segment(x = GOAL_LINE_2_X, y = 5.5, xend = GOAL_LINE_2_X, yend = Y_MAX - 5.5, size = 1, colour = 'red'),
    # Draw outside of rink
    geom_segment(x = CURVE_START_X_1 -1, y = 0, xend = CURVE_START_X_2 + 1, yend = 0, size = 1),
    geom_segment(x = CURVE_START_X_1 -1 , y = Y_MAX, xend = CURVE_START_X_2+1, yend = Y_MAX, size = 1),
    geom_line(data = bottom_left, aes(x = x, y = y), size = 1),
    geom_line(data = bottom_right, aes(x = x, y = y), size = 1), 
    geom_line(data = top_left, aes(x = x, y = y), size = 1),
    geom_line(data = top_right, aes(x = x, y = y), size = 1),
    geom_segment(x = 0, xend = 0, y = 27, yend = 58, size = 1), 
    geom_segment(x = 200, xend = 200, y = 28, yend = 57, size = 1)
  )
}
  