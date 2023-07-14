
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
           "haven", "recodeflow", "stringr", "dplyr")

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
  
  shinyjs::useShinyjs(),
  
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
  sidebarLayout(
    
    sidebarPanel(
      textInput("db", "Choose an optional name for your original dataset"),
      uiOutput("variable"),
      textInput("var_name","Type your preferred name of the variable in the recoded dataset"),
      radioButtons("derived",label = "Derived Variable?", choices = c("Yes","No"), selected = "No" , inline = TRUE),
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
      actionButton("Add","Add to table"),
      numericInput("deleterow", "enter the row number to be deleted", value = 1),
      actionButton("Delete","Delete the row (variable details)"),
        
      tags$div(
        style = "text-align: center; margin-top: 20px;",
        
        HTML(
          '<p style="font-size: smaller; font-style: italic; color: #4a90e2;">',
          'This app was developed by Arian Aminoleslami in June 2023',
          'and released under the GNU General Public License v3.0.</p>',
          '<p style="font-size: smaller; font-style: italic; color: #4a90e2;">',
          'For inquiries or questions, please write to: ',
          '<a href="mailto:arian.aminoleslami@uwaterloo.ca" style="color: #4a90e2;">arian.aminoleslami@uwaterloo.ca</a>',
          
        ),
                 
        tags$img(src = "logo1.png", width = "300px")
      )
     # Credits and logos
       
      
      
       
      
    ),

    mainPanel(
      tabsetPanel(
        
        tabPanel("Recodeflow", 
                 radioButtons("importType", "Please choose the format of your original dataset" ,choices = c(".csv",".RDS",".sas7bdat",".SQLite"), selected = ".csv"),
                 uiOutput("import"),
                 tableOutput("test"),
                 tableOutput("recodedtable"),
                 uiOutput("path"),
                 uiOutput("tablename"),
                 br(),
                 uiOutput("update"),
                 uiOutput("newname"),
                 #uiOutput("importedvars"),
                 uiOutput("chunksize"),
                 uiOutput("addmorevars"),
                 actionButton("recode","Recode the dataset!"),
                 uiOutput("downloadType"),
                 uiOutput("downloadRecoded"),
                 br(),
                 uiOutput("show_recoded_sqlite"),
                 tableOutput("recodedtable_sql")
                 
        ),
        
        
        
        tabPanel("Variable Details Sheet",
                 radioButtons("alreadyD","Already have a .csv Variable Details sheet?", c("Yes","No"), selected = "No"),
                 uiOutput("upD"), 
                 tableOutput("table"),
                 downloadButton("download_data","Download .csv file!")),
        
        tabPanel("Variable Sheet",
                 #radioButtons("alreadyV","Already have a .csv Variable sheet?", c("Yes","No"), selected = "No"),
                 uiOutput("upV"),
                 tableOutput("VariablesSheet"),
                 downloadButton("download_data2","Download .csv file!") ),
        
        
        tabPanel("Summary", 
                 br(),
                 br(),
                 
                 actionButton("showsummary","Extract the variable"),
                 verbatimTextOutput("levels"),
                 verbatimTextOutput("DistinctVals")
                 ,
                 
                 br(),
                 br(),
                 br(),
                 br(),
                 
                 fluidRow(
                   column(3,actionButton("showfreq","Frequency table" )),
                   column(3, tableOutput("freq_table"))
                 )
                 
                 
        ),
        
        tabPanel("Derived variables description",
                 
                 tableOutput("derived_description"),
                 downloadButton("download_description","Download .csv file!") 
                 
        )
        
      )
    )
  )
)







server <- function(input, output, session) {
  
  options(shiny.maxRequestSize= 1000*1024^2)
  
  #### disable action button if new name variable is empty ###
  
  observe({
    if(input$var_name==""  ){
      shinyjs::disable(id= "Add")}
    
    else{
      
      shinyjs::enable(id ="Add")
      
    }
    
  })
  
  
  
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
    
    if(input$importType%in% c(".csv",".RDS",".sas7bdat" )){
      
      radioButtons("downloadType1", "Please choose the format of your recoded dataset",choices = c(".csv",".RDS"))
      
    }
    
    
  })
  
  output$downloadRecoded<-renderUI({
    
    if(input$importType%in% c(".csv",".RDS",".sas7bdat" )){
      
      downloadButton("downloadrecoded","Download your recoded dataset!")
      
    }
    
  })
  
  
  output$addmorevars<-renderUI({
    
    if(input$importType%in% c(".csv",".RDS",".sas7bdat" )){
      
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
    filename= function() { paste0(file_name(),"_","recoded",Sys.Date(),"_",format(Sys.time(), "%H-%M-%S"),ifelse(input$downloadType1==".csv",".csv",".RDS"))
      
    },
    
    content = function(file){
      if (input$downloadType1==".csv"){
        
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
    if(input$importType==".SQLite"){
      
      textInput("path1", "Please enter the path to the database", value = "")
      
    }
    
  })
  
  output$newname<-renderUI({
    if(input$importType==".SQLite"){
      
      textInput("newname1", "Please enter your preferred name of the new recoded table in the database")
      
    }
    
  })
  
  con<-reactive({
    a<-tbl(dbConnect(RSQLite::SQLite(),dbname=input$path1),input$tablename1)
  })
  names_orig<-reactive({
    
    namesss<-colnames(con())
    
  })
  
  output$importedvars<-renderUI({
    if(input$importType==".SQLite"){
      
      selectizeInput("importedvars1","please choose the variables of the dataset to be imported and used in recoding", choices=names_orig(), multiple=TRUE   )
    }
  })
  
  output$chunksize<-renderUI({
    if(input$importType==".SQLite"){
      
      numericInput("chunksize1", "choose the size of chunk", min=100000, max=10000000, step=100000, value = 100000)
      
    }
  })
  
  ############
  #############
  
  
  #######
  output$import<-renderUI({
    
    if (input$importType==".csv"){
      
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
    
    if (input$importType==".csv"){
      
      basename(file$datapath)
      
    }
    
  })
  
  file_name<-reactiveVal(NULL)
  
  dataframe<-reactive({
    
    if (input$importType==".csv"){
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
    
    head(dataframe())
    
  })
  
  names<-reactive({
    
    if(input$importType==".SQLite") {
      
      d<-tbl(dbConnect(RSQLite::SQLite(),dbname=input$path1),input$tablename1 )%>%
        colnames()
    }
    
    else if (input$importType!=".SQLite") {
      
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
  
  output$func_name<-renderUI({
    
    if(input$derived=="Yes"){
      
      textInput("func","Please type the name of your function")
      
    }
  })
  
  output$func_code1<-renderUI({
    if(input$derived=="Yes"){
      
      textAreaInput("func_code","Please enter the function's code", placeholder = "e.g. function(a,b) {a+b}")
      
    }
  })
  
  
  output$derived_type<-renderUI({
    if(input$derived=="Yes"){
      
      radioButtons("derived_type1",label = "what is the type of the derived variable?", choices = c("Categorical","Continous"), selected = "Continous" , inline = TRUE)
      
    }
  })
  
  
  output$warning_n<-renderUI({
    if(input$derived=="Yes"){
      if(input$func==""){
        
        tags$span(style= "color:orange;", "Warning: The function name cannot be empty!")
        
      }}
    
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
      
      selectizeInput("components","Please choose the components of the derived variable",choices=unique(values$df[-1,"variable"]), multiple=TRUE )
      
    }
  })
  
  
  
  output$typeStart<-renderUI({
    
    if(input$derived=="No"){
      
      radioButtons("typeStart",label = "what is the type of variable in the original dataset", choices = c("Categorical","Continous"), selected = "Continous" , inline = TRUE)
    }
  })
  
  output$typeEnd<-renderUI({
    
    if(input$derived=="No"){
      
      radioButtons("typeEnd",label = "what is the type of variable in the recoded dataset", choices = c("Categorical","Continous"), selected = "Continous" , inline = TRUE)
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
      
      values$df <-rbind(data.frame(row_num=NA,
                                   variable=NA,
                                   databaseStart=NA,
                                   variableStart=NA,
                                   typeStart=NA,
                                   typeEnd=NA,
                                   recStart=NA,
                                   recEnd=NA,
                                   catStartLabel=NA,
                                   catLabel=NA,
                                   catLabelLong=NA,
                                   Notes=NA),
                        
                        
                        alreadyD()%>%
                          mutate(row_num=1:(nrow(alreadyD())))%>%
                          mutate(row_num=row_num-1)%>%
                          relocate(row_num, .before=1)
      )
    }
    
    else{
      values$df <- data.frame(row_num=NA,
                              variable=NA,
                              databaseStart=NA,
                              variableStart=NA,
                              typeStart=NA,
                              typeEnd=NA,
                              recStart=NA,
                              recEnd=NA,
                              catStartLabel=NA,
                              catLabel=NA,
                              catLabelLong=NA,
                              Notes=NA)
    }
    
    
  })
  
  
  
  
  
  newentry<-observeEvent(input$Add, {
    
    if(input$typeEnd=="Continous" & input$typeStart=="Continous" & input$cont_miss=="Yes"){
      newline<-isolate(data.frame(row_num=c(nrow(values$df)-1,nrow(values$df)),
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
      newline<-isolate(data.frame(row_num=nrow(values$df)-1,
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
      
      newline<-isolate(data.frame(row_num=seq(nrow(values$df)-1,(nrow(values$df)-1+input$categories)),
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
        newline<-isolate(data.frame(row_num=nrow(values$df)-1,
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
      
      newline<-isolate(data.frame(row_num=seq(nrow(values$df)-1,(nrow(values$df)-1+input$categories)),
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
      
      
      newline<-isolate(data.frame(row_num=nrow(values$df)-1,
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
      
      
      
    }
    
    
    
    
    isolate(values$df<-rbind(values$df, newline))
    
  })
  
  
  derived_vars<-reactiveValues()
  
  derived_vars$df<-data.frame(
    variable_name=NA,
    function_name=NA,
    function_code=NA)
  output$derived_description<-renderTable({
    
    derived_vars$df[-1,]
  })  
  
  new<-observeEvent(input$Add,{
    
    if(input$derived=="Yes" & input$alreadyD=="No"){
      
      newrec<-isolate(data.frame( 
        variable_name=input$var_name,
        function_name=input$func,
        function_code=input$func_code
        
      )
      )
    }
    
    if(input$derived=="Yes" & input$alreadyD=="No"){
      isolate(derived_vars$df<-rbind(derived_vars$df, newrec))
    }
  })
  
  
  
  
  observeEvent(input$Delete, {
    
    values$df<-values$df[-(input$deleterow+2),]
    derived_vars$df<-derived_vars$df%>%
      filter(variable_name%in%values$df[["variable"]] )
    
    
  })
  
  
  
  observeEvent(input$Delete, {
    
    values$df[,"row_num"]=c(seq(-1, nrow(values$df)-2))
    
    
  })
  
  
  
  
  
  
  #### run derived function ###
  
  envValues<-reactiveValues()
  
  observeEvent(input$Add, {
    
    if (input$derived=="Yes"){
      
      result<-eval(parse(text= input$func_code))
      
      envValues[[input$func]]<<-result
      
      tryCatch({
        
        assign(input$func,envValues[[input$func]], envir = .GlobalEnv)},
        error=function(e){
          
          paste("an error happened in ypur function code", e$message)
          
          return()
          
        },
        
        warning=function(w){
          
          paste("an error happened in ypur function code", w$message)
          
        }
      )
    }
    
  })
  
  
  
  ### Clear name of the variable each time add is clicked to avoid user errors
  
  observeEvent(input$Add, {
    
    updateTextInput(session, "var_name", value = "")
    
  })
  
  observeEvent(input$update_t,{
    
    updateSelectizeInput(session,"tablename1","Please choose the name of the table in the database",dbListTables(dbConnect(RSQLite::SQLite(),dbname=input$path1)))
    
  })
  
  
  output$table<-renderTable({
    
    #if(input$alreadyD=="Yes"){
    
    # alreadyD()
    #}
    
    #else if (input$alreadyD=="No"){
    values$df[-1,]
    #}
    
  })
  df2<-reactive({
    
    values$df[-1,]%>%
      group_by(variable)%>%
      slice_head()%>%
      arrange(row_num)%>%
      select(variable, databaseStart, variableStart, typeEnd)%>%
      rename(variableType=typeEnd)%>%
      mutate(label=NA, labelLong=NA, units=NA)
    
    
    
  })
  
  
  output$VariablesSheet<-renderTable({
    
    #if(input$alreadyV=="Yes"){
    
    # alreadyV()
    #}
    
    #else if (input$alreadyV=="No"){
    
    
    df2()
    
    
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
        
        write.csv(values$df[-1,-1],file,row.names = FALSE)
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
    
    values$df[-1,-1]
    
    
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
    
    else if (input$importType!=".SQLite") {
      
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
    
    if(input$importType%in% c(".csv",".RDS",".sas7bdat")){
      tryCatch(withProgress(  rec_with_table(dataframe(),variables =finalV(), variable_details =finalD(),database_name =input$db)%>%cbind(dataframe()%>%select_at(input$cbind)), message = "Please wait!"), error=function(e){
        return(paste("error:", e$message))
      })
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
