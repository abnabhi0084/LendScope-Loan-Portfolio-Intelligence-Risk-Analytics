USE BankLoanAnalytics;
GO

--KPI's Validation
SELECT
    COUNT(CASE
        WHEN loan_status IN ('Fully Paid', 'Charged Off')
        THEN 1
    END) AS Resolved_Loans,

    COUNT(CASE
        WHEN loan_status = 'Charged Off'
        THEN 1
    END) AS Charge_Offs,

    SUM(CASE
        WHEN loan_status = 'Charged Off'
        THEN loan_amount
        ELSE 0
    END) AS CO_Principal,

    SUM(CASE
        WHEN loan_status = 'Charged Off'
        THEN total_payment
        ELSE 0
    END) AS CO_Received,

    CAST(
        SUM(CASE
            WHEN loan_status = 'Charged Off'
            THEN total_payment
            ELSE 0
        END) * 100.0
        /
        NULLIF(
            SUM(CASE
                WHEN loan_status = 'Charged Off'
                THEN loan_amount
                ELSE 0
            END), 0
        )
        AS DECIMAL(10,2)
    ) AS Payment_Percentage,

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

--Graph 1 Funded Exposure & Charge-Off Rate by Grade
WITH Grade_Analysis AS
(
    SELECT
        DG.grade,

        COUNT(*) AS Total_Loans,

        COUNT(CASE
            WHEN FL.loan_status IN ('Fully Paid', 'Charged Off')
            THEN 1
        END) AS Resolved_Loans,

        COUNT(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN 1
        END) AS Charge_Offs,

        SUM(FL.loan_amount) AS Funded_Amount

    FROM analytics.Fact_Loan FL

    INNER JOIN analytics.Dim_CreditGrade DG
        ON FL.credit_grade_key = DG.credit_grade_key

    GROUP BY DG.grade
)
SELECT
    grade,
    Total_Loans,
    Funded_Amount,
    Charge_Offs,

    CAST(
        Charge_Offs * 100.0 /
        NULLIF(Resolved_Loans, 0)
        AS DECIMAL(10,2)
    ) AS Charged_Off_Rate

FROM Grade_Analysis
ORDER BY grade;

-- Table 2 Grade risk matrix
WITH Grade_Risk AS
(
    SELECT
        DG.grade,

        COUNT(*) AS Total_Loans,

        SUM(FL.loan_amount) AS Funded_Amount,

        COUNT(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN 1
        END) AS Charge_Offs,

        SUM(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN FL.loan_amount
            ELSE 0
        END) AS CO_Principal,

        COUNT(CASE
            WHEN FL.loan_status IN ('Fully Paid', 'Charged Off')
            THEN 1
        END) AS Resolved_Loans

    FROM analytics.Fact_Loan FL

    INNER JOIN analytics.Dim_CreditGrade DG
        ON FL.credit_grade_key = DG.credit_grade_key

    GROUP BY DG.grade
)
SELECT
    grade,
    Total_Loans,
    Funded_Amount,
    Charge_Offs,
    CO_Principal,

    CAST(
        Charge_Offs * 100.0 /
        NULLIF(Resolved_Loans, 0)
        AS DECIMAL(10,2)
    ) AS Charged_Off_Rate

FROM Grade_Risk
ORDER BY grade;

--Graph 3 Funded Exposure & Charge-Off Rate by Purpose
WITH Purpose_Analysis AS
(
    SELECT
        DP.purpose,

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

    INNER JOIN analytics.Dim_LoanPurpose DP
        ON FL.purpose_key = DP.purpose_key

    GROUP BY DP.purpose
)
SELECT
    purpose,
    Funded_Amount,
    Charge_Offs,

    CAST(
        Charge_Offs * 100.0 /
        NULLIF(Resolved_Loans, 0)
        AS DECIMAL(10,2)
    ) AS Charged_Off_Rate

FROM Purpose_Analysis
ORDER BY Funded_Amount DESC;

--Graph 4 Loan Term Risk
WITH Term_Analysis AS
(
    SELECT
        term,

        SUM(CASE
            WHEN loan_status = 'Fully Paid'
            THEN loan_amount
            ELSE 0
        END) AS Fully_Paid_Amount,

        SUM(CASE
            WHEN loan_status = 'Charged Off'
            THEN loan_amount
            ELSE 0
        END) AS Charged_Off_Amount,

        COUNT(CASE
            WHEN loan_status = 'Charged Off'
            THEN 1
        END) AS Charge_Offs,

        COUNT(CASE
            WHEN loan_status IN ('Fully Paid', 'Charged Off')
            THEN 1
        END) AS Resolved_Loans

    FROM analytics.Fact_Loan
    GROUP BY term
)
SELECT
    term,
    Fully_Paid_Amount,
    Charged_Off_Amount,

    CAST(
        Charge_Offs * 100.0 /
        NULLIF(Resolved_Loans, 0)
        AS DECIMAL(10,2)
    ) AS Charged_Off_Rate

FROM Term_Analysis
ORDER BY term;