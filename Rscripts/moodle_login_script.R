# modeled after https://gist.github.com/olberger/d34253822a84664648b3
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
