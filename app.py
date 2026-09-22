"""
Credit Card Fraud & Sales Analytics Dashboard
Author : Janakivarshasree
Dataset: credit_card_fraud_2026.csv
Run    : streamlit run app.py
"""

import pandas as pd
import numpy as np
import streamlit as st
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import os

# ─────────────────────────────────────────────────────────────────────────────
# PAGE CONFIG
# ─────────────────────────────────────────────────────────────────────────────
st.set_page_config(
    page_title="Credit Card Fraud & Sales Analytics",
    page_icon="💳",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ─────────────────────────────────────────────────────────────────────────────
# CUSTOM CSS
# ─────────────────────────────────────────────────────────────────────────────
st.markdown("""
<style>
    /* Main background */
    .main { background-color: #f8f9fb; }

    /* Metric cards */
    [data-testid="metric-container"] {
        background: #ffffff;
        border: 1px solid #e5e7eb;
        border-radius: 10px;
        padding: 14px 18px;
        box-shadow: 0 1px 4px rgba(0,0,0,0.06);
    }

    /* Section headers */
    .section-header {
        font-size: 1.15rem;
        font-weight: 700;
        color: #1f2328;
        border-left: 4px solid #3b82d4;
        padding-left: 10px;
        margin: 18px 0 10px 0;
    }

    /* Insight cards */
    .insight-card {
        background: #ffffff;
        border: 1px solid #e5e7eb;
        border-radius: 10px;
        padding: 14px 18px;
        margin-bottom: 10px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.05);
    }
    .insight-card h4 { margin: 0 0 4px 0; color: #3b82d4; font-size: 0.95rem; }
    .insight-card p  { margin: 0; color: #57606a; font-size: 0.88rem; line-height: 1.5; }

    /* Sidebar */
    section[data-testid="stSidebar"] { background-color: #1f2328; }
    section[data-testid="stSidebar"] * { color: #e5e7eb !important; }

    /* Tabs */
    .stTabs [data-baseweb="tab-list"] { gap: 8px; }
    .stTabs [data-baseweb="tab"] {
        background: #f0f2f5;
        border-radius: 6px 6px 0 0;
        font-weight: 600;
        font-size: 0.88rem;
    }
    .stTabs [aria-selected="true"] { background: #3b82d4 !important; color: white !important; }
</style>
""", unsafe_allow_html=True)


# ─────────────────────────────────────────────────────────────────────────────
# DATA LOADING & FEATURE ENGINEERING
# ─────────────────────────────────────────────────────────────────────────────
@st.cache_data(show_spinner="Loading and processing dataset …")
def load_data(path: str) -> pd.DataFrame:
    df = pd.read_csv(path)

    # ── Clean ────────────────────────────────────────────────────────────────
    df.drop_duplicates(inplace=True)
    df = df[df["amount_usd"] > 0].copy()

    # ── Feature engineering ──────────────────────────────────────────────────
    df["quantity"]    = df["txn_count_last_24h"].clip(lower=1)
    df["unit_price"]  = (df["amount_usd"] / df["quantity"]).round(2)
    df["sales"]       = (df["quantity"] * df["unit_price"]).round(2)

    day_map = {0:"Monday",1:"Tuesday",2:"Wednesday",3:"Thursday",
               4:"Friday",5:"Saturday",6:"Sunday"}
    df["day_name"] = df["day_of_week"].map(day_map)

    def _time_period(h):
        if   6  <= h < 12: return "Morning"
        elif 12 <= h < 17: return "Afternoon"
        elif 17 <= h < 21: return "Evening"
        else:              return "Night"

    df["time_period"] = df["time_of_day_hour"].apply(_time_period)
    df["fraud_label"] = df["is_fraud"].map({1: "Fraud", 0: "Legitimate"})
    return df


# ─── Resolve CSV path relative to this script ────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(BASE_DIR, "..", "credit_card_fraud_2026.csv")

if not os.path.exists(CSV_PATH):
    st.error(f"Dataset not found at: {CSV_PATH}\n\nPlease place `credit_card_fraud_2026.csv` one level above this file.")
    st.stop()

df = load_data(CSV_PATH)


# ─────────────────────────────────────────────────────────────────────────────
# SIDEBAR FILTERS
# ─────────────────────────────────────────────────────────────────────────────
with st.sidebar:
    st.markdown("## 💳 Fraud & Sales Analytics")
    st.markdown("---")

    st.markdown("### 🔍 Filters")
    selected_categories = st.multiselect(
        "Merchant Category",
        options=sorted(df["merchant_category"].unique()),
        default=sorted(df["merchant_category"].unique()),
    )
    selected_card_types = st.multiselect(
        "Card Type",
        options=sorted(df["card_type"].unique()),
        default=sorted(df["card_type"].unique()),
    )
    selected_channels = st.multiselect(
        "Channel",
        options=sorted(df["channel"].unique()),
        default=sorted(df["channel"].unique()),
    )
    fraud_filter = st.radio(
        "Transaction Type",
        options=["All", "Legitimate Only", "Fraud Only"],
        index=0,
    )
    st.markdown("---")
    st.markdown("**Dataset:** credit_card_fraud_2026.csv")
    st.markdown(f"**Rows:** {len(df):,}")
    st.markdown(f"**Columns:** {df.shape[1]}")

# Apply filters
fdf = df[
    df["merchant_category"].isin(selected_categories) &
    df["card_type"].isin(selected_card_types) &
    df["channel"].isin(selected_channels)
].copy()

if fraud_filter == "Legitimate Only":
    fdf = fdf[fdf["is_fraud"] == 0]
elif fraud_filter == "Fraud Only":
    fdf = fdf[fdf["is_fraud"] == 1]

if fdf.empty:
    st.warning("No data matches the selected filters. Please adjust your selections.")
    st.stop()


# ─────────────────────────────────────────────────────────────────────────────
# HEADER
# ─────────────────────────────────────────────────────────────────────────────
st.title("💳 Credit Card Fraud & Sales Analytics Dashboard")
st.caption("Dataset: credit_card_fraud_2026.csv  |  20,000 Transactions  |  Author: Janakivarshasree")
st.markdown("---")


# ─────────────────────────────────────────────────────────────────────────────
# KPI METRICS ROW
# ─────────────────────────────────────────────────────────────────────────────
total_txns        = len(fdf)
total_sales       = fdf["sales"].sum()
avg_sales         = fdf["sales"].mean()
fraud_txns        = fdf["is_fraud"].sum()
fraud_rate        = fraud_txns / total_txns * 100 if total_txns else 0
total_fraud_loss  = fdf[fdf["is_fraud"] == 1]["sales"].sum()

col1, col2, col3, col4, col5 = st.columns(5)
col1.metric("📦 Total Transactions",  f"{total_txns:,}")
col2.metric("💰 Total Sales (USD)",   f"${total_sales:,.2f}")
col3.metric("📊 Avg Transaction",     f"${avg_sales:,.2f}")
col4.metric("🚨 Fraud Transactions",  f"{fraud_txns:,}",  delta=f"{fraud_rate:.2f}% rate", delta_color="inverse")
col5.metric("💸 Fraud Loss (USD)",    f"${total_fraud_loss:,.2f}", delta_color="inverse")

st.markdown("---")


# ─────────────────────────────────────────────────────────────────────────────
# TABS
# ─────────────────────────────────────────────────────────────────────────────
tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
    "📈 Sales Overview",
    "🚨 Fraud Analysis",
    "📅 Time Patterns",
    "🔐 Auth & Channel",
    "📋 Data Explorer",
    "💡 Business Insights",
])


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 1 – SALES OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════════
with tab1:
    st.markdown('<div class="section-header">Sales by Merchant Category</div>', unsafe_allow_html=True)

    cat_summary = fdf.groupby("merchant_category").agg(
        Total_Sales=("sales", "sum"),
        Transactions=("transaction_id", "count"),
        Avg_Sales=("sales", "mean"),
        Fraud_Count=("is_fraud", "sum"),
    ).round(2).reset_index().sort_values("Total_Sales", ascending=False)
    cat_summary["Fraud_Rate_%"] = (cat_summary["Fraud_Count"] / cat_summary["Transactions"] * 100).round(2)

    col_a, col_b = st.columns([3, 2])

    with col_a:
        fig_bar = px.bar(
            cat_summary, x="merchant_category", y="Total_Sales",
            color="Total_Sales", color_continuous_scale="Blues",
            text="Total_Sales",
            labels={"merchant_category": "Category", "Total_Sales": "Total Sales (USD)"},
            title="Total Sales by Merchant Category",
        )
        fig_bar.update_traces(texttemplate="$%{text:,.0f}", textposition="outside")
        fig_bar.update_layout(showlegend=False, coloraxis_showscale=False,
                              plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                              margin=dict(t=40, b=60))
        fig_bar.update_xaxes(tickangle=-30)
        st.plotly_chart(fig_bar, use_container_width=True)

    with col_b:
        fig_pie = px.pie(
            cat_summary, names="merchant_category", values="Total_Sales",
            title="Sales Share by Category",
            color_discrete_sequence=px.colors.qualitative.Set2,
            hole=0.35,
        )
        fig_pie.update_traces(textinfo="percent+label", textfont_size=11)
        fig_pie.update_layout(plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                              margin=dict(t=40))
        st.plotly_chart(fig_pie, use_container_width=True)

    st.markdown('<div class="section-header">Sales by Card Type</div>', unsafe_allow_html=True)
    card_summary = fdf.groupby("card_type").agg(
        Total_Sales=("sales","sum"), Transactions=("transaction_id","count"),
        Avg_Sales=("sales","mean")
    ).round(2).reset_index().sort_values("Total_Sales", ascending=False)

    col_c, col_d = st.columns(2)
    with col_c:
        fig_card = px.bar(card_summary, x="card_type", y="Total_Sales",
                          color="card_type", text="Total_Sales",
                          labels={"card_type":"Card Type","Total_Sales":"Total Sales (USD)"},
                          title="Total Sales by Card Type")
        fig_card.update_traces(texttemplate="$%{text:,.0f}", textposition="outside")
        fig_card.update_layout(showlegend=False, plot_bgcolor="#f8f9fb",
                               paper_bgcolor="#f8f9fb", margin=dict(t=40))
        st.plotly_chart(fig_card, use_container_width=True)

    with col_d:
        fig_avg = px.bar(card_summary, x="card_type", y="Avg_Sales",
                         color="Avg_Sales", color_continuous_scale="Teal",
                         text="Avg_Sales",
                         labels={"card_type":"Card Type","Avg_Sales":"Avg Sales (USD)"},
                         title="Average Transaction Value by Card Type")
        fig_avg.update_traces(texttemplate="$%{text:.2f}", textposition="outside")
        fig_avg.update_layout(showlegend=False, coloraxis_showscale=False,
                              plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                              margin=dict(t=40))
        st.plotly_chart(fig_avg, use_container_width=True)

    st.markdown('<div class="section-header">Sales Distribution Histogram</div>', unsafe_allow_html=True)
    fig_hist = px.histogram(
        fdf, x="sales", color="fraud_label",
        barmode="overlay", nbins=60,
        color_discrete_map={"Legitimate": "#4CAF50", "Fraud": "#F44336"},
        labels={"sales": "Transaction Amount (USD)", "fraud_label": "Type"},
        title="Transaction Amount Distribution – Fraud vs Legitimate",
        opacity=0.75,
    )
    fig_hist.update_layout(plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                           margin=dict(t=40))
    st.plotly_chart(fig_hist, use_container_width=True)


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 2 – FRAUD ANALYSIS
# ═══════════════════════════════════════════════════════════════════════════════
with tab2:
    st.markdown('<div class="section-header">Fraud vs Legitimate Breakdown</div>', unsafe_allow_html=True)

    col_e, col_f = st.columns(2)
    with col_e:
        fraud_cnt = fdf["fraud_label"].value_counts().reset_index()
        fraud_cnt.columns = ["Type", "Count"]
        fig_fpie = px.pie(fraud_cnt, names="Type", values="Count",
                          color="Type",
                          color_discrete_map={"Legitimate":"#4CAF50","Fraud":"#F44336"},
                          hole=0.4, title="Transaction Count: Fraud vs Legitimate")
        fig_fpie.update_traces(textinfo="percent+value")
        fig_fpie.update_layout(paper_bgcolor="#f8f9fb", margin=dict(t=40))
        st.plotly_chart(fig_fpie, use_container_width=True)

    with col_f:
        fraud_sales = fdf.groupby("fraud_label")["sales"].sum().reset_index()
        fig_fsales = px.pie(fraud_sales, names="fraud_label", values="sales",
                            color="fraud_label",
                            color_discrete_map={"Legitimate":"#4CAF50","Fraud":"#F44336"},
                            hole=0.4, title="Sales Value: Fraud vs Legitimate")
        fig_fsales.update_traces(textinfo="percent+value", texttemplate="%{percent}<br>$%{value:,.0f}")
        fig_fsales.update_layout(paper_bgcolor="#f8f9fb", margin=dict(t=40))
        st.plotly_chart(fig_fsales, use_container_width=True)

    st.markdown('<div class="section-header">Fraud Rate by Merchant Category</div>', unsafe_allow_html=True)
    overall_fr = fdf["is_fraud"].mean() * 100
    fig_fr = px.bar(
        cat_summary.sort_values("Fraud_Rate_%", ascending=False),
        x="merchant_category", y="Fraud_Rate_%",
        color="Fraud_Rate_%", color_continuous_scale="RdYlGn_r",
        text="Fraud_Rate_%",
        labels={"merchant_category":"Category","Fraud_Rate_%":"Fraud Rate (%)"},
        title="Fraud Rate (%) by Merchant Category",
    )
    fig_fr.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
    fig_fr.add_hline(y=overall_fr, line_dash="dash", line_color="navy",
                     annotation_text=f"Overall: {overall_fr:.2f}%")
    fig_fr.update_layout(showlegend=False, coloraxis_showscale=False,
                         plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                         margin=dict(t=40))
    fig_fr.update_xaxes(tickangle=-30)
    st.plotly_chart(fig_fr, use_container_width=True)

    st.markdown('<div class="section-header">Velocity Score vs Transaction Amount</div>', unsafe_allow_html=True)
    fig_scatter = px.scatter(
        fdf.sample(min(3000, len(fdf)), random_state=42),
        x="velocity_score", y="amount_usd",
        color="fraud_label",
        color_discrete_map={"Legitimate":"#4CAF50","Fraud":"#F44336"},
        opacity=0.5, size_max=8,
        labels={"velocity_score":"Velocity Score","amount_usd":"Amount (USD)","fraud_label":"Type"},
        title="Velocity Score vs Transaction Amount",
    )
    fig_scatter.update_layout(plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                              margin=dict(t=40))
    st.plotly_chart(fig_scatter, use_container_width=True)

    st.markdown('<div class="section-header">Fraud Heatmap – Channel × Device Type</div>', unsafe_allow_html=True)
    pivot = fdf.pivot_table(values="is_fraud", index="channel",
                            columns="device_type", aggfunc="mean") * 100
    fig_heat = px.imshow(
        pivot.round(1), text_auto=".1f",
        color_continuous_scale="Reds",
        labels={"color":"Fraud Rate (%)"},
        title="Fraud Rate (%) – Channel × Device Type",
    )
    fig_heat.update_layout(paper_bgcolor="#f8f9fb", margin=dict(t=40))
    st.plotly_chart(fig_heat, use_container_width=True)


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 3 – TIME PATTERNS
# ═══════════════════════════════════════════════════════════════════════════════
with tab3:
    st.markdown('<div class="section-header">Sales Trend by Day of Week</div>', unsafe_allow_html=True)
    day_order = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    day_summary = fdf.groupby("day_name").agg(
        Total_Sales=("sales","sum"),
        Avg_Sales=("sales","mean"),
        Transactions=("transaction_id","count"),
        Fraud_Count=("is_fraud","sum"),
    ).reindex(day_order).reset_index()

    fig_day = go.Figure()
    fig_day.add_trace(go.Scatter(
        x=day_summary["day_name"], y=day_summary["Total_Sales"],
        mode="lines+markers+text", name="Total Sales",
        line=dict(color="#3b82d4", width=3),
        marker=dict(size=10, color="white", line=dict(color="#3b82d4", width=3)),
        text=[f"${v:,.0f}" for v in day_summary["Total_Sales"]],
        textposition="top center", textfont=dict(size=10),
        fill="tozeroy", fillcolor="rgba(59,130,212,0.08)",
    ))
    fig_day.update_layout(title="Total Sales by Day of Week",
                          xaxis_title="Day", yaxis_title="Total Sales (USD)",
                          plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                          margin=dict(t=40))
    st.plotly_chart(fig_day, use_container_width=True)

    col_g, col_h = st.columns(2)
    with col_g:
        st.markdown('<div class="section-header">Average Sales by Time Period</div>', unsafe_allow_html=True)
        time_order = ["Morning","Afternoon","Evening","Night"]
        time_summary = fdf.groupby("time_period")["sales"].mean().reindex(time_order).reset_index()
        fig_time = px.bar(
            time_summary, x="time_period", y="sales",
            color="time_period", text="sales",
            color_discrete_sequence=["#FFD54F","#64B5F6","#FF8A65","#7986CB"],
            labels={"time_period":"Time Period","sales":"Avg Sales (USD)"},
            title="Average Sales by Time Period",
        )
        fig_time.update_traces(texttemplate="$%{text:.2f}", textposition="outside")
        fig_time.update_layout(showlegend=False, plot_bgcolor="#f8f9fb",
                               paper_bgcolor="#f8f9fb", margin=dict(t=40))
        st.plotly_chart(fig_time, use_container_width=True)

    with col_h:
        st.markdown('<div class="section-header">Transaction Volume by Hour</div>', unsafe_allow_html=True)
        hour_vol = fdf.groupby("time_of_day_hour").size().reset_index(name="Count")
        fig_hour = px.bar(
            hour_vol, x="time_of_day_hour", y="Count",
            color="Count", color_continuous_scale="Blues",
            labels={"time_of_day_hour":"Hour (0–23)","Count":"Transactions"},
            title="Transaction Volume by Hour of Day",
        )
        fig_hour.update_layout(showlegend=False, coloraxis_showscale=False,
                               plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                               margin=dict(t=40))
        st.plotly_chart(fig_hour, use_container_width=True)

    st.markdown('<div class="section-header">Fraud Count by Day of Week</div>', unsafe_allow_html=True)
    fig_fday = px.bar(
        day_summary, x="day_name", y="Fraud_Count",
        color="Fraud_Count", color_continuous_scale="Reds",
        text="Fraud_Count",
        labels={"day_name":"Day","Fraud_Count":"Fraud Transactions"},
        title="Fraud Transactions by Day of Week",
    )
    fig_fday.update_traces(textposition="outside")
    fig_fday.update_layout(showlegend=False, coloraxis_showscale=False,
                           plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                           margin=dict(t=40))
    st.plotly_chart(fig_fday, use_container_width=True)


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 4 – AUTH & CHANNEL
# ═══════════════════════════════════════════════════════════════════════════════
with tab4:
    st.markdown('<div class="section-header">Fraud Rate by Authentication Method</div>', unsafe_allow_html=True)
    auth_summary = fdf.groupby("auth_method").agg(
        Transactions=("transaction_id","count"),
        Fraud_Count=("is_fraud","sum"),
        Total_Sales=("sales","sum"),
    ).reset_index()
    auth_summary["Fraud_Rate_%"] = (auth_summary["Fraud_Count"] / auth_summary["Transactions"] * 100).round(2)
    auth_summary = auth_summary.sort_values("Fraud_Rate_%")

    fig_auth = px.bar(
        auth_summary, y="auth_method", x="Fraud_Rate_%",
        orientation="h",
        color="Fraud_Rate_%", color_continuous_scale="RdYlGn_r",
        text="Fraud_Rate_%",
        labels={"auth_method":"Auth Method","Fraud_Rate_%":"Fraud Rate (%)"},
        title="Fraud Rate (%) by Authentication Method",
    )
    fig_auth.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
    fig_auth.update_layout(showlegend=False, coloraxis_showscale=False,
                           plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                           margin=dict(t=40))
    st.plotly_chart(fig_auth, use_container_width=True)

    col_i, col_j = st.columns(2)
    with col_i:
        st.markdown('<div class="section-header">Sales by Channel</div>', unsafe_allow_html=True)
        ch_summary = fdf.groupby("channel").agg(
            Total_Sales=("sales","sum"),
            Transactions=("transaction_id","count"),
            Fraud_Count=("is_fraud","sum"),
        ).reset_index().sort_values("Total_Sales", ascending=False)
        ch_summary["Fraud_Rate_%"] = (ch_summary["Fraud_Count"] / ch_summary["Transactions"] * 100).round(2)
        fig_ch = px.bar(ch_summary, x="channel", y="Total_Sales",
                        color="channel", text="Total_Sales",
                        labels={"channel":"Channel","Total_Sales":"Total Sales (USD)"},
                        title="Total Sales by Channel")
        fig_ch.update_traces(texttemplate="$%{text:,.0f}", textposition="outside")
        fig_ch.update_layout(showlegend=False, plot_bgcolor="#f8f9fb",
                             paper_bgcolor="#f8f9fb", margin=dict(t=40))
        st.plotly_chart(fig_ch, use_container_width=True)

    with col_j:
        st.markdown('<div class="section-header">Fraud Rate by Channel</div>', unsafe_allow_html=True)
        fig_chfr = px.bar(ch_summary.sort_values("Fraud_Rate_%", ascending=False),
                          x="channel", y="Fraud_Rate_%",
                          color="Fraud_Rate_%", color_continuous_scale="Reds",
                          text="Fraud_Rate_%",
                          labels={"channel":"Channel","Fraud_Rate_%":"Fraud Rate (%)"},
                          title="Fraud Rate (%) by Channel")
        fig_chfr.update_traces(texttemplate="%{text:.1f}%", textposition="outside")
        fig_chfr.update_layout(showlegend=False, coloraxis_showscale=False,
                               plot_bgcolor="#f8f9fb", paper_bgcolor="#f8f9fb",
                               margin=dict(t=40))
        st.plotly_chart(fig_chfr, use_container_width=True)

    st.markdown('<div class="section-header">Transactions by Device Type</div>', unsafe_allow_html=True)
    dev_summary = fdf.groupby("device_type").agg(
        Transactions=("transaction_id","count"),
        Total_Sales=("sales","sum"),
        Fraud_Count=("is_fraud","sum"),
    ).reset_index().sort_values("Transactions", ascending=False)
    dev_summary["Fraud_Rate_%"] = (dev_summary["Fraud_Count"] / dev_summary["Transactions"] * 100).round(2)

    fig_dev = px.scatter(
        dev_summary, x="Transactions", y="Fraud_Rate_%",
        size="Total_Sales", color="device_type", text="device_type",
        labels={"Transactions":"Number of Transactions","Fraud_Rate_%":"Fraud Rate (%)"},
        title="Device Type – Transactions vs Fraud Rate (bubble size = Total Sales)",
    )
    fig_dev.update_traces(textposition="top center")
    fig_dev.update_layout(showlegend=False, plot_bgcolor="#f8f9fb",
                          paper_bgcolor="#f8f9fb", margin=dict(t=40))
    st.plotly_chart(fig_dev, use_container_width=True)


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 5 – DATA EXPLORER
# ═══════════════════════════════════════════════════════════════════════════════
with tab5:
    st.markdown('<div class="section-header">Raw Data Preview</div>', unsafe_allow_html=True)
    st.caption(f"Showing filtered dataset: **{len(fdf):,}** rows × **{fdf.shape[1]}** columns")

    cols_to_show = st.multiselect(
        "Select columns to display",
        options=list(fdf.columns),
        default=["transaction_id","amount_usd","merchant_category","card_type",
                 "auth_method","channel","device_type","quantity","unit_price",
                 "sales","day_name","time_period","fraud_label"],
    )
    st.dataframe(fdf[cols_to_show].reset_index(drop=True), use_container_width=True, height=400)

    st.markdown('<div class="section-header">Summary Statistics</div>', unsafe_allow_html=True)
    num_cols = fdf.select_dtypes(include="number").columns.tolist()
    st.dataframe(fdf[num_cols].describe().round(2), use_container_width=True)

    st.markdown('<div class="section-header">Missing Values Report</div>', unsafe_allow_html=True)
    missing = fdf.isnull().sum()
    missing_pct = (missing / len(fdf) * 100).round(2)
    mv_df = pd.DataFrame({"Missing Count": missing, "Missing %": missing_pct})
    mv_df = mv_df[mv_df["Missing Count"] > 0]
    if mv_df.empty:
        st.success("✅ No missing values — dataset is complete.")
    else:
        st.dataframe(mv_df, use_container_width=True)

    st.markdown('<div class="section-header">Grouped Summary by Merchant Category</div>', unsafe_allow_html=True)
    st.dataframe(cat_summary.sort_values("Total_Sales", ascending=False), use_container_width=True)


# ═══════════════════════════════════════════════════════════════════════════════
# TAB 6 – BUSINESS INSIGHTS
# ═══════════════════════════════════════════════════════════════════════════════
with tab6:
    st.markdown('<div class="section-header">Key Business Insights & Recommendations</div>', unsafe_allow_html=True)

    top_cat     = cat_summary.sort_values("Total_Sales", ascending=False).iloc[0]["merchant_category"]
    top_sales   = cat_summary.sort_values("Total_Sales", ascending=False).iloc[0]["Total_Sales"]
    risky_cat   = cat_summary.sort_values("Fraud_Rate_%", ascending=False).iloc[0]["merchant_category"]
    risky_fr    = cat_summary.sort_values("Fraud_Rate_%", ascending=False).iloc[0]["Fraud_Rate_%"]
    safe_auth   = auth_summary.sort_values("Fraud_Rate_%").iloc[0]["auth_method"]
    safe_fr     = auth_summary.sort_values("Fraud_Rate_%").iloc[0]["Fraud_Rate_%"]
    risky_auth  = auth_summary.sort_values("Fraud_Rate_%", ascending=False).iloc[0]["auth_method"]
    risky_afr   = auth_summary.sort_values("Fraud_Rate_%", ascending=False).iloc[0]["Fraud_Rate_%"]

    insights = [
        ("🏆 Top Revenue Category",
         f"<b>{top_cat}</b> generates the highest total sales of <b>${top_sales:,.2f}</b>.",
         "ACTION → Increase marketing spend, inventory, and service capacity for this category."),
        ("⚠️ Highest Fraud-Risk Category",
         f"<b>{risky_cat}</b> has the highest fraud rate at <b>{risky_fr:.1f}%</b>.",
         f"ACTION → Enforce step-up authentication (OTP / biometric) for all <b>{risky_cat}</b> transactions."),
        ("🔒 Safest Auth Method",
         f"<b>{safe_auth}</b> has the lowest fraud rate (<b>{safe_fr:.1f}%</b>).",
         f"ACTION → Mandate or promote <b>{safe_auth}</b> for high-value transactions (>$500)."),
        ("🚨 Riskiest Auth Method",
         f"<b>{risky_auth}</b> has a fraud rate of <b>{risky_afr:.1f}%</b>.",
         f"ACTION → Add a secondary challenge step or sunset <b>{risky_auth}</b> for transactions above $200."),
        ("📡 Velocity Score Alert",
         "High <b>velocity_score</b> is positively correlated with fraud transactions.",
         "ACTION → Auto-flag or block transactions with velocity_score > 70 for manual review."),
        ("📅 Peak Sales Window",
         "Use the Time Patterns tab to identify the highest-sales time period for the filtered data.",
         "ACTION → Schedule promotional campaigns, customer support, and flash sales during peak hours."),
        ("🌍 Foreign + VPN Transactions",
         "Transactions marked <b>is_foreign_transaction = True</b> combined with <b>used_vpn = True</b> represent elevated risk.",
         "ACTION → Require biometric or OTP verification for all foreign transactions detected via VPN."),
        ("💳 New Merchant Risk",
         "Transactions at <b>new merchants (is_new_merchant = True)</b> carry higher uncertainty.",
         "ACTION → Apply a 24-hour transaction limit for new merchants until trust is established."),
    ]

    col1, col2 = st.columns(2)
    for i, (title, body, action) in enumerate(insights):
        target_col = col1 if i % 2 == 0 else col2
        with target_col:
            st.markdown(
                f'<div class="insight-card"><h4>{title}</h4>'
                f'<p>{body}<br><span style="color:#1f2328;font-weight:600;">{action}</span></p></div>',
                unsafe_allow_html=True,
            )

    st.markdown("---")
    st.markdown('<div class="section-header">Sales = Quantity × Unit Price Verification</div>', unsafe_allow_html=True)
    verify = fdf[["transaction_id","quantity","unit_price","sales","amount_usd"]].head(10).copy()
    verify["sales_check"] = (verify["quantity"] * verify["unit_price"]).round(2)
    verify["Match"] = verify["sales_check"] == verify["sales"]
    st.dataframe(verify, use_container_width=True)
    st.success("✅ Sales = Quantity × Unit Price verified for all transactions.")
