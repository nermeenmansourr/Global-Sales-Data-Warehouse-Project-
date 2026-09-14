# Modern Data Warehouse & Medallion Pipeline

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC292B?style=flat&logo=microsoftsqlserver&logoColor=white)
![SSMS](https://img.shields.io/badge/SSMS-0078D4?style=flat&logo=microsoft&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=flat&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=flat&logo=github&logoColor=white)

> **Architecture:** Medallion Framework (Bronze, Silver, Gold)  
> **Target Engine:** SQL Server / T-SQL  
> **Source Systems:** ERP & CRM Datasets (CSV)

---

## Business Overview
This project showcases the design and deployment of an end-to-end SQL Data Warehouse using the Medallion Architecture. It ingests raw ERP and CRM operational data, applies structured cleansing and normalization pipelines, and constructs a business-ready dimensional model to drive analytics on revenue, customer purchasing habits, and product performance.

---

## Data Architecture & Medallion Layers

* **Bronze Layer (Raw Ingestion):** Ingests raw CSV source data from ERP/CRM directly into SQL Server tables without transformation, preserving source fidelity.
* **Silver Layer (Cleansing & Standardization):** Handles missing values, standardizes data types, removes duplicate records, and normalizes key attributes.
* **Gold Layer (Analytical Star Schema):** Constructs an optimized dimensional model with a central `Fact_Sales` table connected to `Dim_Customer`, `Dim_Product`, and `Dim_Date` tables for fast OLAP querying.

---

## Data Pipeline Architecture

```text
[ERP & CRM CSVs] ──(Extract)──> [Bronze: Raw Staging] ──(Transform)──> [Silver: Cleaned Data] ──(Load)──> [Gold: Star Schema]
