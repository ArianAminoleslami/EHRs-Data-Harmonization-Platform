## Example: Mapping MMSE Numerical Feature to MMSE Category

Let us explain a use case where a user would like to map the mini mental state examination (MMSE) numerical feature into an MMSE category in the Paquid dataset.
In the original Paquid dataset, the MMSE comes as a number between 0 and 30, with higher scores indicating better cognitive function. 
We can categorize the total scores into ranges, such as:

- 0-9: severe cognitive impairment;
- 10-17: moderate cognitive impairment;
- 18-23: mild cognitive impairment (MCI);
- 24-30: normal.

Now we would like to create a new categorical feature that indicates these four pieces of information from the MMSE numerical variable.

To do so, we can follow these steps:

1. Select **MMSE** in the "Choose a variable to be recoded" field;
2. Choose a name for the recoded variable (**MMSE_category**) and write it in the "Type your preferred name of the variable in the recoded dataset" field;
3. Enter 4 in the "Enter the number of categories" field;
4. Select No in the "Derived Variable" to state ours is not a derived feature;
5. Select **continuous** in the "What is the type of variable in the original dataset" to state that the input MMSE variable is numerical;
6. Select **categorical** in the "What is the type of variable in the recoded dataset" to state that our desired output MMSE category variable is categorical;
7. Indicate the intervals of the values of the input MMSE variable in the "Lowerbound 1", "Upperbound 1", ..., "Lowerbound 4", and "Upperbound 4" fields: 0 and 9, 10 and 17, 18 and 23, and 24 and 30;
8. Indicate the corresponding new four categories of the MMSE category variable in the "Final category 1", ..., "Final category 4" fields: severe cognitive impairment, moderate cognitive impairment, mild cognitive impairment, and normal, respectively;
9. Select 0 for the "Enter the row number to be deleted" field;
10. Click on the "Add to table" button;
11. In the "Do you want to add more columns from the original dataset to your recoded dataset?", select the names of all the original variables;
12. Click on the "Recode the dataset" button.

This is a good example to discuss how recodeflow handles missing values. Recodeflow has a standard approach to handle missing values, by recoding missing data categories values into 3 NA values that are commonly used for most studies:

- NA(a) = 'not applicable'
- NA(b) = 'missing'
- NA(c) = 'not asked'

In this example, we will specify that any categories other than what we specified, should be categorized as NA(b) or missing.

<br><br>

<div style="text-align: center;">
<img width="620" alt="categorize" src="https://github.com/user-attachments/assets/b0af4321-001d-4a5a-985b-5559b667cad3">
</div>

Figure shows the steps we followed for this example and how the missing values are handled in the details sheet. Note that labels and notes are not mandatory fields of the details sheet, so there are no inputs for them on the app and users can modify them on the table’s relevant cell if they prefer to.



