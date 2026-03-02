-- =====================================================
-- STAR SCHEMA CREATION
-- Project: Customer Retention RFM Capstone
-- =====================================================

-- -----------------------------------------------------
-- 1. Fact: Transactions
-- --------------------------------------------------------
CREATE TABLE rfm_capstone.fact_transactions AS
SELECT DISTINCT
    transaction_id,
    date,
    customer_id,
    product_id,
    quantity,
    ppu,
    amount
FROM rfm_capstone.raw_transactions;

-- -----------------------------------------------------
-- 2. Dimension: Customers
-- --------------------------------------------------------
CREATE TABLE rfm_capstone.dim_customers AS
SELECT DISTINCT
    customer_id,
    company_name,
    region
FROM rfm_capstone.raw_transactions;

-- -----------------------------------------------------
-- 3. Dimension: Products
-- --------------------------------------------------------
CREATE TABLE rfm_capstone.dim_products AS
SELECT DISTINCT
    product_id,
    product_name,
    product_category
FROM rfm_capstone.raw_transactions;