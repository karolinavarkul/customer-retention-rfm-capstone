"""
make_transactions_flat.py

Purpose
-------
Transform the original retail CSV file into a fully transactional dataset.

The raw dataset contains grouped customer sections where:
- A row starting with "Customer-XXX" appears in the "Transaction ID" column.
- The corresponding region is stored in the "Date" column of that row.
- The following rows contain transaction-level data for that customer
  until the next "Customer-XXX" row appears.

This script:
- Extracts customer_id and region
- Forward-fills them to all related transaction rows
- Removes the customer header rows
- Outputs a clean transactional dataset ready for EDA and SQL analysis

Input
-----
data/raw/<original_file_name>.csv

Output
------
data/cleaned/transactions_flat.csv
"""

import pandas as pd

input_path = "data/raw/sales_raw.csv"
output_path = "data/cleaned/sales_flat.csv"

def main():
    # read as strings so nothing breaks
    df = pd.read_csv(input_path, dtype=str)
    
    # identify customer row
    is_customer_row = df["Transaction ID"].str.startswith("Customer", na=False)

    # extract Customer ID and Region
    df["Customer_ID"] = df["Transaction ID"].where(is_customer_row)
    df["Region"] = df["Date"].where(is_customer_row)

    # fill customer_ID and region for transactions
    df["Customer_ID"] = df["Customer_ID"].ffill()
    df["Region"] = df["Region"].ffill()

    # keep only transaction rows
    is_transaction_row = df["Transaction ID"].str.startswith("T", na=False)
    df = df[is_transaction_row].copy()

    # clean number columns
    for col in ["Quantity", "PPU", "Amount"]:
        if col in df.columns:
            df[col] = (
                df[col]
                .str.replace(",", "", regex=False)
                .str.strip()
            )
    
    # save cleaned file
    df.to_csv(output_path, index=False)


if __name__ == "__main__":
    main()