-- ============================================================
--  Credit Card Fraud & Sales Analytics – SQL Query File
--  Dataset  : credit_card_fraud_2026.csv
--  Author   : Janakivarshasree
--  Database : MySQL / PostgreSQL / SQLite compatible
--  Course   : Data Analytics with AI – IBM × BharathCares
-- ============================================================


-- ============================================================
-- STEP 1 : CREATE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS credit_card_transactions (
    transaction_id              INT             PRIMARY KEY,
    amount_usd                  DECIMAL(10, 2)  NOT NULL,
    merchant_category           VARCHAR(50)     NOT NULL,
    card_type                   VARCHAR(30)     NOT NULL,
    auth_method                 VARCHAR(30)     NOT NULL,
    channel                     VARCHAR(30)     NOT NULL,
    device_type                 VARCHAR(30)     NOT NULL,
    is_foreign_transaction      BOOLEAN         NOT NULL,
    hours_since_last_txn        DECIMAL(6, 2),
    txn_count_last_24h          INT,
    distance_from_home_km       DECIMAL(8, 2),
    card_age_months             INT,
    customer_age                INT,
    account_balance_usd         DECIMAL(12, 2),
    is_new_merchant             BOOLEAN         NOT NULL,
    used_vpn                    BOOLEAN         NOT NULL,
    ip_country_mismatch         BOOLEAN         NOT NULL,
    billing_shipping_mismatch   BOOLEAN         NOT NULL,
    cvv_retry_count             INT,
    velocity_score              DECIMAL(6, 2),
    time_of_day_hour            INT,
    day_of_week                 INT,
    is_ai_generated_scam_attempt BOOLEAN        NOT NULL,
    merchant_risk_score         DECIMAL(5, 2),
    prior_disputes              INT,
    is_fraud                    TINYINT(1)      NOT NULL
);

-- NOTE: Load data using your DB tool or Python:
--   df.to_sql('credit_card_transactions', con=engine, if_exists='replace', index=False)
-- OR via MySQL:
--   LOAD DATA INFILE 'credit_card_fraud_2026.csv'
--   INTO TABLE credit_card_transactions
--   FIELDS TERMINATED BY ',' ENCLOSED BY '"'
--   LINES TERMINATED BY '\n'
--   IGNORE 1 ROWS;


-- ============================================================
-- STEP 2 : ADD DERIVED / COMPUTED COLUMNS (Sales Calculation)
-- ============================================================

-- Sales = Quantity × Unit Price
-- Quantity  = txn_count_last_24h (minimum 1)
-- Unit Price = amount_usd / quantity

-- Use these as expressions in SELECT queries (or create a VIEW):

CREATE OR REPLACE VIEW vw_transactions_enriched AS
SELECT
    transaction_id,
    amount_usd,
    merchant_category,
    card_type,
    auth_method,
    channel,
    device_type,
    is_foreign_transaction,
    txn_count_last_24h,
    CASE
        WHEN txn_count_last_24h < 1 THEN 1
        ELSE txn_count_last_24h
    END                                                         AS quantity,
    ROUND(
        amount_usd / GREATEST(txn_count_last_24h, 1), 2
    )                                                           AS unit_price,
    amount_usd                                                  AS sales,   -- sales = qty × unit_price = amount_usd
    velocity_score,
    merchant_risk_score,
    account_balance_usd,
    customer_age,
    card_age_months,
    cvv_retry_count,
    prior_disputes,
    used_vpn,
    is_foreign_transaction                                      AS is_foreign,
    ip_country_mismatch,
    billing_shipping_mismatch,
    is_new_merchant,
    is_ai_generated_scam_attempt,
    time_of_day_hour,
    CASE
        WHEN time_of_day_hour BETWEEN  6 AND 11 THEN 'Morning'
        WHEN time_of_day_hour BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN time_of_day_hour BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END                                                         AS time_period,
    day_of_week,
    CASE day_of_week
        WHEN 0 THEN 'Monday'
        WHEN 1 THEN 'Tuesday'
        WHEN 2 THEN 'Wednesday'
        WHEN 3 THEN 'Thursday'
        WHEN 4 THEN 'Friday'
        WHEN 5 THEN 'Saturday'
        WHEN 6 THEN 'Sunday'
    END                                                         AS day_name,
    is_fraud,
    CASE is_fraud WHEN 1 THEN 'Fraud' ELSE 'Legitimate' END     AS fraud_label
FROM credit_card_transactions;


-- ============================================================
-- SECTION A : DATA QUALITY CHECK
-- ============================================================

-- Q1. How many total rows are in the dataset?
SELECT COUNT(*) AS total_rows
FROM credit_card_transactions;

-- Q2. Check for NULL values in every column
SELECT
    SUM(CASE WHEN transaction_id           IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN amount_usd               IS NULL THEN 1 ELSE 0 END) AS null_amount_usd,
    SUM(CASE WHEN merchant_category        IS NULL THEN 1 ELSE 0 END) AS null_merchant_category,
    SUM(CASE WHEN card_type                IS NULL THEN 1 ELSE 0 END) AS null_card_type,
    SUM(CASE WHEN auth_method              IS NULL THEN 1 ELSE 0 END) AS null_auth_method,
    SUM(CASE WHEN channel                  IS NULL THEN 1 ELSE 0 END) AS null_channel,
    SUM(CASE WHEN device_type              IS NULL THEN 1 ELSE 0 END) AS null_device_type,
    SUM(CASE WHEN velocity_score           IS NULL THEN 1 ELSE 0 END) AS null_velocity_score,
    SUM(CASE WHEN merchant_risk_score      IS NULL THEN 1 ELSE 0 END) AS null_merchant_risk_score,
    SUM(CASE WHEN is_fraud                 IS NULL THEN 1 ELSE 0 END) AS null_is_fraud
FROM credit_card_transactions;

-- Q3. Find duplicate transaction IDs
SELECT
    transaction_id,
    COUNT(*) AS occurrence_count
FROM credit_card_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

-- Q4. Find rows with invalid (zero or negative) amounts
SELECT
    transaction_id,
    amount_usd,
    merchant_category
FROM credit_card_transactions
WHERE amount_usd <= 0;

-- Q5. Check minimum, maximum, and average transaction amount
SELECT
    MIN(amount_usd)   AS min_amount,
    MAX(amount_usd)   AS max_amount,
    ROUND(AVG(amount_usd), 2) AS avg_amount,
    COUNT(*)          AS total_records
FROM credit_card_transactions;


-- ============================================================
-- SECTION B : SALES OVERVIEW (Sales = Quantity × Unit Price)
-- ============================================================

-- Q6. What is the total sales revenue across all transactions?
SELECT
    COUNT(*)                         AS total_transactions,
    ROUND(SUM(sales), 2)             AS total_sales_usd,
    ROUND(AVG(sales), 2)             AS avg_sales_usd,
    ROUND(MIN(sales), 2)             AS min_sales_usd,
    ROUND(MAX(sales), 2)             AS max_sales_usd
FROM vw_transactions_enriched;

-- Q7. Show Sales = Quantity × Unit Price for the first 10 transactions
SELECT
    transaction_id,
    amount_usd,
    quantity,
    unit_price,
    ROUND(quantity * unit_price, 2)  AS calculated_sales,
    sales
FROM vw_transactions_enriched
LIMIT 10;

-- Q8. What are the total sales, average sales, and transaction count
--     by merchant category? (Sorted by highest total sales)
SELECT
    merchant_category,
    COUNT(*)                          AS total_transactions,
    ROUND(SUM(sales), 2)              AS total_sales_usd,
    ROUND(AVG(sales), 2)              AS avg_sales_usd,
    ROUND(MIN(sales), 2)              AS min_sales_usd,
    ROUND(MAX(sales), 2)              AS max_sales_usd
FROM vw_transactions_enriched
GROUP BY merchant_category
ORDER BY total_sales_usd DESC;

-- Q9. Which merchant category has the highest average transaction value?
SELECT
    merchant_category,
    ROUND(AVG(sales), 2)  AS avg_sales_usd
FROM vw_transactions_enriched
GROUP BY merchant_category
ORDER BY avg_sales_usd DESC
LIMIT 1;

-- Q10. What are the total sales by card type?
SELECT
    card_type,
    COUNT(*)                 AS transactions,
    ROUND(SUM(sales), 2)     AS total_sales_usd,
    ROUND(AVG(sales), 2)     AS avg_sales_usd
FROM vw_transactions_enriched
GROUP BY card_type
ORDER BY total_sales_usd DESC;

-- Q11. What are the total sales by transaction channel?
SELECT
    channel,
    COUNT(*)                 AS transactions,
    ROUND(SUM(sales), 2)     AS total_sales_usd,
    ROUND(AVG(sales), 2)     AS avg_sales_usd
FROM vw_transactions_enriched
GROUP BY channel
ORDER BY total_sales_usd DESC;

-- Q12. What are total sales and transaction count by day of the week?
SELECT
    day_name,
    COUNT(*)                  AS transactions,
    ROUND(SUM(sales), 2)      AS total_sales_usd,
    ROUND(AVG(sales), 2)      AS avg_sales_usd
FROM vw_transactions_enriched
GROUP BY day_of_week, day_name
ORDER BY day_of_week;

-- Q13. Which time period (Morning / Afternoon / Evening / Night)
--      has the highest average sales?
SELECT
    time_period,
    COUNT(*)                   AS transactions,
    ROUND(AVG(sales), 2)       AS avg_sales_usd,
    ROUND(SUM(sales), 2)       AS total_sales_usd
FROM vw_transactions_enriched
GROUP BY time_period
ORDER BY avg_sales_usd DESC;

-- Q14. What is the sales breakdown by device type?
SELECT
    device_type,
    COUNT(*)               AS transactions,
    ROUND(SUM(sales), 2)   AS total_sales_usd,
    ROUND(AVG(sales), 2)   AS avg_sales_usd
FROM vw_transactions_enriched
GROUP BY device_type
ORDER BY total_sales_usd DESC;

-- Q15. Top 10 highest-value transactions
SELECT
    transaction_id,
    amount_usd,
    merchant_category,
    card_type,
    channel,
    fraud_label
FROM vw_transactions_enriched
ORDER BY amount_usd DESC
LIMIT 10;


-- ============================================================
-- SECTION C : FRAUD ANALYSIS
-- ============================================================

-- Q16. What is the overall fraud rate?
SELECT
    COUNT(*)                                         AS total_transactions,
    SUM(is_fraud)                                    AS fraud_count,
    SUM(1 - is_fraud)                                AS legitimate_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)       AS fraud_rate_pct,
    ROUND(SUM(is_fraud * amount_usd), 2)             AS total_fraud_loss_usd
FROM credit_card_transactions;

-- Q17. Compare total sales and average sales for Fraud vs Legitimate
SELECT
    fraud_label,
    COUNT(*)                  AS transactions,
    ROUND(SUM(sales), 2)      AS total_sales_usd,
    ROUND(AVG(sales), 2)      AS avg_sales_usd
FROM vw_transactions_enriched
GROUP BY fraud_label;

-- Q18. What is the fraud rate (%) for each merchant category?
SELECT
    merchant_category,
    COUNT(*)                                             AS total_transactions,
    SUM(is_fraud)                                        AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)           AS fraud_rate_pct,
    ROUND(SUM(is_fraud * amount_usd), 2)                 AS fraud_loss_usd
FROM credit_card_transactions
GROUP BY merchant_category
ORDER BY fraud_rate_pct DESC;

-- Q19. Which authentication method has the lowest fraud rate?
SELECT
    auth_method,
    COUNT(*)                                        AS transactions,
    SUM(is_fraud)                                   AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)      AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY auth_method
ORDER BY fraud_rate_pct ASC;

-- Q20. What is the fraud rate by transaction channel?
SELECT
    channel,
    COUNT(*)                                        AS transactions,
    SUM(is_fraud)                                   AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)      AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY channel
ORDER BY fraud_rate_pct DESC;

-- Q21. What is the fraud rate for foreign vs domestic transactions?
SELECT
    CASE is_foreign_transaction WHEN 1 THEN 'Foreign' ELSE 'Domestic' END AS transaction_type,
    COUNT(*)                                          AS transactions,
    SUM(is_fraud)                                     AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)        AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY is_foreign_transaction;

-- Q22. Does VPN usage increase fraud rate?
SELECT
    CASE used_vpn WHEN 1 THEN 'VPN Used' ELSE 'No VPN' END  AS vpn_status,
    COUNT(*)                                                  AS transactions,
    SUM(is_fraud)                                             AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)                AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY used_vpn;

-- Q23. Fraud rate when BOTH VPN is used AND transaction is foreign
SELECT
    COUNT(*)                                          AS high_risk_transactions,
    SUM(is_fraud)                                     AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)        AS fraud_rate_pct
FROM credit_card_transactions
WHERE used_vpn = 1
  AND is_foreign_transaction = 1;

-- Q24. What is the average velocity score for fraud vs legitimate?
SELECT
    CASE is_fraud WHEN 1 THEN 'Fraud' ELSE 'Legitimate' END AS fraud_label,
    ROUND(AVG(velocity_score), 2)     AS avg_velocity_score,
    ROUND(AVG(merchant_risk_score), 2) AS avg_merchant_risk_score,
    ROUND(AVG(amount_usd), 2)         AS avg_amount_usd
FROM credit_card_transactions
GROUP BY is_fraud;

-- Q25. How many fraud transactions involve AI-generated scam attempts?
SELECT
    COUNT(*)                                       AS total_fraud,
    SUM(is_ai_generated_scam_attempt)              AS ai_scam_count,
    ROUND(
        SUM(is_ai_generated_scam_attempt) * 100.0 / COUNT(*), 2
    )                                              AS ai_scam_pct_of_fraud
FROM credit_card_transactions
WHERE is_fraud = 1;

-- Q26. Fraud rate by number of CVV retry attempts
SELECT
    cvv_retry_count,
    COUNT(*)                                         AS transactions,
    SUM(is_fraud)                                    AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)       AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY cvv_retry_count
ORDER BY cvv_retry_count;

-- Q27. Fraud rate at new merchants vs established merchants
SELECT
    CASE is_new_merchant WHEN 1 THEN 'New Merchant' ELSE 'Established Merchant' END AS merchant_type,
    COUNT(*)                                          AS transactions,
    SUM(is_fraud)                                     AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)        AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY is_new_merchant;

-- Q28. Top 5 highest-value fraud transactions
SELECT
    transaction_id,
    amount_usd,
    merchant_category,
    card_type,
    auth_method,
    channel,
    velocity_score,
    merchant_risk_score
FROM credit_card_transactions
WHERE is_fraud = 1
ORDER BY amount_usd DESC
LIMIT 5;


-- ============================================================
-- SECTION D : CUSTOMER & ACCOUNT ANALYSIS
-- ============================================================

-- Q29. What is the average customer age for fraud vs legitimate transactions?
SELECT
    CASE is_fraud WHEN 1 THEN 'Fraud' ELSE 'Legitimate' END AS fraud_label,
    ROUND(AVG(customer_age), 1)        AS avg_customer_age,
    MIN(customer_age)                  AS min_age,
    MAX(customer_age)                  AS max_age
FROM credit_card_transactions
GROUP BY is_fraud;

-- Q30. Do customers with prior disputes have a higher fraud rate?
SELECT
    prior_disputes,
    COUNT(*)                                         AS transactions,
    SUM(is_fraud)                                    AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)       AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY prior_disputes
ORDER BY prior_disputes;

-- Q31. Fraud rate by customer age group
SELECT
    CASE
        WHEN customer_age < 25              THEN 'Under 25'
        WHEN customer_age BETWEEN 25 AND 34 THEN '25–34'
        WHEN customer_age BETWEEN 35 AND 44 THEN '35–44'
        WHEN customer_age BETWEEN 45 AND 54 THEN '45–54'
        WHEN customer_age BETWEEN 55 AND 64 THEN '55–64'
        ELSE '65+'
    END                                              AS age_group,
    COUNT(*)                                         AS transactions,
    SUM(is_fraud)                                    AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)       AS fraud_rate_pct,
    ROUND(AVG(amount_usd), 2)                        AS avg_transaction_usd
FROM credit_card_transactions
GROUP BY age_group
ORDER BY MIN(customer_age);

-- Q32. Do customers with low account balance transact more fraudulently?
SELECT
    CASE
        WHEN account_balance_usd < 500    THEN 'Low (<$500)'
        WHEN account_balance_usd < 2000   THEN 'Medium ($500–$2000)'
        WHEN account_balance_usd < 5000   THEN 'High ($2000–$5000)'
        ELSE 'Very High (>$5000)'
    END                                              AS balance_tier,
    COUNT(*)                                         AS transactions,
    SUM(is_fraud)                                    AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)       AS fraud_rate_pct,
    ROUND(AVG(amount_usd), 2)                        AS avg_transaction_usd
FROM credit_card_transactions
GROUP BY balance_tier
ORDER BY MIN(account_balance_usd);


-- ============================================================
-- SECTION E : TIME & PATTERN ANALYSIS
-- ============================================================

-- Q33. Which hour of the day has the most transactions?
SELECT
    time_of_day_hour,
    COUNT(*)               AS total_transactions,
    SUM(is_fraud)          AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY time_of_day_hour
ORDER BY total_transactions DESC
LIMIT 5;

-- Q34. Which hour of the day has the highest fraud rate?
SELECT
    time_of_day_hour,
    COUNT(*)                                         AS transactions,
    SUM(is_fraud)                                    AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)       AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY time_of_day_hour
ORDER BY fraud_rate_pct DESC
LIMIT 5;

-- Q35. Sales and fraud comparison by time period
SELECT
    CASE
        WHEN time_of_day_hour BETWEEN  6 AND 11 THEN 'Morning'
        WHEN time_of_day_hour BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN time_of_day_hour BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END                                              AS time_period,
    COUNT(*)                                         AS transactions,
    ROUND(SUM(amount_usd), 2)                        AS total_sales_usd,
    ROUND(AVG(amount_usd), 2)                        AS avg_sales_usd,
    SUM(is_fraud)                                    AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)       AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY time_period;

-- Q36. Transaction volume and fraud count by day of week
SELECT
    CASE day_of_week
        WHEN 0 THEN 'Monday'    WHEN 1 THEN 'Tuesday'
        WHEN 2 THEN 'Wednesday' WHEN 3 THEN 'Thursday'
        WHEN 4 THEN 'Friday'    WHEN 5 THEN 'Saturday'
        WHEN 6 THEN 'Sunday'
    END                                              AS day_name,
    COUNT(*)                                         AS transactions,
    ROUND(SUM(amount_usd), 2)                        AS total_sales_usd,
    SUM(is_fraud)                                    AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)       AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY day_of_week
ORDER BY day_of_week;


-- ============================================================
-- SECTION F : ADVANCED / BUSINESS DECISION QUERIES
-- ============================================================

-- Q37. High-risk transactions: velocity_score > 70 AND is_fraud = 1
SELECT
    transaction_id,
    amount_usd,
    merchant_category,
    auth_method,
    velocity_score,
    merchant_risk_score,
    channel,
    device_type
FROM credit_card_transactions
WHERE velocity_score > 70
  AND is_fraud = 1
ORDER BY velocity_score DESC;

-- Q38. What percentage of high-velocity transactions (score > 70) are fraud?
SELECT
    COUNT(*)                                           AS high_velocity_txns,
    SUM(is_fraud)                                      AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)         AS fraud_rate_pct
FROM credit_card_transactions
WHERE velocity_score > 70;

-- Q39. Category × Channel sales summary (cross-tab)
SELECT
    merchant_category,
    channel,
    COUNT(*)                  AS transactions,
    ROUND(SUM(amount_usd), 2) AS total_sales_usd,
    SUM(is_fraud)             AS fraud_count
FROM credit_card_transactions
GROUP BY merchant_category, channel
ORDER BY merchant_category, total_sales_usd DESC;

-- Q40. Rank merchant categories by total sales using window function
SELECT
    merchant_category,
    ROUND(SUM(amount_usd), 2)                                   AS total_sales_usd,
    RANK() OVER (ORDER BY SUM(amount_usd) DESC)                 AS sales_rank
FROM credit_card_transactions
GROUP BY merchant_category;

-- Q41. Running total of sales ordered by transaction_id
SELECT
    transaction_id,
    amount_usd,
    merchant_category,
    is_fraud,
    ROUND(
        SUM(amount_usd) OVER (ORDER BY transaction_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
        2
    ) AS running_total_sales_usd
FROM credit_card_transactions
ORDER BY transaction_id
LIMIT 20;

-- Q42. Moving average of transaction amount over last 5 transactions
SELECT
    transaction_id,
    amount_usd,
    ROUND(
        AVG(amount_usd) OVER (ORDER BY transaction_id ROWS BETWEEN 4 PRECEDING AND CURRENT ROW),
        2
    ) AS moving_avg_5_txns
FROM credit_card_transactions
ORDER BY transaction_id
LIMIT 20;

-- Q43. Which combination of card_type + auth_method has the lowest fraud rate?
--      (minimum 100 transactions for statistical relevance)
SELECT
    card_type,
    auth_method,
    COUNT(*)                                          AS transactions,
    SUM(is_fraud)                                     AS fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)        AS fraud_rate_pct
FROM credit_card_transactions
GROUP BY card_type, auth_method
HAVING COUNT(*) >= 100
ORDER BY fraud_rate_pct ASC
LIMIT 10;

-- Q44. Find customers (by age bucket) spending above the average transaction amount
SELECT
    transaction_id,
    customer_age,
    amount_usd,
    merchant_category,
    is_fraud
FROM credit_card_transactions
WHERE amount_usd > (SELECT AVG(amount_usd) FROM credit_card_transactions)
ORDER BY amount_usd DESC
LIMIT 20;

-- Q45. Business Decision: Flag HIGH-RISK transactions for manual review
--      Criteria: velocity_score > 60  OR  (is_foreign_transaction=1 AND used_vpn=1)
--                OR  (cvv_retry_count > 0 AND is_new_merchant=1)
SELECT
    transaction_id,
    amount_usd,
    merchant_category,
    card_type,
    auth_method,
    velocity_score,
    is_foreign_transaction,
    used_vpn,
    cvv_retry_count,
    is_new_merchant,
    is_fraud,
    CASE
        WHEN velocity_score > 60                                      THEN 'High Velocity'
        WHEN is_foreign_transaction = 1 AND used_vpn = 1             THEN 'Foreign + VPN'
        WHEN cvv_retry_count > 0 AND is_new_merchant = 1             THEN 'CVV Retry at New Merchant'
        ELSE 'Other Risk'
    END AS risk_reason
FROM credit_card_transactions
WHERE velocity_score > 60
   OR (is_foreign_transaction = 1 AND used_vpn = 1)
   OR (cvv_retry_count > 0 AND is_new_merchant = 1)
ORDER BY velocity_score DESC;

-- Q46. Summary report: overall business KPI dashboard query
SELECT
    COUNT(*)                                              AS total_transactions,
    ROUND(SUM(amount_usd), 2)                             AS total_sales_usd,
    ROUND(AVG(amount_usd), 2)                             AS avg_transaction_usd,
    ROUND(MAX(amount_usd), 2)                             AS max_transaction_usd,
    SUM(is_fraud)                                         AS total_fraud_count,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2)            AS fraud_rate_pct,
    ROUND(SUM(is_fraud * amount_usd), 2)                  AS total_fraud_loss_usd,
    ROUND(
        SUM(is_fraud * amount_usd) * 100.0 / SUM(amount_usd), 2
    )                                                     AS fraud_loss_pct_of_sales,
    COUNT(DISTINCT merchant_category)                     AS unique_categories,
    COUNT(DISTINCT card_type)                             AS unique_card_types,
    COUNT(DISTINCT channel)                               AS unique_channels
FROM credit_card_transactions;

-- ============================================================
-- END OF FILE
-- ============================================================
