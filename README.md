
![logo1](https://github.com/ArianAminoleslami/EHRs-Data-Harmonization-Platform/assets/137816738/afc4e81d-1bc7-4812-80e7-d2ff8b98da73)

# EHRs Data Harmonization Platform
## Description
The EHRs Data Harmonization Platform is a user-friendly, simple, easy-to-use Shiny app developed in R that can be used to harmonize data derived from electronic health records (EHRs).  

## Usage instructions
To use this Shiny app on your computer, please follow these steps:
1. Install [RStudio](https://www.rstudio.com/categories/rstudio-ide/) on your computer;
2. Download the repository from GitHub. Via browser: click on **Code** and then click on [Download ZIP](https://github.com/ArianAminoleslami/EHRs-Data-Harmonization-Platform/archive/refs/heads/main.zip). Or via terminal shell: run the command `git clone https://github.com/ArianAminoleslami/EHRs-Data-Harmonization-Platform.git`  
3. Go to the [App](https://github.com/ArianAminoleslami/EHRs-Data-Harmonization-Platform/tree/main/App) folder and open the `App_v...` file with RStudio;
4. On RStudio, click on **Run App**;
5. The Shiny app interface of the EHRs Data Harmonization Platform
should appear on RStudio (see below).

<img width="724" alt="image" src="https://github.com/ArianAminoleslami/EHRs-Data-Harmonization-Platform/assets/137816738/650a9276-bcc1-4946-b979-fec235f9c50d">


The just-described instructions should work on Linux, Microsoft Windows, and Mac operating systems.


# An Overview of the Platform and Its Features
The Shiny app has 5 main tabs:

## Recodeflow Tab
The “Recodeflow” tab is where we connect/upload the non-curated database. Using the sidebar panel and updating the “variable details sheet” and “variable sheet”, we can determine the output of the recoded dataset and start the recoding process by clicking on the “recoded” data.

## Summary Tab
One important step in curation is to understand how a variable really looks in a non-curated database. The “summary” tab allows users to extract information about a variable in the database, see the distribution of different categories, and gain a better understanding of the variable they wish to recode.

## Derived Variables Documentation Tab
The “derived variables documentation” tab stores the information of derived variables which use a pre-programmed, custom function. This includes the R code of the function and the name of the function. This tab's functionality will be illustrated in an example.

## Credits
The EHRs Data Harmonization Platform is mainly based on the [recodeflow](https://big-life-lab.github.io/recodeflow/) R package and is released for free here on GitHub under the GPL-3.0 license.

## Contacts
The EHRs Data Harmonization Platform was developed and is maintained by Arian Aminoleslami. For inquiries or questions, please write an email to: aaminoleslami@uwaterloo.ca
