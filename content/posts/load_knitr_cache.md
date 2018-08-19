Title: Loading an Rmarkdown cache
Tags: R, Rmarkdown, knitr
Slug: load_rmd_cache
Status: published
Authors: Will Hopper
Summary: How to load the knitr cache of an Rmarkdown documents

I am a huge fan of [Rmarkdown](https://rmarkdown.rstudio.com/) documents - it's safe to say it's changed how I do research forever. But upgrading to Rmarkdown comes with some important changes, one being that Rmarkdown documents aren't run "interactively". If you use the "Knit" button in RStudio, then your document is created using a completely new R session than the one behind your console window. So, the context your Rmarkdown code runs in is completely separate from the environment and context of the interactive R session you have open in Rstudio.

One *good* thing about this is reproducibility - your document won't produce different results depending on the contents of your current R session. But, this separation also limits how you can work with your code and its outputs. If you have an error, you can't easily inspect the objects involved in the error. For example, if your index into a vector, like `x[100]`, produces an `NA` that you didn't expect, you can't quickly check whether your index was out of bounds, or if there were just missing values stored in your vector for some reason. Having the code's execution context vanish can reduce debugging to a slow, trial and error process.

Another thing you can't do is a quick, interactive exploration of the objects you create, or test out new code for your document. Imagine you just used `lm()` to do a linear regression, but you accidentally printed the `lm` object instead of the summarized `lm` object (which actually shows the inferential tests, R<sup>2</sup>, etc.). If your regression was done in an Rmarkdown document, you'd have to add the `summary(...)` call to the relevant code chunk, and re-run the whole thing! If you had done it in the console, or `source`-d a `.R` file, you could just execute the `summary(...)` in the console, and have your answer. Of course, RStudio allows you to run chunks interactively, but this also means you have to run code twice - once to knit it, and once again in your interactive R session.

## Introducing: The knitr cache!
But despair not - there's a way to have your Rmarkdown cake and eat it too! The Rmarkdown "backend" is the [knitr package](https://yihui.name/knitr/), which has the ability to store the computations you perform in R code chunks. Then, `knitr` can automatically re-use the results from knitting the document previously, saving you computation time in the future. The [knitr cache](https://yihui.name/knitr/demo/cache/) has some advanced features that give you fairly fine grain control over what gets cached, and when the cache gets invalidated. But, we'll be completely ignoring the advanced features here, and focusing on the simple situation where you cache all the code chunks in a document.

But first, what does caching have to do with the problems (or inconveniences, perhaps) stemming from non-interactive code execution I mentioned earlier? By loading the objects saved in the cache yourself, you get the best of both worlds! You get all the nice reporting facilities afforded by dynamic Rmarkdown documents, but can still quickly load up the objects you created to debug errors, or to interactively explore and write code to extend your existing report.

To give a concrete example, let's imagine we want to study how accurately bivariate regression can recover the true data-generating parameters. To do so, we'll simulate 10,000 different data sets, fit a linear regression to each one, and compute the estimation error in each regression. We're writing up our report in an Rmarkdown file called `Model_Report.Rmd` with the following contents:

<pre>
    ```{r setup, include=FALSE}`
    knitr::opts_chunk$set(echo = TRUE, cache = TRUE)
    set.seed(1234)
    reps <- 10000
    ```

    "True" intercept is 5, "True" slope is 3

    ```{r regression}
    estimates <- replicate(reps, c(NA,NA), simplify = FALSE)
    for (i in 1:reps) {
      x <- rnorm(100, 10, 2.5)
      y <- 5 + 3*x + rnorm(100, 0, 3)
      estimates[[i]] <- coef(lm(y ~ x)) - c(5, 3)
    }
    ```
</pre>

The `knitr` chunk option `cache=TRUE` is important, as it says to cache the output of all chunks (after the setup one). Once we knit the document, here's what our file tree would look like:
```
C:\Users\Will\Big Project
├───Model_Report.Rmd
├───Model Report.html
├───Model Report_cache/
    ├───html/
        ├───__packages
        ├───regression_5aaee0a6ca789357b07ea9af871f18af.RData
        ├───regression_5aaee0a6ca789357b07ea9af871f18af.rdb
        ├───regression_5aaee0a6ca789357b07ea9af871f18af.rdx
```

If you were to open up the `Model Report.html` file, you'd see that the simulation code we wrote is there, but that's all - we forgot to print out, anything about the coefficient estimates! I guess we have to do the whole thing again, right?

## Manually loading the knitr cache
Not so! Luckily, the results from our `regression` chunk are cached! In the `Model_Report_cache/html/` folder, the 3 files with the regression prefix store all the objects from that chunk in the form of a [lazyload db](https://stat.ethz.ch/R-manual/R-patched/library/base/html/lazyload.html). Armed with this knowledge, we can easily load the results of our simulation into an existing R session like so:

```r
lazyLoad("Model_Report_cache/html/regression_5aaee0a6ca789357b07ea9af871f18af")
```

If we turn to the environment of our R session, we can see that all the variables from the regression simulation are now here!

![loaded_knitr_cache]({filename}/img/loaded_knitr_cache.png)

Now, lets plot histograms of the estimation error for each parameter:
```r
library(ggplot2)
library(tidyr)
estimates <- as.data.frame(do.call(rbind, estimates))
colnames(estimates) <- c("Intercept", "Slope")
estimates$rep <- 1:nrow(estimates)
estimates <- gather(estimates, key = "parameter", value = "error",
                   Intercept, Slope)

ggplot(estimates, aes(x = error)) +
  geom_histogram() +
  facet_grid( ~ parameter, scales = "free_x")
```

![parameter_error_histograms]({filename}/img/regression_param_error.png)

We can see by the scales on the X axis that the magnitude of estimation error is much greater for the intercept than the slope, but that in both cases the error appears normally distributed. Now that we've got our plotting code figured out, we should go back an update our report with it.

## The load_knitr_cache function
Loading the cached chunk was easy here - just one line of code. But, in real analyses situations, you're going to have lots of chunks to load, and potentially many different cached reports. So, figuring out the file names of what to load might end up taking just as long as re-running the whole report!

Luckily for you, the [`whoppeR`](https://github.com/wjhopper/whoppeR) package has the [`load_knitr_cache`](https://github.com/wjhopper/whoppeR/blob/master/R/rmarkdown_helpers.R) function to simplify this process. Just point it at the knitr cache folder you want to load (e.g., `Model_Report_cache/html/`), and let it do the rest! It can even load all the packages used in the Rmarkdown document, so you can jump right in where the document left off.

You can install the `whoppeR` package from GitHub using the handy `install_github` function from the `devtools` library:

```r
# install.packages('devtools') # if necessary
devtools::install_github('wjhopper/whoppeR')
whoppeR::load_knitr_cache('Model_Report_cache/html/') # Voilà!
```

And that's it! Hope this post taught you a little bit about how useful the `knitr` cache can be, and how to get even more out of it than just faster knitting!
