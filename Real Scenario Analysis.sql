-- Scenario Bases Solutions
/*
1. Automatically Assign Drivers to Peak Areas
Use Case: Assign more drivers to high-demand areas based on past booking trends.
*/
CREATE OR REPLACE PROCEDURE AssignDriversToPeakAreas()
LANGUAGE plpgsql
AS $$
DECLARE
    top_locations RECORD;
    updated_count INT;
BEGIN
    -- Step 1: Identify top 5 pickup locations
    FOR top_locations IN
        SELECT 
            Pickup_Location,
            COUNT(*) AS TotalBookings
        FROM BookingData
        WHERE Booking_Status = 'Success'
        GROUP BY Pickup_Location
        ORDER BY TotalBookings DESC
        LIMIT 5
    LOOP
        -- Log the pickup location being processed
        RAISE NOTICE 'Processing Pickup Location: %, Total Bookings: %', 
                     top_locations.Pickup_Location, top_locations.TotalBookings;

        -- Step 2: Update Drivers table based on the top locations
        UPDATE Drivers
        SET Assigned_Area = top_locations.Pickup_Location
        WHERE Driver_Availability = 'Available'
          AND Assigned_Area IS NULL
        RETURNING 1 INTO updated_count; -- Returns number of rows updated
        
        -- Log the number of drivers updated
        RAISE NOTICE 'Drivers assigned to Pickup Location %: %', 
                     top_locations.Pickup_Location, updated_count;
    END LOOP;
END;
$$;
CALL AssignDriversToPeakAreas();

/*
Scenario 2: Revenue Forecast by Vehicle Type
Use Case: A stored procedure can be created to forecast revenue for different vehicle types based on historical data.
*/
CREATE OR REPLACE PROCEDURE ForecastRevenue(forecast_days INT)
LANGUAGE plpgsql
AS $$
DECLARE
    vehicle_type TEXT;
    forecasted_revenue NUMERIC;
BEGIN
    -- Loop through each vehicle type and calculate the forecasted revenue
    FOR vehicle_type, forecasted_revenue IN
        SELECT 
            bd.Vehicle_Type,
            SUM(bd.Booking_Value) / COUNT(DISTINCT bd.Ride_Date) * forecast_days AS ForecastedRevenue
        FROM BookingData bd
        WHERE bd.Booking_Status = 'Success'
        GROUP BY bd.Vehicle_Type
    LOOP
        -- Print the result using RAISE NOTICE
        RAISE NOTICE 'Vehicle Type: %, Forecasted Revenue: %', vehicle_type, forecasted_revenue;
    END LOOP;
END;
$$;
CALL ForecastRevenue(30);

/*
Scenario 3: Generate a Monthly Report on Revenue and Cancellations
Use Case: Generate a consolidated monthly report for revenue, completed rides, and cancellations for management.
*/
CREATE OR REPLACE PROCEDURE GenerateMonthlyReport(report_month INT, report_year INT)
LANGUAGE plpgsql
AS $$
DECLARE
    vehicle_record RECORD;
    customer_cancellation RECORD;
    driver_cancellation RECORD;
BEGIN
    -- Revenue and completed rides
    RAISE NOTICE '--- Revenue and Completed Rides ---';
    FOR vehicle_record IN
        SELECT 
            Vehicle_Type,
            COUNT(*) AS TotalCompletedRides,
            SUM(Booking_Value) AS TotalRevenue
        FROM BookingData
        WHERE Booking_Status = 'Success'
          AND EXTRACT(MONTH FROM Ride_Date) = report_month
          AND EXTRACT(YEAR FROM Ride_Date) = report_year
        GROUP BY Vehicle_Type
    LOOP
        RAISE NOTICE 'Vehicle Type: %, Completed Rides: %, Revenue: %', 
                     vehicle_record.Vehicle_Type, 
                     vehicle_record.TotalCompletedRides, 
                     vehicle_record.TotalRevenue;
    END LOOP;

    -- Customer cancellations
    RAISE NOTICE '--- Customer Cancellations ---';
    FOR customer_cancellation IN
        SELECT 
            Reason_For_Cancelling_By_Customer AS CustomerCancellationReason,
            COUNT(*) AS TotalCancellationsByCustomers
        FROM BookingData
        WHERE Cancelled_By_Customer = TRUE
          AND EXTRACT(MONTH FROM Ride_Date) = report_month
          AND EXTRACT(YEAR FROM Ride_Date) = report_year
        GROUP BY Reason_For_Cancelling_By_Customer
    LOOP
        RAISE NOTICE 'Reason: %, Total Cancellations by Customers: %', 
                     customer_cancellation.CustomerCancellationReason, 
                     customer_cancellation.TotalCancellationsByCustomers;
    END LOOP;

    -- Driver cancellations
    RAISE NOTICE '--- Driver Cancellations ---';
    FOR driver_cancellation IN
        SELECT 
            Reason_For_Cancelling_By_Driver AS DriverCancellationReason,
            COUNT(*) AS TotalCancellationsByDrivers
        FROM BookingData
        WHERE Cancelled_By_Driver = TRUE
          AND EXTRACT(MONTH FROM Ride_Date) = report_month
          AND EXTRACT(YEAR FROM Ride_Date) = report_year
        GROUP BY Reason_For_Cancelling_By_Driver
    LOOP
        RAISE NOTICE 'Reason: %, Total Cancellations by Drivers: %', 
                     driver_cancellation.DriverCancellationReason, 
                     driver_cancellation.TotalCancellationsByDrivers;
    END LOOP;

    RAISE NOTICE '--- End of Monthly Report ---';
END;
$$;
CALL GenerateMonthlyReport(12, 2024); -- Example for December 2024

/*
Scenario 4: Dynamic Surge Pricing Based on Demand
Use Case: Automatically adjust pricing in high-demand areas during peak hours to balance supply and demand. This helps increase revenue and ensure availability for customers.
*/
CREATE OR REPLACE PROCEDURE AdjustSurgePricing()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Step 1: Identify high-demand areas based on bookings in the last hour
    CREATE TEMP TABLE HighDemandAreas AS
    SELECT 
        Pickup_Location,
        COUNT(*) AS TotalBookings
    FROM BookingData
    WHERE Ride_Date = CURRENT_DATE 
      AND EXTRACT(HOUR FROM Ride_Time) = EXTRACT(HOUR FROM CURRENT_TIME) - 1
      AND Booking_Status = 'Success'
    GROUP BY Pickup_Location
    HAVING COUNT(*) > 50; -- Define threshold for high demand

    -- Step 2: Update pricing for high-demand areas
    UPDATE Pricing
    SET SurgeMultiplier = 1.5 -- Increase fare by 50%
    WHERE Location IN (SELECT Pickup_Location FROM HighDemandAreas);

    -- Step 3: Clean up the temporary table (optional, temp tables are auto-dropped at the end of session)
    DROP TABLE HighDemandAreas;
END;
$$;
CALL AdjustSurgePricing();

/*
Scenario 5: Customer Compensation for Delayed Rides
Use Case: Automatically compensate customers if their ride is delayed beyond a specific threshold (e.g., 15 minutes).
*/
CREATE OR REPLACE PROCEDURE CompensateDelayedRides()
LANGUAGE plpgsql
AS $$
DECLARE
    record RECORD; -- Declaring the variable to hold rows in the loop
BEGIN
    -- Step 1: Identify delayed rides
    CREATE TEMP TABLE DelayedRides AS
    SELECT 
        BookingID,
        CustomerID,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - Ride_Time)) / 60 AS DelayMinutes
    FROM BookingData
    WHERE Booking_Status = 'Success'
      AND EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - Ride_Time)) / 60 > 15; -- Delay threshold in minutes

    -- Step 2: Insert compensation records into the Compensation table
    INSERT INTO Compensation (CustomerID, BookingID, CompensationAmount, CompensationReason)
    SELECT 
        CustomerID,
        BookingID,
        20.00,  -- Fixed compensation amount
        'Ride Delayed Beyond 15 Minutes'
    FROM DelayedRides;

    -- Step 3: Notify customers (optional - simulated here with a RAISE NOTICE)
    FOR record IN 
        SELECT CustomerID, BookingID 
        FROM DelayedRides
    LOOP
        RAISE NOTICE 'CustomerID: %, BookingID: %, Notification: You have been compensated $20 for a delayed ride.', 
                     record.CustomerID, record.BookingID;
    END LOOP;

    -- Step 4: Clean up temporary table
    DROP TABLE DelayedRides;
END;
$$;

CALL CompensateDelayedRides();


/*
Scenario 6: Automatic Cancellation Analysis
Use Case: A stored procedure can analyze cancellations and provide a summary of reasons, grouped by customers and drivers, to identify recurring issues.
*/
CREATE OR REPLACE PROCEDURE AnalyzeCancellations()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Customer cancellations analysis
    RAISE NOTICE 'Customer Cancellations:';
    PERFORM 
        Reason_For_Cancelling_By_Customer AS CustomerReason,
        COUNT(*) AS TotalCustomerCancellations
    FROM BookingData
    WHERE Cancelled_By_Customer = TRUE
    GROUP BY CustomerReason;

    -- Driver cancellations analysis
    RAISE NOTICE 'Driver Cancellations:';
    PERFORM 
        Reason_For_Cancelling_By_Driver AS DriverReason,
        COUNT(*) AS TotalDriverCancellations
    FROM BookingData
    WHERE Cancelled_By_Driver = TRUE
    GROUP BY DriverReason;
END;
$$;
CALL AnalyzeCancellations();
