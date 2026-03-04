-- =====================================================
-- RFM CALCULATION
-- Project: Customer Retention RFM Capstone
-- =====================================================

-- Calculate recency, frequency, monetary:
WITH rfm AS (
  SELECT
    customers.customer_id,
    company_name,
    DATE_DIFF(DATE("2025-07-01"), MAX(date), DAY) AS recency,
    COUNT(transaction_id) AS frequency,
    SUM(amount) AS monetary
  FROM `rfm_capstone.dim_customers` AS customers
  LEFT JOIN `rfm_capstone.fact_transactions` AS transactions
  ON  customers.customer_id = transactions.customer_id
  GROUP BY 1,2
),
-- Score RFM from 1 to 4:
rfm_scores AS (
  SELECT
    customer_id,
    company_name,
    recency,
    frequency,
    monetary,
    CASE WHEN recency <=7 THEN 4
    WHEN recency <= 45 THEN 3
    WHEN recency <= 100 THEN 2
    ELSE 1
    END AS r_score,
    NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm
),
-- Segment customers on RFM scores:
final AS (
  SELECT
    customer_id,
    company_name,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_score,
    CASE
      WHEN r_score = 4 AND f_score = 4 AND m_score = 4 THEN 'Champions'
      WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Loyal'
      WHEN r_score = 4 AND f_score = 1 AND m_score = 1 THEN 'Active Low-Value'
      WHEN r_score = 4 AND (f_score >= 2 OR m_score >= 2) THEN 'Potential Loyalist'
      WHEN r_score = 3 THEN 'Active'
      WHEN r_score = 2 THEN 'At Risk'
      WHEN r_score = 1 AND (f_score = 4 OR m_score = 4) THEN 'Can’t Lose Them'
      WHEN r_score = 1 THEN 'Hibernating'
      ELSE 'Others'
    END AS segment_label
  FROM rfm_scores
)
SELECT *
FROM final
