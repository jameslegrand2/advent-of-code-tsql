--Set to the repository location on the local machine
DECLARE @RepositoryLocation VARCHAR(MAX) = 'C:\Users\Jim LeGrand\Documents\T-SQL\advent-of-code-tsql\advent-of-code-tsql'

--Speed up execution
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

--Variable declarations
DECLARE @InputFile VARCHAR(MAX) = @RepositoryLocation + '\2016\07\Input.txt'
DECLARE @SQL VARCHAR(MAX)
DECLARE @CurrentTextId INT = 1
DECLARE @TotalText INT
DECLARE @CurrentSubTextId INT
DECLARE @TotalSubText INT
DECLARE @Hyperset VARCHAR(MAX)
DECLARE @NotHyperset VARCHAR(MAX)

--Cleanup in case of previous errors
DROP TABLE IF EXISTS #Input
DROP TABLE IF EXISTS #Tracking
DROP TABLE IF EXISTS #Numbers
DROP TABLE IF EXISTS #SubText
DROP TABLE IF EXISTS #aba
DROP TABLE IF EXISTS #bab

--Load the file containing the input data
CREATE TABLE #Input(IPAddress varchar(max))
SET @SQL = 'BULK INSERT #Input FROM ''' + @InputFile + ''''
EXEC(@SQL);

--Create table to track results for each input line
CREATE TABLE #Tracking (TextId INT IDENTITY, OriginalText VARCHAR(MAX),BaseHasABBA BIT,HypersetHasABBA BIT,SupportsSSL BIT)
INSERT INTO #Tracking
    SELECT IPAddress
        ,0
        ,0
        ,0
    FROM #Input

--Create table to have a list of numbers for joining on
CREATE TABLE #Numbers (num INT);
WITH
    n1(n) AS (SELECT 1 UNION ALL SELECT 1),    -- returns 1 row
    n2(n) AS (SELECT 1 FROM n1 AS x, n1 AS y), -- 4 rows
    n3(n) AS (SELECT 1 FROM n2 AS x, n2 AS y), -- 16
    n4(n) AS (SELECT 1 FROM n3 AS x, n3 AS y), -- 256
    nums(n) AS (SELECT ROW_NUMBER() OVER(ORDER BY n) FROM n4)
INSERT INTO #numbers
SELECT n FROM nums;

--Loop through the lines
SET @TotalText = (SELECT COUNT(TextId) FROM #Tracking)
WHILE @CurrentTextId <= @TotalText
BEGIN
    --Create table to track sections of the line
    CREATE TABLE #SubText (SubtextId INT IDENTITY,SubText VARCHAR(MAX),SubtextLength INT);

    --Create tables to track ABA and BAB
    CREATE TABLE #aba (a varchar(1),b varchar(1))
    CREATE TABLE #bab (a varchar(1),b varchar(1));

    --Check the first non-hyperset section for ABBA
    WITH SearchText1 AS (
        SELECT [value] SearchText1
            , LEN([value]) Text1Length
        FROM string_split((SELECT OriginalText FROM #Tracking WHERE TextId = @CurrentTextId),'[')
        WHERE [value] NOT LIKE '%]%'
    ), Search1 AS (
        SELECT 
            MAX(CASE 
                WHEN
                    SUBSTRING(SearchText1,num,4) = REVERSE(SUBSTRING(SearchText1,num,4))
                    AND SUBSTRING(SearchText1,num,1) != SUBSTRING(SearchText1,num+1,1)
                    THEN 1
                ELSE 0
            END) Result
        FROM SearchText1 t
            CROSS JOIN #Numbers n
        WHERE num <= Text1Length - 3
    )
    UPDATE #Tracking
    SET BaseHasABBA = (SELECT Result FROM Search1)
    WHERE TextId = @CurrentTextId;

    --Check the first non-hyperset section for ABA
    WITH SearchText1 AS (
        SELECT [value] SearchText1
            , LEN([value]) Text1Length
        FROM string_split((SELECT OriginalText FROM #Tracking WHERE TextId = @CurrentTextId),'[')
        WHERE [value] NOT LIKE '%]%'
    )
    INSERT INTO #ABA
    SELECT SUBSTRING(SearchText1,num,1)
        , SUBSTRING(SearchText1,num+1,1)
    FROM SearchText1 t
        CROSS JOIN #Numbers n
    WHERE num <= Text1Length - 2
        AND SUBSTRING(SearchText1,num,3) = REVERSE(SUBSTRING(SearchText1,num,3))
        AND SUBSTRING(SearchText1,num,1) != SUBSTRING(SearchText1,num+1,1)

    --Further split up the sections of the line
    INSERT INTO #SubText
        SELECT [value]
        , LEN([value])
        FROM string_split((SELECT OriginalText FROM #Tracking WHERE TextId = @CurrentTextId),'[')
        WHERE [value] LIKE '%]%'

    --Loop through the remaining pairs of hyperset and non-hyperset sections
    SET @CurrentSubTextId = 1
    SET @TotalSubText = (SELECT COUNT(SubtextId) FROM #SubText)
    WHILE @CurrentSubTextId <= @TotalSubText
    BEGIN
        --Get the hyperset section
        SELECT TOP 1 @Hyperset = [value]
        FROM string_split((SELECT Subtext FROM #SubText WHERE SubtextId = @CurrentSubtextId),']')

        --Get the non-hyperset section
        SELECT @NotHyperset = [value]
        FROM string_split((SELECT Subtext FROM #SubText WHERE SubtextId = @CurrentSubtextId),']')
        WHERE [value] <> @Hyperset;

        --Skip checking the hyperset section if an ABBA one has already been found
        IF (SELECT HypersetHasABBA FROM #Tracking WHERE TextId = @CurrentTextId) = 0
        BEGIN
            --Check the hyperset section for ABBA
            WITH SearchText2 AS (
                SELECT @Hyperset SearchText2
                    ,LEN(@Hyperset) Text2Length
            ), Search2 AS (
                SELECT 
                    MAX(CASE
                        WHEN SUBSTRING(SearchText2,num,4) = REVERSE(SUBSTRING(SearchText2,num,4))
                            AND SUBSTRING(SearchText2,num,1) != SUBSTRING(SearchText2,num+1,1)
                            THEN 1
                        ELSE 0 END
                    ) Result
                FROM SearchText2 t
                    CROSS JOIN #Numbers n
                WHERE num <= Text2Length - 3
            )
            UPDATE #Tracking
                SET HypersetHasABBA = (SELECT Result FROM Search2)
                WHERE TextId = @CurrentTextId
        END;

        --Check the hyperset section for ABA
        WITH SearchText2 AS (
            SELECT @Hyperset SearchText2
                ,LEN(@Hyperset) Text2Length
        )
        INSERT INTO #BAB
        SELECT SUBSTRING(SearchText2,num+1,1)
            , SUBSTRING(SearchText2,num,1)
        FROM SearchText2 t
            CROSS JOIN #Numbers n
        WHERE num <= Text2Length - 2
            AND SUBSTRING(SearchText2,num,3) = REVERSE(SUBSTRING(SearchText2,num,3))
            AND SUBSTRING(SearchText2,num,1) != SUBSTRING(SearchText2,num+1,1)

        --Skip checking the non-hyperset section if an ABBA one has already been found
        IF (SELECT BaseHasABBA FROM #Tracking WHERE TextId = @CurrentTextId) = 0
        BEGIN
            --Check the non-hyperset section for ABBA
            WITH SearchText1 AS (
                SELECT @NotHyperset SearchText1
                    ,LEN(@NotHyperset) Text1Length
            ), Search1 AS (
                SELECT 
                    MAX(CASE 
                        WHEN
                            SUBSTRING(SearchText1,num,4) = REVERSE(SUBSTRING(SearchText1,num,4))
                            AND SUBSTRING(SearchText1,num,1) != SUBSTRING(SearchText1,num+1,1)
                            THEN 1
                        ELSE 0
                    END) Result
                FROM SearchText1 t
                    CROSS JOIN #Numbers n
                WHERE num <= Text1Length - 3
            )
            UPDATE #Tracking
            SET BaseHasABBA = (SELECT Result FROM Search1)
            WHERE TextId = @CurrentTextId
        END;

        --Check the non-hyperset section for ABA
        WITH SearchText1 AS (
            SELECT @NotHyperset SearchText1
                ,LEN(@NotHyperset) Text1Length
        )
        INSERT INTO #ABA
        SELECT SUBSTRING(SearchText1,num,1)
            , SUBSTRING(SearchText1,num+1,1)
        FROM SearchText1 t
            CROSS JOIN #Numbers n
        WHERE num <= Text1Length - 2
            AND SUBSTRING(SearchText1,num,3) = REVERSE(SUBSTRING(SearchText1,num,3))
            AND SUBSTRING(SearchText1,num,1) != SUBSTRING(SearchText1,num+1,1)

        --Iterate to the next pair
        SET @CurrentSubTextId += 1
    END

    --Calculate if there are any aba/bab pairs
    UPDATE #Tracking
    SET SupportsSSL = 
        CASE
            WHEN (
                SELECT COUNT(a.a)
                FROM #aba a
                    CROSS JOIN #bab b
                WHERE a.a = b.a
                    AND a.b = b.b) > 0 THEN 1
            ELSE 0
        END
    WHERE TextId = @CurrentTextId

    --Cleanup section testing, iterate to the next line
    DROP TABLE #SubText
    DROP TABLE #aba
    DROP TABLE #bab
    SET @CurrentTextId += 1
END

--Return results
SELECT COUNT(TextId) 
FROM #Tracking
WHERE BaseHasABBA = 1
    AND HypersetHasABBA <> 1
    
SELECT COUNT(TextId) 
FROM #Tracking
WHERE SupportsSSL = 1

--Cleanup
DROP TABLE #Input
DROP TABLE #Tracking
DROP TABLE #Numbers