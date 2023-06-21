#
# Common Word Checker
#
# This app checks what percentage of words are not in the top 1000 most
# common English words


# load packages
list.of.packages <- c("stringr", "tokenizers", "stopwords", "shinyWidgets")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

library(shiny)
library(stringr)
library(tokenizers)
library(stopwords)
library(shinyWidgets)

# import words
top1000 <- read.csv("top1000_english_words.txt",
                    header = FALSE,
                    col.names	= c("words"))
top1000$words <- tolower(top1000$words)
# \\b are word boundaries
top1000_test <- paste(paste("\\b",unlist(top1000),"\\b", sep=""),collapse = "|")
top1000stem_test <- paste(
  paste("\\b",
        unlist(tokenize_word_stems(paste(top1000$words, collapse = " "))),
        "\\b", sep=""),collapse = "|")
stop_test <- paste(
  paste("\\b",
        unlist(stopwords::stopwords("en")),
        "\\b", sep=""),collapse = "|")

# Define UI layout
ui <- fluidPage(

    # Application title
    titlePanel("Does your text use the top 1000 most common words?"),

    fluidRow(
      column(5,
             h4("Use word stem"),
             switchInput("switchStem", value = TRUE),
             textAreaInput(
               "yourText",
               "Your text here:",
               rows = "20"
             ),
             uiOutput("footer"),
             br()),
      
      column(5,
             htmlOutput(
               "outText"
             ),
             br()),
      
      column(2,
             h4("Total uncommon:"),
             textOutput(
               "warningTotal"
             ),
             h4("Percentage uncommon:"),
             textOutput(
               "warningPerc"
             )
             # h4("Uncommon words:"),
             # textOutput(
             #   "warningList"
             # )
    ))
)

# Define server interactions
server <- function(input, output) {
  # to lower and remove line breaks
  cleanText = reactive(
    str_replace_all(str_to_lower(input$yourText), "[\r\n]" , " ")
  )
  
  # separate words
  stringList = reactive(tokenize_words(cleanText())[[1]])
  
  # word stems
  stemList = reactive(tokenize_word_stems(cleanText())[[1]])
  
  # check words
  stopwordIdx = reactive(
    if(input$switchStem){
      # option 1 - use stem
      str_detect(stemList(), stop_test)
    } else {
      # option 2 - use full word
      str_detect(stringList(), stop_test)
    }
  )
  
  warningIdx = reactive(
    if(input$switchStem){
      # option 1 - use stem
      !str_detect(stemList(), top1000stem_test)
    } else{
      # option 2 - use full word
      !str_detect(stringList(), top1000_test)
    })
  
  highlightIdx = reactive(
    warningIdx() & !stopwordIdx()
  )
  
  # highlight words using html <mark>
  addMark <- function(textList, idx){
    if (length(textList) !=  length(idx)){
      stop("text and index length doesn't match")
    }
    
    outList = textList
    outList[idx] = paste("<mark>", outList[idx], "</mark>",
                         sep="")
    return(outList)
  }
  
  highlightList = reactive(
    addMark(stringList(),highlightIdx())
  )
  output$outText <- renderText({paste(highlightList())})
  
  
  output$warningTotal <- renderText({sum(highlightIdx())})
  output$warningPerc <- renderText({paste0(
    round(100*sum(highlightIdx())/length(stringList()), 2),
    "%")})
  
  # output$warningList <- renderText({stringList()[highlightIdx()]})
  
  # footer
  url <- a("/kevinchtsang", href="https://github.com/kevinchtsang/common_word_checker")
  output$footer <- renderUI({
    tagList("Developed by ", url)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
