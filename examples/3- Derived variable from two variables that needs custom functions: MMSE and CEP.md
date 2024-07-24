## Example: Creating a Derived Variable with a Custom Function

In this last use case, we will see an example of a derived variable with a pre-programmed, custom function. *recodeflow* supports the use of any custom functions as long as the variable can be calculated on a per row basis.

Let us suppose we would like to have a feature that indicates both the MMSE category and the education level of the patients, which is recorded in the dataset through the CEP factor. CEP = 1 means that the patient graduated from primary school, and CEP = 0 means he or she did not.

It might be useful to have a derived feature that indicates both the MMSE category and the CEP status.

|                           | **severe cognitive**          | **moderate cognitive**       | **mild cognitive**        | **normal**                |
|---------------------------|-------------------------------|------------------------------|---------------------------|---------------------------|
| **impairment**            |                               |                              | impairment                | condition                 |
| **graduated**             | severe cognitive              | moderate cognitive           | mild cognitive            | normal                    |
|                           | impairment and graduated      | impairment and graduated     | impairment and graduated  | and graduated             |
| **non-graduated**         | severe cognitive              | moderate cognitive           | mild cognitive impairment | normal                    |
|                           | impairment and non-graduated  | impairment and non-graduated | non-graduated             | and non-graduated         |

*Table of the MMSE-CEP values. Each patient can have one of these eight values for the derived variable MMSE-CEP*

To generate this derived feature, we can use the `MMSE_category` variable we produced in the previous step, and we need to create a new recoded feature for CEP, too. As per the rules of *recodeflow*, a derived variable can be created only from recoded variables.

We follow the steps described in the previous section and generate a recoded variable called `CEP_bin`, which has the value `graduated` when CEP equals 1 and has the value `non-graduated` when CEP equals 0.

To create a new derived feature based on `MMSE_category` and `CEP_bin`, we follow these steps:

1. Write `MMSE-CEP` in the "Type your preferred name of the variable in the recoded dataset" field.
2. In the "Derived Variable?" field, select Yes.
3. In the "Please enter the function's code" field, insert the R code of the function that needs to create the new feature. In our case:
   ```r
   function(MMSE_category, CEP_bin) { return(paste0(MMSE_category, "_", CEP_bin)) }
