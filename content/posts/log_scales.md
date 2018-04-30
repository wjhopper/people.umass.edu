Title: How log scales work in ggplot
Tags: ggplot, R, visualization, logarithms
Slug: log_scales_ggplot
Status: published
Authors: Will Hopper
Summary: Log scaled axis in figures can be a good way to represent information that spans a very large range of the scale. However, the axis themselves aren't very easy to interpret. To make matters worse, the two methods for automatically producing log scaled axis with `ggplot` produce *very* different looking figures. This post tries to clarify what differs between these two methods, and hopefully bring some clarity to your figure's axis.

On a log scaled axis, a change of one unit along the axis reflects a change of one order of magnitude of the variable. For example, if an axis is plotted in log base 10 scale, a change of one unit along the axis represents a 10-fold increase on the variable. This can be a good way to represent information that spans a very large range of a scale (e.g., some observations near 0, and others near 10,000).

For easier interpretation of the plot in terms of the variable, a log scaled axis is typically labelled in the units of the variable, not the log units. However, this makes it really hard to understand log scales themselves. But, *c'est la vie*, you’re supposed to understand that when you see a log scaled axis that "the units of this axis are *really* just powers you raise the base to, but it's not labeled that way, so just remember that moving through this axis produces exponential changes in your variable. OK?" ![shrug]({filename}/img/shrug.png).

But with `ggplot`, things get even more confusing because there are two ways to make a log-scaled axis. You can use a scale transformation (e.g., using `scale_x_continuous(trans='log2')`), or a coordinate transformation (e.g., using `coord_trans(x="log2")`. Having two ways to do things wouldn't be a bad thing, if the final product didn’t look so damn different between then two of them.

To see what I mean, let's examine the output of these two methods by plotting some data. We'll use the speed and stopping distance measurements in the built-in `cars` dataset. First, we'll plot the data using the linear scale on both axis.

```R
p1 <- ggplot(cars, aes(x = speed, y = dist)) + geom_point() +
  ggtitle("Linear axis scales")
print(p1)
```
![shrug]({filename}/img/logscale_linear.png).

So far, so good - a pretty linear relationship between stopping distance and speed. Now, lets plot it with a log<sub>2</sub> scaled x axis (the car's speed), using a scale transformation.

```R
p1 + scale_x_continuous(trans='log2') +
  ggtitle("Log axis, scale transform")
```
![scale_trans]({filename}/img/logscale_scaletrans.png).

Now the relationship between speed and stopping distance looks a bit curvilinear, and the lablel on the x axis aren't evenly spaced in the linear scale. The distance between the first two tick marks represents the change from 4 to 8, but that same distance between the second and third tick marks represents the change from from 8 to 16 - a change two times as large!

Now for the second way of log<sub>2</sub> scaling the x axis - with a coordinate transformation.
```R
p1 + coord_trans(x='log10') +
  ggtitle("Log axis, coord. transform")
```
![coord_trans]({filename}/img/logscale_coordtrans.png).

This is very different! Instead of having ticks at 4, 8 and 16, we have ticks at 5, 10, 15, 20, 25 (just like the first linear scale plot), and they aren't spaced evenly. Instead, they converge - larger values are closer together than smaller values.

Lets put all 3 plots side by side and compare:
![all three]({filename}/img/logscale_all3.png).

We can see that in the last two plots, the points in each plot exactly line up each with other - we could overlay the two plots, and not be able tell the difference. So, the scaling worked, and we definitely got a log<sub>2</sub> scale in both. But the axis ticks, labels, and grid marks are wildly different. Why?

In classic R help page fashion, the help page for `coord_trans` explains the difference precisely, but incomprehensibly. It says:
> "`coord_trans` is different to scale transformations in that it occurs after statistical transformation and will affect the visual appearance of geoms - there is no guarantee that straight lines will continue to be straight."

Um, OK? Do you get it? If not, keep reading.

What happens in practice is that when using scale transformation method (i.e., using `scale_x_continuous(trans='log2')`), ggplot transforms the axis and data into log scale *before* figuring out where the tick marks go on the axis and what the tick labels should be. In `cood_trans` case, ggplot figures out where the ticks marks go on the axis first (still on the linear scale!), figures out what the labels should be, and *then* transforms observations into the log scale. But, it doesn’t recalculate the tick positions or the label values. It just moves their positions into log scale, along with the rest of the data. That’s why 20 and 25 are so much closer together than 5 and 10 when using `coord_trans` – because 5 and 10 are further apart on the log scale than 20 and 25 (log<sub>2</sub>10 - log<sub>2</sub>5 = 1, while log<sub>2</sub>25 - log<sub>2</sub>20 = 0.321].

So in essence, this big visual difference boils down to an order of operations - do you transform the data before, or after, creating the axis ticks and labels. I love ggplot2, but I don't get how I'm supposed to understand why the two methods of log scaling produce visually different results from the documentation. Unless you've read the grammar of graphics, how are you supposed to know that determining axis tick positions (and thus, labels for a continuous variable) are related to "statistical transformations", or that a log scaled axis is a "statistical transformation". I didn't calculate statistics at all!

Oh well. I still don't fully understand the fundamental difference between a scale transformation and a coordinate transformation. But, I do understand the essence of why the produce different visual results in the case of the log scale transformation. I suppose I should go get working on a PR for the `coord_trans` documentation...
