--Set to the repository location on the local machine
DECLARE @RepositoryLocation VARCHAR(MAX) = 'C:\Users\Jim LeGrand\Documents\T-SQL\advent-of-code-tsql\advent-of-code-tsql'

--Speed up execution in VS Code
SET NOCOUNT ON;

--Variable declarations
DECLARE @InputFile VARCHAR(MAX) = @RepositoryLocation + '\2016\04\Input.txt'
DECLARE @SQL VARCHAR(MAX)
DECLARE @CurrentRoomId INT
DECLARE @TotalPotentialRooms INT
DECLARE @CurrentLetter INT
DECLARE @TotalLetters INT

--Cleanup in case of previous errors
DROP TABLE IF EXISTS #Input
DROP TABLE IF EXISTS #Rooms
DROP TABLE IF EXISTS #Letters
DROP TABLE IF EXISTS #checksumLetters
DROP TABLE IF EXISTS #decryptedLetters

--Load the file containing the input data
CREATE TABLE #Input(nameAndSector varchar(max),checksum varchar(6))
SET @SQL = 'BULK INSERT #Input FROM ''' + @InputFile + ''' WITH (FIELDTERMINATOR = ''['')'
EXEC(@SQL);

CREATE TABLE #Rooms(
    roomId INT IDENTITY
    , name varchar(max)
    , sector int
    , providedChecksum varchar(5)
    , calculatedChecksum varchar(5)
    , decryptedName varchar(max)
    ,CONSTRAINT PK_rooms PRIMARY KEY CLUSTERED (roomId))

INSERT INTO #Rooms(name,sector,providedChecksum)    
    SELECT SUBSTRING(nameAndSector,1,LEN(nameAndSector) - 3)
        ,CAST (SUBSTRING(nameAndSector,LEN(nameAndSector) - 2,3) AS INT)
        ,SUBSTRING(checksum,1,5)
    FROM #Input

--Caclulate checksums
SET @CurrentRoomId = 1
SET @TotalPotentialRooms = (SELECT COUNT(roomId) FROM #Rooms)
WHILE @CurrentRoomId <= @TotalPotentialRooms
BEGIN
    CREATE TABLE #Letters(letter varchar(1))
    SET @CurrentLetter = 1
    SET @TotalLetters = (SELECT LEN(name) FROM #Rooms WHERE roomId = @CurrentRoomId)

    WHILE @CurrentLetter <= @TotalLetters
    BEGIN
        INSERT INTO #Letters(letter)
            SELECT SUBSTRING(name,@CurrentLetter,1) 
            FROM #Rooms
            WHERE roomId = @CurrentRoomId

        SET @CurrentLetter += 1
    END

    CREATE TABLE #checksumLetters(letters VARCHAR(1))
    INSERT INTO #checksumLetters(letters)
        SELECT TOP 5 letter
        FROM #Letters 
        WHERE letter <> '-'
        GROUP BY letter 
        ORDER BY COUNT(letter) DESC
            , letter

    UPDATE #Rooms
        SET calculatedChecksum = (SELECT STRING_AGG(letters,'') FROM #checksumLetters)
        WHERE roomId = @CurrentRoomId

    IF (SELECT providedChecksum FROM #Rooms WHERE roomId = @CurrentRoomId) = (SELECT calculatedChecksum FROM #Rooms WHERE roomId = @CurrentRoomId)
    BEGIN
        CREATE TABLE #decryptedLetters(letters VARCHAR(1))
        INSERT INTO #decryptedLetters(letters)
            SELECT
                CASE
                    WHEN letter = '-' THEN ' '
                    WHEN (ASCII(letter) + (SELECT sector % 26 FROM #Rooms WHERE roomId = @CurrentRoomId)) <= 122 THEN CHAR(ASCII(letter) + (SELECT sector % 26 FROM #Rooms WHERE roomId = @CurrentRoomId))
                    ELSE CHAR(ASCII(letter) + (SELECT sector % 26 FROM #Rooms WHERE roomId = @CurrentRoomId) - 26)
                END
            FROM #Letters
        
        UPDATE #Rooms
            SET decryptedName = (SELECT RTRIM(STRING_AGG(letters,'')) FROM #decryptedLetters)
            WHERE roomId = @CurrentRoomId

        DROP TABLE #decryptedLetters
    END

    DROP TABLE #Letters
    DROP TABLE #checksumLetters
    SET @CurrentRoomId += 1
END

SELECT SUM(sector)
FROM #Rooms
WHERE providedChecksum = calculatedChecksum

SELECT sector
FROM #Rooms
WHERE decryptedName = 'northpole object storage'

--Cleanup
DROP TABLE #Input
DROP TABLE #Rooms