Title: May I be excused? Tracking late adds in Moodle with R
Date: 2019-02-10
Tags: R, Moodle, teaching
Slug: moodle_late_adds
Status: published
Authors: Will Hopper
Summary: A guide showing you how to access your Moodle courses from R, and how to track when your students joined your course.

I'm taking on a new challenge in the Spring 2019 semester - teaching my own course! I'm teaching Psych 315, our department's "Cognitive Psychology" lecture class, where about 170 students get a broad overview of perception, attention, memory, language, and decision making. So far, it has been going well, but there are a few administrative challenges to running a large class that I hadn't fully anticipated.

One of these is dealing with people who join your class after it has begun, which isn't uncommon. If you've had any assignments come due, then these people are entitled to either a make-up assignment, or being excused altogether. This raises the question of how to keep track of who these people are, and which assignments they get excused from. The easier you make this the better, because you *will* be getting regular emails from these students asking about their grades for assignments they missed.

If your class has a Moodle page associated with it (as almost all do at UMass), then you're in luck - the "Enrolled Users" page has a table which includes a time stamp of their enrollment (it's *slightly* off, as students are usually added to Moodle in nightly batch jobs from from an external system for managing course enrollments, but it's accurate to the day at least). However, you can't sort or filer this table on the "Enrollment method" column.. This makes it hard to use this information quickly when you're inputing grades, and you need to know whether a student whose assignment is missing should get a 0, be excused, or get a make-up opportunity.

![moodle_enrolled_users]({filename}/img/moodle_enrolled_users.png)

Since I felt like I was close to having a usable solution, and had a Friday afternoon without any pressing activities, I decided I'd investigate how I could get this table imported into R, so I could filter and sort the dates properly. This turned out to be an interesting challenge, so today I bring you the "Level 1" and "Level 100" ways to get a list of your late-add students out of Moodle.

## Logging in to Moodle - the easy way
The easiest way to get this data out of Moodle and into R is to use a web browser to login to Moodle, go to the "Enrolled Users" page of your class, and save a copy of the web page to your hard drive (e.g., hit <kbd>Ctrl</kbd> + <kbd>s</kbd>). Then you can use the `rvest` R package to scrape the HTML table out of the file on disk, and into a `data.frame`.

**Protip: If you use this method, make sure to manually append `&page=0&perpage=1000` to the URL and reload the "Enrolled users"  page before downloading it. This will make sure the table has all your students in it, instead of just the first 100 (the default).**

This is straightforward, but it's tedious if you ever have to update your list. If you were able to log in to Moodle directly from R, you could automate this process. And, it would open the door to potentially scraping lots of other useful data from Moodle in an quick way. So, I went down the rabbit hole of authenticating to Moodle from R...

## Logging in to Moodle - the cool way
UMass has a "Single Sign On" (SS0) system of federated logins for almost all its digital services. This is actually really great - you have one username and password which you use for all your services (email, Moodle, Box, etc.), and logging into one service translates into logging into (almost) all the others. But, this makes the actual login processes slightly more involved that just POST-ing a username and password to some HTML form. Behind the scences, UMass uses [Shibboleth](https://www.shibboleth.net/) and an [LDAP](https://www.tldp.org/HOWTO/LDAP-HOWTO/whatisldap.html) server to handle authentication. I knew you could log in to "normal" websites on the command line using [curl](https://curl.haxx.se/), and I knew there were R packages that provided bindings for the `libcurl` C library, so I figured I'd look up how to log in to Shibboleth protected websites with standard curl, and go from there.

A quick google for 'curl shibboleth' took me to [this gist](https://gist.github.com/olberger/d34253822a84664648b3), which demonstrated logging into a Shibboleth + CAS protected web app. This wasn't a drop-in script for my situation, but running through it I figured out the basic steps I needed to take:

1. Get a session ID from the UMass SSO servers by visiting the Moodle login page, save this in some session cookies, and send these cookies with each subsequent request
2. Post my username and password to the SSO login page I get redirected to, which doesn't actually log you in yet.
3. Extract the "SAMLResponse" and "RelayState" codes I receive after providing login credentials
4. Post those codes back to the SSO servers to *really* log in this time

I implemented these steps using the `httr` R package, which provides a nice API for `libcurl`'s HTTP capabilities. But, I was getting stuck between steps 2 and 3 - I wasn't receiving the SAMLResponse and RelayState codes after sending my username and password to the login form. Instead, I just got the same login page back. Completely bewildered, I eventually had the bright idea to look at the login request as sent by my web browser when I logged in "normally" in Chromium.

I found the POST that sent the username and password in the Network tab of the developer tools, and eventually found the problem. **In addition to the username and password, the browser also posted an empty value called `eventId_proceed`**. Ughhh. Once I added the same magical blank parameter to my code, I got back a big, beautiful SAMLResponse and RelayState, and everything went swimmingly there after.

Without further ado, I present the `moodle_login` R function. If you're reading this as a UMass student/staff/faculty member, then you're welcome, you've got a drag-and-drop Moodle login function here. If you're at another school, but you also have a Shibboleth + LDAP SSO backend, then you might be able to tweak this for your school's setup. If you've got some other SSO backend, then sorry, you've got your own HW to do.

```r
library(rvest)
library(httr)

moodle_login <- function(login_page_url, username, password) {
  resp1 <- httr::GET(login_page_url)
  # Hitting the login page should trigger a bunch of redirects that start the SSO process
  # We need to know the URL of the last redirect, which is where we post the auth credentials to
  # This URL should be in the last 'location' header we received
  all_headers <- unlist(lapply(resp1$all_headers, `[[`, 'headers'),
                        recursive = FALSE) # get a list of all headers received
  locations <- all_headers[names(all_headers)=='location'] # all location headers received
  auth_url <- locations[[length(locations)]] # final location header received

  # I the auth URL doesn't have the sessionid in it, splice it in
  if (!grepl("jsessionid",x = auth_url)) {
    auth_url <- strsplit(auth_url, "?",fixed=TRUE)
    moodle_cookies <- cookies(resp1)
    auth_url <- paste0(auth_url[[1]][1],
                       ";jsessionid=",
                       moodle_cookies[moodle_cookies$name == "JSESSIONID", "value", drop=TRUE],
                       "?",
                       auth_url[[1]][2])
  }

  resp2 <- httr::POST(auth_url,
                      encode = "form",
                      httr::add_headers("User-Agent" = "curl/7.59.0",
                                        "Accept" = "*/*"),
                      body = list(j_username=username,
                                  j_password=password,
                                  `_eventId_proceed`=""
                      ),
                      set_cookies = httr::cookies(resp1)
                      )

  resp2_content <- httr::content(resp2)
  SAML_response <- rvest::html_node(resp2_content, "input[name=SAMLResponse]") %>%
    html_attr('value')
  relay_state <- rvest::html_node(resp2_content, "input[name=RelayState]") %>%
    html_attr('value')
  target <- rvest::html_node(resp2_content, "form") %>%
    html_attr('action') %>%
    utils::URLdecode()

  resp3 <- httr::POST(target,
                      encode = "form",
                      httr::add_headers("User-Agent" = "curl/7.59.0",
                                        "Accept" = "*/*"),
                      body = list(RelayState=relay_state,
                                  SAMLResponse=SAML_response
                      ),
                      set_cookies = httr::cookies(resp2)
  )

  login_cookies <- httr::cookies(resp3)
  return(login_cookies)
}
```
Take the `login_cookies` data.frame that gets spit out, include it with any future `httr` requests, and you can scrape live data from Moodle, easy peasy lemon squeezy.

## Finding your late-add students
Oh yeah, we had a job to do, before our little afternoon tour into HTTP redirects and cookies and the like. Here's how to find your late-add students. The basic steps are:

1. Login to Moodle using our new `moodle_login` function, and save the cookies that prove it
2. Download the "Enrolled Users" page - make sure to include your class ID, the page number (0) and the per-page (1000) query parameters, and your login cookies.
3. Parse the HTML table into a data.frame (thanks, `rvest` package!)
4. Extract a valid `DateTime` from the "Enrollment method" column
5. Filter out the students with add dates before the first class
6. Profit!

```r
library(httr)
library(rvest)
library(tidyr)
library(dplyr)
source("moodle_login.R") # defined above!

#### Step 1 - log in ####
username <- readline("NetID: ")
cat('\n')
password <- readline("Password: ")
cat('\n')

course_id <- 53226
first_day <- "2019-01-23"

login_cookies <- moodle_login("http://moodle.umass.edu/login/index.php", username, password)

#### Step 2 - Download enrolled users table ####
users_page <- httr::GET("https://moodle.umass.edu/enrol/users.php",
                        query = list(id=53226,
                                     page=0,
                                     perpage=1000
                        ),
                        set_cookies = login_cookies
)
#### Step 3 - Extract the table as a data frame ####
users <- rvest::html_table(rvest::html_nodes(httr::content(users_page),
                                             ".userenrolment ")
                           )[[1]]
students <- dplyr::filter(users, Roles=="Student")

#### Step 4 - Parse the enrollment date ####
students$`Enrollment methods` <- sub("IMS Enterprise file enrolled ", "",
                                     students$`Enrollment methods`)
students$Date <- strptime(students$`Enrollment methods`,
                          format = "%A, %B %d, %Y, %I:%M %p")
students$Date <- as.POSIXct(students$Date)
students <- dplyr::arrange(students, Date)

#### Step 5 - Find the late add students ####
students <- dplyr::select(students, `First name / Last name / Email address`, Date)
students <- tidyr::separate(students, `First name / Last name / Email address`,
                            into=c("First name", "Last name", "Email address"),
                            sep="\\ ",
                            fill = "right")

late_students <- dplyr::filter(students, Date > first_day)
```

The `late_students` data frame will look something like this when you're done:

|First name |Last name    |Email address             |Date                |
|:----------|:------------|:-------------------------|:-------------------|
|Bob        |Sacamano     |russianhats@umass.edu     |2019-01-23 16:32:00 |
|Patrick    |Pattycakes   |pcakes@umass.edu          |2019-01-28 12:32:00 |
|Lap        |Pal          |lappal@umass.edu          |2019-01-29 10:32:00 |
|Andrea     |Catalog      |acatalog@umass.edu        |2019-02-01 09:32:00 |
|Merika     |theBeautiful |purplemountains@umass.edu |2019-02-04 09:32:00 |

Save this list somewhere, check it when you're entering grades, and your life might just have a few less angry "Why did I get a 0..." emails from your students in it.  
