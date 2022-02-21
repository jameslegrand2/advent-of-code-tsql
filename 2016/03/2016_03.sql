--Set to the repository location on the local machine
DECLARE @RepositoryLocation VARCHAR(MAX) = 'C:\Users\Jim LeGrand\Documents\T-SQL\advent-of-code-tsql\advent-of-code-tsql'

--Variable declarations
DECLARE @InputFile VARCHAR(MAX) = @RepositoryLocation + '\2016\03\Input.txt'
DECLARE @SQL VARCHAR(MAX)
DECLARE @ValidTriangles2 INT = 0

--Cleanup in case of previous errors
DROP TABLE IF EXISTS #Input
DROP TABLE IF EXISTS #three
DROP TABLE IF EXISTS #sides

--Load the file containing the input data
CREATE TABLE #Input(triangle varchar(max))
SET @SQL = 'BULK INSERT #Input FROM ''' + @InputFile + ''' WITH (FIELDTERMINATOR = '' '')'
EXEC(@SQL);

WITH sides AS (
    SELECT CAST(SUBSTRING(triangle,1,5) AS INT) AS Side1
        ,CAST(SUBSTRING(triangle,6,5) AS INT) AS Side2
        ,CAST(SUBSTRING(triangle,11,5) AS INT) AS Side3
    FROM #Input
)
SELECT 
    SUM(
        CASE 
            WHEN Side1 + Side2 > Side3 AND Side1 + Side3 > Side2  AND Side3 + Side2 > Side1 THEN 1 ELSE 0 
        END
    ) AS ValidTriangles1
FROM sides

CREATE TABLE #three(Id INT IDENTITY,side1 INT,side2 INT, side3 INT)
CREATE TABLE #sides(Id INT IDENTITY,side1 INT,side2 INT, side3 INT)

WHILE 1 = 1
BEGIN
    TRUNCATE TABLE #three
    TRUNCATE TABLE #sides
    
    INSERT INTO #three
        SELECT TOP 3 
            CAST(SUBSTRING(triangle,1,5) AS INT) AS Side1
            ,CAST(SUBSTRING(triangle,6,5) AS INT) AS Side2
            ,CAST(SUBSTRING(triangle,11,5) AS INT) AS Side3 
        FROM #Input;

    INSERT INTO #sides
        SELECT p1.* FROM (
            SELECT Id,side1 FROM #three
        ) t 
        PIVOT(
            MAX(side1) 
            FOR Id IN ([1],[2],[3])
        ) p1

        UNION

        SELECT p2.* FROM (
            SELECT Id,side2 FROM #three
        ) t 
        PIVOT(
            MAX(side2) 
            FOR Id IN ([1],[2],[3])
        ) p2

        UNION

        SELECT p3.* FROM (
            SELECT Id,side3 FROM #three
        ) t 
        PIVOT(
            MAX(side3) 
            FOR Id IN ([1],[2],[3])
        ) p3
    
   SET @ValidTriangles2 += (
        SELECT 
            SUM(
                CASE 
                    WHEN Side1 + Side2 > Side3 AND Side1 + Side3 > Side2  AND Side3 + Side2 > Side1 THEN 1 ELSE 0 
                END
            ) AS ValidTriangles2
        FROM #sides)

    DELETE TOP (3)
    FROM #Input

    IF (SELECT COUNT(triangle) FROM #Input) = 0 BREAK
END

SELECT @ValidTriangles2 AS ValidTriangles2

--Cleanup
DROP TABLE #Input
DROP TABLE #three
DROP TABLE #sides