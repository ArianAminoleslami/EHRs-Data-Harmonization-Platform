## Example: Renaming and Recoding a Variable

One of the most common curations in databases is to rename a variable. In our example, there’s a “male” variable in the Paquid dataset which gets binary values of 0, 1. We want to first rename the variable to “sex” and then recode it so that 0 represents “Female” and 1 represents “Male”. To do so, follow these initial steps:

1. Upload the Paquid dataset by selecting `.csv`, clicking on “Browse”, and selecting the `paquid.csv` file on your computer. This CSV file is available within our GitHub repository (see the “Data availability” section).
2. (Optional) Name this dataset "Paquid" by writing it in the “Choose an optional name for your original dataset” field.

After these preliminary steps, follow these steps:

3. Choose the “male” variable.
4. Type our preferred new name for the variable, which is “sex”.
5. Choose the original and recoded data type, which is Categorical to Categorical.
6. Enter the number of categories, which is 2, and specify how categories should be recoded.

Once all these steps are done, add the information to the details sheet by clicking on the “add to table” button.


<img width="353" alt="Gender" src="https://github.com/user-attachments/assets/aa6d45c5-00cb-4e55-9e95-469a6e5be4a7">
