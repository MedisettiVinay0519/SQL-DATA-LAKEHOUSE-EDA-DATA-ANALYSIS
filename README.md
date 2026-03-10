# SQL Data Warehouse Project 🚀

Welcome to the **Data Warehouse and Analytics Project** repository!  
This project demonstrates an **end-to-end modern data warehousing solution**, from raw data ingestion to business-ready analytics.

Designed as a **portfolio project**, it showcases **industry best practices** in:
- Data Engineering  
- SQL Development  
- Data Modeling  
- Analytics & Reporting  

---

## 🏗️ Data Architecture

This project follows the **Medallion Architecture** pattern with **Bronze**, **Silver**, and **Gold** layers.

### 🔹 Bronze Layer
- Stores raw data **as-is** from source systems  
- Data ingested from **CSV files** into **SQL Server**
- No transformations applied

### 🔸 Silver Layer
- Data cleansing and standardization
- Data validation and normalization
- Prepares data for analytical consumption

### ⭐ Gold Layer
- Business-ready, curated datasets
- Modeled using a **Star Schema**
- Optimized for reporting and analytics

---

## 📖 Project Overview

This project covers the complete data warehousing lifecycle:

- **Data Architecture**  
  Designing a modern data warehouse using the Medallion Architecture

- **ETL Pipelines**  
  Extracting, transforming, and loading data from ERP and CRM source systems

- **Data Modeling**  
  Building fact and dimension tables optimized for analytical queries

- **Analytics & Reporting**  
  Developing SQL-based analytical queries to generate actionable insights

---


## 🧰 Tools & Technologies Used

- **Datasets**: CSV files (ERP & CRM source systems)
- **SQL Server Express**: Data warehouse hosting
- **SQL Server Management Studio (SSMS)**: Database management and querying
- **Git & GitHub**: Version control and collaboration
- **Draw.io**: Architecture, ETL, data flow, and data model diagrams
- **Notion**: Project planning and task tracking

---

## 🚀 Project Requirements

### 🏗️ Data Engineering – Building the Data Warehouse

**Objective**  
Develop a modern data warehouse using SQL Server to consolidate sales data and enable analytical reporting.

**Specifications**
- **Data Sources**: ERP and CRM systems (CSV files)
- **Data Quality**: Clean and resolve data quality issues before analysis
- **Integration**: Merge multiple sources into a single analytical data model
- **Scope**: Focus on the latest dataset only (no historization required)
- **Documentation**: Provide clear and detailed data model documentation

---

### 📊 BI & Analytics – Reporting and Insights

**Objective**  
Develop SQL-based analytics to generate insights into:

- Customer Behavior  
- Product Performance  
- Sales Trends  

These insights help stakeholders track key business metrics and support strategic decision-making.

📄 For detailed requirements, see: `docs/requirements.md`

---

## 📂 Repository Structure

```text
data-warehouse-project/
│
├── datasets/                           # Raw datasets (ERP and CRM data)
│
├── docs/                               # Documentation and architecture artifacts
│   ├── etl.drawio                      # ETL techniques and workflows
│   ├── data_architecture.drawio        # Overall project architecture
│   ├── data_catalog.md                 # Dataset catalog and metadata
│   ├── data_flow.drawio                # Data flow diagrams
│   ├── data_models.drawio              # Star schema data models
│   ├── naming-conventions.md           # Naming standards
│
├── scripts/                            # SQL scripts
│   ├── bronze/                         # Raw data ingestion
│   ├── silver/                         # Data transformation and cleansing
│   ├── gold/                           # Analytical models
│
├── tests/                              # Data quality and validation tests
│
├── README.md                           # Project overview
├── LICENSE                             # License information
├── .gitignore                          # Git ignore rules
└── requirements.txt                    # Project dependencies
