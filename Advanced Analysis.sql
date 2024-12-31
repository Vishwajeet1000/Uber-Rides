-- Advanced Queries
-- Running total revenue for each daySELECT 
 SELECT 
    Ride_Date,
    SUM(Booking_Value) OVER (PARTITION BY Ride_Date ORDER BY Ride_Time) AS RunningTotalRevenue
FROM BookingData
WHERE Booking_Status = 'Success'
ORDER BY Ride_Date, Ride_Time;

-- Question 2: What is the rank of each vehicle type based on total revenue?

SELECT 
    Vehicle_Type,
    SUM(Booking_Value) AS TotalRevenue,
    RANK() OVER (ORDER BY SUM(Booking_Value) DESC) AS RevenueRank
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY RevenueRank;

-- Question 3: What is the average booking value for each customer

SELECT 
    CustomerID,
    AVG(Booking_Value) AS AvgBookingValuePerCustomer
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY 1;

-- Question 4: Identify Top 3 Drivers with Highest Ratings for Each Day

SELECT 
    Ride_Date,
    CustomerID,
    Driver_Ratings,
    DENSE_RANK() OVER (PARTITION BY Ride_Date ORDER BY Driver_Ratings DESC) AS RankPerDay
FROM BookingData
WHERE Booking_Status = 'Success'
  AND Driver_Ratings IS NOT NULL
  AND Driver_Ratings > 4.5
ORDER BY Ride_Date, RankPerDay
LIMIT 3;

-- Question 5. Calculate Average Booking Value Per Location (and Deviation from Overall Average)
WITH LocationAverages AS (
    SELECT 
        Pickup_Location,
        AVG(Booking_Value) AS AvgBookingValue
    FROM BookingData
    WHERE Booking_Status = 'Success'
    GROUP BY Pickup_Location
),
OverallAverage AS (
    SELECT AVG(Booking_Value) AS OverallAvgBookingValue
    FROM BookingData
    WHERE Booking_Status = 'Success'
)
SELECT 
    la.Pickup_Location,
    la.AvgBookingValue,
    oa.OverallAvgBookingValue,
    la.AvgBookingValue - oa.OverallAvgBookingValue AS DeviationFromOverallAvg
FROM LocationAverages la
CROSS JOIN OverallAverage oa
ORDER BY la.AvgBookingValue DESC;


-- Question 6.Find the Most Frequent Cancellation Time
WITH CancellationsByHour AS (
    SELECT 
        EXTRACT(HOUR FROM Ride_Time) AS HourOfDay,
        COUNT(*) AS TotalCancellations
    FROM BookingData
    WHERE Booking_Status IN ('Cancelled by Customer', 'Cancelled by Driver')
    GROUP BY HourOfDay
)
SELECT 
    HourOfDay,
    TotalCancellations,
    RANK() OVER (ORDER BY TotalCancellations DESC) AS CancellationRank
FROM CancellationsByHour
ORDER BY CancellationRank;
