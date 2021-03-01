
## GG RINK FUNCTION
HEX_BLUE = '#dbdbff'
HEX_RED = '#ffdbdb'
# Add function to generate circle dataframe to add to ggplot
# Credit: https://stackoverflow.com/questions/6862742/draw-a-circle-with-ggplot2.
circleFun <- function(center = c(0,0),diameter = 1, npoints = 100){
  r = diameter / 2
  tt <- seq(0,2*pi,length.out = npoints)
  xx <- center[1] + r * cos(tt)
  yy <- center[2] + r * sin(tt)
  return(data.frame(x = xx, y = yy))
}

# Generate quarter circles to use at the corners of the rink
bottom_left = circleFun(center = c(28,28), diameter = 56) %>% filter(x <= 28, y <= 28)
top_left = circleFun(center = c(28,57), diameter = 56) %>% filter(x <= 28, y >= 57)
bottom_right = circleFun(center = c(172,28), diameter = 56) %>% filter(x >= 172, y <= 28)
top_right = circleFun(center = c(172,57), diameter = 56) %>% filter(x >= 172, y >= 57)

# Write rink function to use as border for other plots:
custom_rink = function(line_opacity = NULL) {
  list(
    theme_minimal(),
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(), 
          axis.text.x = element_blank(), 
          axis.text.y = element_blank(),
          plot.title = element_text(hjust = 0.5),
          plot.subtitle = element_text(hjust = 0.5)),
    # Draw zone lines
    geom_segment(x = GOAL_LINE_1_X, y = 5.5, xend = GOAL_LINE_1_X, yend = Y_MAX - 5.5, size = 1, colour = HEX_RED), 
    geom_segment(x = BLUE_LINE_1_X, y = 0, xend = BLUE_LINE_1_X, yend = Y_MAX, size = 2, colour = HEX_BLUE),
    geom_segment(x = CENTRE_X, y = 0, xend = CENTRE_X, yend = Y_MAX, size = 2, colour = HEX_RED),
    geom_segment(x = BLUE_LINE_2_X, y = 0, xend = BLUE_LINE_2_X, yend = Y_MAX, size = 2, colour = HEX_BLUE), 
    geom_segment(x = GOAL_LINE_2_X, y = 5.5, xend = GOAL_LINE_2_X, yend = Y_MAX - 5.5, size = 1, colour = HEX_RED),
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
  