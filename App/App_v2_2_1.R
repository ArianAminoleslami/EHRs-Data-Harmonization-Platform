
# This app was developed b Arian Aminoleslami in June 2023 and 
# released under the GNU General Public License v3.0. 

# For inquires or questions, please write to <arian.aminoleslami@utoronto.ca>/
#<aaminoleslami@uwaterloo.ca>

# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com

# A limited version of this app is also publicly available at <https://poxotn-arian-aminoleslami.shinyapps.io/Arian/>



packages=c("shiny","shinyjs", "RSQLite", "ggplot2",
           "haven", "recodeflow", "stringr", "dplyr","shinybusy","rhandsontable",
           "shinydashboard","data.table")

for (package in packages) {
  # Check if the package is already installed
  if (!require(package, character.only = TRUE)) {
    # If not installed, install the package
    install.packages(package, repos='http://cran.us.r-project.org', dependecies = TRUE)
  }
}

library(shiny)
library(shinyjs)
library(RSQLite)
library(ggplot2)
library(haven)
library(recodeflow)
library(stringr)
library(dplyr)
library(data.table)
library(shinybusy)
library(rhandsontable)
library(shinydashboard)

### multiple psv files 

csv_chunk_multiple<-function(file_input,chunk_size,file_output,var_sheet,var_details,db_name,var){
  withProgress(message = "Please wait while your dataset is being recoded!", value = 0,{
    csv_files <- list.files(path = file_input, pattern = ".csv", full.names = TRUE)
    S<-colnames(read.csv(csv_files[1],nrows=1,sep="|"))
    #rows<-fread(file_input,select = var,sep="|")%>%
    # nrow()
  for (i in 1:length(csv_files)){
      
    input_file2<-csv_files[i]
    input_con2<-file(input_file2, "r")
    
    num_rows <- 0
    # Read the file line by line and count rows
    while (length(line <- readLines(input_con2, n = 1,warn = FALSE)) > 0) {
      num_rows <- num_rows + 1
    }
    
    # Close the file
    close(input_con2)
    
    
    # Open the input CSV file for reading
    input_file <- csv_files[i]
    input_conn <- file(input_file, "r")
    
    ## create the output folder
    
    dir.create(file_output)
    
    ##
    
    # Open the output CSV file for writing 
    output_file <- paste0(file_output,'\\',tools::file_path_sans_ext(basename(csv_files[i])),"_recoded.csv")
    output_conn <- file(output_file, "w")
    
    # Read, process, and append data in chunks
    n<-1
    end<-FALSE
    while (!end) {
      # Read a chunk of data
      if(n==1){
        chunk <- read.csv(input_conn, nrows = chunk_size ,header = TRUE,sep="|")
      }
      else{
        chunk <- read.csv(input_conn, nrows = chunk_size ,header = FALSE,sep="|")
      }
      
      # Check if the chunk is empty (end of file)
      
      colnames(chunk)<-S
      
      recoded<-rec_with_table(chunk,variables =var_sheet, variable_details = var_details,database_name =db_name)
      
      if(n>1){
        colnames(recoded)<-NULL
      }
      n=n+1
      
      # If the header has not been written yet, write it to the output file
      # Append the processed chunk to the output file (skip writing the header)
      
      write.table(recoded, output_conn,row.names = FALSE, append = TRUE, quote=FALSE, sep = "|")
      if (n==ceiling((num_rows-1)/chunk_size)+1) {
        end <- TRUE
      }
      
      incProgress(1/floor((num_rows-1)/chunk_size)*(1/length(csv_files))) 
    }
    # Close both input and output files
    closeAllConnections()
  }
    
  }
  )
}








### one single csv pipe delimited file
csv_chunk<-function(file_input,chunk_size,file_output,var_sheet,var_details,db_name,var){
  withProgress(message = "Please wait while your dataset is being recoded!", value = 0,{
    S<-colnames(read.csv(file_input,nrows=1,sep="|"))
    #rows<-fread(file_input,select = var,sep="|")%>%
     # nrow()
 
    input_file2<-file_input
    input_con2<-file(input_file2, "r")
   
     num_rows <- 0
    # Read the file line by line and count rows
    while (length(line <- readLines(input_con2, n = 1,warn = FALSE)) > 0) {
      num_rows <- num_rows + 1
    }
    
    # Close the file
    close(input_con2)
    
    
    # Open the input CSV file for reading
    input_file <- file_input
    input_conn <- file(input_file, "r")
    
    # Open the output CSV file for writing (or create it if it doesn't exist)
    output_file <- file_output
    output_conn <- file(output_file, "w")
    
    # Read, process, and append data in chunks
    n<-1
    end<-FALSE
    while (!end) {
      # Read a chunk of data
      if(n==1){
        chunk <- read.csv(input_conn, nrows = chunk_size ,header = TRUE,sep="|")
      }
      else{
        chunk <- read.csv(input_conn, nrows = chunk_size ,header = FALSE,sep="|")
      }
      
      # Check if the chunk is empty (end of file)
      
      colnames(chunk)<-S
      
      recoded<-rec_with_table(chunk,variables =var_sheet, variable_details = var_details,database_name =db_name)
      
      if(n>1){
        colnames(recoded)<-NULL
      }
      n=n+1
      
      # If the header has not been written yet, write it to the output file
      # Append the processed chunk to the output file (skip writing the header)
      
      write.table(recoded, output_conn,row.names = FALSE, append = TRUE, quote=FALSE, sep = "|")
      if (n==ceiling((num_rows-1)/chunk_size)+1) {
        end <- TRUE
      }
      
      incProgress(1/floor((num_rows-1)/chunk_size)) 
    }
    # Close both input and output files
    closeAllConnections()
    
    
  }
  )
}




recodeflow_sqlChunk=function(db_connection,var_sheet, var_details,original_table,chunk_size,new_table_name, db_name,variables ){
  
  withProgress(message = "Please wait while your dataset is being recoded!", value = 0,{
    rows<-as.numeric(dbGetQuery(db_connection, paste("SELECT count(*) FROM", original_table)))
    
    counter<-c(seq(1,rows, by = chunk_size))
    initial<-dbGetQuery(db_connection, paste("SELECT", paste(variables,collapse = "," ),"FROM", original_table, "LIMIT 1"))
    initial_recoded=rec_with_table(initial ,variables =var_sheet, variable_details =var_details, database_name =db_name )
    dbWriteTable(conn = db_connection, name =new_table_name, value = initial_recoded, overwrite=FALSE)
    
    
    for (i in counter) {
      
      chunk<-dbGetQuery(db_connection, paste("SELECT", paste(variables,collapse = "," ),"FROM", original_table ,"LIMIT", i,",", chunk_size))
      
      recoded<-rec_with_table(chunk,variables =var_sheet, variable_details = var_details,database_name =db_name)
      
      dbAppendTable(db_connection,new_table_name,recoded)
      
      incProgress(1/length(counter))}
  }
  
  )
}

ui <- fluidPage(
  
  tags$head(
    tags$style(HTML("
      .fancy-button {
        background-color: #4CAF50; /* Green background color */
        border: none; /* Remove borders */
        color: white; /* White text */
        padding: 15px 32px; /* Some padding */
        text-align: center; /* Centered text */
        text-decoration: none; /* Remove underline */
        display: inline-block;
        font-size: 16px;
        border-radius: 8px; /* Rounded corners */
        transition-duration: 0.4s; /* Transition on hover */
        cursor: pointer; /* Add a pointer cursor on mouse-over */
      }
      
      .fancy-button:hover {
        background-color: #45a049; /* Darker green on hover */
      }
    "))
  ),
  
  tags$head(
    tags$style(HTML("
      .fancy-button2 {
         background-color: #FFA500; /* Orange background color */
        border: none; /* Remove borders */
        color: white; /* White text */
        padding: 15px 32px; /* Some padding */
        text-align: center; /* Centered text */
        text-decoration: none; /* Remove underline */
        display: inline-block;
        font-size: 16px;
        border-radius: 8px; /* Rounded corners */
        transition-duration: 0.4s; /* Transition on hover */
        cursor: pointer; /* Add a pointer cursor on mouse-over */
      }
      
      .fancy-button2:hover {
        background-color: #FF8C00; /* Darker orange on hover */
      }
    "))
  ),
  
  tags$head(
    tags$style(HTML("
      .fancy-button3 {
        background-color: #87CEFA; /* Pale blue background color */
        border: none; /* Remove borders */
        color: white; /* White text */
        padding: 15px 32px; /* Some padding */
        text-align: center; /* Centered text */
        text-decoration: none; /* Remove underline */
        display: inline-block;
        font-size: 16px;
        border-radius: 8px; /* Rounded corners */
        transition-duration: 0.4s; /* Transition on hover */
        cursor: pointer; /* Add a pointer cursor on mouse-over */
      }
      
      .fancy-button3:hover {
         background-color: #5F9EA0; /* Darker pale blue on hover */
      }
    "))
  ),
  
  tags$head(
    tags$style(HTML("
      .fancy-button4 {
        background-color: #FFB6C1; /* Light pink background color */
        border: none; /* Remove borders */
        color: white; /* White text */
        padding: 15px 32px; /* Some padding */
        text-align: center; /* Centered text */
        text-decoration: none; /* Remove underline */
        display: inline-block;
        font-size: 16px;
        border-radius: 8px; /* Original shape (not round) */
        transition-duration: 0.4s; /* Transition on hover */
        cursor: pointer; /* Add a pointer cursor on mouse-over */
      }
      
      .fancy-button4:hover {
        background-color: #FF69B4; /* Darker pink on hover */
      }
    "))
  ),
  
  shinyjs::useShinyjs(),
  add_busy_spinner(spin = "cube-grid"),
  #tags$head(
  #tags$style(
  # HTML("
  # body{
  # background-color: #F8F8F8;
  # color= blue;
  #  }"
  #    )
  
  #  )
  #),
  
  titlePanel("EHRs Data Harmonization Platform"),
  dashboardPage(
    dashboardHeader(title = tags$img(src = "logo1.png", width = "100px")),
    dashboardSidebar(
      textInput("db", "Choose an optional name for your original dataset"),
      uiOutput("variable"),
      textInput("var_name","Type your preferred name of the variable in the recoded dataset"),
      radioButtons("derived",label = "Derived variable?", choices = c("Yes","No"), selected = "No" , inline = TRUE),
      
      conditionalPanel(
        condition = "input.derived == 'Yes'",
        radioButtons("library", "Do you want to add derived variables from DVL?", choices = c("Yes", "No"), selected = "No")
      ),
      
      uiOutput("dvlpath1"),
      uiOutput("dvllist1"),
      uiOutput("func_code1"),
      uiOutput("warning_c"),
      uiOutput("func_name"),
      uiOutput("warning_n"),
      uiOutput("components"),
      uiOutput("derived_type"),
      uiOutput("typeStart"),
      uiOutput("typeEnd"),
      uiOutput("cont_miss"),
      fluidRow(
        column(width = 6,uiOutput("cont_mis_min")),
        column(width = 6,uiOutput("cont_mis_max"))
      ),
      uiOutput("categories"),
      uiOutput("catS"),
      uiOutput("catF"),
      #uiOutput("missingvalue"),
      actionButton("Add","Add to table", class="fancy-button3"),
      #numericInput("deleterow", "enter the row number to be deleted", value = 1),
      #actionButton("Delete","Delete the row (variable details)"),
      
      tags$div(
        style = "text-align: center; margin-top: 20px;",
        
        HTML(
          '<p style="font-size: smaller; font-style: italic; color: #4a90e2;">',
          'This app was developed by Arian Aminoleslami in June 2023',
          'and released under the GNU General Public License v3.0.</p>',
          '<p style="font-size: smaller; font-style: italic; color: #4a90e2;">',
          'For inquiries or questions, please write to: ',
          '<a href="mailto:aaminoleslami@uwaterloo.ca" style="color: #4a90e2;">aaminoleslami@uwaterloo.ca</a>',
          
        )
        
        
      )
      # Credits and logos
      
      
      
      
      
    ),
    
    dashboardBody(
      tags$style(HTML('
      .skin-blue .main-header .logo {
        background-color: #2E3E4E; /* Light blue color code */
      }
    ')),
      
      tags$style(HTML('
      .skin-blue .main-header .navbar {
        background-color: #FFDAB9; /* Dark orange color code */
      }
    ')),
      
      
      tabsetPanel(
        
        tabPanel("Recodeflow", 
                 radioButtons("importType", "Please choose the format of your original dataset" ,choices = c("Comma-delimited CSVs",".RDS",".sas7bdat",".SQLite", "Large pipe-delimited CSVs"), selected = "Comma-delimited CSVs"),
                 conditionalPanel(
                   condition = "input.importType == 'Large pipe-delimited CSVs'",
                   radioButtons("singleorgroup", "From a single file or multiple files in a folder?", choices = c("Single", "Multiple"), selected = "Single")
                 ),
                 conditionalPanel(
                   condition = "input.singleorgroup == 'Multiple' & input.importType == 'Large pipe-delimited CSVs'",
                   textInput("pathtofolder", "Please enter the path to the folder where all files are located", value = "", placeholder = "e.g. C:/users/../files/original_data")
                 ),
                 conditionalPanel(
                   condition = "input.singleorgroup == 'Multiple' & input.importType == 'Large pipe-delimited CSVs'",
                   textInput("pathtofolderwrite", "Please enter the path to the folder where all recoded files will be stored", value = "", placeholder = "e.g. C:/users/../files/recoded_data")
                 ),
                 uiOutput("import"),
                 tableOutput("test"),
                 tableOutput("recodedtable"),
                 uiOutput("path"),
                 uiOutput("tablename"),
                 uiOutput("pathtowrite"),
                 br(),
                 uiOutput("update"),
                 uiOutput("newname"),
                 #uiOutput("importedvars"),
                 uiOutput("chunksize"),
                 uiOutput("addmorevars"),
                 actionButton("recode","Recode the dataset!", class="fancy-button4"),
                 uiOutput("downloadType"),
                 br(),
                 uiOutput("downloadRecoded"),
                 uiOutput("show_recoded_sqlite"),
                 tableOutput("recodedtable_sql")
                 
        ),
        
        
        
        tabPanel("Variable details sheet",
                 radioButtons("alreadyD","Already have a .csv Variable Details sheet?", c("Yes","No"), selected = "No"),
                 uiOutput("upD"), 
                 rHandsontableOutput("table"),
                 downloadButton("download_data","Download .csv file!")),
        
        tabPanel("Variable sheet",
                 #radioButtons("alreadyV","Already have a .csv Variable sheet?", c("Yes","No"), selected = "No"),
                 uiOutput("upV"),
                 rHandsontableOutput("VariablesSheet"),
                 downloadButton("download_data2","Download .csv file!") ),
        
        
        tabPanel("Summary", 
                 br(),
                 br(),
                 
                 actionButton("showsummary","Extract the variable", class = "fancy-button"),
                 verbatimTextOutput("levels"),
                 verbatimTextOutput("DistinctVals")
                 ,
                 
                 br(),
                 br(),
                 br(),
                 br(),
                 
                 fluidRow(
                   column(3,actionButton("showfreq","Frequency table", class = "fancy-button2" )),
                   column(3, tableOutput("freq_table"))
                 )
                 
                 
        ),
        
        tabPanel("Derived variables description",
                 
                 tableOutput("derived_description"),
                 downloadButton("download_description","Download .csv file!"),
                 
                 
                 
                 
        )
        
      )
    )
  )
)







server <- function(input, output, session) {
  
  options(shiny.maxRequestSize= 1000*1024^2)
  
  #### disable action button if new name variable is empty ###
  
  observe({
    if(input$var_name=="" && input$library == "No"){
      shinyjs::disable(id= "Add")}
    
    else{
      
      shinyjs::enable(id ="Add")
      
    }
    
  })
  
  
  
  
  
  #observe({
  # if(input$derived=="Yes"){
  #    shinyjs::enable(id= "var_name")
  #}
  
  #  })
  
  #### already have var and var det ####
  
  
  output$upD<-renderUI({
    
    if (input$alreadyD=="Yes"){
      
      fileInput("upD", "Please upload your .csv variable details sheet")
      
    }
    
  })
  # output$upV<-renderUI({
  
  #  if (input$alreadyV=="Yes"){
  
  #   fileInput("upV", "Please upload your .csv variable sheet")
  
  #}
  
  #})
  
  
  
  
  
  
  ####################
  ##### sql recoded ##########
  ####################
  
  #### download recoded ####
  output$downloadType<-renderUI({
    
    if(input$importType%in% c("Comma-delimited CSVs",".RDS",".sas7bdat" )){
      
      radioButtons("downloadType1", "Please choose the format of your recoded dataset",choices = c("Comma-delimited CSVs",".RDS"))
      
    }
    
    
  })
  
  output$downloadRecoded<-renderUI({
    
    if(input$importType%in% c("Comma-delimited CSVs",".RDS",".sas7bdat" )){
      
      downloadButton("downloadrecoded","Download your recoded dataset!")
      
    }
    
  })
  
  
  output$addmorevars<-renderUI({
    
    if(input$importType%in% c("Comma-delimited CSVs",".RDS",".sas7bdat" )){
      
      selectInput("cbind","Do you want to add more columns from the original dataset to your recoded dataset?", choices = names(), multiple = TRUE )
      
    }
    
  })
  
  
  output$show_recoded_sqlite<-renderUI({
    
    if(input$importType==".SQLite"){
      
      actionButton("show_recoded_sqlite1", "Header of the table")
      
    }
    
  })
  
  table_sql<-eventReactive(input$show_recoded_sqlite1,{
    
    withProgress(tbl(dbConnect(RSQLite::SQLite(),dbname=input$path1), input$tablename1)%>%collect()%>%slice(1:20),message = "Please Wait")
    
    
  })
  
  output$recodedtable_sql<-renderTable({
    
    table_sql()
    
  })
  
  
  output$downloadrecoded<-downloadHandler(
    filename= function() { paste0(file_name(),"_","recoded",Sys.Date(),"_",format(Sys.time(), "%H-%M-%S"),ifelse(input$downloadType1=="Comma-delimited CSVs",".csv",".RDS"))
      
    },
    
    content = function(file){
      if (input$downloadType1=="Comma-delimited CSVs"){
        
        write.csv(df_recoded(),file,row.names = FALSE)
      }
      
      else if (input$downloadType1==".RDS"){
        saveRDS(df_recoded(), file)
      }
      
    }
    
  )
  ###################
  
  ####################
  ##### sql recoded ######
  ####################
  
  output$tablename<-renderUI({
    if(input$importType==".SQLite"){
      
      selectizeInput("tablename1", "Please choose the name of the table in the database", dbListTables(dbConnect(RSQLite::SQLite(),dbname=input$path1)))
      
    }
    
  })
  
  output$update<-renderUI({
    if(input$importType==".SQLite"){
      
      actionButton("update_t","Update table names")
    }
    
  })
  
  
  output$path<-renderUI({
    if((input$importType == ".SQLite") | (input$importType== "Large pipe-delimited CSVs"& input$singleorgroup=="Single" ) ){
      
      textInput("path1", "Please enter the path to the database or dataset", value = "", placeholder = "e.g. C:/users/../test.csv or test.sqlite ")
      
    }
    
  })
  
  output$newname<-renderUI({
    if(input$importType==".SQLite"){
      
      textInput("newname1", "Please enter your preferred name of the new recoded table in the database")
      
    }
    
  })
  
  
  output$pathtowrite<-renderUI({
    if(input$importType=="Large pipe-delimited CSVs" & input$singleorgroup=="Single"){
      
      textInput("pathtowrite1", "Please enter a preferred path to a csv file that you want to create for the recoded data", placeholder ="e.g. C:/users/../test_recoded.csv" )
      
    }
    
  })
  
  
  
  con<-reactive({
    a<-tbl(dbConnect(RSQLite::SQLite(),dbname=input$path1),input$tablename1)
  })
  names_orig<-reactive({
    
    namesss<-colnames(con())
    
  })
  
  #output$importedvars<-renderUI({
  # if(input$importType==".SQLite"){
  
  #  selectizeInput("importedvars1","please choose the variables of the dataset to be imported and used in recoding", choices=names_orig(), multiple=TRUE   )
  #}
  #})
  
  output$chunksize<-renderUI({
    if(input$importType %in% c(".SQLite","Large pipe-delimited CSVs")){
      
      numericInput("chunksize1", "choose the size of chunk", min=100000, max=10000000, step=100000, value = 100000)
      
    }
  })
  
  ############
  #############
  
  
  #######
  output$import<-renderUI({
    
    if (input$importType=="Comma-delimited CSVs"){
      
      fileInput("file1", "Please choose a csv file")
      
    }
    
    else  if (input$importType==".RDS") {
      
      fileInput("file1", "Please choose a rds file")
      
    }
    
    
    else  if (input$importType==".sas7bdat") {
      
      fileInput("file1", "Please choose a sas file")
      
    }
    
  })
  
  database<-reactive({
    
    if (input$importType=="Comma-delimited CSVs"){
      
      basename(file$datapath)
      
    }
    
  })
  
  file_name<-reactiveVal(NULL)
  
  dataframe<-reactive({
    
    if (input$importType=="Comma-delimited CSVs"){
      file<-input$file1
      ext<-tools:: file_ext(file$datapath)
      
      req(file)
      
      validate(need(ext%in%c("csv","CSV"), "Please choose a 'csv' file!"))
      
      file_name(str_remove(file$name, "\\..*"))
      
      read.csv(file$datapath, header = TRUE)
    }
    
    else if (input$importType==".RDS"){
      file<-input$file1
      ext<-tools:: file_ext(file$datapath)
      
      req(file)
      
      
      validate(need(ext%in%c("RDS","rds"), "Please choose a 'RDS' file!"))
      
      file_name(str_remove(file$name, "\\..*"))
      
      readRDS(file$datapath)
    }
    
    else if (input$importType==".sas7bdat"){
      file<-input$file1
      ext<-tools:: file_ext(file$datapath)
      
      req(file)
      
      
      validate(need(ext=="sas7bdat", "Please choose a 'SAS' file!"))
      
      file_name(str_remove(file$name, "\\..*"))
      
      read_sas (file$datapath)
    }
    
    
    
    
  })
  
  output$test<-renderTable({
    
    if (input$importType%in% c("Comma-delimited CSVs",".RDS",".sas7bdat" )) {
      
      dataframe()%>%
        select(1:min(12,ncol(dataframe())))%>%
        slice(1:5)
    }
  })
  
  names<-reactive({
    
    if(input$importType==".SQLite") {
      
      d<-tbl(dbConnect(RSQLite::SQLite(),dbname=input$path1),input$tablename1 )%>%
        colnames()
    }
    else if(input$importType=="Large pipe-delimited CSVs" & input$singleorgroup=="Single") {
      colnames(read.csv(input$path1,nrows=1,sep="|"))
    }
    
    else if(input$importType=="Large pipe-delimited CSVs" & input$singleorgroup=="Multiple") {
      
      colnames(read.csv(list.files(path = input$pathtofolder, pattern = ".csv", full.names = TRUE)[1],nrows=1,sep="|"))
    }
    
    else if (input$importType%in% c("Comma-delimited CSVs",".RDS",".sas7bdat" )) {
      
      d<-dataframe()%>%
        colnames()
    }
    
    #else if (input$db=="RDEN_CCRS_Epis"){
    
    #d<-columnnames_ccrs_epis
    
    #}
    
    #  else {
    
    #   d<-columnnames_dad
    
    #}
    
  })
  
  
  output$variable<-renderUI({
    
    if(input$derived=="No"){
      
      selectInput("var", "Choose a variable to be recoded", choices = names())
    }
  })
  
  #output$uselibrary<-renderUI({
  
  # if(input$derived=="Yes"){
  
  #radioButtons("library",label = "Do you want to add the derived variables from DVL?", choices = c("Yes","No"), selected = "No" , inline = TRUE)
  
  
  #}
  #})
  
  
  ##cdisable var_name in case of dvl
  observe({
    if (input$derived == "Yes" && input$library == "Yes") {
      # Both derived and library are "Yes", disable var_name
      shinyjs::disable(id = "var_name")
    } else {
      # Either derived or library (or both) are not "Yes", enable var_name
      shinyjs::enable(id = "var_name")
    }
  })
  
  # observe({
  #  if(input$derived=="Yes"){
  #   if (input$library=="Yes"){
  #shinyjs::disable(id = "var_name")
  # }
  #} else {
  # If derived is not "Yes", enable library and var_name
  # shinyjs::enable(id = "var_name")
  #  }
  #})
  
  
  output$dvlpath1<-renderUI({
    
    if(input$derived=="Yes"){
      if(input$library=="Yes"){
        
        textInput("dvlpath","Please enter the path to the DVL", value = paste0("C:\\Users\\arian\\OneDrive\\Desktop\\derived_variables_library.csv"))
        
      }}
  })
  
  output$dvllist1<-renderUI({
    
    if(input$derived=="Yes"){
      if(input$library=="Yes"){
        
        selectizeInput("dvllist","please select the derived variables of your interest",
                       choices = read.csv(input$dvlpath)%>%
                         distinct(variable_name),
                       multiple = TRUE,  # Enable multiple selections
                       options = list(
                         plugins = list("remove_button"),  # Enable checkboxes
                         
                         onInitialize = I('function() { this.settings.labelField = "text"; }')  # Set labelField for checkboxes
                       )
        )
        
      }}
  })
  
  
  
  output$func_name<-renderUI({
    if(input$derived=="Yes"){
      if(input$library=="No"){
        
        textInput("func","Please type the name of your function")
        
      }}
  })
  
  output$func_code1<-renderUI({
    if(input$derived=="Yes"){
      if(input$library=="No"){
        textAreaInput("func_code","Please enter the function's code", placeholder = "e.g. function(a,b) {a+b}")
        
      }}
  })
  
  
  output$derived_type<-renderUI({
    if(input$derived=="Yes"){
      if(input$library=="No"){
        radioButtons("derived_type1",label = "What is the type of the derived variable?", choices = c("Categorical","Continous"), selected = "Continous" , inline = TRUE)
        
      }}
  })
  
  
  output$warning_n<-renderUI({
    if(input$derived=="Yes"){
      if(input$library=="No"){
        if(input$func==""){
          
          tags$span(style= "color:orange;", "Warning: The function name cannot be empty!")
          
        }}}
    
  })
  
  
  observeEvent(input$func_code,{
    
    code<-input$func_code
    
    result<-tryCatch(parse(text=code),error=function(e) e)
    
    if (inherits(result, "error")){
      
      output$warning_c<-renderUI({
        
        tags$div(
          style="color:orange;",
          paste("Syntax error:", result$message)
          
        )
        
      })
    } else {
      
      output$warning_c<-renderUI(NULL)
      
    }
    
  })
  
  
  output$components<-renderUI({
    if(input$derived=="Yes"){
      if(input$library=="No"){
        selectizeInput("components","Please choose the components of the derived variable",choices=unique(values$df[-1,"variable"]), multiple=TRUE )
        
      }}
  })
  
  
  
  output$typeStart<-renderUI({
    
    if(input$derived=="No"){
      
      radioButtons("typeStart",label = "What is the type of variable in the original dataset?", choices = c("Categorical","Continous"), selected = "Continous" , inline = TRUE)
    }
  })
  
  output$typeEnd<-renderUI({
    
    if(input$derived=="No"){
      
      radioButtons("typeEnd",label = "What is the type of variable in the recoded dataset?", choices = c("Categorical","Continous"), selected = "Continous" , inline = TRUE)
    }
  })
  
  
  
  
  
  
  
  
  output$cont_miss<-renderUI({
    
    if(input$typeEnd=="Continous" & input$typeStart=="Continous" & input$derived=="No"){
      radioButtons("cont_miss", "Put missing values for the values out of a range? ", choices = c("Yes", "No"), selected = "No")
    }
  })
  
  
  output$categories<- renderUI({
    
    
    
    if( input$derived=="No" & (input$typeStart=="Categorical"| input$typeEnd=="Categorical")){
      
      numericInput("categories","Enter the number of categories", min=0, max=30, value=2)
      
    }
    
  })
  
  
  output$catS<-renderUI({
    
    
    if((input$typeStart=="Categorical" & input$typeEnd=="Categorical" & input$derived=="No")|(input$typeStart=="Categorical" & input$typeEnd=="Continous"& input$derived=="No")){
      
      if(input$categories>0){
        
        lapply(1:input$categories, function(i){
          
          textInput(paste0("cats",i),paste("Original category",i))
          
        })
      }}
    
  })
  
  
  output$catF<-renderUI({
    
    if((input$typeStart=="Categorical" & input$typeEnd=="Categorical" & input$derived=="No")|(input$typeStart=="Continous" & input$typeEnd=="Categorical"& input$derived=="No")|(input$typeStart=="Categorical" & input$typeEnd=="Continous"& input$derived=="No")){
      
      if(input$categories>0){
        
        lapply(1:input$categories, function(i){
          
          textInput(paste0("catF",i),paste("Final category",i))
          
        })
      }}
  })
  
  #output$missingvalue<-renderUI({
  
  # if((input$typeStart=="Categorical" & input$typeEnd=="Categorical" & input$derived=="No")|
  #   (input$typeStart=="Continous" & input$typeEnd=="Categorical"& input$derived=="No")|
  #  (input$typeStart=="Continous" & input$typeEnd=="Continous"& input$derived=="No" & input$cont_miss=="Yes"  ))
  
  #{
  
  #selectizeInput("missingvaluestype","Otherwise, what type of missing values?",choices=c("Not applicable","Missing", "Not asked"))
  
  
  #}
  
  
  
  
  
  
  
  # })
  
  dvl<-reactive({
    
    if (input$derived=="Yes"){
      if(input$library=="Yes"){
        
        read.csv(input$dvlpath)%>%
          filter(variable_name %in% input$dvllist)%>%
          mutate(variable=variable_name,
                 recEnd=paste0("Func::",function_name),
                 variableStart=paste0("DerivedVar::",components),
                 typeEnd=type)
      }}
  })
  
  values<-reactiveValues()
  
  alreadyD<-reactive({
    
    if(input$alreadyD=="Yes"){
      
      file<-input$upD
      ext<-tools:: file_ext(file$datapath)
      
      req(file)
      
      
      validate(need(ext%in%c("csv","CSV"), "Please choose a 'csv' file!"))
      
      read.csv(file$datapath, header = TRUE)
      
    }
  })
  
  alreadyV<-reactive({
    
    if(input$alreadyV=="Yes"){
      
      file<-input$upV
      ext<-tools:: file_ext(file$datapath)
      
      req(file)
      
      
      validate(need(ext%in%c("csv","CSV"), "Please choose a 'csv' file!"))
      
      read.csv(file$datapath, header = TRUE)
      
    }
  })
  
  
  
  observe({
    if(input$alreadyD=="Yes"){
      
      values$df <-rbind(data.frame(variable="a",
                                   databaseStart="a",
                                   variableStart="a",
                                   typeStart="a",
                                   typeEnd="a",
                                   recStart="a",
                                   recEnd="a",
                                   catStartLabel="a",
                                   catLabel="a",
                                   catLabelLong="a",
                                   Notes="a"),
                        alreadyD()%>%
                          select(any_of(c("variable","databaseStart","variableStart",
                                          "typeStart","typeEnd","recStart","recEnd",
                                          "catStartLabel", "catLabel","catLabelLong","Notes")))
                        
      )
    }
    
    else{
      values$df <- data.frame(variable="a",
                              databaseStart="a",
                              variableStart="a",
                              typeStart="a",
                              typeEnd="a",
                              recStart="a",
                              recEnd="a",
                              catStartLabel="a",
                              catLabel="a",
                              catLabelLong="a",
                              Notes="a")
    }
    
    
  })
  
  
  
  
  
  newentry<-observeEvent(input$Add, {
    
    if(input$typeEnd=="Continous" & input$typeStart=="Continous" & input$cont_miss=="Yes"){
      newline<-isolate(data.frame(
        variable=c(input$var_name,input$var_name),
        databaseStart=c(input$db,input$db),
        variableStart=c(paste0(input$db,"::",input$var),paste0(input$db,"::",input$var)),
        typeStart=c(ifelse(input$typeStart=="Continous", "cont","cat"),ifelse(input$typeStart=="Continous", "cont","cat")),
        typeEnd=c(ifelse(input$typeEnd=="Continous", "cont","cat"),ifelse(input$typeEnd=="Continous", "cont","cat")),
        recStart=c(ifelse(input$cont_miss=="Yes",paste0("[",input$min,",",input$max,"]")),"else"),
        recEnd=c("copy","NA::b"),
        catStartLabel=NA,
        catLabel=NA,
        catLabelLong=NA,
        Notes=NA
      ))
    }
    if(input$cont_miss=="No"& input$typeEnd=="Continous" ){
      newline<-isolate(data.frame(
        variable=input$var_name,
        databaseStart=input$db,
        variableStart=paste0(input$db,"::",input$var),
        typeStart=ifelse(input$typeStart=="Continous", "cont","cat"),
        typeEnd=ifelse(input$typeEnd=="Continous", "cont","cat"),
        recStart="else",
        recEnd="copy",
        catStartLabel=NA,
        catLabel=NA,
        catLabelLong=NA,
        Notes=NA
      ))
    }
    
    if((input$typeEnd=="Categorical" & input$typeStart=="Categorical" & input$derived=="No")|(input$typeStart=="Categorical" & input$typeEnd=="Continous" & input$derived=="No")){
      
      recEnd<-vector(mode = "numeric")
      for (i in 1:input$categories) {
        recEnd<-rbind(recEnd,eval(parse(text=paste0("input$catF",i))))
      }
      
      recStart<-vector(mode = "numeric")
      for (i in 1:input$categories) {
        recStart<-rbind(recStart,eval(parse(text=paste0("input$cats",i))))
      }
      
      newline<-isolate(data.frame(
        variable=rep(input$var_name,input$categories+1),
        databaseStart=rep(input$db,input$categories+1),
        variableStart=rep(paste0(input$db,"::",input$var),input$categories+1),
        typeStart=rep(ifelse(input$typeStart=="Continous", "cont","cat"),input$categories+1),
        typeEnd=rep(ifelse(input$typeEnd=="Continous", "cont","cat"),input$categories+1),
        recStart=c(recStart,"else"),
        recEnd=c(recEnd,"NA::b"),
        catStartLabel=NA,
        catLabel=NA,
        catLabelLong=NA,
        Notes=NA
      ))
      
      
      
    }
    
    
    if(input$typeEnd=="Categorical" & input$typeStart=="Categorical" & input$derived=="No"){
      if(input$categories==0){
        newline<-isolate(data.frame(
          variable=input$var_name,
          databaseStart=input$db,
          variableStart=paste0(input$db,"::",input$var),
          typeStart="cat",
          typeEnd="cat",
          recStart="else",
          recEnd="copy",
          catStartLabel=NA,
          catLabel=NA,
          catLabelLong=NA,
          Notes=NA
        ))
        
        
      }}
    
    
    
    
    if(input$typeStart=="Continous" & input$typeEnd=="Categorical" & input$derived=="No"){
      
      recEnd<-vector(mode = "numeric")
      for (i in 1:input$categories) {
        recEnd<-rbind(recEnd,eval(parse(text=paste0("input$catF",i))))
      }
      recStart<-vector()
      for (i in 1:input$categories) {
        recStart<-rbind(recStart,paste0("[",eval(parse(text=paste0("input$min",i))),
                                        "," , eval(parse(text=paste0("input$max",i))),"]"))
      }
      
      newline<-isolate(data.frame(
        variable=rep(input$var_name,input$categories+1),
        databaseStart=rep(input$db,input$categories+1),
        variableStart=rep(paste0(input$db,"::",input$var),input$categories+1),
        typeStart=rep(ifelse(input$typeStart=="Continous", "cont","cat"),input$categories+1),
        typeEnd=rep(ifelse(input$typeEnd=="Continous", "cont","cat"),input$categories+1),
        recStart=c(recStart,"else"),
        recEnd=c(recEnd,"NA::b"),
        catStartLabel=NA,
        catLabel=NA,
        catLabelLong=NA,
        Notes=NA
      ))
    }
    
    if (input$derived=="Yes"){
      if(input$library=="Yes"){
        
        newline<-isolate(data.frame(
          variable=dvl()["variable"],
          databaseStart=rep(input$db,nrow(dvl())),
          variableStart=dvl()["variableStart"],
          typeStart=rep("cont",nrow(dvl())),
          typeEnd=dvl()["typeEnd"],
          recStart=rep("else",nrow(dvl())),
          recEnd=dvl()["recEnd"],
          catStartLabel=NA,
          catLabel=NA,
          catLabelLong=NA,
          Notes=NA
        ))
        
      }}
    
    
    
    
    if (input$derived=="Yes"){
      if(input$library=="No"){
        
        newline<-isolate(data.frame(
          variable=input$var_name,
          databaseStart=input$db,
          variableStart=paste0("DerivedVar::[",paste0(input$components, collapse = ","),"]"),
          typeStart="cont",
          typeEnd=ifelse(input$derived_type1=="Categorical","cat","cont"),
          recStart="else",
          recEnd=paste0("Func::",input$func),
          catStartLabel=NA,
          catLabel=NA,
          catLabelLong=NA,
          Notes=NA
        ))
        
        
        
      }}
    
    
    
    
    isolate(values$df<-rbind(values$df, newline))
    
  })
  
  
  derived_vars<-reactiveValues()
  
  derived_vars$df<-data.frame(
    variable_name=NA,
    components=NA,
    function_name=NA,
    function_code=NA,
    type=NA)
  output$derived_description<-renderTable({
    
    derived_vars$df[-1,]
  })  
  
  new<-observeEvent(input$Add,{
    
    if(input$derived=="Yes" & input$alreadyD=="No"){
      if(input$library=="No"){
        newrec<-isolate(data.frame( 
          variable_name=input$var_name,
          components=paste0("[",paste0(input$components, collapse = ","),"]"),
          function_name=input$func,
          function_code=input$func_code,
          type=ifelse(input$derived_type1=="Continous","cont","cat")
          
        )
        )
      }}
    
    if(input$derived=="Yes" & input$alreadyD=="No"){
      if(input$library=="No"){
        isolate(derived_vars$df<-rbind(derived_vars$df, newrec))
      }}
  })
  
  
  
  
  #observeEvent(input$Delete, {
  
  # values$df<-values$df[-(input$deleterow+2),]
  #derived_vars$df<-derived_vars$df%>%
  # filter(variable_name%in%values$df[["variable"]] )
  
  
  #})
  
  
  
  #observeEvent(input$Delete, {
  
  # values$df[,"row_num"]=c(seq(-1, nrow(values$df)-2))
  
  
  #})
  
  
  
  
  
  
  #### run derived function ###
  
  observeEvent(input$Add,{
    if (input$derived=="Yes"){
      if(input$library=="Yes"){
        
        for(i in 1:nrow(dvl())){
          
          assign(dvl()[i,"function_name"],eval(parse(text= dvl()[i,"function_code"])),envir = .GlobalEnv)
          
        }
        
      }}
  })
  
  
  
  envValues<-reactiveValues()
  
  
  observeEvent(input$Add, {
    
    if (input$derived=="Yes"){
      if(input$library=="No"){
        result<-eval(parse(text= input$func_code))
        
        envValues[[input$func]]<<-result
        
        tryCatch({
          
          assign(input$func,envValues[[input$func]], envir = .GlobalEnv)},
          error=function(e){
            
            paste("an error happened in your function code", e$message)
            
            return()
            
          },
          
          warning=function(w){
            
            paste("an error happened in your function code", w$message)
            
          }
        )
      }}
    
  })
  
  
  
  ### Clear name of the variable each time add is clicked to avoid user errors
  
  observeEvent(input$Add, {
    
    updateTextInput(session, "var_name", value = "")
    
  })
  
  observeEvent(input$update_t,{
    
    updateSelectizeInput(session,"tablename1","Please choose the name of the table in the database",dbListTables(dbConnect(RSQLite::SQLite(),dbname=input$path1)))
    
  })
  
  
  output$table<-renderRHandsontable({
    
    #if(input$alreadyD=="Yes"){
    
    # alreadyD()
    #}
    
    #else if (input$alreadyD=="No"){
    rhandsontable(values$df[-1,],rowHeaders = NULL)
    #}
    
  })
  
  observeEvent(input$table, {
    updated_data <- hot_to_r(input$table)
    values$df<-rbind(data.frame(variable="a",
                                databaseStart="a",
                                variableStart="a",
                                typeStart="a",
                                typeEnd="a",
                                recStart="a",
                                recEnd="a",
                                catStartLabel="a",
                                catLabel="a",
                                catLabelLong="a",
                                Notes="a"),updated_data)
  })
  
  
  
  
  df2<-reactive({
    data.frame(variable="a",
               databaseStart="a",
               variableStart="a",
               typeStart="a",
               typeEnd="a",
               recStart="a",
               recEnd="a",
               catStartLabel="a",
               catLabel="a",
               catLabelLong="a",
               Notes="a",
               label="a",
               labelLong="a",
               units="a")%>%
      rbind(
        values$df[-1,]%>%
          mutate(label=NA, labelLong=NA, units=NA))%>%
      slice(-1)%>%
      group_by(variable)%>%
      slice_head()%>%
      ungroup()%>%
      #arrange(row_num)%>%
      select(variable, databaseStart, variableStart, typeEnd,label,labelLong,units)%>%
      rename(variableType=typeEnd)
    
    
    
    
  })
  
  
  output$VariablesSheet<-renderRHandsontable({
    
    #if(input$alreadyV=="Yes"){
    
    # alreadyV()
    #}
    
    #else if (input$alreadyV=="No"){
    
    
    rhandsontable(df2(),rowHeaders = NULL)
    
    
    #}
  })
  
  
  output$cont_mis_min<- renderUI({
    
    if (input$cont_miss=="Yes" & input$typeEnd=="Continous"  & input$typeStart=="Continous" & input$derived=="No") {
      
      numericInput("min", "Lowerbound", value=0)
    }
    
    else if(input$typeStart=="Continous" & input$typeEnd=="Categorical" & input$derived=="No" ){
      
      lapply(1:input$categories, function(i){
        
        textInput(paste0("min",i),paste("Lowerbound",i))
        
      })
      
      
    }
    
  })
  
  
  output$cont_mis_max<- renderUI({
    
    if (input$cont_miss=="Yes" & input$typeEnd=="Continous"& input$typeStart=="Continous" & input$derived=="No" ) {
      
      numericInput("max", "Upperbound", value=0)
      
    }
    
    else if(input$typeStart=="Continous" & input$typeEnd=="Categorical" & input$derived=="No" ){
      
      lapply(1:input$categories, function(i){
        
        textInput(paste0("max",i),paste("Upperbound",i))
        
      })
    }
    
    
  })
  
  output$download_data <- 
    downloadHandler(
      filename= function() { paste0("details_sheet","_",Sys.time(),".csv")
        
      },
      
      content = function(file){
        
        write.csv(values$df[-1,],file,row.names = FALSE)
      }
    )
  output$download_data2 <- downloadHandler(
    filename= function() { paste0("Variable_sheet",Sys.time(),".csv")
      
    },
    
    content = function(file){
      
      write.csv(df2(),file,row.names = FALSE)
    }
  )
  
  output$download_description <- 
    downloadHandler(
      filename= function() { paste0("Derived_vars_description",Sys.time(),".csv")
        
      },
      
      content = function(file){
        
        write.csv(derived_vars$df[-1,],file,row.names = FALSE)
      }
    )
  
  
  finalD<-reactive({
    
    # if(input$alreadyD=="Yes"){
    
    #  alreadyD()
    
    #}
    #  else if (input$alreadyD=="No"){
    
    values$df[-1,]
    
    
    # }
    
  })
  
  
  finalV<-reactive({
    
    # if(input$alreadyV=="Yes"){
    
    #  alreadyV()
    
    #  }
    # else if (input$alreadyD=="No"){
    
    df2()
    
    
    # }
    
  })
  
  
  ### sql import only required variables ###
  
  variablesToImport<-reactive({
    
    # if(input$alreadyV=="Yes"){
    
    #  alreadyV()%>%
    #   filter(!str_detect(variableStart,"DerivedVar"))%>%
    #  mutate(variableStart=gsub("\\[|\\]","",variableStart ))%>%
    # mutate(variableStart=sub(".*::","", variableStart))%>%
    #distinct(variableStart)%>%
    #pull()
    
    #}
    
    #else if (input$alreadyV=="No"){
    
    
    df2()%>%
      filter(!str_detect(variableStart,"DerivedVar"))%>%
      mutate(variableStart=gsub("\\[|\\]","",variableStart ))%>%
      mutate(variableStart=sub(".*::","", variableStart))%>%
      distinct(variableStart)%>%
      pull()
    
    
    # }
    
    
  })
  
  #####################################################
  ############################Summary Panel ###########
  #####################################################
  
  
  table<-eventReactive(input$showsummary,{ 
    
    if(input$importType==".SQLite") {
      
      withProgress( tbl(dbConnect(RSQLite::SQLite(),dbname=input$path1),input$tablename1 )%>%
                      select_at(input$var)%>%
                      collect())
    }
    
    else if(input$importType=="Large pipe-delimited CSVs" & input$singleorgroup=="Single") {
      fread(input$path1, select = input$var,sep="|")
      
    }
    
    else if(input$importType=="Large pipe-delimited CSVs" & input$singleorgroup=="Multiple") {
      shinyjs::alert("The summary stats does not work 
                       when the data is splitted to multiple files. Please select a single file.")
    }
    
    else if (input$importType%in%c("Comma-delimited CSVs",".RDS",".sas7bdat" )) {
      
      withProgress( dataframe()%>%
                      select_at(input$var)
      )
      
    }
    
  })
  
  distincts<-eventReactive(input$showsummary,{
    
    table()%>%
      unique()%>%
      nrow()
  })
  
  
  summarys<-eventReactive(input$showsummary,{
    
    table()%>%
      summary()
  })
  
  frequencies<-eventReactive(input$showfreq,{
    withProgress( table()%>%
                    group_by_at(input$var)%>%
                    count())
  }
  )
  
  output$DistinctVals<-renderPrint({
    
    paste("Distinct values:", distincts())
    
  })
  
  output$levels<-renderPrint({
    
    summarys()
    
  })
  
  output$freq_table<-renderTable({
    
    frequencies()
    
  })
  
  
  ####################################
  #######rec_with table ##############
  ####################################
  
  df_recoded<- eventReactive(input$recode,{
    
    if(input$importType%in% c("Comma-delimited CSVs",".RDS",".sas7bdat")){
      tryCatch(rec_with_table(dataframe(),variables =finalV(), variable_details =finalD(),database_name =input$db)%>%cbind(dataframe()%>%select_at(input$cbind)))
      
    }
    
    
    else if (input$importType== "Large pipe-delimited CSVs" & input$singleorgroup=="Single"){
      
      csv_chunk(file_input = input$path1,file_output = input$pathtowrite1, chunk_size =input$chunksize1, var_sheet = finalV(), var_details =finalD(), db_name = input$db, var=input$var )
    }
    
    else if (input$importType== "Large pipe-delimited CSVs" & input$singleorgroup=="Multiple"){
      
      csv_chunk_multiple(file_input = input$pathtofolder, file_output =input$pathtofolderwrite ,chunk_size =input$chunksize1, var_sheet = finalV(), var_details =finalD(), db_name = input$db, var=input$var )
    }
    
    
    
    else if(input$importType== ".SQLite") {
      recodeflow_sqlChunk(dbConnect(RSQLite::SQLite(),dbname=input$path1),finalV(),finalD(),input$tablename1,input$chunksize1,input$newname1, input$db,variables = paste(variablesToImport(),collapse = "," ))
    }
    
  })
  
  
  output$recodedtable<-renderTable({
    
    head(df_recoded())
    
    
    
  })
  
}

shinyApp(ui, server)

