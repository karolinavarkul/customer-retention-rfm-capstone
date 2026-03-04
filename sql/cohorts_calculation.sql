-- =====================================================
-- BEHAVIORAL COHORT CALCULATION
-- Project: Customer Retention RFM Capstone
-- =====================================================

-- Select months for analysis:
WITH months AS (
  SELECT
    month
  FROM UNNEST(
    GENERATE_DATE_ARRAY(
      (SELECT DATE_TRUNC(MIN(date), MONTH) FROM `rfm_capstone.fact_transactions`),
      (SELECT DATE_TRUNC(MAX(date), MONTH) FROM `rfm_capstone.fact_transactions`),
      INTERVAL 1 MONTH
    )
  ) AS month
),
-- Create combination for every customer and every month:
customer_month AS (
  SELECT
    c.customer_id,
    c.company_name,
    m.month
  FROM `rfm_capstone.dim_customers` AS c
  CROSS JOIN months AS m
),
-- Calculate recency, frequency, monetary for every month:
rfm AS (
  SELECT
    cm.customer_id,
    cm.company_name,
    cm.month,
    IF(MAX(t.date) IS NULL, NULL, DATE_DIFF(LAST_DAY(cm.month), MAX(t.date), DAY)) AS recency,
    COUNT(DISTINCT t.transaction_id) AS frequency,
    COALESCE(SUM(t.amount), 0) AS monetary
  FROM customer_month AS cm
  LEFT JOIN `rfm_capstone.fact_transactions` AS t
  ON cm.customer_id = t.customer_id
  AND t.date <= LAST_DAY(cm.month)
  GROUP BY 1,2,3
),
-- Score RFM from 1 to 4:
rfm_scores AS (
  SELECT
    customer_id,
    company_name,
    month,
    recency, frequency,
    monetary,
    CASE WHEN recency <= 30 THEN 4
    WHEN recency <= 60 THEN 3
    WHEN recency <= 120 THEN 2
    ELSE 1
    END AS r_score,
    NTILE(4) OVER (PARTITION BY month ORDER BY frequency ASC) AS f_score,
    NTILE(4) OVER (PARTITION BY month ORDER BY monetary ASC) AS m_score
  FROM rfm
),
-- Segment customers on RFM scores:
segments AS (
  SELECT
    customer_id,
    company_name,
    month,
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
      WHEN r_score = 1 AND (f_score = 4 OR m_score = 4) THEN 'Cant Lose Them'
      WHEN r_score = 1 THEN 'Hibernating'
      ELSE 'Others'
    END AS segment_label
  FROM rfm_scores
),
-- Create cohort label based on Jan segment:
cohort AS (
  SELECT
  customer_id,
  segment_label AS cohort_name_jan,
  FROM segments
  WHERE month = DATE("2025-01-01")
),
final AS (
  SELECT 
    segments.customer_id,
    company_name,
    cohort_name_jan,
    DATE_DIFF(month, DATE("2025-01-01"), MONTH) AS month_offset,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_score,
    segment_label
  FROM segments
  LEFT JOIN cohort
  ON segments.customer_id = cohort.customer_id
)
SELECT *
FROM final