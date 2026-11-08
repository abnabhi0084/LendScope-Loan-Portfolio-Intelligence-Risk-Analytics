USE BankLoanAnalytics;
GO

--Graph 1 Credit Grade Exposure & Payment Performance
WITH Grade_Payment AS
(
    SELECT
        DG.grade,

        SUM(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN FL.loan_amount ELSE 0
        END) AS CO_Principal,

        SUM(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN FL.total_payment ELSE 0
        END) AS CO_Received

    FROM analytics.Fact_Loan FL

    INNER JOIN analytics.Dim_CreditGrade DG
        ON FL.credit_grade_key = DG.credit_grade_key

    GROUP BY DG.grade
)
SELECT
    grade,
    CO_Principal,
    CO_Received,

    CAST(
        CO_Received * 100.0 /
        NULLIF(CO_Principal, 0)
        AS DECIMAL(10,2)
    ) AS Payment_Percentage

FROM Grade_Payment
ORDER BY grade;

--Table 2 Grade Risk Matrix
WITH Grade_SubGrade_Analysis AS
(
    SELECT
        DG.grade,
        DG.sub_grade,

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
            THEN FL.loan_amount
            ELSE 0
        END) AS CO_Principal,

        SUM(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN FL.total_payment
            ELSE 0
        END) AS CO_Received,

        AVG(CAST(FL.int_rate AS DECIMAL(10,4)))
            AS AVG_Interest,

        AVG(CAST(FL.dti AS DECIMAL(10,4)))
            AS AVG_DTI,

        COUNT(CASE
            WHEN FL.loan_status IN ('Fully Paid', 'Charged Off')
            THEN 1
        END) AS Resolved_Loans

    FROM analytics.Fact_Loan FL

    INNER JOIN analytics.Dim_CreditGrade DG
        ON FL.credit_grade_key = DG.credit_grade_key

    GROUP BY GROUPING SETS
    (
        (DG.grade, DG.sub_grade),
        ()
    )
)
SELECT
    CASE
        WHEN grade IS NULL THEN 'Total'
        ELSE grade
    END AS Grade,

    ISNULL(sub_grade, '') AS Sub_Grade,

    Total_Loans,
    Funded_Amount,
    Fully_Paids,
    Charge_Offs,
    CO_Principal,
    CO_Received,

    CAST(AVG_Interest * 100.0 AS DECIMAL(10,2))
        AS AVG_Interest,

    CAST(AVG_DTI * 100 AS DECIMAL(10,2))
        AS AVG_DTI,

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

FROM Grade_SubGrade_Analysis

ORDER BY
    grade,
    sub_grade;

--Graph 3 Loan Purpose Exposure & Payment Performance
WITH Purpose_Payment AS
(
    SELECT
        DP.purpose,

        SUM(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN FL.loan_amount ELSE 0
        END) AS CO_Principal,

        SUM(CASE
            WHEN FL.loan_status = 'Charged Off'
            THEN FL.total_payment ELSE 0
        END) AS CO_Received

    FROM analytics.Fact_Loan FL

    INNER JOIN analytics.Dim_LoanPurpose DP
        ON FL.purpose_key = DP.purpose_key

    GROUP BY DP.purpose
)
SELECT
    purpose,
    CO_Principal,
    CO_Received,

    CAST(
        CO_Received * 100.0 /
        NULLIF(CO_Principal, 0)
        AS DECIMAL(10,2)
    ) AS Payment_Percentage

FROM Purpose_Payment
ORDER BY CO_Principal DESC;

--Graph 4 Loan Term Exposure & Payment Performance
WITH Term_Payment AS
(
    SELECT
        term,

        SUM(CASE
            WHEN loan_status = 'Charged Off'
            THEN loan_amount ELSE 0
        END) AS CO_Principal,

        SUM(CASE
            WHEN loan_status = 'Charged Off'
            THEN total_payment ELSE 0
        END) AS CO_Received

    FROM analytics.Fact_Loan
    GROUP BY term
)
SELECT
    term,
    CO_Principal,
    CO_Received,

    CAST(
        CO_Received * 100.0 /
        NULLIF(CO_Principal, 0)
        AS DECIMAL(10,2)
    ) AS Payment_Percentage

FROM Term_Payment
ORDER BY term DESC;