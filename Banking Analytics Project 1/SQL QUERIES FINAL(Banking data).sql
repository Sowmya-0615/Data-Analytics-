Create database banking_KPI;
use banking_kpi;


# - TABLE 1: dim_client
CREATE TABLE dim_client (
    client_id INT PRIMARY KEY,
    client_name VARCHAR(100),
    gender_id VARCHAR(50),
    age VARCHAR(50),
    age_t VARCHAR(50),
    dateof_birth VARCHAR(50),
    caste VARCHAR(50),
    religion VARCHAR(50),
    home_ownership VARCHAR(50),
    client_income_range VARCHAR(100),
    employment_type VARCHAR(100),
    credit_score VARCHAR(50)
);

SHOW VARIABLES LIKE 'secure_file_priv';

SET GLOBAL Local_infile=1;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Dim_Client.csv'
INTO TABLE dim_client
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# - TABLE 2: dim_branch
CREATE TABLE dim_branch (
    branch_name VARCHAR(100),
    bank_name VARCHAR(100),
    region_name VARCHAR(100),  
    state_abbr VARCHAR(50),
    state_name VARCHAR(100),
    city VARCHAR(100),
    center_id VARCHAR(50),
    bh_name VARCHAR(100),
    branch_performance_category VARCHAR(100),
    branch_id VARCHAR(50)
);

SET GLOBAL Local_infile=1;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Dim_Branch.csv'
INTO TABLE dim_branch
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# - TABLE 3: dim_product
CREATE TABLE dim_product (
    product_id VARCHAR(50),
    product_code VARCHAR(50),
    purpose_category VARCHAR(100),
    term VARCHAR(50),
    int_rate VARCHAR(50),
    grade VARCHAR(50),
    sub_grade VARCHAR(50)
);

SET GLOBAL Local_infile=1;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Dim_Product.csv'
INTO TABLE dim_product
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# - TABLE 4: fact_loan
CREATE TABLE fact_loan (
    account_id VARCHAR(50),
    client_id VARCHAR(50),
    branch_name VARCHAR(100),
    product_id VARCHAR(50),
    loan_amount VARCHAR(50),
    funded_amount VARCHAR(50),
    funded_amount_inv VARCHAR(50),
    disbursement_date VARCHAR(50),
    loan_status VARCHAR(50),
    repayment_type VARCHAR(100),
    center_id VARCHAR(50),
    branch_id VARCHAR(50)
);


SET GLOBAL Local_infile=1;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Fact_Loan.csv'
INTO TABLE fact_loan
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

# - TABLE 5: fact_repayment
CREATE TABLE fact_repayment (
    account_id  VARCHAR(20),
    total_pymnt FLOAT,
    total_pymnt_inv FLOAT,
    total_rec_prncp  FLOAT,
    total_fees  FLOAT,
    total_rec_int FLOAT,
    is_delinquent_loan VARCHAR(5),
    is_default_loan VARCHAR(5),
    delinq_2yrs INT,
    repayment_behavior VARCHAR(20)
);


SET GLOBAL Local_infile=1;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Fact_Repayment.csv'
INTO TABLE fact_repayment
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

#- TABLE 6: Final_fact
CREATE TABLE final_fact (
    account_id VARCHAR(20),
    client_id INT,
    client_name VARCHAR(100),
	gender VARCHAR(50),
	date_of_birth VARCHAR(20),
    age VARCHAR(50),
    age_t VARCHAR(50),
    caste VARCHAR(20),
    religion VARCHAR(20),
	home_ownership VARCHAR(50),
    client_income_range VARCHAR(100),
	employment_type VARCHAR(100),
    credit_score INT,
    branch_name VARCHAR(50),
	branch_id VARCHAR(100),
	center_id INT,
    bh_name VARCHAR(100),
	branch_performance_category VARCHAR(50),
    bank_name VARCHAR(20),
    region_name VARCHAR(100),
    state_Abbr VARCHAR(20),
	state_name VARCHAR(100),
	city VARCHAR(100),
	product_id VARCHAR(20),
    product_code VARCHAR(20),
    purpose_category VARCHAR(20),
    term_rate VARCHAR(20),
    int_rate DECIMAL(5,2),
    grade VARCHAR(10),
    sub_grade VARCHAR(10),
    loan_amount INT,
    funded_amount INT,
    funded_amount_inv INT,
    disbursement_date VARCHAR(20),
    loan_status VARCHAR(20),
    repayment_type VARCHAR(20),
    total_pymnt INT,
    total_pymnt_inv INT,
    total_rec_prncp INT,
    total_fees FLOAT,
    total_rec_int FLOAT,
    Is_delinquent_loan VARCHAR(20),
    is_default_loan VARCHAR(20),
    delinq_2_yrs INT,
    repayment_behavior VARCHAR(100)
    );



SET GLOBAL Local_infile=1;
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Final_Fact.csv'
INTO TABLE final_fact
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;


# KPI 1 - Total Clients
SELECT COUNT(DISTINCT client_id) AS Total_Clients
FROM dim_client;

# KPI 2 - Active Clients
SELECT COUNT(DISTINCT client_id) AS Active_Clients
FROM fact_loan
WHERE loan_status = 'Active';


# KPI 3 - New Clients
SELECT COALESCE(CAST(disbursement_year AS CHAR), 'Grand Total') AS Year,
COUNT(*) AS New_Clients FROM(SELECT Client_id,
YEAR(MIN(Disbursement_Date)) AS disbursement_year
FROM Fact_Loan
GROUP BY Client_id) AS first_loans
GROUP BY disbursement_year WITH ROLLUP
ORDER BY disbursement_year IS NULL, disbursement_year ASC;


# KPI 4 - Total Loan Amount Disbursed
SELECT CONCAT(ROUND(SUM(loan_amount)/1000000,2),'M') AS Total_Loan_Amount_Disbursed
FROM fact_loan;


# KPI 5 - Total Funded Amount 
SELECT CONCAT(ROUND(SUM(funded_amount)/1000000,2),'M') AS Total_Funded_Amount
FROM fact_loan;


# KPI 6 - Average Loan Size
SELECT CONCAT(ROUND(AVG(loan_amount)/1000,2),'K') AS Avg_Loan_Size
FROM fact_loan;


# KPI 7 - Total Repayment Collected
SELECT CONCAT(ROUND(SUM(total_pymnt)/1000000,2),'M') AS Total_Repayment
FROM fact_repayment;



# KPI 8 - Principal Recovery Rate
SELECT CONCAT(ROUND((SUM(total_rec_prncp)/(SELECT SUM(loan_amount) FROM fact_loan))*100,2),'%') AS principal_recovery_rate
FROM fact_repayment;


# KPI 9 - Delinquency Rate
SELECT CONCAT(ROUND((COUNT(CASE WHEN is_delinquent_loan = 'Y' THEN 1 END)/COUNT(*))*100,2),'%')AS delinquency_rate
FROM fact_repayment;


# KPI 10 - On-Time Repayment Percentage
SELECT CONCAT(ROUND((COUNT(CASE WHEN repayment_behavior = 'On-Time' THEN 1 END)/COUNT(*))*100,2),'%') AS On_Time_Repayment_Percent
FROM fact_repayment;


# KPI 11 - Loan Distribution by Branch
SELECT ifnull( branch_name,"Grand Total") as "Branch Name",
CONCAT(ROUND(SUM(loan_amount)/1000000,2),'M') AS Total_loan
FROM fact_loan
GROUP BY branch_name with rollup
ORDER BY CASE WHEN branch_name IS NULL THEN 1 ELSE 0 END,
SUM(loan_amount) DESC;



# KPI 12 - Branch Performance Category Split
SELECT ifnull( branch_performance_category,"Grand Total") as "Branch Performance Category",
COUNT(*) AS total_branches
FROM dim_branch
GROUP BY branch_performance_category with rollup;


Create table Total_Clients AS SELECT COUNT(DISTINCT client_id) AS Total_Clients
FROM dim_client;


Create table Active_Clients AS SELECT COUNT(DISTINCT client_id) AS Active_Clients
FROM fact_loan
WHERE loan_status = 'Active';


Create table New_Clients AS SELECT COALESCE(CAST(disbursement_year AS CHAR), 'Grand Total') AS Year,
COUNT(*) AS New_Clients FROM(SELECT Client_id,
YEAR(MIN(Disbursement_Date)) AS disbursement_year
FROM Fact_Loan
GROUP BY Client_id) AS first_loans
GROUP BY disbursement_year WITH ROLLUP
ORDER BY disbursement_year IS NULL, disbursement_year ASC;

Create table Total_Loan_Amount_Disbursed AS SELECT CONCAT(ROUND(SUM(loan_amount)/1000000,2),'M') AS Total_Loan_Amount_Disbursed
FROM fact_loan;

Create table Total_Funded_Amount AS SELECT CONCAT(ROUND(SUM(funded_amount)/1000000,2),'M') AS Total_Funded_Amount
FROM fact_loan;

Create table Avg_Loan_Size AS SELECT CONCAT(ROUND(AVG(loan_amount)/1000,2),'K') AS Avg_Loan_Size
FROM fact_loan;

Create table Total_Repayment_Collected AS SELECT CONCAT(ROUND(SUM(total_pymnt)/1000000,2),'M') AS Total_Repayment
FROM fact_repayment;


Create table Principal_Recovery_Rate AS SELECT CONCAT(ROUND((SUM(total_rec_prncp)/(SELECT SUM(loan_amount) FROM fact_loan))*100,2),'%') AS Principal_Recovery_Rate
FROM fact_repayment;


Create table Delinquency_Rate AS SELECT CONCAT(ROUND((COUNT(CASE WHEN is_delinquent_loan = 'Y' THEN 1 END)/COUNT(*))*100,2),'%')AS Delinquency_Rate
FROM fact_repayment;


Create table On_Time_Repayment_Percent AS SELECT CONCAT(ROUND((COUNT(CASE WHEN repayment_behavior = 'On-Time' THEN 1 END)/COUNT(*))*100,2),'%') AS On_Time_Repayment_Percent
FROM fact_repayment;


Create table Loan_Distribution_by_Branch AS SELECT ifnull( branch_name,"Grand Total") as "Branch Name",
CONCAT(ROUND(SUM(loan_amount)/1000000,2),'M') AS Total_loan
FROM fact_loan
GROUP BY branch_name with rollup
ORDER BY CASE WHEN branch_name IS NULL THEN 1 ELSE 0 END,
SUM(loan_amount) DESC;


Create table Branch_Performance_Category AS SELECT ifnull( branch_performance_category,"Grand Total") as "Branch Performance Category",
COUNT(*) AS total_branches
FROM dim_branch
GROUP BY branch_performance_category with rollup;



select * from Total_Clients;
select * from Active_Clients;
select * from New_Clients;
select * from Total_Loan_Amount_Disbursed;
select * from Total_Funded_Amount;
select * from Avg_Loan_Size;
select * from Total_Repayment_Collected;
select * from Principal_Recovery_Rate;
select * from Delinquency_Rate;
select * from On_Time_Repayment_Percent;
select * from Loan_Distribution_by_Branch;
select * from Branch_Performance_Category;


