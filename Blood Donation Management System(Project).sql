--Blood Donation Management System Database
/*Contains: 
			1. Tables
            2. Indexes
            3. Views
            4. Stored Procedures
            5. User Defined Functions
            6. Triggers */

CREATE DATABASE BDMS
ON
(
  SIZE = 10mb,
  FILENAME = 'path\BDMS.mdf'
  FILEGROWTH = 10%
  MAXSIZE = 500mb
)
LOG ON
(
  SIZE = 10mb,
  FILENAME = 'path\BDMS.ldf'
  FILEGROWTH = 10%
  MAXSIZE = 500mb	
)

CREATE TABLE Donors (
    DonorID INT PRIMARY KEY,
    Name VARCHAR(50),
    BloodType VARCHAR(3),
    Age INT,
    ContactDetails VARCHAR(100),
  
);


CREATE TABLE Clinics (
    ClinicID INT PRIMARY KEY,
    Name VARCHAR(50),
    Location VARCHAR(100),
    ContactDetails VARCHAR(100),
   
);


CREATE TABLE BloodInventory (
    BloodID INT PRIMARY KEY,
    BloodType VARCHAR(3),
    Quantity INT,
    ExpirationDate DATE,
   
);


CREATE TABLE Donations (
    DonationID INT PRIMARY KEY,
    DonorID INT,
    ClinicID INT,
    DonationDate DATE,
    
);


CREATE INDEX IX_Donors ON Donors (DonorID);
CREATE INDEX IX_Clinics ON Clinics (ClinicID);
CREATE INDEX IX_BloodInventory ON BloodInventory (BloodType);


CREATE VIEW DonorDetails AS
SELECT DonorID, Name, BloodType, ContactDetails
FROM Donors;

CREATE VIEW ClinicInventory AS
SELECT c.ClinicID, c.Name, b.BloodType, b.Quantity
FROM Clinic c
INNER JOIN BloodInventory b ON c.ClinicID = b.bloodid;

CREATE PROCEDURE AddDonor
    @DonorID INT,
    @Name VARCHAR(50),
    @BloodType VARCHAR(3),
    @Age INT,
    @ContactDetails VARCHAR(100)
AS
BEGIN
    INSERT INTO Donors (DonorID, Name, BloodType, Age, ContactDetails)
    VALUES (@DonorID, @Name, @BloodType, @Age, @ContactDetails);
END;

CREATE PROCEDURE AddClinic
    @ClinicID INT,
    @Name VARCHAR(50),
    @Location VARCHAR(100),
    @ContactDetails VARCHAR(100)
AS
BEGIN
    INSERT INTO Clinics (ClinicID, Name, Location, ContactDetails)
    VALUES (@ClinicID, @Name, @Location, @ContactDetails);
END;

CREATE PROCEDURE AddDonation
    @DonationID INT,
    @DonorID INT,
    @ClinicID INT,
    @DonationDate DATE
AS
BEGIN
    INSERT INTO Donations (DonationID, DonorID, ClinicID, DonationDate)
    VALUES (@DonationID, @DonorID, @ClinicID, @DonationDate);

    UPDATE BloodInventory
    SET Quantity = Quantity - 1
    WHERE BloodType = (SELECT BloodType FROM Donors WHERE DonorID = @DonorID);
END;

CREATE PROCEDURE GetDonorDonations
    @DonorID INT
AS
BEGIN
    SELECT *
    FROM Donations
    WHERE DonorID = @DonorID;
END;

CREATE PROCEDURE GetClinicInventory
    @ClinicID INT
AS
BEGIN
    SELECT *
    FROM ClinicInventory
    WHERE ClinicID = @ClinicID;
END;

CREATE FUNCTION CalculateAge
(
	@Birthdate DATE
)
RETURNS INT
AS
BEGIN
	DECLARE @age INT;
    SET @age = DATEDIFF(YEAR, @Birthdate, GETDATE());
    RETURN @age;
END;

CREATE FUNCTION CheckbloodAvailability
(
	@Bloodtype varchar(3)
)
RETURNS BIT
AS
BEGIN
	DECLARE @Availability BIT;
    SET @Availability = CASE WHEN EXISTS 
    (SELECT 1 FROM BloodInventory WHERE bloodtype= @Bloodtype
    AND quantity>0) THEN 1 
    ELSE 0
    END;
    RETURN @Availability;
END;

CREATE TRIGGER UpdateBloodInventory
on Donations
AFTER INSERT
AS
BEGIN
	UPDATE bi
    SET quantity = quantity -1
    FROM BloodInventory bi
    INNER JOIN INSERTED i ON bi.BloodType = 
    (SELECT bloodtype FROM Donors WHERE donorid=i.donorid)
    WHERE bi.bloodid=i.clinicid;
    UPDATE BloodInventory
    SET quantity = 0
    WHERE expirationdate <= GETDATE();
END;