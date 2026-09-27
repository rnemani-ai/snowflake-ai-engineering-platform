import os
import streamlit as st
import pandas as pd
import altair as alt

st.set_page_config(page_title="DQ Monitoring Dashboard", layout="wide")
conn = st.connection("snowflake", ttl=os.getenv("SNOWFLAKE_CONNECTION_TTL"))

# -- Enterprise color palette --
C_PASS = "#10B981"
C_FAIL = "#EF4444"
C_WARN = "#F59E0B"
C_INFO = "#3B82F6"
C_PURPLE = "#8B5CF6"
C_TEAL = "#14B8A6"
C_SLATE = "#64748B"
SEVERITY_COLORS = {"HIGH": "#EF4444", "MEDIUM": "#F59E0B", "LOW": "#3B82F6"}
STATUS_COLORS = {"PASS": C_PASS, "FAIL": C_FAIL}
TYPE_PALETTE = ["#6366F1", "#EC4899", "#14B8A6", "#F59E0B", "#3B82F6", "#8B5CF6", "#EF4444"]


def alt_theme():
    return {
        "config": {
            "background": "transparent",
            "axis": {"labelFontSize": 11, "titleFontSize": 12, "titleColor": "#475569", "labelColor": "#64748B", "gridColor": "#E2E8F0", "domainColor": "#CBD5E1"},
            "legend": {"labelFontSize": 11, "titleFontSize": 12},
            "view": {"strokeWidth": 0},
            "title": {"fontSize": 14, "color": "#1E293B"},
        }
    }


alt.themes.register("enterprise", alt_theme)
alt.themes.enable("enterprise")


@st.cache_data(ttl=120)
def load_rule_results():
    return conn.query("SELECT RESULT_ID, RUN_ID, RULE_ID, DB_NAME, TABLE_NAME, COLUMN_NAME, RULE_NAME, RULE_TYPE, EXPECTED_VALUE, ACTUAL_VALUE, FAILED_RECORD_COUNT, TOTAL_RECORD_COUNT, PASS_PERCENTAGE, RESULT_STATUS, SEVERITY, EXECUTED_AT FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_RESULTS ORDER BY EXECUTED_AT DESC")


@st.cache_data(ttl=120)
def load_rule_config():
    return conn.query("SELECT RULE_ID, RULE_NAME, RULE_TYPE, CRITICALITY, DB_NAME, TABLE_NM, COLUMN_NM, RULE_DESCRIPTION, THRESHOLD_VALUE, RULE_DIMENSION, IS_ACTIVE FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RULE_CONFIG ORDER BY RULE_ID")


@st.cache_data(ttl=120)
def load_anomalies():
    return conn.query("SELECT ANOMALY_ID, RUN_ID, DATABASE_NAME, SCHEMA_NAME, TABLE_NAME, METRIC_NAME, CURRENT_VALUE, PREVIOUS_VALUE, BASELINE_AVG, BASELINE_STDDEV, ANOMALY_STATUS, ANOMALY_REASON, DETECTED_AT FROM BANKING_DQ_DB.DQ_MONITORING.DQ_ANOMALY_RESULTS ORDER BY DETECTED_AT DESC")


@st.cache_data(ttl=120)
def load_error_records():
    return conn.query("SELECT ERROR_ID, RUN_ID, RULE_ID, DB_NAME, TABLE_NAME, ERROR_RECORD_VARIANT, ERROR_REASON, CREATED_AT FROM BANKING_DQ_DB.DQ_MONITORING.DQ_ERROR_RECORDS ORDER BY CREATED_AT DESC")


@st.cache_data(ttl=120)
def load_run_control():
    return conn.query("SELECT RUN_ID, RULE_ID, RUN_START_TIME, RUN_END_TIME, RULE_EXEC_RESULT, RULE_OUTPUT_VALUE, RUN_STATUS, TRIGGERED_BY, ERROR_MESSAGE FROM BANKING_DQ_DB.DQ_MONITORING.DQ_RUN_CONTROL ORDER BY RUN_START_TIME DESC")


with st.spinner("Loading data quality metrics..."):
    results_df = load_rule_results()
    config_df = load_rule_config()
    anomalies_df = load_anomalies()
    errors_df = load_error_records()
    runs_df = load_run_control()

# -- Sidebar --
with st.sidebar:
    st.header("Data quality filters", divider="blue")
    if st.button("Refresh data", on_click=load_rule_results.clear, type="primary"):
        load_rule_config.clear()
        load_anomalies.clear()
        load_error_records.clear()
        load_run_control.clear()
        st.rerun()
    st.space("small")

if not results_df.empty:
    latest_results = results_df.sort_values("EXECUTED_AT", ascending=False).drop_duplicates(subset=["RULE_NAME"], keep="first")
else:
    latest_results = pd.DataFrame()

with st.sidebar:
    all_tables = sorted(latest_results["TABLE_NAME"].dropna().unique()) if not latest_results.empty else []
    sel_tables = st.multiselect("Tables", all_tables, default=all_tables)
    all_types = sorted(latest_results["RULE_TYPE"].dropna().unique()) if not latest_results.empty else []
    sel_types = st.multiselect("Rule type", all_types, default=all_types)
    all_severities = sorted(latest_results["SEVERITY"].dropna().unique()) if not latest_results.empty else []
    sel_severities = st.multiselect("Severity", all_severities, default=all_severities)
    sel_statuses = st.multiselect("Status", ["PASS", "FAIL"], default=["PASS", "FAIL"])
    st.space("small")
    if not results_df.empty:
        last_run = pd.to_datetime(results_df["EXECUTED_AT"].max())
        st.caption(f"Last run: {last_run.strftime('%b %d, %Y %H:%M')}")
    st.caption(f"BANKING_DQ_DB.RAW")

if not latest_results.empty:
    filtered = latest_results[
        (latest_results["TABLE_NAME"].isin(sel_tables)) & (latest_results["RULE_TYPE"].isin(sel_types))
        & (latest_results["SEVERITY"].isin(sel_severities)) & (latest_results["RESULT_STATUS"].isin(sel_statuses))
    ]
else:
    filtered = pd.DataFrame()

# -- Header --
st.title("Data quality monitoring")
st.caption("Enterprise data quality framework — BANKING_DQ_DB.RAW")

tab_overview, tab_results, tab_anomalies, tab_coverage = st.tabs(
    ["Overview", "Rule results", "Anomalies", "Coverage"]
)

# ======= TAB 1: OVERVIEW =======
with tab_overview:
    if not filtered.empty:
        total_rules = len(filtered)
        passed = int((filtered["RESULT_STATUS"] == "PASS").sum())
        failed = int((filtered["RESULT_STATUS"] == "FAIL").sum())
        health = round(passed / total_rules * 100, 1) if total_rules > 0 else 0
        crit_fail = int(((filtered["RESULT_STATUS"] == "FAIL") & (filtered["SEVERITY"] == "HIGH")).sum())
        active_rules = int(config_df["IS_ACTIVE"].sum()) if not config_df.empty else 0
        n_anomalies = len(anomalies_df) if not anomalies_df.empty else 0

        # Compute deltas from previous run
        prev_health = None
        if not results_df.empty:
            run_dates = results_df["EXECUTED_AT"].drop_duplicates().sort_values(ascending=False)
            if len(run_dates) >= 2:
                prev_date = run_dates.iloc[1]
                prev_results = results_df[results_df["EXECUTED_AT"] == prev_date]
                prev_pass = int((prev_results["RESULT_STATUS"] == "PASS").sum())
                prev_total = len(prev_results)
                prev_health = round(prev_pass / prev_total * 100, 1) if prev_total > 0 else 0

        health_delta = f"{health - prev_health:+.1f}%" if prev_health is not None else None

        with st.container(horizontal=True):
            st.metric("Overall health", f"{health}%", delta=health_delta, border=True)
            st.metric("Monitored tables", len(sel_tables), border=True)
            st.metric("Active rules", active_rules, border=True)
            st.metric("Passed", passed, border=True)
            st.metric("Failed", failed, border=True)
            st.metric("Critical failures", crit_fail, border=True)
            st.metric("Anomalies detected", n_anomalies, border=True)

        st.space("small")
        failed_df = filtered[filtered["RESULT_STATUS"] == "FAIL"]

        col1, col2 = st.columns(2)
        with col1:
            with st.container(border=True):
                st.markdown("**Table health scores**")
                table_health = filtered.groupby("TABLE_NAME").apply(
                    lambda x: round((x["RESULT_STATUS"] == "PASS").sum() / len(x) * 100, 1) if len(x) > 0 else 0
                ).reset_index(name="HEALTH")
                bars = alt.Chart(table_health).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6, size=32).encode(
                    x=alt.X("TABLE_NAME:N", title=None, sort="-y", axis=alt.Axis(labelAngle=-30)),
                    y=alt.Y("HEALTH:Q", title="Health %", scale=alt.Scale(domain=[0, 100])),
                    color=alt.condition(alt.datum.HEALTH >= 70, alt.value(C_PASS), alt.value(C_FAIL)),
                    tooltip=[alt.Tooltip("TABLE_NAME:N", title="Table"), alt.Tooltip("HEALTH:Q", title="Health %", format=".1f")],
                ).properties(height=320)
                threshold = alt.Chart(pd.DataFrame({"y": [70]})).mark_rule(color=C_WARN, strokeDash=[6, 4], strokeWidth=2).encode(y="y:Q")
                text = alt.Chart(table_health).mark_text(dy=-12, fontSize=13, fontWeight="bold").encode(
                    x=alt.X("TABLE_NAME:N", sort="-y"), y=alt.Y("HEALTH:Q"),
                    text=alt.Text("HEALTH:Q", format=".1f"),
                    color=alt.condition(alt.datum.HEALTH >= 70, alt.value("#065F46"), alt.value("#991B1B")),
                )
                st.altair_chart(bars + threshold + text)

        with col2:
            with st.container(border=True):
                st.markdown("**Rule pass/fail distribution**")
                status_counts = filtered["RESULT_STATUS"].value_counts().reset_index()
                status_counts.columns = ["Status", "Count"]
                donut = alt.Chart(status_counts).mark_arc(innerRadius=60, outerRadius=110, cornerRadius=4).encode(
                    theta=alt.Theta("Count:Q"),
                    color=alt.Color("Status:N", scale=alt.Scale(domain=["PASS", "FAIL"], range=[C_PASS, C_FAIL]), legend=alt.Legend(orient="bottom", title=None)),
                    tooltip=["Status:N", "Count:Q"],
                ).properties(height=320)
                donut_text = alt.Chart(pd.DataFrame({"text": [f"{health}%"]})).mark_text(fontSize=28, fontWeight="bold", color="#1E293B").encode(text="text:N")
                st.altair_chart(donut + donut_text)

        col3, col4 = st.columns(2)
        with col3:
            with st.container(border=True):
                st.markdown("**Failures by severity**")
                if not failed_df.empty:
                    sev = failed_df["SEVERITY"].value_counts().reset_index()
                    sev.columns = ["Severity", "Count"]
                    chart = alt.Chart(sev).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6, size=36).encode(
                        x=alt.X("Severity:N", sort="-y", title=None),
                        y=alt.Y("Count:Q", title="Failed rules"),
                        color=alt.Color("Severity:N", scale=alt.Scale(domain=list(SEVERITY_COLORS.keys()), range=list(SEVERITY_COLORS.values())), legend=None),
                        tooltip=["Severity", "Count"],
                    ).properties(height=260)
                    text = alt.Chart(sev).mark_text(dy=-10, fontSize=14, fontWeight="bold").encode(
                        x=alt.X("Severity:N", sort="-y"), y="Count:Q", text="Count:Q",
                    )
                    st.altair_chart(chart + text)
                else:
                    st.success("No failures detected.")

        with col4:
            with st.container(border=True):
                st.markdown("**Failures by rule type**")
                if not failed_df.empty:
                    tc = failed_df["RULE_TYPE"].value_counts().reset_index()
                    tc.columns = ["Type", "Count"]
                    chart = alt.Chart(tc).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6, size=28).encode(
                        x=alt.X("Type:N", sort="-y", title=None, axis=alt.Axis(labelAngle=-30)),
                        y=alt.Y("Count:Q", title="Failed rules"),
                        color=alt.Color("Type:N", scale=alt.Scale(range=TYPE_PALETTE), legend=None),
                        tooltip=["Type", "Count"],
                    ).properties(height=260)
                    st.altair_chart(chart)
                else:
                    st.success("No failures detected.")

        col5, col6 = st.columns(2)
        with col5:
            with st.container(border=True):
                st.markdown("**Top failing tables**")
                if not failed_df.empty:
                    tt = failed_df["TABLE_NAME"].value_counts().head(5).reset_index()
                    tt.columns = ["Table", "Failures"]
                    chart = alt.Chart(tt).mark_bar(cornerRadiusEnd=6, size=24).encode(
                        y=alt.Y("Table:N", sort="-x", title=None),
                        x=alt.X("Failures:Q", title="Failed rules"),
                        color=alt.value(C_FAIL),
                        tooltip=["Table", "Failures"],
                    ).properties(height=220)
                    text = alt.Chart(tt).mark_text(dx=14, fontSize=13, fontWeight="bold", color="#991B1B").encode(
                        y=alt.Y("Table:N", sort="-x"), x="Failures:Q", text="Failures:Q",
                    )
                    st.altair_chart(chart + text)
                else:
                    st.success("No failures detected.")

        with col6:
            with st.container(border=True):
                st.markdown("**Top failing columns**")
                if not failed_df.empty:
                    tcc = failed_df["COLUMN_NAME"].dropna().value_counts().head(5).reset_index()
                    tcc.columns = ["Column", "Failures"]
                    chart = alt.Chart(tcc).mark_bar(cornerRadiusEnd=6, size=24).encode(
                        y=alt.Y("Column:N", sort="-x", title=None),
                        x=alt.X("Failures:Q", title="Failed rules"),
                        color=alt.value(C_WARN),
                        tooltip=["Column", "Failures"],
                    ).properties(height=220)
                    text = alt.Chart(tcc).mark_text(dx=14, fontSize=13, fontWeight="bold", color="#92400E").encode(
                        y=alt.Y("Column:N", sort="-x"), x="Failures:Q", text="Failures:Q",
                    )
                    st.altair_chart(chart + text)
                else:
                    st.success("No failures detected.")

        with st.container(border=True):
            st.markdown("**Health score trend over time**")
            if not results_df.empty:
                trend_df = results_df.copy()
                trend_df["RUN_DATE"] = pd.to_datetime(trend_df["EXECUTED_AT"]).dt.floor("min")
                trend = trend_df.groupby("RUN_DATE").apply(
                    lambda x: round((x["RESULT_STATUS"] == "PASS").sum() / len(x) * 100, 1) if len(x) > 0 else 0
                ).reset_index(name="HEALTH")
                line = alt.Chart(trend).mark_area(
                    line={"color": C_INFO, "strokeWidth": 3},
                    color=alt.Gradient(gradient="linear", stops=[alt.GradientStop(color=C_INFO, offset=0), alt.GradientStop(color="transparent", offset=1)], x1=0, x2=0, y1=0, y2=1),
                    point=alt.OverlayMarkDef(color=C_INFO, size=60, filled=True),
                ).encode(
                    x=alt.X("RUN_DATE:T", title="Run time"),
                    y=alt.Y("HEALTH:Q", title="Health %", scale=alt.Scale(domain=[0, 100])),
                    tooltip=[alt.Tooltip("RUN_DATE:T", title="Run"), alt.Tooltip("HEALTH:Q", title="Health %", format=".1f")],
                ).properties(height=280)
                rule70 = alt.Chart(pd.DataFrame({"y": [70]})).mark_rule(color=C_WARN, strokeDash=[6, 4], strokeWidth=2).encode(y="y:Q")
                st.altair_chart(line + rule70)

        # -- Drill-down --
        st.space("small")
        st.subheader("Table drill-down")
        selected_table = st.selectbox("Select a table", sel_tables, key="overview_drill")

        if selected_table:
            tr = filtered[filtered["TABLE_NAME"] == selected_table]
            t_pass = int((tr["RESULT_STATUS"] == "PASS").sum())
            t_fail = int((tr["RESULT_STATUS"] == "FAIL").sum())
            t_health = round(t_pass / len(tr) * 100, 1) if len(tr) > 0 else 0

            with st.container(horizontal=True):
                st.metric(f"{selected_table} health", f"{t_health}%", border=True)
                st.metric("Rules", len(tr), border=True)
                st.metric("Passed", t_pass, border=True)
                st.metric("Failed", t_fail, border=True)

            if not results_df.empty:
                tt = results_df[results_df["TABLE_NAME"] == selected_table].copy()
                tt["RUN_DATE"] = pd.to_datetime(tt["EXECUTED_AT"]).dt.floor("min")
                th = tt.groupby("RUN_DATE").apply(
                    lambda x: round((x["RESULT_STATUS"] == "PASS").sum() / len(x) * 100, 1) if len(x) > 0 else 0
                ).reset_index(name="HEALTH")
                if not th.empty:
                    with st.container(border=True):
                        st.markdown(f"**{selected_table} health trend**")
                        chart = alt.Chart(th).mark_line(point=True, strokeWidth=3, color=C_TEAL).encode(
                            x=alt.X("RUN_DATE:T", title="Run time"), y=alt.Y("HEALTH:Q", title="Health %", scale=alt.Scale(domain=[0, 100])),
                        ).properties(height=200)
                        st.altair_chart(chart)

            t_failed = tr[tr["RESULT_STATUS"] == "FAIL"]
            if not t_failed.empty:
                with st.container(border=True):
                    st.markdown(f"**Failed rules for {selected_table}**")
                    st.dataframe(
                        t_failed[["RULE_NAME", "COLUMN_NAME", "RULE_TYPE", "SEVERITY", "FAILED_RECORD_COUNT", "TOTAL_RECORD_COUNT", "PASS_PERCENTAGE"]],
                        column_config={
                            "PASS_PERCENTAGE": st.column_config.ProgressColumn("Pass %", min_value=0, max_value=100, format="%.1f%%"),
                            "FAILED_RECORD_COUNT": st.column_config.NumberColumn("Failed", format="%d"),
                            "TOTAL_RECORD_COUNT": st.column_config.NumberColumn("Total", format="%d"),
                        },
                        hide_index=True,
                    )
            else:
                st.success(f"All rules passing for {selected_table}.")

            if not errors_df.empty:
                te = errors_df[errors_df["TABLE_NAME"] == selected_table]
                if not te.empty:
                    with st.container(border=True):
                        st.markdown(f"**Sample error records**")
                        st.dataframe(te[["RULE_ID", "ERROR_REASON", "ERROR_RECORD_VARIANT", "CREATED_AT"]], hide_index=True)

            if not anomalies_df.empty:
                ta = anomalies_df[anomalies_df["TABLE_NAME"] == selected_table]
                if not ta.empty:
                    with st.container(border=True):
                        st.markdown(f"**Recent anomalies**")
                        st.dataframe(ta[["METRIC_NAME", "CURRENT_VALUE", "PREVIOUS_VALUE", "ANOMALY_REASON", "DETECTED_AT"]], hide_index=True)
    else:
        st.warning("No data available. Run the DQ framework first.")

# ======= TAB 2: RULE RESULTS =======
with tab_results:
    st.subheader("All rule results (latest run)")
    if not filtered.empty:
        display_df = filtered[["RULE_NAME", "TABLE_NAME", "COLUMN_NAME", "RULE_TYPE", "SEVERITY", "RESULT_STATUS", "FAILED_RECORD_COUNT", "TOTAL_RECORD_COUNT", "PASS_PERCENTAGE", "EXECUTED_AT"]].sort_values(["RESULT_STATUS", "SEVERITY"], ascending=[True, True])
        st.dataframe(
            display_df, hide_index=True, height=420,
            column_config={
                "PASS_PERCENTAGE": st.column_config.ProgressColumn("Pass %", min_value=0, max_value=100, format="%.1f%%"),
                "FAILED_RECORD_COUNT": st.column_config.NumberColumn("Failed", format="%d"),
                "TOTAL_RECORD_COUNT": st.column_config.NumberColumn("Total", format="%d"),
                "EXECUTED_AT": st.column_config.DatetimeColumn("Executed", format="MMM DD, YYYY HH:mm"),
            },
        )

        st.space("small")
        st.subheader("Table drill-down")
        drill_table = st.selectbox("Select a table", sel_tables, key="results_drill")

        if drill_table:
            dr = filtered[filtered["TABLE_NAME"] == drill_table]
            dp = int((dr["RESULT_STATUS"] == "PASS").sum())
            df_ = int((dr["RESULT_STATUS"] == "FAIL").sum())
            dh = round(dp / len(dr) * 100, 1) if len(dr) > 0 else 0

            with st.container(horizontal=True):
                st.metric("Health", f"{dh}%", border=True)
                st.metric("Total rules", len(dr), border=True)
                st.metric("Passed", dp, border=True)
                st.metric("Failed", df_, border=True)

            col_r1, col_r2 = st.columns(2)
            tbl_failed = dr[dr["RESULT_STATUS"] == "FAIL"]
            tbl_passed = dr[dr["RESULT_STATUS"] == "PASS"]

            with col_r1:
                with st.container(border=True):
                    st.markdown(f"**Failed rules**")
                    if not tbl_failed.empty:
                        st.dataframe(
                            tbl_failed[["RULE_NAME", "COLUMN_NAME", "RULE_TYPE", "SEVERITY", "FAILED_RECORD_COUNT", "TOTAL_RECORD_COUNT", "PASS_PERCENTAGE"]],
                            column_config={"PASS_PERCENTAGE": st.column_config.ProgressColumn("Pass %", min_value=0, max_value=100, format="%.1f%%")},
                            hide_index=True,
                        )
                    else:
                        st.success("All rules passing.")

            with col_r2:
                with st.container(border=True):
                    st.markdown(f"**Passing rules**")
                    if not tbl_passed.empty:
                        st.dataframe(
                            tbl_passed[["RULE_NAME", "COLUMN_NAME", "RULE_TYPE", "SEVERITY", "PASS_PERCENTAGE"]],
                            column_config={"PASS_PERCENTAGE": st.column_config.ProgressColumn("Pass %", min_value=0, max_value=100, format="%.1f%%")},
                            hide_index=True,
                        )

            if not errors_df.empty:
                de = errors_df[errors_df["TABLE_NAME"] == drill_table]
                if not de.empty:
                    with st.container(border=True):
                        st.markdown(f"**Sample error records**")
                        st.dataframe(de[["RULE_ID", "ERROR_REASON", "ERROR_RECORD_VARIANT", "CREATED_AT"]], hide_index=True)

            if not tbl_failed.empty:
                with st.container(border=True):
                    st.markdown(f"**Recommended fixes for {drill_table}**")
                    for _, row in tbl_failed.iterrows():
                        sev_badge = {"HIGH": ":red-badge[HIGH]", "MEDIUM": ":orange-badge[MEDIUM]", "LOW": ":blue-badge[LOW]"}.get(row["SEVERITY"], "")
                        st.markdown(f"- {sev_badge} `{row['RULE_NAME']}` on `{row['COLUMN_NAME']}` — {row['FAILED_RECORD_COUNT']:.0f} failed of {row['TOTAL_RECORD_COUNT']:.0f} ({row['PASS_PERCENTAGE']:.1f}% pass)")
    else:
        st.caption("No results match the current filters.")

# ======= TAB 3: ANOMALIES =======
with tab_anomalies:
    st.subheader("Anomaly detection results")
    if not anomalies_df.empty:
        with st.container(horizontal=True):
            st.metric("Total anomalies", len(anomalies_df), border=True)
            n_tables_anom = anomalies_df["TABLE_NAME"].nunique()
            st.metric("Tables affected", n_tables_anom, border=True)
            new_fail_count = int(anomalies_df["ANOMALY_REASON"].str.contains("New failures", na=False).sum())
            st.metric("New failures", new_fail_count, border=True)
            spike_count = int(anomalies_df["ANOMALY_REASON"].str.contains("spike", case=False, na=False).sum())
            st.metric("Failure spikes", spike_count, border=True)

        col_a1, col_a2 = st.columns(2)
        with col_a1:
            with st.container(border=True):
                st.markdown("**Anomalies by table**")
                anom_by_tbl = anomalies_df["TABLE_NAME"].value_counts().reset_index()
                anom_by_tbl.columns = ["Table", "Count"]
                chart = alt.Chart(anom_by_tbl).mark_bar(cornerRadiusTopLeft=6, cornerRadiusTopRight=6, size=30).encode(
                    x=alt.X("Table:N", sort="-y", title=None, axis=alt.Axis(labelAngle=-30)),
                    y=alt.Y("Count:Q", title="Anomalies"),
                    color=alt.value(C_PURPLE),
                    tooltip=["Table", "Count"],
                ).properties(height=280)
                st.altair_chart(chart)

        with col_a2:
            with st.container(border=True):
                st.markdown("**Anomaly trend**")
                anom_trend = anomalies_df.copy()
                anom_trend["DATE"] = pd.to_datetime(anom_trend["DETECTED_AT"]).dt.date
                abd = anom_trend.groupby("DATE").size().reset_index(name="COUNT")
                chart = alt.Chart(abd).mark_area(
                    line={"color": C_PURPLE, "strokeWidth": 2},
                    color=alt.Gradient(gradient="linear", stops=[alt.GradientStop(color=C_PURPLE, offset=0), alt.GradientStop(color="transparent", offset=1)], x1=0, x2=0, y1=0, y2=1),
                    point=alt.OverlayMarkDef(color=C_PURPLE, size=50, filled=True),
                ).encode(x=alt.X("DATE:T", title="Date"), y=alt.Y("COUNT:Q", title="Anomalies"), tooltip=["DATE:T", "COUNT:Q"]).properties(height=280)
                st.altair_chart(chart)

        with st.container(border=True):
            st.markdown("**Anomaly details**")
            st.dataframe(
                anomalies_df[["TABLE_NAME", "METRIC_NAME", "CURRENT_VALUE", "PREVIOUS_VALUE", "ANOMALY_REASON", "DETECTED_AT"]],
                column_config={
                    "DETECTED_AT": st.column_config.DatetimeColumn("Detected", format="MMM DD, YYYY HH:mm"),
                    "CURRENT_VALUE": st.column_config.NumberColumn("Current", format="%.0f"),
                    "PREVIOUS_VALUE": st.column_config.NumberColumn("Previous", format="%.0f"),
                },
                hide_index=True, height=400,
            )
    else:
        st.caption("No anomalies detected yet. Anomalies are identified by comparing consecutive DQ runs.")

# ======= TAB 4: COVERAGE =======
with tab_coverage:
    st.subheader("Rule coverage summary")
    if not config_df.empty:
        with st.container(horizontal=True):
            st.metric("Total rules", len(config_df), border=True)
            st.metric("Active rules", int(config_df["IS_ACTIVE"].sum()), border=True)
            st.metric("Tables covered", config_df["TABLE_NM"].nunique(), border=True)
            st.metric("Rule types", config_df["RULE_TYPE"].nunique(), border=True)

        col_c1, col_c2 = st.columns(2)
        with col_c1:
            with st.container(border=True):
                st.markdown("**Rules per table**")
                tbl_cov = config_df.groupby("TABLE_NM").agg(TOTAL=("RULE_ID", "count"), ACTIVE=("IS_ACTIVE", "sum")).reset_index()
                tbl_cov.columns = ["Table", "Total rules", "Active rules"]
                st.dataframe(
                    tbl_cov, hide_index=True,
                    column_config={
                        "Total rules": st.column_config.NumberColumn(format="%d"),
                        "Active rules": st.column_config.NumberColumn(format="%d"),
                    },
                )

        with col_c2:
            with st.container(border=True):
                st.markdown("**Rules by type**")
                tc = config_df["RULE_TYPE"].value_counts().reset_index()
                tc.columns = ["Type", "Count"]
                chart = alt.Chart(tc).mark_arc(innerRadius=55, outerRadius=110, cornerRadius=4).encode(
                    theta=alt.Theta("Count:Q"),
                    color=alt.Color("Type:N", scale=alt.Scale(range=TYPE_PALETTE), legend=alt.Legend(orient="bottom", title=None)),
                    tooltip=["Type", "Count"],
                ).properties(height=300)
                st.altair_chart(chart)

        with st.container(border=True):
            st.markdown("**Rules by criticality per table**")
            cc = config_df.groupby(["TABLE_NM", "CRITICALITY"]).size().reset_index(name="COUNT")
            chart = alt.Chart(cc).mark_bar(cornerRadiusTopLeft=4, cornerRadiusTopRight=4).encode(
                x=alt.X("TABLE_NM:N", title=None, axis=alt.Axis(labelAngle=-30)),
                y=alt.Y("COUNT:Q", title="Rule count", stack="zero"),
                color=alt.Color("CRITICALITY:N", scale=alt.Scale(domain=list(SEVERITY_COLORS.keys()), range=list(SEVERITY_COLORS.values())), legend=alt.Legend(orient="bottom", title=None)),
                tooltip=["TABLE_NM", "CRITICALITY", "COUNT"],
            ).properties(height=300)
            st.altair_chart(chart)

        with st.container(border=True):
            st.markdown("**Full rule configuration**")
            st.dataframe(
                config_df[["RULE_ID", "RULE_NAME", "RULE_TYPE", "TABLE_NM", "COLUMN_NM", "CRITICALITY", "RULE_DESCRIPTION", "IS_ACTIVE"]],
                column_config={
                    "IS_ACTIVE": st.column_config.CheckboxColumn("Active"),
                    "RULE_ID": st.column_config.NumberColumn("ID", format="%d"),
                },
                hide_index=True, height=400,
            )
    else:
        st.caption("No rule configuration found.")
