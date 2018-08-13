Title: Loading an Rmarkdown cache
Tags: R, Rmarkdown, knitr
Slug: load_rmd_cache
Status: draft
Authors: Will Hopper
Summary: How to load the knitr cache of an Rmarkdown documents

I am a huge fan of [Rmarkdown](https://rmarkdown.rstudio.com/) documents - it's safe to say it's changed how I do research forever. But, there are few drawbacks to replacing R scripts with Rmarkdown documents that relate to how code in the Rmarkdown document is not run "interactively". If you use the "Knit" button in RStudio, then your document is created using a completely new R session. So, the context your Rmarkdown code runs in  completely separate from the environment and context of the interactive R session you have open in Rstudio.

One *good* thing about this is reproducibility - your document won't produce different results depending on what's been going on in your current R session before you knit is. But, this separation also limits how you can work with your code and its outputs. If you have an error, you can't easily inspect the objects involved in the error. For example, if your index into a vector, like `x[y]`, produces an `NA` that you didn't expect, you can't quickly check whether your index was out of bounds, or if there were just missing values stored in your vector for some reason. Having the code's execution context vanish can reduce debugging to a slow, trial and error process.

Another thing you can't do is interactively quickly explore objects you create, or test out new code for your document. Imagine you just used `lm()` to do a linear regression, but you accidentally printed the `lm` object instead of the summarized `lm` object (which actually shows the coefficients, R^2, etc.). If your regression was done in an Rmarkdown document, you'd have to add the `summary(...)` call to the relevant code chunk, and re-run the whole thing! If you had done it in the console, or `source`-d a .R file, you could just execute the `summary(...)` in the console, and have your answer. Of course, RStudio allows you to run chunks interactively, but this also means you have to run code twice - once to knit it, and once in your interactive R session.

But do not despair, because there is a way to have your Rmarkdown cake and eat it too. The "backend" of Rmarkdown is the [https://yihui.name/knitr/](knitr package), which has the ability to cache the computations you perform in R code chunks. Knitr can automatically re-use the results from knitting the document previously, saving you computation time in the future. The (https://yihui.name/knitr/demo/cache/)[knitr cache] has some advanced features that give you fairly fine grain control over what gets cached, and when the cache gets invalidated. We'll be completely ignoring the advanced features here, and focusing on the simple situation where you cache all the code chunks in a document.

But first, what does caching have to do with the problems (or inconveniences, perhaps) stemming from non-interactive code execution I mentioned earlier? By loading the objects saved in the cache yourself, you get the best of both worlds! You can execute your code in the Rmarkdown document, along with all the nice reporting facilities afforded by dynamic documents, but still quickly load up the objects you created to debug errors encountered during the rendering process, or to interactively explore and write code to extend your existing report.

To give a (contrived) concrete example, let's imagine we have this big modeling project where we have to do a... bivariate regression! We're writing up our report in an Rmarkdown file called `Model_Report.Rmd` with the following contents:

```{r, eval=TRUE}
knitr::opts_chunk$set(echo = TRUE, cache = TRUE)
```

```
C:\Users\Will\Big Project
C:.
├───Model_Report.Rmd
├───Model Report.html
├───Model Report_cache/
    ├───html/
        ├───
```
