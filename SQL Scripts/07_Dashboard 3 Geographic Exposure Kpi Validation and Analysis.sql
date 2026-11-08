USE BankLoanAnalytics;
GO

--KPI's Validation
SELECT
    COUNT(DISTINCT state_key) AS Total_States,

    COUNT(*) AS Total_Loans,

    SUM(loan_amount) AS Funded_Amount,

    CAST(
        COUNT(CASE
            WHEN loan_status = 'Charged Off'
            THEN 1
        END) * 100.0
        /
        NULLIF(
            COUNT(CASE
                WHEN loan_status IN ('Fully Paid', 'Charged Off')
                THEN 1
            END), 0
        )
        AS DECIMAL(10,2)
    ) AS Charged_Off_Rate

FROM analytics.Fact_Loan;

--Graph 1 Top 10 States by Loan Amount vs Charged-Off rate
WITH State_Analysis AS
(
    SELECT
        DS.state_name,

        SUM(FL.loan_amount) AS Funded_Amount,

        COUNT(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN 1
        END) AS Charge_Offs,

        COUNT(CASE
            WHEN FL.loan_status IN ('Fully Paid', 'Charged Off')
            THEN 1
        END) AS Resolved_Loans

    FROM analytics.Fact_Loan FL

    INNER JOIN analytics.Dim_State DS
        ON FL.state_key = DS.state_key

    GROUP BY DS.state_name
),
Ranked_States AS
(
    SELECT
        state_name,
        Funded_Amount,
        Charge_Offs,
        Resolved_Loans,

        ROW_NUMBER() OVER(
            ORDER BY Funded_Amount DESC
        ) AS State_Rank

    FROM State_Analysis
)
SELECT
    state_name,
    Funded_Amount,

    CAST(
        Charge_Offs * 100.0 /
        NULLIF(Resolved_Loans, 0)
        AS DECIMAL(10,2)
    ) AS Charged_Off_Share

FROM Ranked_States

WHERE State_Rank <= 10

ORDER BY Funded_Amount DESC;

--Table 2 State Risk Table
WITH State_Analysis AS
(
    SELECT
        DS.state_name,

        COUNT(*) AS Total_Loans,

        SUM(FL.loan_amount) AS Funded_Amount,

        COUNT(CASE
            WHEN FL.loan_status = 'Fully Paid'
            THEN 1
        END) AS Fully_Paids,

        COUNT(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN 1
        END) AS Charge_Offs,

        SUM(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN FL.loan_amount ELSE 0
        END) AS CO_Principal,

        SUM(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN FL.total_payment ELSE 0
        END) AS CO_Received,

        COUNT(CASE
            WHEN FL.loan_status IN ('Fully Paid', 'Charged Off')
            THEN 1
        END) AS Resolved_Loans

    FROM analytics.Fact_Loan FL

    INNER JOIN analytics.Dim_State DS
        ON FL.state_key = DS.state_key

    GROUP BY DS.state_name
),
State_Result AS
(
    SELECT
        state_name AS State_Name,
        Total_Loans,
        Funded_Amount,
        Fully_Paids,
        Charge_Offs,
        CO_Principal,
        CO_Received,

        CAST(
            CO_Received * 100.0 /
            NULLIF(CO_Principal, 0)
            AS DECIMAL(10,2)
        ) AS Payment_Percentage,

        CAST(
            Charge_Offs * 100.0 /
            NULLIF(Resolved_Loans, 0)
            AS DECIMAL(10,2)
        ) AS Charged_Off_Rate

    FROM State_Analysis
)
SELECT *
FROM State_Result

UNION ALL

SELECT
    'Total',
    SUM(Total_Loans),
    SUM(Funded_Amount),
    SUM(Fully_Paids),
    SUM(Charge_Offs),
    SUM(CO_Principal),
    SUM(CO_Received),

    CAST(
        SUM(CO_Received) * 100.0 /
        NULLIF(SUM(CO_Principal), 0)
        AS DECIMAL(10,2)
    ),

    CAST(
        SUM(Charge_Offs) * 100.0 /
        NULLIF(SUM(Resolved_Loans), 0)
        AS DECIMAL(10,2)
    )

FROM State_Analysis

ORDER BY State_Name;