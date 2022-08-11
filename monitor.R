####################################
#
# Ultrasignup email tool
#
# written by Anna Walsdorff
# anna.walsdorff@protonmail.com
# 
# last updated July 15, 2019
#
#
# What this code does:
# Looks for your name in the waitlist of an Ultrasignup event, 
# alerts you per email if there has been a change in your spot
# on the waitlist. It also saves your current rank together with
# previous results in a csv file. To run this code, you will need
# to input 1) a working directory,
#          2) the Ultrasignup event ID,
#          3) your name
#          4) one or more email addresses to send the update to,
#          5) smtp info on the email address to send the update from


# packages

library(rvest)
library(mailR)
library(lubridate)
library(foreign)

# set your local parameters

wd <- "~/Documents/projects/ultrasignup_waitlist"  # change to your working directory
eventid <- 60102                                   # change: look at your event's url and copy the number after "did="
name <- ""                                         # your name as is appears on Ultrasignup
email.to <- c("YOURRECIPIENTEMAILHERE")            # change to email you want to send update to
email.from <- "YOURSENDEREMAILHERE"                # change to email you want to send update from

# smtp settings for your sending email, change to your specifications  
smtp <- list(host.name = "smtp.gmail.com", port = 465,
              user.name = "USERNAMESENDEREMAIL",
              passwd = "PASSWORDSENDEREMAIL", ssl = TRUE)  
  
setwd(wd)

####


url <- paste("https://ultrasignup.com/event_waitlist.aspx?did=", eventid, sep="")

grab <- read_html(url)
table <- html_nodes(grab, xpath = "//table")[[1]] %>% html_table(fill=TRUE)

# failsave for case first table is participants to respond
if (colnames(table)[1] != "Order"){
  table <- html_nodes(grab, xpath = "//table")[[2]] %>% html_table(fill=TRUE)
}

colnames(table) <- c("Order", "", "Name", "Place", "Rank")

# find my rank

rank <- as.numeric(which(table$Name==name))

date <- Sys.Date()

if (file.exists("rankmonitor.csv")){
  rankmonitor <- read.csv("rankmonitor.csv")
  #rankmonitor[,1] <- toString(rankmonitor[,1])
  diff <- as.numeric(rankmonitor[nrow(rankmonitor), 2]) - rank
  levels(rankmonitor$X1) <- c(levels(rankmonitor$X1), toString(date))
  rankmonitor <- rbind(rankmonitor, c(toString(date), as.numeric(rank), diff, 0, NA, NA))
} else {
  rankmonitor <- data.frame(cbind(toString(date), as.numeric(rank), 0, 0, NA, NA))
  diff <- 0
}

rankmonitor[as.numeric(rankmonitor[,3]) > 0, 4] <- 1

# send email alert

# title of event
title <- grab %>%
  html_nodes("title")
title <- gsub(".*\t|\r.*", "", title)

body <- paste("Your rank in the ", title, " is now "
              , rank
              , "."
              , sep="")
  
if (diff > 0) {
  send.mail(from = email.from,
            to = email.to,
            subject = paste(title, " - Change in rank", sep=""),
            body = body,
            smtp = smtp,
            authenticate = TRUE,
            send = TRUE)
}


# extra stuff

# calculate change in rank per day

datediff <- strptime(c(toString(Sys.Date()), toString(rankmonitor$X1[1])), format = "%Y-%m-%d")
datediff <- as.numeric(difftime(datediff[2], datediff[1], units = "days"))
rankdiff <- as.numeric(rankmonitor$X2[nrow(rankmonitor)]) - as.numeric(rankmonitor$X2[1])

if (datediff != 0) {
  changeperday <- rankdiff/datediff
} else {
  changeperday <- 0
}  

rankmonitor$changeperday[nrow(rankmonitor)] <- changeperday

