### Customer Risk Analysis
SELECT c.customer_id, c.name, c.credit_score,
    l.loan_id, l.loan_amount, l.loan_status, l.default_risk,
    c.risk_category, c.income, c.employment_status
FROM customer_table c
JOIN loan_table l
ON c.customer_id = l.customer_id
WHERE c.credit_score < 600 -- Low credit score threshold
    AND l.default_risk = 'High' -- High-risk loans
ORDER BY c.credit_score ASC, l.loan_amount DESC;

###Loan Purpose Insights
SELECT loan_purpose, 
	COUNT(*) AS total_loans,
    SUM(loan_amount) AS total_revenue,
    AVG(loan_amount) AS avg_loan_amount
FROM loan_table GROUP BY loan_purpose
ORDER BY total_loans DESC, total_revenue DESC;

###High-Value Transactions
SELECT t.transaction_id,
    t.loan_id, t.customer_id, t.transaction_date, t.transaction_amount, l.loan_amount,
    ROUND(l.loan_amount * 0.3, 2) AS threshold_amount, t.transaction_type, t.status
FROM transaction_table t JOIN loan_table l
ON t.loan_id = l.loan_id WHERE t.transaction_amount > (l.loan_amount * 0.3)
ORDER BY t.transaction_amount DESC;

##Missed EMI Count.
SELECT l.loan_id, l.customer_id, l.loan_amount, l.loan_status,
    COUNT(CASE WHEN t.status = 'Failed' AND t.transaction_type = 'EMI Payment' THEN 1 END) AS missed_emi_count, l.default_risk
FROM loan_table l
LEFT JOIN transaction_table t
ON l.loan_id = t.loan_id
GROUP BY l.loan_id, l.customer_id, l.loan_amount, l.loan_status, l.default_risk
HAVING missed_emi_count > 0 -- Only show loans with missed EMIs
ORDER BY missed_emi_count DESC, l.loan_amount DESC;

##Regional Loan Distribution
SELECT 
    SUBSTRING_INDEX(c.address, ',', -2) AS region,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_disbursement,
    AVG(l.loan_amount) AS avg_loan_amount
FROM customer_table c
JOIN loan_table l
ON c.customer_id = l.customer_id
GROUP BY region
ORDER BY total_disbursement DESC, total_loans DESC;

##Loyal Customers
SELECT 
    c.customer_id, c.name, c.customer_since,
    TIMESTAMPDIFF(YEAR, STR_TO_DATE(c.customer_since, '%m/%d/%Y'), CURDATE()) AS years_with_bank,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_loan_amount,
    AVG(l.loan_amount) AS avg_loan_amount,
    COUNT(CASE WHEN l.loan_status = 'Closed' THEN 1 END) AS closed_loans,
    COUNT(CASE WHEN l.loan_status = 'Defaulted' THEN 1 END) AS defaulted_loans
FROM customer_table c
LEFT JOIN loan_table l
ON c.customer_id = l.customer_id
WHERE TIMESTAMPDIFF(YEAR, STR_TO_DATE(c.customer_since, '%m/%d/%Y'), CURDATE()) > 5
GROUP BY c.customer_id, c.name, c.customer_since
ORDER BY years_with_bank DESC, total_loans DESC;

##High-Performing Loans

SELECT l.loan_id, l.customer_id,l.loan_amount,l.loan_status,l.repayment_history,l.interest_rate,l.loan_purpose,
    COUNT(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN 1 END) AS successful_payments,
    COUNT(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Failed' THEN 1 END) AS missed_payments
FROM loan_table l
LEFT JOIN transaction_table t
ON l.loan_id = t.loan_id
GROUP BY l.loan_id, l.customer_id, l.loan_amount, l.loan_status, l.repayment_history, l.interest_rate, l.loan_purpose
HAVING missed_payments = 0 -- No missed payments
    AND l.repayment_history >= 9 -- Excellent repayment history threshold
ORDER BY l.repayment_history DESC, successful_payments DESC, l.loan_amount DESC;

##Age-Based Loan Analysis
	SELECT 
    CASE 
        WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
        WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
        WHEN c.age BETWEEN 36 AND 50 THEN '36-50'
        WHEN c.age > 50 THEN '50+'
        ELSE 'Unknown'
    END AS age_group,
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_disbursement,
    AVG(l.loan_amount) AS avg_loan_amount
FROM customer_table c
JOIN loan_table l
ON c.customer_id = l.customer_id
GROUP BY age_group
ORDER BY total_disbursement DESC;

##Seasonal Transaction Trends:
SELECT 
    YEAR(STR_TO_DATE(t.transaction_date, '%m/%d/%Y %H:%i')) AS transaction_year,
    MONTHNAME(STR_TO_DATE(t.transaction_date, '%m/%d/%Y %H:%i')) AS transaction_month,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.transaction_amount) AS total_amount,
    AVG(t.transaction_amount) AS avg_transaction_amount,
    COUNT(CASE WHEN t.transaction_type = 'EMI Payment' THEN 1 END) AS emi_transactions,
    SUM(CASE WHEN t.transaction_type = 'EMI Payment' THEN t.transaction_amount ELSE 0 END) AS emi_amount
FROM transaction_table t
GROUP BY transaction_year, transaction_month
ORDER BY transaction_year ASC, FIELD(transaction_month, 
        'January', 'February', 'March', 'April', 'May', 'June', 
        'July', 'August', 'September', 'October', 'November', 'December');

##Fraud Detection
SELECT 
    t.transaction_id,t.customer_id,c.name AS customer_name,c.address AS registered_address,
    t.transaction_date,t.remarks AS transaction_ip_location,t.transaction_amount,t.transaction_type,
    t.status
FROM transaction_table t
JOIN customer_table c
ON t.customer_id = c.customer_id
WHERE NOT t.remarks LIKE CONCAT('%', SUBSTRING_INDEX(c.address, ',', -1), '%')
    AND t.status = 'Successful' -- Focus on successful transactions
ORDER BY t.transaction_date DESC;

##Repayment History Analysis
SELECT l.loan_id,l.customer_id,l.loan_amount,l.loan_status,l.repayment_history,
    COUNT(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN 1 END) AS successful_payments,
    SUM(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN t.transaction_amount ELSE 0 END) AS total_repaid_amount,
    RANK() OVER (ORDER BY l.repayment_history DESC, COUNT(CASE WHEN t.transaction_type = 'EMI Payment' AND t.status = 'Successful' THEN 1 END) DESC) AS performance_rank
FROM loan_table l
LEFT JOIN transaction_table t
ON l.loan_id = t.loan_id
GROUP BY l.loan_id, l.customer_id, l.loan_amount, l.loan_status, l.repayment_history
ORDER BY performance_rank ASC;

##Credit Score vs. Loan Amount
SELECT 
    CASE 
        WHEN c.credit_score BETWEEN 300 AND 499 THEN '300-499'
        WHEN c.credit_score BETWEEN 500 AND 649 THEN '500-649'
        WHEN c.credit_score BETWEEN 650 AND 749 THEN '650-749'
        WHEN c.credit_score >= 750 THEN '750+'
        ELSE 'Unknown'
    END AS credit_score_range,
    COUNT(l.loan_id) AS total_loans,
    AVG(l.loan_amount) AS avg_loan_amount,
    SUM(l.loan_amount) AS total_loan_amount
FROM customer_table c
JOIN loan_table l
ON c.customer_id = l.customer_id
GROUP BY credit_score_range
ORDER BY credit_score_range;

##Top Borrowing Regions
SELECT 
    SUBSTRING_INDEX(c.address, ',', -2) AS region, 
    COUNT(l.loan_id) AS total_loans,
    SUM(l.loan_amount) AS total_disbursement,
    AVG(l.loan_amount) AS avg_loan_amount
FROM customer_table c
JOIN loan_table l
ON c.customer_id = l.customer_id
GROUP BY region
ORDER BY total_disbursement DESC;

#Early Repayment Patterns
SELECT l.loan_id,l.customer_id,l.loan_amount,l.interest_rate,l.loan_purpose,
    COUNT(CASE WHEN t.transaction_type = 'EMI Payment' AND t.remarks LIKE '%Early%' THEN 1 END) AS early_repayment_count,
    SUM(CASE WHEN t.transaction_type = 'EMI Payment' AND t.remarks LIKE '%Early%' THEN t.transaction_amount ELSE 0 END) AS early_repayment_amount,
    (l.loan_amount * (l.interest_rate / 100)) AS expected_revenue,
    (l.loan_amount * (l.interest_rate / 100)) - SUM(CASE WHEN t.transaction_type = 'EMI Payment' AND t.remarks LIKE '%Early%' THEN t.transaction_amount ELSE 0 END) AS revenue_impact
FROM loan_table l
LEFT JOIN transaction_table t
ON l.loan_id = t.loan_id
GROUP BY l.loan_id, l.customer_id, l.loan_amount, l.interest_rate, l.loan_purpose
HAVING early_repayment_count > 0 -- Only show loans with early repayments
ORDER BY early_repayment_count DESC, revenue_impact DESC;

##Feedback Correlation
SELECT l.loan_id,l.customer_id,l.loan_amount,l.loan_status,f.credit_score,
    AVG(f.credit_score) OVER (PARTITION BY l.loan_status) AS avg_sentiment_by_status,
    COUNT(l.loan_id) OVER (PARTITION BY l.loan_status) AS loans_by_status
FROM loan_table l
JOIN customer_table f
ON l.customer_id = f.customer_id
WHERE f.credit_score IS NOT NULL
ORDER BY l.loan_status, f.credit_score DESC;


