
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


## An Overview of the Platform and Its Features

The Shiny app has 5 main tabs:

- **Recodeflow, variable and variable details sheet Tabs**:
  - Connect/upload the non-curated database.
  - Use the sidebar panel to update the “variable details sheet” and “variable sheet”.
  - Determine the output of the recoded dataset.
  - Start the recoding process by clicking on the “recoded” data.

- **Summary Tab**:
  - Extract information about a variable in the database.
  - See the distribution of different categories.
  - Gain a better understanding of the variable to be recoded.
  
  <br><br>

  <div style="text-align: center;">
    <img width="433" alt="Summarytab" src="https://github.com/user-attachments/assets/aed39b3d-ff4f-4739-b538-3335c3b7a1a4">
  </div>


- **Derived Variables Documentation Tab**:
  - Store information of derived variables using pre-programmed, custom functions.
  - Include the R code of the function and the name of the function.
# Credits
The EHRs Data Harmonization Platform is mainly based on the [recodeflow](https://big-life-lab.github.io/recodeflow/) R package and is released for free here on GitHub under the GPL-3.0 license.

# Contacts
The EHRs Data Harmonization Platform was developed and is maintained by Arian Aminoleslami. For inquiries or questions, please write an email to: aaminoleslami@uwaterloo.ca
