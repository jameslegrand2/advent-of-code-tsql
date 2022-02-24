--Set to the repository location on the local machine
DECLARE @RepositoryLocation VARCHAR(MAX) = 'C:\Users\Jim LeGrand\Documents\T-SQL\advent-of-code-tsql\advent-of-code-tsql'

--Speed up execution
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

--Variable declarations
DECLARE @InputFile VARCHAR(MAX) = @RepositoryLocation + '\2016\08\Input.txt'
DECLARE @SQL VARCHAR(MAX)
DECLARE @CurrentCommandId INT = 1
DECLARE @TotalCommands INT

--Cleanup in case of previous errors
DROP TABLE IF EXISTS #Input
DROP TABLE IF EXISTS #Commands
DROP TABLE IF EXISTS #Screen
DROP TABLE IF EXISTS #CommandWords

--Load the file containing the input data
CREATE TABLE #Input(command varchar(max))
SET @SQL = 'BULK INSERT #Input FROM ''' + @InputFile + ''''
EXEC(@SQL);

--Create table for tracking commands
CREATE TABLE #Commands (
    CommandId INT IDENTITY
    ,Command VARCHAR(MAX)
)
INSERT INTO #Commands
    SELECT command
    FROM #Input

--Create table for tracking screen
CREATE TABLE #Screen (
    x INT
    ,y INT
    ,state BIT
);
WITH
    n1(n) AS (SELECT 1 UNION ALL SELECT 1),    -- returns 1 row
    n2(n) AS (SELECT 1 FROM n1 AS x, n1 AS y), -- 4 rows
    n3(n) AS (SELECT 1 FROM n2 AS x, n2 AS y), -- 16
    n4(n) AS (SELECT 1 FROM n3 AS x, n3 AS y), -- 256
    nums(n) AS (SELECT ROW_NUMBER() OVER(ORDER BY n) FROM n4)
INSERT INTO #Screen
    SELECT a.n - 1
        ,b.n - 1
        ,0
    FROM nums a
        CROSS JOIN nums b
    WHERE a.n <= 50
        AND b.n <= 6;

--Loop through commands
SET @TotalCommands = (SELECT COUNT(CommandId) FROM #Commands)
WHILE @CurrentCommandId <= @TotalCommands
BEGIN
    --Create table for tracking the current command
    CREATE TABLE #CommandWords(
        CommandWordId INT IDENTITY
        ,CommandWord VARCHAR(MAX)
    )
    INSERT INTO #CommandWords
        SELECT [value]
        FROM string_split((SELECT Command FROM #Commands WHERE CommandId = @CurrentCommandId),' ')

    IF (SELECT CommandWord FROM #CommandWords WHERE CommandWordId = 1) = 'rect'
    BEGIN
        --Modify screen with rectangle
        WITH params AS (
            SELECT CAST(SUBSTRING(CommandWord,1,CHARINDEX('x',CommandWord) - 1) AS INT) x
                ,CAST(SUBSTRING(CommandWord,CHARINDEX('x',CommandWord) + 1,1) AS INT) y
            FROM #CommandWords 
            WHERE CommandWordId = 2
        )
        UPDATE #Screen
        SET [state] = 1
        WHERE x < (SELECT x FROM params)
            AND y < (SELECT y FROM params)
    END
    ELSE IF (SELECT CommandWord FROM #CommandWords WHERE CommandWordId = 1) = 'rotate'
    BEGIN
        IF (SELECT CommandWord FROM #CommandWords WHERE CommandWordId = 2) = 'row'
        BEGIN  
            --Modify screen to rotate row
            WITH y AS (
                SELECT CAST(SUBSTRING(CommandWord,CHARINDEX('=',CommandWord) + 1,1) AS INT) y
                FROM #CommandWords 
                WHERE CommandWordId = 3
            ), amount AS (
                SELECT CAST(CommandWord AS INT) amount
                FROM #CommandWords
                WHERE CommandWordId = 5
            ),CurrentStates AS (
                SELECT s.x
                    ,s.y
                    ,s.[state]
                FROM #Screen s
                    INNER JOIN y
                        ON s.y = y.y
            ),ReferenceRow AS (
                SELECT 
                    x currentx
                    ,y currenty
                    , CASE
                        WHEN x - (SELECT amount FROM amount) >= 0 THEN x - (SELECT amount FROM amount)
                        ELSE x - (SELECT amount FROM amount) + 50
                    END referencex
                FROM CurrentStates
            ), NewStates AS (
                SELECT
                    cs.x
                    ,cs.y
                    ,cs2.[state]
                FROM CurrentStates cs
                    INNER JOIN ReferenceRow rr
                        ON rr.currentx = cs.x
                            AND rr.currenty = cs.y
                    INNER JOIN CurrentStates cs2
                        ON cs2.x = rr.referencex
                            AND cs2.y = cs.y
            ) 
            UPDATE #Screen
                SET [state] = ns.[state]
                FROM #Screen s
                    INNER JOIN NewStates ns
                        ON ns.x = s.x
                            AND ns.y = s.y
        END
        ELSE IF (SELECT CommandWord FROM #CommandWords WHERE CommandWordId = 2) = 'column'
        BEGIN
            --Modify screen to rotate column
            WITH x AS (
                SELECT CAST(SUBSTRING(CommandWord,CHARINDEX('=',CommandWord) + 1,LEN(CommandWord) - CHARINDEX('=',CommandWord)) AS INT) x
                FROM #CommandWords 
                WHERE CommandWordId = 3
            ), amount AS (
                SELECT CAST(CommandWord AS INT) amount
                FROM #CommandWords
                WHERE CommandWordId = 5
            ),CurrentStates AS (
                SELECT s.x
                    ,s.y
                    ,s.[state]
                FROM #Screen s
                    INNER JOIN x
                        ON s.x = x.x
            ),ReferenceColumn AS (
                SELECT 
                    x currentx
                    ,y currenty
                    , CASE
                        WHEN y - (SELECT amount FROM amount) >= 0 THEN y - (SELECT amount FROM amount)
                        ELSE y - (SELECT amount FROM amount) + 6
                    END referencey
                FROM CurrentStates
            ), NewStates AS (
                SELECT
                    cs.x
                    ,cs.y
                    ,cs2.[state]
                FROM CurrentStates cs
                    INNER JOIN ReferenceColumn rc
                        ON rc.currenty = cs.y
                            AND rc.currentx = cs.x
                    INNER JOIN CurrentStates cs2
                        ON cs2.y = rc.referencey
                            AND cs2.x = cs.x
            ) 
            UPDATE #Screen
                SET [state] = ns.[state]
                FROM #Screen s
                    INNER JOIN NewStates ns
                        ON ns.x = s.x
                            AND ns.y = s.y
        END
    END

    SET @CurrentCommandId += 1
    DROP TABLE #CommandWords
END

--Return Results
SELECT SUM(
    CASE 
        WHEN [state] = 1 THEN 1
        ELSE 0
    END)
FROM #Screen

--Cleanup 
DROP TABLE #Input
DROP TABLE #Commands
DROP TABLE #Screen