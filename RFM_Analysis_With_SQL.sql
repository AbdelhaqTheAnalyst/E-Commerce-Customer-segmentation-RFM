SELECT *
INTO Online_Retail_Work
FROM online_retail_perfect_clean;

ALTER TABLE Online_Retail_Work
ALTER COLUMN UnitPrice FLOAT;

ALTER TABLE Online_Retail_Work
ALTER COLUMN TotalAmount FLOAT;

ALTER TABLE Online_Retail_Work
ALTER COLUMN Clean_Date DATE;

SELECT TOP 1 *
FROM Online_Retail_Work;

EXEC sp_rename 'Online_Retail_Work.Clean_Data', 'Clean_Date', 'COLUMN';

SELECT TOP 1 *
FROM Online_Retail_Work;

ALTER TABLE Online_Retail_Work
ALTER COLUMN Clean_Date DATE;


SELECT TOP 5 *
FROM Online_Retail_Work;

UPDATE Online_Retail_Work
SET UnitPrice = REPLACE(UnitPrice, ',', '.');

ALTER TABLE Online_Retail_Work
ALTER COLUMN UnitPrice FLOAT;

UPDATE Online_Retail_Work
SET TotalAmount = REPLACE(TotalAmount, ',', '.');

ALTER TABLE Online_Retail_Work
ALTER COLUMN TotalAmount FLOAT;

SELECT TOP 5 *
FROM Online_Retail_Work;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Online_Retail_Work' AND COLUMN_NAME IN ('UnitPrice', 'TotalAmount');

SELECT 
    CustomerID,
    DATEDIFF(DAY, MAX(Clean_Date), (SELECT MAX(Clean_Date) FROM Online_Retail_Work)) AS RecencyValue,
    COUNT(DISTINCT InvoiceNo) AS FrequencyValue,
    SUM(TotalAmount) AS MonetaryValue
INTO RFM_Base_Values
FROM Online_Retail_Work
GROUP BY CustomerID;

SELECT TOP 10 * 
FROM RFM_Base_Values;

SELECT 
    CustomerID,
    RecencyValue,
    FrequencyValue,
    MonetaryValue,
    NTILE(5) OVER (ORDER BY RecencyValue ASC) AS R_Score,
    NTILE(5) OVER (ORDER BY FrequencyValue DESC) AS F_Score,
    NTILE(5) OVER (ORDER BY MonetaryValue DESC) AS M_Score
INTO RFM_Scores_Table
FROM RFM_Base_Values;

SELECT TOP 10 * 
FROM RFM_Scores_Table;


WITH RFM_Combined AS (
    SELECT 
        CustomerID,
        RecencyValue,
        FrequencyValue,
        MonetaryValue,
        R_Score,
        F_Score,
        M_Score,
        CONCAT(R_Score, F_Score, M_Score) AS RFM_Score
    FROM RFM_Scores_Table
)

SELECT 
    CustomerID,
    RecencyValue,
    FrequencyValue,
    MonetaryValue,
    R_Score,
    F_Score,
    M_Score,
    RFM_Score,
    CASE 
        
        WHEN R_Score IN (1, 2) AND F_Score IN (1, 2) AND M_Score IN (1, 2) THEN 'Champions'
        WHEN R_Score IN (1, 2) AND F_Score IN (1, 2) AND M_Score IN (3, 4) THEN 'Loyal Customers'
        WHEN R_Score IN (1, 2) AND F_Score IN (3, 4) AND M_Score IN (1, 2, 3) THEN 'Potential Loyalists'
        WHEN R_Score IN (1, 2) AND F_Score = 5 AND M_Score = 5 THEN 'Recent Customers'
        WHEN R_Score = 3 AND F_Score IN (1, 2) AND M_Score IN (1, 2) THEN 'Customers Needing Attention'
        WHEN R_Score IN (3, 4) AND F_Score IN (3, 4) AND M_Score IN (3, 4) THEN 'About To Sleep'
        WHEN R_Score IN (4, 5) AND F_Score IN (1, 2) AND M_Score IN (1, 2) THEN 'Cant Lose Them'
        WHEN R_Score IN (4, 5) AND F_Score IN (3, 4) AND M_Score IN (3, 4) THEN 'At Risk'
        WHEN R_Score = 5 AND F_Score = 5 AND M_Score = 5 THEN 'Hibernating'
        ELSE 'About To Sleep'
    END AS Customer_Segment
INTO RFM_Final_Segments
FROM RFM_Combined;

SELECT TOP 10 *
FROM RFM_Final_Segments;

SELECT 
   Customer_Segment,
   COUNT(CustomerID) AS Total_Customers,
   ROUND(COUNT(CustomerID) * 100.0 / (SELECT COUNT(*) FROM RFM_Final_Segments), 2) AS Percentage
FROM RFM_Final_Segments
GROUP BY Customer_Segment
ORDER BY Total_Customers DESC;













