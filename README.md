# Amazon Revenue Analysis (2021)


## Background 

The goal of this project is to analyze the 2021 revenue of US users in order to surface recommendations for product and marketing strategies. This dataset contains purchases data with 1000K records from 5027 Amazon.com users, spanning 2018 through 2022. 
Tableau dashboard can be found [here](https://public.tableau.com/app/profile/shin.p1459/viz/AmazonRevenueAnalysis2021/AmazonRevenueAnalysis).<br><br>

![Image](https://github.com/user-attachments/assets/9dbba1c9-7401-4c15-adc8-05da4b05dca8)


## Dataset Structure

Each row in this file corresponds to an Amazon order, and consists of the following: 
- Survey ResponseID
- Order date
- Shipping address state
- Purchase price per unit
- Quantity
- ASIN/ISBN (Product Code)
- Title
- Category

#### Reference
Berke, A., Calacci, D., Mahari, R. Yabe, T., Larson, K., & Pentland, S. Open e-commerce 1.0, five years of crowdsourced U.S. Amazon purchase histories with user demographics. Sci Data 11, 491 (2024). https://doi.org/10.1038/s41597-024-03329-6


## Insights Summary

#### Revenue trend
- Although revenue is growing YoY, growth rate is slowing down since the peak of COVID.

#### Revenue by time
- Across all years, November and December had the highest revenue, likely driven by Black Friday and the Christmas holiday season.
- Interestingly, there is an unsual pattern in March 2021 where it had a significant spike in revenue at $1000K - investigate what happened internally or externally.

#### Revenue by category
- March saw a huge growth for revenue in **computer sales** at $31K. This is likely correlated to price growth at 29% YoY whereas # of purchases sold has grown at 0%.
- **Book sales** is consistently the top category throughout the year.


## Key recommendations

- Computer sales have an outsized impact on revenue, but the average purchase per user is low ( ≈ 1.19 computer per user in 2021). Consider increasing the budget to attract new users instead of existing users, such as advertising in regions with lower-than-average computer purchases.
- Book sales remain the strongest revenue-driving category, with users buying more frequently ( ≈ 6.48 books per user in 2021). To boost sales further, consider product strategies like cross selling in Amazon ecosystem - i.e. prompting Audible users to buy a physical copy after finishing an audiobook. 
