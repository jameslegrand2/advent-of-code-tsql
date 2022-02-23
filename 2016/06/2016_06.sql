--Set to the repository location on the local machine
DECLARE @RepositoryLocation VARCHAR(MAX) = 'C:\Users\Jim LeGrand\Documents\T-SQL\advent-of-code-tsql\advent-of-code-tsql'

--Speed up execution
SET NOCOUNT ON;
SET ANSI_WARNINGS OFF;

--Variable declarations
DECLARE @InputFile VARCHAR(MAX) = @RepositoryLocation + '\2016\06\Input.txt'
DECLARE @SQL VARCHAR(MAX)
DECLARE @LetterPosition INT = 1
DECLARE @CorrectedMessage VARCHAR(8) = ''
DECLARE @OriginalMessage VARCHAR(8) = ''

--Cleanup in case of previous errors
DROP TABLE IF EXISTS #Input

--Load the file containing the input data
CREATE TABLE #Input(message varchar(8))
SET @SQL = 'BULK INSERT #Input FROM ''' + @InputFile + ''''
EXEC(@SQL);

WHILE @LetterPosition <= 8
BEGIN
    WITH letters AS (
        SELECT SUBSTRING([message],@LetterPosition,1) letter
        FROM #Input
    )
    SELECT TOP 1 
        @CorrectedMessage += letter
    FROM letters
    GROUP BY letter
    ORDER BY COUNT(letter) DESC;

    WITH letters AS (
        SELECT SUBSTRING([message],@LetterPosition,1) letter
        FROM #Input
    )
    SELECT TOP 1 
        @OriginalMessage += letter
    FROM letters
    GROUP BY letter
    ORDER BY COUNT(letter)

    SET @LetterPosition += 1
END

SELECT @CorrectedMessage
SELECT @OriginalMessage