USE BankLoanAnalytics;
GO

--Checking KPI's
SELECT
    COUNT(*) AS Total_Loans,

    SUM(loan_amount) AS Funded_Amount,

    SUM(total_payment) AS Received_Amount,

    CAST(
        SUM(CASE
            WHEN loan_status = 'Fully Paid' THEN 1 ELSE 0
        END) * 100.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Fully_Paid_Share,

    CAST(
        SUM(CASE
            WHEN loan_status = 'Charged Off' THEN 1 ELSE 0
        END) * 100.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Charged_Off_Share

FROM analytics.Fact_Loan;

-- Graph 1 Loan Status Distribution
WITH Loan_Status AS
(
    SELECT
        loan_status,
        COUNT(*) AS Total_Loans
    FROM analytics.Fact_Loan
    GROUP BY loan_status
)
SELECT
    loan_status,
    Total_Loans,

    CAST(
        Total_Loans * 100.0 /
        SUM(Total_Loans) OVER()
        AS DECIMAL(10,2)
    ) AS Loan_Percentage

FROM Loan_Status
ORDER BY Total_Loans DESC;


--Graph 2 FUnded VS Received amount for Loan Type
SELECT
    loan_status,

    SUM(loan_amount) AS Funded_Amount,

    SUM(total_payment) AS Received_Amount

FROM analytics.Fact_Loan
GROUP BY loan_status
ORDER BY Funded_Amount DESC;

--Graph 3 Monthly issuance and Amount
WITH Monthly_Analysis AS
(
    SELECT
        YEAR(issue_date) AS Issue_Year,
        MONTH(issue_date) AS Issue_Month,

        COUNT(*) AS Total_Loans,

        SUM(loan_amount) AS Total_Funded_Amount

    FROM analytics.Fact_Loan
    WHERE issue_date IS NOT NULL

    GROUP BY
        YEAR(issue_date),
        MONTH(issue_date)
)
SELECT
    Issue_Year,
    Issue_Month,
    Total_Loans,
    Total_Funded_Amount

FROM Monthly_Analysis
ORDER BY Issue_Year, Issue_Month;

-- Graph 4 Top 5 purpose by Loan Amount Funded
WITH Purpose_Analysis AS
(
    SELECT
        LP.purpose,

        SUM(FL.loan_amount) AS Funded_Amount

    FROM analytics.Fact_Loan FL

    INNER JOIN analytics.Dim_LoanPurpose LP
        ON FL.purpose_key = LP.purpose_key

    GROUP BY LP.purpose
),
Ranked_Purposes AS
(
    SELECT
        purpose,
        Funded_Amount,

        ROW_NUMBER() OVER(
            ORDER BY Funded_Amount DESC
        ) AS Purpose_Rank

    FROM Purpose_Analysis
)
SELECT
    purpose,
    Funded_Amount

FROM Ranked_Purposes
WHERE Purpose_Rank <= 6
ORDER BY Funded_Amount DESC;