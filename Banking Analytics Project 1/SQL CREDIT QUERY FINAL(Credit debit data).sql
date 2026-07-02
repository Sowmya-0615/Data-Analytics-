Create database Credit_Debit_KPI;
use Credit_Debit_KPI;

 CREATE TABLE bank_data
    (Customer_ID VARCHAR(50),
    Customer_Name VARCHAR(100),
    Account_Number BIGINT,
    Transaction_Date VARCHAR(30),
    Transaction_Type VARCHAR(20),
    Amount DECIMAL(15,2),
    Balance DECIMAL(15,2),
    Branch VARCHAR(100),
    Transaction_Method VARCHAR(50),
    Bank_Name VARCHAR(100),
    Credit_Amount DECIMAL(15,2),
    Debit_Amount DECIMAL(15,2),
    High_Risk_Flag VARCHAR(10),
    Month_Year VARCHAR(20)
    );



 
SET GLOBAL Local_infile=1;
LOAD DATA LOCAL INFILE "C:/Temp/Credit and Debit Data SQL.csv"
INTO TABLE bank_data
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS

(
Customer_Id,
Customer_Name,
Account_Number,
@Transaction_Date,
Transaction_Type,
Amount,
Balance,
Branch,
Transaction_Method,
Bank_Name,
Credit_Amount,
Debit_Amount,
High_Risk_Flag,
Month_Year
)
SET Transaction_Date = STR_TO_DATE(@Transaction_Date, '%d-%m-%Y');

select * from bank_data;
SELECT COUNT(*) FROM bank_data;



# 1 - Total Credit Amount
SELECT CONCAT(ROUND(SUM(Amount)/1000000.0,2),'M') AS Total_Credit_Amount
FROM bank_data
WHERE Transaction_Type = 'Credit';

# 2 - Total Debit Amount
SELECT CONCAT(ROUND(SUM(Amount)/1000000.0,2),'M') AS Total_Debit_Amount
FROM bank_data
WHERE Transaction_Type = 'Debit';

# 3 - Credit to Debit Ratio
SELECT CONCAT(ROUND(SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END)/NULLIF(SUM(CASE WHEN Transaction_Type = 'Debit'
THEN Amount ELSE 0 END),0),3),'M') AS Credit_to_Debit_Ratio
FROM bank_data;

# 4 - Net Transaction Amount
SELECT CONCAT(ROUND((SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END)-SUM(CASE WHEN Transaction_Type = 'Debit'
THEN Amount ELSE 0 END))/1000000.0,2),'M') AS Net_Transaction_Amount
FROM bank_data;

# 5 - ACCOUNT ACTIVITY RATIO
SELECT ROUND(COUNT(*)/Avg(Balance),2) as "Account Activity Ratio"
from bank_data;

# 6 - TRANSACTIONS PER MONTH 
SELECT IFNULL(Month_Year, 'Grand Total') AS Month,
CONCAT(ROUND(SUM(Amount)/1000000,2),'M') AS Total_Amount
FROM bank_data
GROUP BY Month_Year WITH ROLLUP
ORDER BY CASE WHEN Month_Year IS NULL THEN 1 ELSE 0 END,
SUM(Amount) DESC;

# 7 - TOTAL TRANSACTION AMOUNT BY BRANCH 
SELECT IFNULL(Branch, 'Grand Total') AS Branch,
CONCAT(ROUND(SUM(Amount)/1000000,2),'M') AS Total_Amount
FROM bank_data
GROUP BY Branch with rollup
ORDER BY CASE WHEN Branch IS NULL THEN 1 ELSE 0 END,
SUM(Amount) DESC;


# 8 - Transaction Volume by Bank 
SELECT IFNULL(Bank_Name, 'Grand Total') AS Bank_Name, 
CONCAT(ROUND(SUM(Amount)/1000000,2),'M') AS Total_Amount FROM bank_data
GROUP BY Bank_Name with rollup ORDER BY CASE WHEN Bank_Name IS NULL THEN 1 ELSE 0 END, SUM(Amount) DESC;

# 9 - Transaction Method Distribution
SELECT IFNULL(Transaction_Method, 'Grand Total') AS Bank_Name, 
CONCAT(ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM bank_data),2),'%') AS Transaction_Distribution FROM bank_data
GROUP BY Transaction_Method with rollup ORDER BY CASE WHEN Transaction_Method IS NULL THEN 1 ELSE 0 END, COUNT(*) DESC;

#10 - Branch Transaction Growth
SELECT branch, MONTHNAME(STR_TO_DATE(transaction_date,'%d-%m-%Y')) AS month_name, ROUND(SUM(amount),2) AS total_transaction,
COALESCE(ROUND(LAG(SUM(amount)) OVER (PARTITION BY branch ORDER BY YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),
MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y'))),2),'NA') AS previous_month_transaction,
COALESCE(ROUND((SUM(amount)-LAG(SUM(amount)) OVER (PARTITION BY branch ORDER BY YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),
MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y'))))/LAG(SUM(amount)) OVER (PARTITION BY branch ORDER BY YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),
MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y')))*100,2),'NA') AS growth_percentage
FROM bank_data GROUP BY branch, MONTHNAME(STR_TO_DATE(transaction_date,'%d-%m-%Y')),YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y'))
ORDER BY branch, YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y'));

# 11 - High Risk Transaction Flag
SELECT IFNULL(High_Risk_Flag,"Grand Total") as "Risk Flag",
CONCAT(ROUND(COUNT(High_Risk_Flag)/1000 ,2) ," K") as "High Risk Transaction"
from bank_data
group by High_Risk_Flag with rollup
ORDER BY CASE WHEN High_Risk_Flag IS NULL THEN 1 ELSE 0 END,
COUNT(High_Risk_Flag) asc;

# 12 - Suspicious Transaction Frequency
SELECT IFNULL(Month_Year,"Grand Total") as "Month Name",
COUNT(High_Risk_Flag) as "Suspicious Transaction Frequency"
from bank_data
where High_Risk_Flag ="High Risk"
group by Month_Year with rollup
order by field(Month_Year,
'January','February','March','April','May','June',
'July','August','September','October','November','December');


Create table Total_Credit_Amount AS SELECT CONCAT(ROUND(SUM(Amount)/1000000.0,2),'M') AS Total_Credit_Amount
FROM bank_data
WHERE Transaction_Type = 'Credit';


Create table Total_Debit_Amount AS SELECT CONCAT(ROUND(SUM(Amount)/1000000.0,2),'M') AS Total_Debit_Amount
FROM bank_data
WHERE Transaction_Type = 'Debit';



Create table Credit_to_Debit_ratio AS SELECT CONCAT(ROUND(SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END)/NULLIF(SUM(CASE WHEN Transaction_Type = 'Debit'
THEN Amount ELSE 0 END),0),3),'M') AS Credit_to_Debit_Ratio
FROM bank_data;



Create table Net_Transaction_Amount AS SELECT CONCAT(ROUND((SUM(CASE WHEN Transaction_Type = 'Credit' THEN Amount ELSE 0 END)-SUM(CASE WHEN Transaction_Type = 'Debit'
THEN Amount ELSE 0 END))/1000000.0,2),'M') AS Net_Transaction_Amount
FROM bank_data;



create table account_activity_ratio AS
select ROUND(COUNT(*)/Avg(Balance),2) as "Account Activity Ratio"
from bank_data;


Create table Transactions_per_month AS SELECT IFNULL(Month_Year, 'Grand Total') AS Month,
CONCAT(ROUND(SUM(Amount)/1000000,2),'M') AS Total_Amount
FROM bank_data
GROUP BY Month_Year WITH ROLLUP
ORDER BY CASE WHEN Month_Year IS NULL THEN 1 ELSE 0 END,
SUM(Amount) DESC;


Create table Total_transaction_amout_by_branch AS SELECT IFNULL(Branch, 'Grand Total') AS Branch,
CONCAT(ROUND(SUM(Amount)/1000000,2),'M') AS Total_Amount
FROM bank_data
GROUP BY Branch with rollup
ORDER BY CASE WHEN Branch IS NULL THEN 1 ELSE 0 END,
SUM(Amount) DESC;


Create table Transaction_volume_bank AS SELECT IFNULL(Bank_Name, 'Grand Total') AS Bank_Name, 
CONCAT(ROUND(SUM(Amount)/1000000,2),'M') AS Total_Amount
FROM bank_data
GROUP BY Bank_Name with rollup
ORDER BY CASE WHEN Bank_Name IS NULL THEN 1 ELSE 0 END,
SUM(Amount) DESC;


Create table Transaction_Method_Distribution AS SELECT IFNULL(Transaction_Method, 'Grand Total') AS Bank_Name, 
CONCAT(ROUND(COUNT(*)*100.0/(SELECT COUNT(*) FROM bank_data),2),'%') AS Transaction_Distribution
FROM bank_data
GROUP BY Transaction_Method with rollup
ORDER BY CASE WHEN Transaction_Method IS NULL THEN 1 ELSE 0 END,
COUNT(*) DESC;


Create table Branch_Transaction_Growth AS SELECT branch, MONTHNAME(STR_TO_DATE(transaction_date,'%d-%m-%Y')) AS month_name,
ROUND(SUM(amount),2) AS total_transaction,
COALESCE(ROUND(LAG(SUM(amount)) OVER (PARTITION BY branch ORDER BY YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),
MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y'))),2),'NA') AS previous_month_transaction,
COALESCE(ROUND((SUM(amount)-LAG(SUM(amount)) OVER (PARTITION BY branch ORDER BY YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),
MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y'))))/LAG(SUM(amount)) OVER (PARTITION BY branch ORDER BY YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),
MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y')))*100,2),'NA') AS growth_percentage
FROM bank_data
GROUP BY
    branch,
    MONTHNAME(STR_TO_DATE(transaction_date,'%d-%m-%Y')),
    YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),
    MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y'))
ORDER BY
    branch,
    YEAR(STR_TO_DATE(transaction_date,'%d-%m-%Y')),
    MONTH(STR_TO_DATE(transaction_date,'%d-%m-%Y'));


Create table High_Risk_Flag AS SELECT IFNULL(High_Risk_Flag,"Grand Total") as "Risk Flag",
CONCAT(ROUND(COUNT(High_Risk_Flag)/1000 ,2) ," K") as "High Risk Transaction"
from bank_data
group by High_Risk_Flag with rollup
ORDER BY CASE WHEN High_Risk_Flag IS NULL THEN 1 ELSE 0 END,
COUNT(High_Risk_Flag) asc;


Create table Suspicious_Transaction_Freq AS SELECT IFNULL(Month_Year,"Grand Total") as "Month Name",
COUNT(High_Risk_Flag) as "Suspicious Transaction Frequency"
from bank_data
where High_Risk_Flag ="High Risk"
group by Month_Year with rollup
order by field(Month_Year,
'January','February','March','April','May','June',
'July','August','September','October','November','December');



select * from Total_Credit_Amount;
select * from Total_Debit_Amount;
select * from Credit_to_Debit_ratio;
select * from Net_Transaction_Amount;
select * from Account_activity_ratio;
select * from Transactions_per_month;
select * from Total_transaction_amout_by_branch;
select * from Transaction_volume_bank;
select * from Transaction_Method_Distribution;
select * from Branch_Transaction_Growth;
select * from High_Risk_Flag;
select * from Suspicious_Transaction_Freq;

