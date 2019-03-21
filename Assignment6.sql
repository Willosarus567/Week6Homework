/*#1. Write a stored procedure that takes a class name and returns all guests that have any levels of that class */

    CREATE PROCEDURE ClassFinder
    
    AS 
        TABLE
    BEGIN
        SELECT Classes.Class_Name, Classes.Class_Id, GuestClasses.Guest_Id FROM Classes RIGHT JOIN GuestClasses ON GuestClasses.Guest_Id = Classes.Class_Id ORDER BY Classes.Class_Name;
    END   

        ALTER PROCEDURE ClassFinder
    
    AS 
    BEGIN
        SELECT DISTINCT Classes.Class_Name, Classes.Class_Id, GuestClasses.Guest_Id FROM GuestClasses RIGHT JOIN Classes ON GuestClasses.Guest_Id = Classes.Class_Id;
    END

/*This one worked best*/
    ALTER PROCEDURE ClassFinder 
    
    AS 
    BEGIN
        SELECT DISTINCT Classes.Class_Name, Classes.Class_Id, GuestClasses.Guest_Id FROM GuestClasses RIGHT JOIN Classes ON GuestClasses.Class_Id = Classes.Class_Id;
    END

    EXEC dbo.ClassFinder; 

/*#2. Write a stored procedure that takes a guest id and returns the total that guest spent on services */

    CREATE PROCEDURE GuestExpenses
    
    AS 
    BEGIN
        SELECT Sales.Guest_Id, Sales.Sale_Id, Sales.Price, Sales.Sale_Amount, SUM(Sales.Price * Sales.Sale_Amount) AS 'Expenses per Guest' FROM Sales WHERE Sales.Guest_id = 16; 
    END

    CREATE PROCEDURE GuestExpenses
    
    AS 
    BEGIN
        SELECT SUM(Sales.Price * Sales.Sale_Amount) AS 'Expenses per Guest' FROM Sales WHERE Sales.Guest_Id = 16; 
    END

    ALTER PROCEDURE GuestExpenses
    
    AS 
    BEGIN
        SELECT SUM(Sales.Price * Sales.Sale_Amount) AS 'Expenses per Guest' FROM Sales WHERE Sales.Guest_Id = 16; 
    END

    ALTER PROCEDURE GuestExpenses
    
    AS 
    BEGIN
        SELECT CONCAT( Sales.Guest_Id, ' spent ', SUM(Sales.Price * Sales.Sale_Amount), ' on ', Sales.Service_Id) AS 'Expenses per Guest' FROM Sales WHERE Sales.Guest_Id = 16 
        GROUP BY Sales.Guest_Id, Sales.Service_Id; 
    END

/*This one has the most features*/
    ALTER PROCEDURE GuestExpenses
    
    AS 
    BEGIN
        SELECT Guests.Guest_Name, CONCAT( Sales.Guest_Id, ' spent ', SUM(Sales.Price * Sales.Sale_Amount), ' on ', Sales.Service_Id) AS 'Expenses per Guest' FROM Sales 
            LEFT JOIN Guests ON Guests.Guest_Id = Sales.Guest_Id
                WHERE Sales.Guest_Id = 16 
            GROUP BY Sales.Guest_Id, Sales.Service_Id, Guests.Guest_Name; 
    END

	EXEC dbo.GuestExpenses; 

/*#3. Write a stored procedure that takes a level and an optional argument that determines whether the procedure returns guests of that level and higher or that level and lower */

/*CREATE PROCEDURE ReturnGuestInfo
        @LevelRequirement INT = 40;

    AS
        IF (@LevelRequirement >= 40) 
    BEGIN
            SELECT CONCAT('Congratulaions, you may proceed on the quest.')
        ELSE
            SELECT CONCAT('You must level up before you can start.')
    END

    EXEC

    CREATE PROCEDURE ReturnGuestInfo*/

        @Parameter1 INT = 30,
        @Parameter2 VARCHAR (100) = 'Congratulations you meet the requirement',
AS

/* check for the NULL / default value (indicating nothing was passed */
IF (@Parameter1 >= 30)

BEGIN

    /* whatever code you desire for a missing parameter*/
    SELECT Guests.Guest_Name, GuestClasses.Guest_Id, GuestClasses.Class_Level FROM GuestClasses LEFT JOIN Guests ON Guests.Guest_Id = GuestClasses.Guest_Id WHERE GuestClasses.Class_Level = @Parameter1; 
END

      CREATE PROCEDURE ReturnGuestInfo

        @Parameter1 INT = 30,
        @Parameter2 VARCHAR (100) = NULL
AS

/* check for the NULL / default value (indicating nothing was passed */
--This ones a winner.

BEGIN
IF (@Parameter1 >= 30)
    /* whatever code you desire for a missing parameter*/
    SELECT Guests.Guest_Name, GuestClasses.Guest_Id, GuestClasses.Class_Level FROM GuestClasses 
    LEFT JOIN Guests ON Guests.Guest_Id = GuestClasses.Guest_Id WHERE GuestClasses.Class_Level = @Parameter1; 

ELSE IF 
	 (@Parameter2 IS NOT NULL)
		SELECT 'Guest has not met the level requirement.'

ELSE
	SELECT 'Please Find a guest who meets the requirement.'
END

EXEC ReturnGuestInfo 30, NULL;

/*#4. Write a stored procedure that deletes a Tavern ( don’t run it yet or rollback your transaction if you do ) */

ALTER PROCEDURE DeleteTavernWithId
    @TavernID INT = 5

    AS
    BEGIN
        DELETE FROM Taverns WHERE Taverns.Tavern_Id = @TavernID;
    END

    EXEC dbo.DeleteTavernWithId;

	SELECT * FROM Taverns; 

/*#5. Write a trigger that watches for deleted taverns and use it to remove taverns, supplies, rooms, and services tied to it */

/*CREATE TRIGGER DeleteTavernInformation @TavernID INT = 5

    ON Taverns 
    INSTEAD OF DELETE 
        AS 
            BEGIN 
            DELETE Tavern_Id FROM Taverns WHERE Tavern_Id IN (SELECT deleted.Tavern_Id FROM Deleted); 
            DELETE Tavern_Id FROM Taverns WHERE Tavern_Id = @TavernID; 
            DELETE Tavern_Name FROM Taverns WHERE Tavern_Id = @TavernID; 
            DELETE Owner_Id FROM Taverns WHERE Tavern_Id = @TavernID; 
            DELETE Floors FROM Taverns WHERE Tavern_Id = @TavernID;
            DELETE Rooms FROM Taverns WHERE Tavern_Id = @TavernID;
            DELETE City_Id FROM Taverns WHERE Tavern_Id = @TavernID;
            ROLLBACK;
            END;

        
EXEC DeleteTavernInformation;*/

DROP TRIGGER DeleteTavernInformation;
GO
CREATE TRIGGER DeleteTavernInformation 

    ON Taverns 
    INSTEAD OF DELETE 
        AS 
            BEGIN 

            DELETE FROM NPCs WHERE Tavern_Id IN (SELECT deleted.Tavern_Id FROM deleted);
            DELETE FROM Taverns WHERE Tavern_Name IN (SELECT deleted.Tavern_Name FROM deleted); 
            DELETE FROM Owners WHERE Owner_Id IN (SELECT deleted.Owner_Id FROM deleted);
			DELETE FROM Payments_Recieved WHERE Tavern_Id IN (SELECT deleted.Tavern_Id FROM deleted);
			DELETE FROM Supplies WHERE Tavern_Id IN (SELECT deleted.Tavern_Id FROM deleted); 
			DELETE FROM Sales WHERE Tavern_Id IN (SELECT deleted.Tavern_Id FROM deleted);
			DELETE FROM Services WHERE Tavern_Id IN (SELECT deleted.Tavern_Id FROM deleted);
            DELETE FROM Rooms WHERE Room_Id IN (SELECT deleted.Tavern_Id FROM deleted);
			DELETE FROM GuestRooms WHERE Tavern_Id IN (SELECT deleted.Tavern_Id FROM deleted);
            DELETE FROM Cities WHERE City_Id IN (SELECT deleted.City_Id FROM deleted); 
			ROLLBACK;
    END;
GO
DELETE FROM Taverns
WHERE Tavern_Id = 5

SELECT * FROM Taverns; 

/*#6. Write a stored procedure that uses the function from the last assignment that returns open rooms with their prices, and automatically book the lowest price room with a guest for one day */

ALTER FUNCTION dbo.OpenRooms( @Date DATE )
    RETURNS 
        TABLE
    AS 
    RETURN(
        SELECT TOP 1 Rooms.Room_Id, Rooms.Tavern_Id, Rooms.Floor, Rooms.Room_Status, Rooms.Room_Rate, Rooms.Date_Info FROM Rooms LEFT JOIN Taverns ON Rooms.Room_Id = Taverns.Tavern_Id WHERE Rooms.Date_Info = @Date
    );

CREATE PROCEDURE BookRoom (@RoomDate DATE)
AS
BEGIN 
UPDATE Rooms 
SET Room_Status = 'Occupied'
FROM Rooms LEFT JOIN dbo.OpenRooms(@RoomDate) ON Rooms.Room_Id = dbo.OpenRooms(@RoomDate).Room_Id AND Rooms.Tavern_Id = dbo.OpenRooms(@RoomDate).Tavern_Id
END;


EXEC dbo.BookRoom('2019-02-18');


SELECT * FROM dbo.OpenRooms('2019-01-28');

CREATE PROCEDURE [dbo].[uspGetMFGTotal]
(@RoomDate date)
AS 
BEGIN
Update Rooms
SET Room_Status = 'Occupied'
FROM Rooms R JOIN dbo.OpenRooms(@RoomDate) OP on R.Room_Id = OP.Room_Id and R.Tavern_Id = OP.Tavern_Id
END;


exec [uspGetMFGTotal] '2019-02-18'


/*#7. Write a trigger that watches for new bookings and adds a new sale for the guest for a service (for free if you can in your schema) */

ALTER TRIGGER InsertNewBooking
    ON Sales 
    FOR INSERT 
        AS 
            BEGIN 

INSERT INTO [dbo].[Sales]
           ([Sale_Id]
           ,[Service_Id]
           ,[Guest_Id]
           ,[Price]
           ,[Sale_Date]
           ,[Sale_Amount]
           ,[Tavern_Id])
     VALUES
           ((select inserted.Sale_Id + 1 from inserted)
           ,8
           ,(select inserted.Guest_Id from inserted)
           ,0
           ,(select inserted.Sale_Date from inserted)
           ,0
           ,(select inserted.Tavern_Id from inserted))
       END;
			GO


USE [Roon_Skaep_Taverns]
GO

INSERT INTO [dbo].[Sales]
           ([Sale_Id]
           ,[Service_Id]
           ,[Guest_Id]
           ,[Price]
           ,[Sale_Date]
           ,[Sale_Amount]
           ,[Tavern_Id])
     VALUES
           (15
           ,3
           ,2
           ,110.00
           ,'03/20/2019'
           ,110.00
           ,1)
GO

select * from Sales
where sale_Id = 15

/* Heres the code, it USES the schema WRovinski_2019.*/

INSERT INTO [dbo].[Sales]
           ([Sale_Id]
           ,[Service_Id]
           ,[Guest_Id]
           ,[Price]
           ,[Sale_Date]
           ,[Sale_Amount]
           ,[Tavern_Id])
     VALUES
           ((select inserted.Sale_Id + 1 from inserted)
           ,8
           ,(select inserted.Guest_Id from inserted)
           ,0
           ,(select inserted.Sale_Date from inserted)
           ,0
           ,(select inserted.Tavern_Id from inserted))
       END;
			GO


USE [WRovinski_2019]
GO

INSERT INTO [dbo].[Sales]
           ([Sale_Id]
           ,[Service_Id]
           ,[Guest_Id]
           ,[Price]
           ,[Sale_Date]
           ,[Sale_Amount]
           ,[Tavern_Id])
     VALUES
           (15
           ,3
           ,2
           ,110.00
           ,'03/20/2019'
           ,110.00
           ,1)
GO

select * from Sales
where sale_Id = 15

