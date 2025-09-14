USE [AdventureWorks2022]
GO


--ALTER TABLE PERSON.PERSON ADD EmailAddress  VARCHAR(128) NULL
ALTER TABLE PERSON.PERSON ALTER COLUMN EmailAddress VARCHAR(128) NULL;

update PERSON.PERSON set EmailAddress = 'rmuroc74@gmail.com'
where BusinessEntityID between 1 and 10

update PERSON.PERSON set EmailAddress = 'mm.lopeztimana@gmail.com'
where BusinessEntityID between 11 and 20

SELECT * FROM PERSON.PERSON

GO
CREATE PROCEDURE [person].[uspObtenerInformacionPersona]
(
	@BusinessEntityID  INT NULL,
	@PersonType nchar(2)  NULL,
	@FirstName name  NULL,
	@MiddleName name NULL,
	@LastName name  NULL,
	@Demographics xml NULL,
	@EmailAddress varchar(128) NULL
)
AS
select 
BusinessEntityID,
PersonType,
FirstName, 
MiddleName, 
LastName, 
CAST (Demographics AS VARCHAR (MAX)) AS Demographics,
EmailAddress
FROM person.person
WHERE 
    ([BusinessEntityID] = @BusinessEntityID OR @BusinessEntityID IS NULL)
    AND ([LastName] LIKE @LastName OR @LastName IS NULL)
    AND ([FirstName] LIKE @FirstName OR @FirstName IS NULL)
    AND ([MiddleName] = @MiddleName OR @MiddleName IS NULL)
    AND ([EmailAddress] LIKE @EmailAddress OR @EmailAddress IS NULL)
    AND (CAST (Demographics AS VARCHAR (MAX)) = CAST (@Demographics AS VARCHAR (MAX)) OR CAST (@Demographics AS VARCHAR (MAX))  IS NULL)
    AND ([PersonType] = @PersonType OR @PersonType IS NULL)
GO

sp_helpindex 'person.person'

CREATE INDEX idx_EmailAddress ON person.person ([EmailAddress]);
CREATE INDEX idx_PersonType ON person.person ([PersonType]);
GO

--B.2.-SEGUNDO PROCEDIMIENTO, LA CONDICI�N SE BASA EN COALESCE DONDE SE SELECCIONAR� LOS CAMPOS EN DONDE ENCUENTRE INFORMACI�N.
GO
CREATE PROCEDURE [person].[uspObtenerInformacionPersona2]
(
	@BusinessEntityID  INT NULL,
	@PersonType nchar(2)  NULL,
	@FirstName name  NULL,
	@MiddleName name NULL,
	@LastName name  NULL,
	@Demographics xml NULL,
	@EmailAddress varchar(128) NULL
)
AS
select 
BusinessEntityID,
PersonType,
FirstName,
MiddleName,
LastName,
CAST (Demographics AS VARCHAR (MAX)) AS Demographics,
EmailAddress
from person.person
WHERE 
    [BusinessEntityID]= COALESCE(@BusinessEntityID, [BusinessEntityID])
    AND [LastName] LIKE COALESCE(@LastName, [LastName])
    AND [FirstName] LIKE COALESCE(@FirstName, [FirstName])
    AND [MiddleName] = COALESCE(@MiddleName, [MiddleName])
    AND [EmailAddress] LIKE COALESCE(@EmailAddress, [EmailAddress])
    AND CAST (Demographics AS VARCHAR (MAX)) = COALESCE(CAST (@Demographics AS  VARCHAR (MAX)), CAST (Demographics AS VARCHAR (MAX)))
    AND [PersonType] = COALESCE(@PersonType, [PersonType]);
GO

--B.3.-TERCER PROCEDIMIENTO, LA CONDICI�N SE BASA EN CASE COLOCANDO CASOS POR CADA VCAMPO PARA SU SELECCI�N Y B�SQUEDA.
GO
CREATE PROCEDURE [person].[uspObtenerInformacionPersona3]
(
	@BusinessEntityID  INT NULL,
	@PersonType nchar(2)  NULL,
	@FirstName name  NULL,
	@MiddleName name NULL,
	@LastName name  NULL,
	@Demographics xml NULL,
	@EmailAddress varchar(128) NULL
)
AS
select BusinessEntityID, PersonType,FirstName, MiddleName, LastName, CAST (Demographics AS VARCHAR (MAX)) AS Demographics, EmailAddress
from person.person
WHERE
 [BusinessEntityID] = 
CASE WHEN @BusinessEntityID IS NULL THEN [BusinessEntityID]
	  ELSE @BusinessEntityID 
END
AND [LastName] LIKE 
CASE WHEN @lastname IS NULL THEN [LastName]
	ELSE @lastname 
END
AND [FirstName] LIKE 
CASE WHEN @firstname IS NULL THEN [FirstName]
	 ELSE @firstname 
END
AND [MiddleName] = 
CASE WHEN @MiddleName IS NULL THEN [MiddleName]
	 ELSE @MiddleName
 END
AND [EmailAddress] LIKE
 CASE WHEN @EmailAddress IS NULL THEN [EmailAddress]
	ELSE @EmailAddress
 END
AND CAST (Demographics AS VARCHAR (MAX)) = 
CASE WHEN CAST (@Demographics AS VARCHAR (MAX)) IS NULL THEN  CAST (Demographics AS VARCHAR (MAX))
 ELSE CAST (Demographics AS VARCHAR (MAX))
 END
AND [PersonType] =
 CASE WHEN @PersonType IS NULL THEN [PersonType]
  ELSE @PersonType
 END
GO

--C.3.- QUERY DINAMICO - Se procedi� a crear el Procedimientos Almacenados donde utilizaremos una estructura l�gica para realizar la b�squeda de ciertos campos con el fin de obtener la informaci�n del Personal
GO
CREATE PROC [person].uspObtenerInformacionPersona4
 (
	@BusinessEntityID  INT NULL,
	@PersonType nchar(2)  NULL,
	@FirstName name  NULL,
	@MiddleName name NULL,
	@LastName name  NULL,
	@Demographics xml NULL,
	@EmailAddress varchar(128) NULL

)
AS
IF (
	@BusinessEntityID IS NULL AND
	@PersonType IS NULL AND
	@FirstName IS NULL AND
	@MiddleName IS NULL AND
	@LastName IS NULL AND
	@EmailAddress IS NULL )

BEGIN
    RAISERROR ('You must supply at least one parameter.', 16, -1);
    RETURN;
END;
 
DECLARE @ExecStr NVARCHAR (4000),
        @Recompile  BIT = 1;
 
SELECT @ExecStr =
    N'SELECT BusinessEntityID, PersonType,FirstName, MiddleName, LastName, CAST (Demographics AS VARCHAR (MAX)) AS Demographics, EmailAddress FROM [Person].[Person] AS [P] WHERE 1=1';
 
IF @BusinessEntityID IS NOT NULL
    SELECT @ExecStr = @ExecStr
        + N' AND [P].[BusinessEntityID] = @BusinessEntityID';

 
IF @PersonType IS NOT NULL
    SELECT @ExecStr = @ExecStr
        + N' AND [P].[PersonType] LIKE @PersonT'; 
 
IF @FirstName IS NOT NULL
    SELECT @ExecStr = @ExecStr
        + N' AND [P].[Firstname] LIKE @FirstN';
 
IF @MiddleName IS NOT NULL
    SELECT @ExecStr = @ExecStr
        + N' AND [P].[MiddleName]  LIKE @MiddleN';
 
IF @LastName IS NOT NULL
    SELECT @ExecStr = @ExecStr
        + N' AND [P].[LastName] LIKE @LastN';
 
IF @EmailAddress IS NOT NULL
    SELECT @ExecStr = @ExecStr
        + N' AND [P].[EmailAddress] LIKE @EmailA';
 
IF (@BusinessEntityID IS NOT NULL)
    SET @Recompile = 0

	IF (PATINDEX('%[%_?]%', @PersonType)= 4 OR PATINDEX('%[%_?]%', @PersonType) = 0)
	SET @Recompile = 0
 
	IF (PATINDEX('%[%_?]%', @LastName)= 4 OR PATINDEX('%[%_?]%', @LastName) = 0)
    AND (PATINDEX('%[%_?]%', @FirstName) = 4  OR PATINDEX('%[%_?]%', @FirstName) = 0)
	AND (PATINDEX('%[%_?]%', @MiddleName) = 4  OR PATINDEX('%[%_?]%', @MiddleName) = 0)
    SET @Recompile = 0
 
	--IF (PATINDEX('%[%_?]%', @Demographics)= 4 OR PATINDEX('%[%_?]%', @Demographics) = 0)
	--SET @Recompile = 0
 
	IF (PATINDEX('%[%_?]%', @EmailAddress)= 4 OR PATINDEX('%[%_?]%', @EmailAddress) = 0)
    SET @Recompile = 0
 
IF @Recompile = 1
BEGIN
    --SELECT @ExecStr, @Lastname, @Firstname, @CustomerID;
    SELECT @ExecStr = @ExecStr + N' OPTION(RECOMPILE)'; --RECOMPILE
--Indica a Motor de base de datos de SQL Server que genere un plan nuevo y temporal para la consulta y descarte de inmediato ese plan una vez que se completa la ejecuci�n de la consulta. El plan de consulta
END;
 
EXEC [sp_executesql] @ExecStr
    , N'@BusinessEn  int,
	 @PersonT  nchar(2), 
	 @FirstN  name,
	 @MiddleN  name, 
	 @LastN  name,
	 @EmailA  varchar(128)'
    , @BusinessEn = @BusinessEntityID
    , @PersonT = @PersonType
    , @FirstN = @FirstName
    , @MiddleN = @MiddleName
    , @LastN = @LastName
    , @EmailA = @EmailAddress;
	
GO

SET STATISTICS IO ON
DBCC FREEPROCCACHE 
	EXECUTE [PERSON].USPOBTENERINFORMACIONPERSONA NULL,'EM','GAIL','A','ERICKSON',	NULL,'RMUROC74@GMAIL.COM'
DBCC FREEPROCCACHE 
	EXECUTE [PERSON].USPOBTENERINFORMACIONPERSONA2 NULL,'EM','GAIL','A','ERICKSON',	NULL,'RMUROC74@GMAIL.COM'
DBCC FREEPROCCACHE 
	EXECUTE [PERSON].[USPOBTENERINFORMACIONPERSONA3] NULL,'EM','GAIL','A','ERICKSON',NULL,'RMUROC74@GMAIL.COM'
DBCC FREEPROCCACHE 
	EXECUTE [PERSON].USPOBTENERINFORMACIONPERSONA4 NULL,'EM','GAIL','A','ERICKSON', NULL, 'RMUROC74@GMAIL.COM'
SET STATISTICS IO OFF

SET STATISTICS IO ON
DBCC FREEPROCCACHE 
	EXECUTE [PERSON].[USPOBTENERINFORMACIONPERSONA] NULL,NULL,'GAIL','A','ERICKSON',NULL, NULL
DBCC FREEPROCCACHE 
	EXECUTE [PERSON].[USPOBTENERINFORMACIONPERSONA2] NULL,NULL,'GAIL','A','ERICKSON',NULL, NULL
DBCC FREEPROCCACHE 
	EXECUTE [PERSON].[USPOBTENERINFORMACIONPERSONA3] NULL,NULL,'GAIL','A','ERICKSON',NULL, NULL
DBCC FREEPROCCACHE 
	EXECUTE [PERSON].[USPOBTENERINFORMACIONPERSONA4] NULL,NULL,'GAIL','A','ERICKSON',NULL, NULL
SET STATISTICS IO OFF

SET STATISTICS IO ON
DBCC FREEPROCCACHE 
  EXECUTE [PERSON].[USPOBTENERINFORMACIONPERSONA] NULL,NULL,NULL,NULL,NULL,NULL,'RMUROC74@GMAIL.COM'
DBCC FREEPROCCACHE 
  EXECUTE [PERSON].USPOBTENERINFORMACIONPERSONA2 NULL,NULL,NULL,NULL,NULL,NULL,'RMUROC74@GMAIL.COM'
DBCC FREEPROCCACHE 
  EXECUTE [PERSON].[USPOBTENERINFORMACIONPERSONA3] NULL,NULL,NULL,NULL,NULL,NULL,'RMUROC74@GMAIL.COM'
DBCC FREEPROCCACHE 
  EXECUTE [PERSON].[USPOBTENERINFORMACIONPERSONA4] NULL,NULL,NULL,NULL,NULL,NULL,'RMUROC74@GMAIL.COM'
SET STATISTICS IO OFF

--Cleaned
DROP INDEX IDX_EMAILADDRESS ON PERSON.PERSON;
DROP INDEX IDX_PERSONTYPE ON PERSON.PERSON;
GO

DROP PROCEDURE [PERSON].[USPOBTENERINFORMACIONPERSONA]
DROP PROCEDURE [PERSON].[USPOBTENERINFORMACIONPERSONA2]
DROP PROCEDURE [PERSON].[USPOBTENERINFORMACIONPERSONA3]
DROP PROCEDURE [PERSON].[USPOBTENERINFORMACIONPERSONA4]
GO


--SET STATISTICS IO ON
--DBCC FREEPROCCACHE 
--execute [person].[uspObtenerInformacionPersona] NULL,'EM','Gail','A','Erickson',
--	'<IndividualSurvey xmlns="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey"><TotalPurchaseYTD>0</TotalPurchaseYTD></IndividualSurvey>',
--	'rmuroc74@gmail.com'
--DBCC FREEPROCCACHE 
--execute [person].[uspObtenerInformacionPersona2] NULL,'EM','Gail','A','Erickson',
--	'<IndividualSurvey xmlns="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey"><TotalPurchaseYTD>0</TotalPurchaseYTD></IndividualSurvey>',
--	'rmuroc74@gmail.com'
--DBCC FREEPROCCACHE 
--execute [person].[uspObtenerInformacionPersona3] NULL,'EM','Gail','A','Erickson',
--	'<IndividualSurvey xmlns="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey"><TotalPurchaseYTD>0</TotalPurchaseYTD></IndividualSurvey>',
--	'rmuroc74@gmail.com'
--DBCC FREEPROCCACHE 
--execute [person].[uspObtenerInformacionPersona4] NULL,'EM','Gail','A','Erickson',
--	'<IndividualSurvey xmlns="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/IndividualSurvey"><TotalPurchaseYTD>0</TotalPurchaseYTD></IndividualSurvey>',
--	'rmuroc74@gmail.com'
--SET STATISTICS IO OFF