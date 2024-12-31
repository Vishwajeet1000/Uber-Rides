--Basic Explorations
-- 1.View All Records
SELECT * FROM BookingData LIMIT 100; -- View the first 100 rows

-- 2.Verify total rows with the csv file
SELECT COUNT(*) AS TotalRecords FROM BookingData;

-- 3.View unique vehicle types
SELECT DISTINCT Vehicle_Type FROM BookingData;

-- Aggregations
-- 4.Total Booking By Status

SELECT Booking_Status, COUNT(*) AS TotalBookings
FROM BookingData
GROUP BY Booking_Status
ORDER BY TotalBookings DESC;

-- 5.Total Revenue by Vehicle Type
SELECT Vehicle_Type, SUM(Booking_Value) AS TotalRevenue
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY TotalRevenue DESC;

--6.Average Driver and Customer Ratings by Vehicle Type
SELECT Vehicle_Type, 
       ROUND(AVG(Driver_Ratings)::numeric,2) AS AvgDriverRating, 
       ROUND(AVG(Customer_Rating)::numeric,2) AS AvgCustomerRating
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY AvgDriverRating DESC;

-- Time-Based Trends
-- 7.Daily Total Revenue

SELECT Ride_Date, SUM(Booking_Value) AS DailyRevenue
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Ride_Date
ORDER BY Ride_Date DESC;

-- 8.Hourly Booking Trends
SELECT EXTRACT(HOUR FROM Ride_Time) AS HourOfDay, COUNT(*) AS TotalBookings
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY HourOfDay
ORDER BY TotalBookings DESC;

--9.Weekend vs. Weekday Revenue
SELECT 
    CASE 
        WHEN EXTRACT(DOW FROM Ride_Date) IN (0, 6) THEN 'Weekend' -- 0: Sunday, 6: Saturday
        ELSE 'Weekday'
    END AS DayType,
    SUM(Booking_Value) AS TotalRevenue
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY DayType;

-- Cancellation Insights
-- 10.Top Reasons for Customer Cancellations
SELECT Reason_For_Cancelling_By_Customer, COUNT(*) AS CustomerCancellations
FROM BookingData
WHERE Cancelled_By_Customer = TRUE
GROUP BY Reason_For_Cancelling_By_Customer
ORDER BY CustomerCancellations DESC;

-- 11.Top Reasons for Driver Cancellations
SELECT Reason_For_Cancelling_By_Driver, COUNT(*) AS DriverCancellations
FROM BookingData
WHERE Cancelled_By_Driver = TRUE
GROUP BY Reason_For_Cancelling_By_Driver
ORDER BY DriverCancellations DESC;

-- Distance and Revenue Analysis
-- 12.Revenue by Distance Range
SELECT 
    CASE 
        WHEN Ride_Distance < 5 THEN '< 5 km'
        WHEN Ride_Distance BETWEEN 5 AND 10 THEN '5-10 km'
        WHEN Ride_Distance BETWEEN 10 AND 20 THEN '10-20 km'
        ELSE '> 20 km'
    END AS DistanceRange,
    SUM(Booking_Value) AS TotalRevenue
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY DistanceRange
ORDER BY TotalRevenue DESC;

-- 13.Average Booking Value by Distance
SELECT Ride_Distance, 
ROUND(AVG(Booking_Value)::numeric,2) AS AvgBookingValue
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Ride_Distance
ORDER BY Ride_Distance DESC;

--Customer and Driver Ratings
--14.Customer Rating Distribution

SELECT Customer_Rating, COUNT(*) AS succes_TotalRatings
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Customer_Rating
ORDER BY Customer_Rating DESC;

-- 15.Driver Rating Distribution
SELECT Driver_Ratings, COUNT(*) AS TotalRatings
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Driver_Ratings
ORDER BY Driver_Ratings DESC;


-- Location-Based Analysis
--16. Top 10 Pickup Locations

SELECT Pickup_Location, COUNT(*) AS TotalPickups
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Pickup_Location
ORDER BY TotalPickups DESC
LIMIT 10;

-- 17.Top 10 drop locations
SELECT Drop_Location, COUNT(*) AS TotalDrops
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Drop_Location
ORDER BY TotalDrops DESC
LIMIT 10;

--18.Most Frequent Pickup-Drop Pairs
SELECT Pickup_Location, Drop_Location, COUNT(*) AS TotalRides
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Pickup_Location, Drop_Location
ORDER BY TotalRides DESC
LIMIT 10;

--Insights and Reporting
--19.Highest Revenue Days

SELECT Ride_Date, SUM(Booking_Value) AS DailyRevenue
FROM BookingData
WHERE Booking_Status = 'Success'
GROUP BY Ride_Date
ORDER BY DailyRevenue DESC
LIMIT 10;

--20.Rides with Incomplete Status
SELECT *
FROM BookingData
WHERE Incomplete_Rides = TRUE;
