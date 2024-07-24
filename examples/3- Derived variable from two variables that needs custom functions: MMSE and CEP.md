## Example: Creating a Derived Variable with a Custom Function

In this use case, we will see an example of a derived variable with a pre-programmed, custom function. *recodeflow* supports the use of any custom functions as long as the variable can be calculated on a per row basis.

Let us suppose we would like to have a feature that indicates both the MMSE category and the education level of the patients, which is recorded in the dataset through the CEP factor. CEP = 1 means that the patient graduated from primary school, and CEP = 0 means he or she did not.

It might be useful to have a derived feature that indicates both the MMSE category and the CEP status.


<br>

<div style="text-align: center;">
<img width="631" alt="image" src="https://github.com/user-attachments/assets/c727d0fb-5a4e-4bec-8d57-60ec4759e8da">
</div>
<br>
To generate this derived feature, we can use the `MMSE_category` variable we produced in the previous step, and we need to create a new recoded feature for CEP, too. As per the rules of *recodeflow*, a derived variable can be created only from recoded variables.

We follow the steps described in the previous section and generate a recoded variable called `CEP_bin`, which has the value `graduated` when CEP equals 1 and has the value `non-graduated` when CEP equals 0.

To create a new derived feature based on `MMSE_category` and `CEP_bin`, we follow these steps:

1. Write `MMSE-CEP` in the "Type your preferred name of the variable in the recoded dataset" field.
2. In the "Derived Variable?" field, select Yes.
3. In the "Please enter the function's code" field, insert the R code of the function that needs to create the new feature. In our case:
   ```r
   function(MMSE_category, CEP_bin) { return(paste0(MMSE_category, "_", CEP_bin)) }
4. Write MMSECEPfunction in the "Please type the name of your function" field.
5. In the "Please choose the components of the derived variable" field, select MMSE_cat and CEP_bin.
6. Select categorical in the "What is the type of the derived variable?" field.
7. Select 0 in the "Enter the row number to be deleted" field.
8. Click on "Add to table".
9. In the central lower menu, select all the features of the dataset in the "Do you want to add more columns from the original dataset to your recoded dataset?" field.
10. Click on "Recode this dataset!"
11. At this point, the new column MMSE-CEP should appear in the header of the recoded dataset.
12. Click on "Download the recoded dataset!" and save the dataset file in CSV format.

<img width="678" alt="detailssheet" src="https://github.com/user-attachments/assets/fca9bcac-f3f2-4f01-a1b4-41cfd49ddf45">

