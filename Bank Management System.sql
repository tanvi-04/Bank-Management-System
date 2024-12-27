/*
** Author : Group_1
** Team Member-1: - Priyam Rameshbhai Mistri
** Team Member-2: - Tanvi Hemantbhai Patel
** Course : IFT/530
** SQL Server Version: Microsoft SQL Server 2012(SP1)
*/

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'Group_1')
BEGIN
    CREATE DATABASE Group_1;
END;
GO

USE Group_1;
GO

IF OBJECT_ID('dbo.Transactions', 'U') IS NOT NULL 
    DROP TABLE dbo.Transactions;

IF OBJECT_ID('dbo.Loans', 'U') IS NOT NULL 
    DROP TABLE dbo.Loans;

IF OBJECT_ID('dbo.Accounts', 'U') IS NOT NULL 
    DROP TABLE dbo.Accounts;

IF OBJECT_ID('dbo.Employees', 'U') IS NOT NULL 
    DROP TABLE dbo.Employees;

IF OBJECT_ID('dbo.Customer_Logs', 'U') IS NOT NULL 
    DROP TABLE dbo.Customer_Logs;

IF OBJECT_ID('dbo.Customer_Nominee', 'U') IS NOT NULL 
    DROP TABLE dbo.Customer_Nominee;

IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL 
    DROP TABLE dbo.Customers;

IF OBJECT_ID('dbo.Branches', 'U') IS NOT NULL 
    DROP TABLE dbo.Branches;

/****************************************************************************************************************
                               Table Creation
******************************************************************************************************************/
-- Create the Branches table
CREATE TABLE dbo.Branches (
    branch_id INT PRIMARY KEY IDENTITY(1,1),
    branch_name VARCHAR(100) NOT NULL,
    branch_location VARCHAR(255) NOT NULL
);

-- Create the Customers table
CREATE TABLE dbo.Customers (
    customer_id INT PRIMARY KEY IDENTITY(1,1),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL,
    address VARCHAR(255) NOT NULL
);

-- Create the Accounts table
CREATE TABLE dbo.Accounts (
    account_id INT PRIMARY KEY IDENTITY(1,1),
    account_number VARCHAR(20) NOT NULL UNIQUE,
    account_type VARCHAR(50) NOT NULL,
    balance DECIMAL(18, 2) NOT NULL,
    customer_id INT,
    branch_id INT,
    FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES dbo.Branches(branch_id)
);

-- Create the Loans table
CREATE TABLE dbo.Loans (
    loan_id INT PRIMARY KEY IDENTITY(1,1),
    loan_type VARCHAR(50) NOT NULL,
    amount DECIMAL(18, 2) NOT NULL,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id)
);

-- Create the Employees table
CREATE TABLE dbo.Employees (
    employee_id INT PRIMARY KEY IDENTITY(1,1),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL,
    position VARCHAR(50) NOT NULL,
    branch_id INT,
    FOREIGN KEY (branch_id) REFERENCES dbo.Branches(branch_id)
);

CREATE TABLE dbo.Transactions (
    transaction_id INT NOT NULL, -- Removed IDENTITY since it's part of the composite key
    transaction_date DATETIME NOT NULL,
    amount DECIMAL(18, 2) NOT NULL,
    transaction_type VARCHAR(10) NOT NULL,
    account_id INT NOT NULL,
    FOREIGN KEY (account_id) REFERENCES dbo.Accounts(account_id),
    PRIMARY KEY (transaction_id, account_id) -- Composite primary key
);


-- Create the Customer Nominee table
CREATE TABLE dbo.Customer_Nominee (
    nominee_id INT PRIMARY KEY IDENTITY(1,1),     
    nominee_name VARCHAR(100) NOT NULL,             
    relationship VARCHAR(50) NOT NULL,            
    contact_number VARCHAR(15),                    
    address VARCHAR(255),                           
    customer_id INT,                                
    FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id)  
);

-- Create the Customer Log table
CREATE TABLE dbo.Customer_Logs (
    log_id INT PRIMARY KEY IDENTITY(1,1),
    activity_type VARCHAR(50), 
    customer_id INT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone_number VARCHAR(15),
    address VARCHAR(255),
    timestamp DATETIME,  
    action_timestamp DATETIME DEFAULT GETDATE(),
	Reason nvarchar(MAX),
    FOREIGN KEY (customer_id) REFERENCES dbo.Customers(customer_id)
);
select * from Customer_Nominee
select * from Accounts
select * from Branches
select * from Employees
select * from Loans
select * from Transactions
select * from Customer_Logs
/****************************************************************************************************************
                               Insert Triggers
******************************************************************************************************************/
IF OBJECT_ID('dbo.Customer_Insert_Log') IS NOT NULL
    DROP TRIGGER dbo.Customer_Insert_Log;
Go
CREATE TRIGGER Customer_Insert_Log
ON dbo.Customers
AFTER INSERT
AS
BEGIN
    DECLARE @customer_id INT;
    DECLARE @first_name VARCHAR(50);
    DECLARE @last_name VARCHAR(50);
    DECLARE @email VARCHAR(100);
    DECLARE @phone_number VARCHAR(15);
    DECLARE @address VARCHAR(255);

    SELECT 
        @customer_id = customer_id,
        @first_name = first_name,
        @last_name = last_name,
        @email = email,
        @phone_number = phone_number,
        @address = address
    FROM INSERTED;

    INSERT INTO dbo.Customer_Logs (activity_type, customer_id, first_name, last_name, email, phone_number, address, timestamp, Reason)
    VALUES ('INSERT', @customer_id, @first_name, @last_name, @email, @phone_number, @address, GETDATE(), 'New Account Opening');
END;
Go
/****************************************************************************************************************
                               Update Triggers
******************************************************************************************************************/
IF OBJECT_ID('dbo.Customer_Update_Log') IS NOT NULL
    DROP TRIGGER dbo.Customer_Update_Log;
Go
CREATE TRIGGER Customer_Update_Log
ON dbo.Customers
AFTER UPDATE
AS
BEGIN
    DECLARE @customer_id INT;
    DECLARE @old_first_name VARCHAR(50), @new_first_name VARCHAR(50);
    DECLARE @old_last_name VARCHAR(50), @new_last_name VARCHAR(50);
    DECLARE @old_email VARCHAR(100), @new_email VARCHAR(100);
    DECLARE @old_phone_number VARCHAR(15), @new_phone_number VARCHAR(15);
    DECLARE @old_address VARCHAR(255), @new_address VARCHAR(255);

    SELECT 
        @customer_id = customer_id,
        @old_first_name = (SELECT first_name FROM DELETED WHERE customer_id = INSERTED.customer_id),
        @new_first_name = first_name,
        @old_last_name = (SELECT last_name FROM DELETED WHERE customer_id = INSERTED.customer_id),
        @new_last_name = last_name,
        @old_email = (SELECT email FROM DELETED WHERE customer_id = INSERTED.customer_id),
        @new_email = email,
        @old_phone_number = (SELECT phone_number FROM DELETED WHERE customer_id = INSERTED.customer_id),
        @new_phone_number = phone_number,
        @old_address = (SELECT address FROM DELETED WHERE customer_id = INSERTED.customer_id),
        @new_address = address
    FROM INSERTED;

    INSERT INTO dbo.Customer_Logs (activity_type, customer_id, first_name, last_name, email, phone_number, address, timestamp, Reason)
    VALUES ('UPDATE', @customer_id, @new_first_name, @new_last_name, @new_email, @new_phone_number, @new_address, GETDATE(), 'Customer Request');
END;
Go
/****************************************************************************************************************
                               Populating the tables
******************************************************************************************************************/
INSERT INTO dbo.Branches (branch_name, branch_location) VALUES
('Main Branch', '123 Main St, City, State'),
('Downtown Branch', '456 Downtown Rd, City, State'),
('Uptown Branch', '789 Uptown Blvd, City, State'),
('North Branch', '321 North St, City, State'),
('South Branch', '654 South Ave, City, State'),
('East Branch', '987 East St, City, State'),
('West Branch', '654 West Blvd, City, State'),
('Central Branch', '159 Central St, City, State'),
('Park Branch', '753 Park Rd, City, State'),
('Hill Branch', '852 Hilltop Dr, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('John', 'Doe', 'john.doe@gmail.com', '555-1234', '123 Elm St, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('Jane', 'Smith', 'jane.smith@gmail.com', '555-5678', '456 Oak St, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('Alice', 'Johnson', 'alice.johnson@gmail.com', '555-8765', '789 Pine St, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('Bob', 'Brown', 'bob.brown@gmail.com', '555-4321', '321 Maple St, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('Charlie', 'Davis', 'charlie.davis@gmail.com', '555-3456', '654 Cedar St, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('Eve', 'Wilson', 'eve.wilson@gmail.com', '555-7890', '987 Birch St, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('Frank', 'Moore', 'frank.moore@gmail.com', '555-2345', '159 Cherry St, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('Grace', 'Taylor', 'grace.taylor@gmail.com', '555-6789', '753 Walnut St, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('Hannah', 'Anderson', 'hannah.anderson@gmail.com', '555-4567', '852 Spruce St, City, State');

INSERT INTO dbo.Customers (first_name, last_name, email, phone_number, address)
VALUES ('Isaac', 'Thomas', 'isaac.thomas@gmail.com', '555-3450', '258 Fir St, City, State');


INSERT INTO dbo.Customer_Nominee (nominee_name, relationship, contact_number, address, customer_id)
VALUES 
    ('Jane Doe', 'Spouse', '555-1234', '123 Elm St, City, State', 1),
    ('James Doe', 'Brother', '555-5678', '123 Elm St, City, State', 1),
    ('Mary Smith', 'Sister', '555-8765', '456 Oak St, City, State', 2),
    ('Carol Johnson', 'Mother', '555-4321', '789 Pine St, City, State', 3),
    ('Lisa Brown', 'Friend', '555-2468', '321 Maple St, City, State', 4),
    ('Tom Brown', 'Colleague', '555-1357', '321 Maple St, City, State', 4),
    ('Peter Wilson', 'Brother', '555-3698', '987 Birch St, City, State', 6),
    ('John Taylor', 'Father', '555-6789', '753 Walnut St, City, State', 8),
    ('Rachel Thomas', 'Spouse', '555-2468', '258 Fir St, City, State', 10);
 

INSERT INTO dbo.Accounts (account_number, account_type, balance, customer_id, branch_id) VALUES
('10001', 'Savings', 1500.00, 1, 1),
('10002', 'Checking', 2500.00, 2, 1),
('10003', 'Savings', 3000.00, 3, 2),
('10004', 'Checking', 4500.00, 4, 2),
('10005', 'Savings', 6000.00, 5, 3),
('10006', 'Checking', 7500.00, 6, 3),
('10007', 'Savings', 9000.00, 7, 4),
('10008', 'Checking', 12000.00, 8, 4),
('10009', 'Savings', 2000.00, 9, 5),
('10010', 'Checking', 1000.00, 10, 5);

INSERT INTO dbo.Loans (loan_type, amount, loan_date, due_date, customer_id) VALUES
('Personal Loan', 5000.00, '2024-01-01', '2025-01-01', 1),
('Home Loan', 250000.00, '2024-02-01', '2034-02-01', 2),
('Car Loan', 20000.00, '2024-03-01', '2025-03-01', 3),
('Education Loan', 15000.00, '2024-04-01', '2026-04-01', 4),
('Business Loan', 100000.00, '2024-05-01', '2030-05-01', 5),
('Personal Loan', 7000.00, '2024-06-01', '2025-06-01', 6),
('Home Loan', 300000.00, '2024-07-01', '2035-07-01', 7),
('Car Loan', 25000.00, '2024-08-01', '2025-08-01', 8),
('Education Loan', 20000.00, '2024-09-01', '2026-09-01', 9),
('Business Loan', 120000.00, '2024-10-01', '2030-10-01', 10);

INSERT INTO dbo.Employees (first_name, last_name, email, phone_number, position, branch_id) VALUES
('Mike', 'Jones', 'mike.jones@chase.co.in', '555-0011', 'Manager', 1),
('Sara', 'Williams', 'sara.williams@chase.co.in', '555-0022', 'Teller', 1),
('David', 'Brown', 'david.brown@chase.co.in', '555-0033', 'Loan Officer', 2),
('Anna', 'Johnson', 'anna.johnson@chase.co.in', '555-0044', 'Manager', 2),
('Tom', 'Davis', 'tom.davis@chase.co.in', '555-0055', 'Teller', 3),
('Lisa', 'Miller', 'lisa.miller@chase.co.in', '555-0066', 'Loan Officer', 3),
('Steve', 'Wilson', 'steve.wilson@chase.co.in', '555-0077', 'Manager', 4),
('Emily', 'Moore', 'emily.moore@chase.co.in', '555-0088', 'Teller', 4),
('John', 'Anderson', 'john.anderson@chase.co.in', '555-0099', 'Loan Officer', 5),
('Kate', 'Thomas', 'kate.thomas@chase.co.in', '555-0100', 'Manager', 5);

INSERT INTO dbo.Transactions (transaction_id,transaction_date, amount, transaction_type, account_id) VALUES
('1','2024-01-10', 500.00, 'credit', 1),
('2','2024-01-15', 300.00, 'debit', 1),
('3','2024-01-20', 700.00, 'credit', 2),
('4','2024-01-25', 200.00, 'debit', 2),
('5','2024-02-01', 1500.00, 'credit', 3),
('6','2024-02-05', 1200.00, 'debit', 3),
('7','2024-02-10', 3000.00, 'credit', 4),
('8','2024-02-15', 500.00, 'debit', 4),
('9','2024-03-01', 250.00, 'credit', 5),
('10','2024-03-05', 100.00, 'debit', 5),
('11', '2024-03-10', 750.00, 'credit', 1),
('12', '2024-03-15', 500.00, 'debit', 1),
('13', '2024-03-20', 1250.00, 'credit', 2),
('14', '2024-03-25', 300.00, 'debit', 2),
('15', '2024-04-01', 1800.00, 'credit', 3),
('16', '2024-04-05', 1000.00, 'debit', 3),
('17', '2024-04-10', 3500.00, 'credit', 4),
('18', '2024-04-15', 700.00, 'debit', 4),
('19', '2024-05-01', 400.00, 'credit', 5),
('20', '2024-05-05', 250.00, 'debit', 5),
('21', '2024-05-10', 600.00, 'credit', 1),
('22', '2024-05-15', 350.00, 'debit', 1),
('23', '2024-05-20', 1450.00, 'credit', 2),
('24', '2024-05-25', 550.00, 'debit', 2),
('25', '2024-06-01', 2200.00, 'credit', 3),
('26', '2024-06-05', 1400.00, 'debit', 3),
('27', '2024-06-10', 2700.00, 'credit', 4),
('28', '2024-06-15', 900.00, 'debit', 4),
('29', '2024-07-01', 500.00, 'credit', 5),
('30', '2024-07-05', 300.00, 'debit', 5),
('31', '2024-07-10', 800.00, 'credit', 1),
('32', '2024-07-15', 450.00, 'debit', 1),
('33', '2024-07-20', 1550.00, 'credit', 2),
('34', '2024-07-25', 600.00, 'debit', 2),
('35', '2024-08-01', 2500.00, 'credit', 3);

select * from Customer_Nominee
select * from Accounts
select * from Branches
select * from Employees
select * from Loans
select * from Transactions
select * from Customer_Logs

/*********************************************************************************************************************
                                       Update Script to test trigger
*********************************************************************************************************************/
update Customers set first_name = 'Tanvi', last_name = 'Patel', phone_number = '123-4567' where customer_id = '1'
update Customers set first_name = 'John', last_name = 'Doe', phone_number = '555-1234' where customer_id = '1'
update Customers set first_name = 'Priyam', last_name = 'Mistri', phone_number = '321-7456' where customer_id = '2'
update Customers set first_name = 'Jane', last_name = 'smith', phone_number = '555-5678' where customer_id = '2'
Select * from Customer_Logs where customer_id = '1'
Select * from Customer_Logs where customer_id = '2'

/************************************************************************************************************************
                                                  Query-1
************************************************************************************************************************/
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS where TABLE_NAME = 'vw_CustomerAccountBalancesByBranch')
begin
	DROP VIEW vw_CustomerAccountBalancesByBranch
end;
Go

CREATE VIEW vw_CustomerAccountBalancesByBranch AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    a.account_number,
    a.account_type,
    a.balance,
    b.branch_name
FROM 
    dbo.Customers AS c
JOIN 
    dbo.Accounts AS a ON c.customer_id = a.customer_id
JOIN 
    dbo.Branches AS b ON a.branch_id = b.branch_id
WHERE 
    a.balance > 0;
Go
select * from vw_CustomerAccountBalancesByBranch
/************************************************************************************************************************
                        Query-2
************************************************************************************************************************/
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS where TABLE_NAME = 'vw_LoanDetailsByCustomer')
begin
	DROP VIEW vw_LoanDetailsByCustomer
end;
Go

CREATE VIEW vw_LoanDetailsByCustomer AS
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    l.loan_id,
    l.loan_type,
    l.amount,
    l.loan_date,
    l.due_date
FROM 
    dbo.Customers AS c
JOIN 
    dbo.Loans AS l ON c.customer_id = l.customer_id
WHERE 
    l.due_date > GETDATE();
Go
select * from vw_LoanDetailsByCustomer
/************************************************************************************************************************
                        Query-3
************************************************************************************************************************/
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'vw_RecentTransactionsByBranch')
BEGIN
    DROP VIEW vw_RecentTransactionsByBranch;
END;
GO

CREATE VIEW vw_RecentTransactionsByBranch AS
SELECT 
    t.transaction_id,
    t.transaction_date,
    t.amount,
    t.transaction_type,
    a.account_number,
    b.branch_name
FROM 
    dbo.Transactions AS t
JOIN 
    dbo.Accounts AS a ON t.account_id = a.account_id
JOIN 
    dbo.Branches AS b ON a.branch_id = b.branch_id
WHERE 
    t.transaction_date >= DATEADD(MONTH, -1, '2024-07-01'); 
GO

-- Query the view
SELECT * FROM vw_RecentTransactionsByBranch;
/*********************************************************************************************************************
                                       Stored Procedure
*********************************************************************************************************************/
IF OBJECT_ID('dbo.GetCustomerDetails', 'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.GetCustomerDetails;
END;
GO

CREATE PROCEDURE GetCustomerDetails 
    @CustomerID INT = NULL,
    @FirstName VARCHAR(50) = NULL,
    @LastName VARCHAR(50) = NULL
AS
BEGIN
    IF @CustomerID IS NULL AND @FirstName IS NULL AND @LastName IS NULL
    BEGIN
        PRINT 'Please provide either CustomerID or FirstName and LastName';
        RETURN;
    END

    SELECT 
        C.customer_id,
        CONCAT(C.first_name, ' ', C.last_name) AS Fullname,
        C.email,
        C.phone_number,
        C.address,
        A.account_id,
        A.account_number,
        A.account_type,
        A.balance,
        B.branch_id,
        B.branch_name,
        B.branch_location,
        L.loan_id,
        L.loan_type,
        L.amount AS loan_amount,
        L.loan_date,
        L.due_date
    FROM dbo.Customers AS C
    LEFT JOIN dbo.Accounts AS A ON C.customer_id = A.customer_id
    LEFT JOIN dbo.Branches AS B ON A.branch_id = B.branch_id
    LEFT JOIN dbo.Loans AS L ON C.customer_id = L.customer_id
    WHERE (C.customer_id = @CustomerID)
       OR (C.first_name = @FirstName AND C.last_name = @LastName);

    PRINT 'Customer details retrieved successfully';
END;
GO

EXEC GetCustomerDetails @CustomerID = 1, @FirstName = 'John', @LastName = 'Doe';
/*********************************************************************************************************************
                                       User-Defined Function
*********************************************************************************************************************/
IF OBJECT_ID('dbo.CalculateInterest', 'FN') IS NOT NULL
BEGIN
    DROP FUNCTION dbo.CalculateInterest;
END;
GO 

CREATE FUNCTION dbo.CalculateInterest
(
    @PrincipalAmount DECIMAL(18, 2),  
    @AnnualInterestRate DECIMAL(5, 2),  
    @TimeInYears INT 
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @Interest DECIMAL(18, 2);

    SET @Interest = (@PrincipalAmount * @AnnualInterestRate * @TimeInYears) / 100;

    RETURN @Interest;
END;
GO  

DECLARE @Principal DECIMAL(18, 2) = 10000;  
DECLARE @Rate DECIMAL(5, 2) = 5;  
DECLARE @Time INT = 3;  

DECLARE @CalculatedInterest DECIMAL(18, 2);
SET @CalculatedInterest = dbo.CalculateInterest(@Principal, @Rate, @Time);


SELECT @CalculatedInterest AS Interest;

/*********************************************************************************************************************
                                       Cursor to generate customer account Statement
*********************************************************************************************************************/
DECLARE @Customer_id int = '1', @Transaction_Date Date, @Amount money, @Transaction_Type nvarchar(100);
CREATE TABLE #CustomerTransactions (
    Transaction_Date DATE,
    Amount MONEY,
    Transaction_Type NVARCHAR(100),
	Customer_ID int
 );
DECLARE CustomerStatementCursor CURSOR FOR
Select transaction_date, amount, transaction_type from Transactions where account_id = @Customer_id

OPEN CustomerStatementCursor;
	
FETCH NEXT FROM CustomerStatementCursor INTO @Transaction_Date, @Amount, @Transaction_Type;
	print @Transaction_Type
WHILE @@FETCH_STATUS = 0
BEGIN

	INSERT INTO #CustomerTransactions (Transaction_Date, Amount, Transaction_Type, Customer_ID)
    VALUES (@Transaction_Date, @Amount, @Transaction_Type, @Customer_id);

    FETCH NEXT FROM CustomerStatementCursor INTO @Transaction_Date, @Amount, @Transaction_Type;
END;

CLOSE CustomerStatementCursor;

DEALLOCATE CustomerStatementCursor;

/*********************************************************************************************************************
                                       Query to display opening balance
*********************************************************************************************************************/
select CONCAT(b.first_name , ' ', b.last_name) as 'Customer Name',a.balance as 'Opening Balance' from Accounts as a LEFT JOIN Customers as b on a.account_id = b.customer_id where a.customer_id = @Customer_id 

/*********************************************************************************************************************
                                       Query to generate final statement
*********************************************************************************************************************/
SELECT	a.Transaction_Date AS Date,a.Transaction_Type AS Type,a.Amount AS 'Transaction Amount',
		ISNULL(
			SUM(
				CASE 
					WHEN a.Transaction_Type = 'credit' THEN a.Amount
					WHEN a.Transaction_Type = 'debit' THEN -a.Amount
					ELSE 0
				END
			) OVER (PARTITION BY a.Customer_ID ORDER BY a.Transaction_Date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			+ b.Balance,
			b.Balance
		) AS Closing
FROM 
    #CustomerTransactions AS a
LEFT JOIN 
    Accounts AS b 
ON 
    a.Customer_ID = b.Customer_ID
ORDER BY 
    a.Transaction_Date;

drop table #CustomerTransactions