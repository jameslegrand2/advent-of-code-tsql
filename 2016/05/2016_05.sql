--Set to the repository location on the local machine
DECLARE @RepositoryLocation VARCHAR(MAX) = 'C:\Users\Jim LeGrand\Documents\T-SQL\advent-of-code-tsql\advent-of-code-tsql'

--Speed up execution
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

--Variable declarations
DECLARE @InputFile VARCHAR(MAX) = @RepositoryLocation + '\2016\05\Input.txt'
DECLARE @SQL VARCHAR(MAX)
DECLARE @door VARCHAR(8)
DECLARE @Iteration INT = 1

--Cleanup in case of previous errors
DROP TABLE IF EXISTS #Input
DROP TABLE IF EXISTS #numbers
DROP TABLE IF EXISTS #PasswordLetters
DROP TABLE IF EXISTS #positionsToFind

--Load the file containing the input data
CREATE TABLE #Input(door varchar(8))
SET @SQL = 'BULK INSERT #Input FROM ''' + @InputFile + ''' WITH (FIELDTERMINATOR = ''['')'
EXEC(@SQL);
SET @door = (SELECT door FROM #Input)

CREATE TABLE #PasswordLetters (
    indexUsed INT
	,letter1 VARCHAR(1)
    ,letter2 VARCHAR(1)
)

CREATE TABLE #numbers(
	number INT
	, CONSTRAINT PK_numbers PRIMARY KEY CLUSTERED (number)
);

CREATE TABLE #positionsToFind(
	position VARCHAR(1)
)
INSERT INTO #positionsToFind(position)
VALUES
	('0'),
	('1'),
	('2'),
	('3'),
	('4'),
	('5'),
	('6'),
	('7');

WITH
    n1(n) AS (SELECT 1 UNION ALL SELECT 1),    -- returns 1 row
    n2(n) AS (SELECT 1 FROM n1 AS x, n1 AS y), -- 4 rows
    n3(n) AS (SELECT 1 FROM n2 AS x, n2 AS y), -- 16
    n4(n) AS (SELECT 1 FROM n3 AS x, n3 AS y), -- 256
    n5(n) AS (SELECT 1 FROM n4 AS x, n4 AS y), -- 65 536
    n6(n) AS (SELECT 1 FROM n5 AS x, n5 AS y), -- 4 294 967 296
    nums(n) AS (SELECT ROW_NUMBER() OVER(ORDER BY n) FROM n6)
INSERT INTO #numbers
SELECT TOP(1000000 /* set limit here */) n FROM nums

WHILE (SELECT COUNT(position) FROM #positionsToFind) > 0
BEGIN
	WITH hashes(indexUsed,hashstring) AS(
		SELECT number + (1000000 * (@Iteration-1))
		, CONVERT(VARCHAR(32),HASHBYTES('MD5',@door + CAST(number + (1000000 * (@Iteration-1)) AS VARCHAR(MAX))),2) 
		FROM #numbers
	), letters(indexUsed,letter1,letter2) AS(
		SELECT indexUsed
			,SUBSTRING(hashstring,6,1)
			,SUBSTRING(hashstring,7,1) 
		FROM hashes
		WHERE SUBSTRING(hashstring,1,5) = '00000'
	) 
	INSERT INTO #PasswordLetters(indexUsed,letter1,letter2)
	SELECT indexUsed,letter1,letter2 
	FROM letters

	DELETE FROM #positionsToFind
	WHERE position IN (SELECT DISTINCT letter1 FROM #PasswordLetters)

    SET @Iteration += 1
END;

--Output results
WITH password1letters AS (
	SELECT TOP 8 letter1
	FROM #PasswordLetters
	ORDER BY indexUsed
)
SELECT STRING_AGG(letter1,'')
FROM password1letters;

WITH password2ranking AS (
	SELECT indexUsed
		,RANK() OVER(PARTITION BY letter1 ORDER BY indexUsed) ranking
	FROM #PasswordLetters
	WHERE letter1 IN ('0','1','2','3','4','5','6','7')
), password2letters AS (
	SELECT TOP 8 letter2
	FROM #PasswordLetters pl
		INNER JOIN password2ranking p2r
			ON p2r.indexUsed = pl.indexUsed
	WHERE ranking = 1
	ORDER BY pl.letter1
) SELECT STRING_AGG(letter2,'')
FROM password2letters

--Cleanup
DROP TABLE #numbers
DROP TABLE #PasswordLetters
DROP TABLE #positionsToFind