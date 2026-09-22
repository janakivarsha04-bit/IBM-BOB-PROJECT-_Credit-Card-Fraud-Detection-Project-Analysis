# 💳 Credit Card Fraud & Sales Analytics

**Author:** Janakivarshasree  
**Dataset:** `credit_card_fraud_2026.csv` (20,000 transactions)  
**Tools:** Python · Pandas · Matplotlib · Seaborn · Plotly · Streamlit

---

## 📌 Project Overview

This project performs end-to-end data analytics on a 2026 credit card transaction dataset. It covers:

1. **Data Collection & Loading** – Load and inspect the CSV dataset.
2. **Data Quality Check** – Identify and handle missing values, duplicates, and invalid records.
3. **Feature Engineering** – Derive `Sales = Quantity × Unit Price` and time-based features.
4. **Grouping & Summarisation** – Totals, counts, and averages by category, card type, channel, and day.
5. **Charts & Visualisations** – 10+ charts comparing fraud vs. legitimate transactions.
6. **Business Insights** – Actionable recommendations based on findings.

---

## 📁 Project Structure

```
master class5/
├── credit_card_fraud_2026.csv               ← Raw dataset (place here)
└── credit_card_fraud_analysis/
    ├── app.py                               ← Streamlit web dashboard
    ├── Janakivarshasree_CreditCardFraudAnalysis.ipynb  ← Jupyter Notebook analysis
    ├── Janakivarshasree_ProjectReport.docx             ← Full project report (Word)
    ├── Janakivarshasree_UIProjectReport.docx           ← UI output & dashboard report (Word)
    ├── requirements.txt                     ← Python dependencies
    └── README.md                            ← This file
```

---

## 📊 Dataset Columns

| Column | Description |
|---|---|
| `transaction_id` | Unique transaction identifier |
| `amount_usd` | Transaction amount in USD |
| `merchant_category` | Category of merchant (Groceries, Travel, Electronics …) |
| `card_type` | Card brand (Visa, Mastercard, Amex, RuPay, Discover) |
| `auth_method` | Authentication used (OTP, Biometric, PIN, 3D Secure …) |
| `channel` | Transaction channel (Online, POS, In-App, ATM, Contactless) |
| `device_type` | Device used (Android Phone, iPhone, Mac, POS Terminal …) |
| `is_foreign_transaction` | Whether the transaction was foreign |
| `txn_count_last_24h` | Number of transactions in last 24 hours (used as Quantity) |
| `velocity_score` | Risk velocity score |
| `merchant_risk_score` | Merchant risk score |
| `account_balance_usd` | Customer account balance |
| `customer_age` | Age of the customer |
| `is_fraud` | Target label: 1 = Fraud, 0 = Legitimate |

---

## 🔧 Feature Engineering

| Derived Feature | Formula |
|---|---|
| `quantity` | `txn_count_last_24h` (clipped to min 1) |
| `unit_price` | `amount_usd / quantity` |
| `sales` | `quantity × unit_price` = `amount_usd` ✅ |
| `day_name` | Readable day name from `day_of_week` |
| `time_period` | Morning / Afternoon / Evening / Night from `time_of_day_hour` |
| `fraud_label` | "Fraud" or "Legitimate" from `is_fraud` |

---

## 🚀 How to Run

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Launch the Streamlit Dashboard

**Option A – One-click (Windows):**
```
Double-click  run_dashboard.bat
```
This automatically installs packages, checks the dataset, and opens the browser at **http://localhost:8501**.

**Option B – Manual (any OS):**
```bash
cd "master class5/credit_card_fraud_analysis"
streamlit run app.py
```
The dashboard opens at **http://localhost:8501**

### 3. Open the Jupyter Notebook
```bash
jupyter notebook Janakivarshasree_CreditCardFraudAnalysis.ipynb
```

---

## 📈 Dashboard Tabs

| Tab | Content |
|---|---|
| 📈 Sales Overview | Sales by category, card type, and distribution histogram |
| 🚨 Fraud Analysis | Fraud vs legitimate breakdown, heatmaps, scatter plots |
| 📅 Time Patterns | Sales by day, hour, and time period |
| 🔐 Auth & Channel | Fraud rate by auth method, channel, and device type |
| 📋 Data Explorer | Raw data viewer, summary statistics, missing-value report |
| 💡 Business Insights | 8 actionable insight cards with recommendations |

---

## 💡 Key Findings

- **Fraud rate** across all transactions is approximately **10–12%**.
- **High velocity_score** is the strongest indicator of fraudulent activity.
- **No Authentication** method has the highest fraud rate — enforce step-up auth.
- **Biometric and 3D Secure** methods have the lowest fraud rates.
- **Electronics and Travel** categories show above-average fraud rates.
- **Peak transaction hours** are between 10 AM–2 PM — ideal for promotional targeting.

---

## 📝 Files Delivered

| File | Description |
|---|---|
| `Janakivarshasree_CreditCardFraudAnalysis.ipynb` | Full notebook with 7 sections and 10+ charts |
| `app.py` | Streamlit web dashboard with 6 tabs and 15+ interactive charts |
| `Janakivarshasree_ProjectReport.docx` | Formal project report in Microsoft Word format |
| `Janakivarshasree_UIProjectReport.docx` | UI output, dashboard screenshots & visual report |
| `credit_card_fraud_analysis.sql` | SQL file with 46 analytical queries |
| `run_dashboard.bat` | One-click Windows launcher — installs packages, checks dataset, opens browser |
| `requirements.txt` | All required Python packages |
| `README.md` | Project documentation (this file) |

---

*Project submitted as part of Data Analytics with AI – IBM × BharathCares Masterclass*
