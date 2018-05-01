theme_set(theme_grey(base_size = 16) + 
            theme(plot.title = element_text(size = 16, face = "bold")))

p1 <- ggplot(cars, aes(x = speed, y = dist)) + geom_point() +
  ggtitle("Linear axis scales")

p2 <- p1  + 
  scale_x_continuous(trans = 'log2') + 
  ggtitle("Log axis, scale transform")

p3 <- p1  + 
  coord_trans(x='log10') +
  ggtitle("Log axis, coord. transform")

theme_set(theme_grey(base_size = 10) + 
            theme(plot.title = element_text(size = 8, face = "bold")))
p4 <- grid.arrange(p1, p2, p3, ncol=3)

ggsave("logscale_linear.png", p1, device = 'png',
       width = 350/96, height = 350/96,
       path = 'source/people.umass.edu/content/img/', dpi=96)
ggsave("logscale_scaletrans.png", p2, device = 'png',
       width = 350/96, height = 350/96,
       path = 'source/people.umass.edu/content/img/', dpi=96)
ggsave("logscale_coordtrans.png", p3, device = 'png',
       width = 350/96, height = 350/96,
       path = 'source/people.umass.edu/content/img/', dpi=96)
ggsave("logscale_all3.png", p4, device = 'png',
       width = 700/96, height = 300/96,
       path = 'source/people.umass.edu/content/img/', dpi=96)
