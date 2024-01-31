**README.md**


# Application Data Cleaning and Rating Calculation

In this notebook, I've addressed several tasks related to application data stored in the 'applications.csv' file using **Pandas** and  **Matplotlib**  libraries in Python.
Here's what I've done:

# Task Overview

1. **Data Cleaning:**
   - Eliminated duplicate entries based on the 'applicant_id' column.
   - Filled missing values in the 'External Rating' field with zeros.
   - Populated missing values in the 'Education level' field with "Середня" (average).

2. **Data Augmentation:**
   - Integrated data from the 'industries.csv' file, specifically industry ratings.

3. **Rating Calculation:**
   - Computed the application rating based on predefined criteria.
   - Ensured the rating falls within the range of 0 to 100.
   - Considered various factors such as age, submission day, marital status, location, industry score, and external rating.

4. **Data Analysis:**
   - Grouped the resulting dataset by the weekday of application submission.
   - Visualized the average rating of accepted applications for each weekday.


## Project Structure


- [applications.csv](https://drive.google.com/file/d/1m3HxqewNhxYvx5CTkqDWd3rLqb-jjM3w/view) - file with applicants information;
- [industries.csv](https://drive.google.com/file/d/1Cww0UgohJ4UqvjYsEi_c0ApJS-UAigrD/view) - file with industries scores;
- **Python-Data Cleaning.ipynb:** Jupyter Notebook containing the code for data analysis and visualization.

Project's focus was on cleaning the data and computing the application rating, aiming to analyze and visualize the average ratings over time.
