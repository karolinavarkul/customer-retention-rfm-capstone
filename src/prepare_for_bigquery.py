"""
prepare_for_bigquery.py

Purpose
-------
Prepare the flattened sales transactions dataset for loading into BigQuery.

This script:
- Standardizes column headers to snake_case
- Parses and standardizes the date column
- Generates synthetic customer/company names for readability in analysis and dashboards

Input
-----
data/cleaned/sales_flat.csv

Output
------
data/cleaned/sales_clean.csv
data/cleaned/customer_name_map.csv
"""

import pandas as pd
import re
import random
from itertools import product

input_path = "data/cleaned/sales_flat.csv"
output_path_data = "data/cleaned/sales_clean.csv"
output_path_map = "data/cleaned/customer_name_map.csv"

adjectives = [
    "Golden", "Apex", "Summit", "Prime", "Delta",
    "Pioneer", "Everest", "Emerald", "Skyline", "Vertex",
    "Frontier", "Atlas", "Prestige", "Elite", "Nova",
    "Horizon", "Sterling", "Unity", "Capital", "Grand"
]

nouns = [
    "Trading", "Enterprises", "Solutions", "Industries",
    "Holdings", "Logistics", "Supplies", "Distribution",
    "Partners", "Technologies"
]

suffixes = [
    "Ltd.", "Co.", "LLC", "Inc.", "Group"
]

def to_snake_case(columns):
    cleaned_columns=[]

    for col in columns:
        col = col.strip().lower()
        col = re.sub(r"\s+", "_", col)
        cleaned_columns.append(col)
    
    return cleaned_columns

def generate_company_names(n: int, seed: int = 42) -> list[str]:
    # Build all possible combinations
    pool = [f"{a} {b} {c}" for a, b, c in product(adjectives, nouns, suffixes)]

    # Deterministically shuffle
    rng = random.Random(seed)
    rng.shuffle(pool)

    if n > len(pool):
        raise ValueError(f"Need {n} names but only {len(pool)} unique combinations available.")

    return pool[:n]

def main():
    df = pd.read_csv(input_path)

    df.columns = to_snake_case(df.columns)

    df["date"] = pd.to_datetime(df["date"], format="%d.%m.%Y")

    unique_customers = sorted(df["customer_id"].unique())
    company_names = generate_company_names(len(unique_customers), seed=42)

    customer_map = pd.DataFrame({
        "customer_id": unique_customers, "company_name": company_names
    })

    df = df.merge(customer_map, on="customer_id", how="left")

    customer_map.to_csv(output_path_map, index=False)
    df.to_csv(output_path_data, index=False)


if __name__ == "__main__":
    main()