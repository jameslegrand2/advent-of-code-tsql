--Set to the repository location on the local machine
DECLARE @RepositoryLocation VARCHAR(MAX) = 'C:\Users\Jim LeGrand\Documents\T-SQL\advent-of-code-tsql\advent-of-code-tsql'

--Variable declarations
DECLARE @InputFile VARCHAR(MAX) = @RepositoryLocation + '\2016\02\Input.txt'
DECLARE @SQL VARCHAR(MAX)
DECLARE @TotalLines INT
DECLARE @CurrentLineId INT = 1
DECLARE @TotalLineSteps INT
DECLARE @CurrentLineStepId INT

--Cleanup in case of previous errors
DROP TABLE IF EXISTS #Input
DROP TABLE IF EXISTS #Lines
DROP TABLE IF EXISTS #LineSteps
DROP TABLE IF EXISTS #MoveLookup2

--Load the file containing the input data
CREATE TABLE #Input(line varchar(max))
SET @SQL = 'BULK INSERT #Input FROM ''' + @InputFile + ''''
EXEC(@SQL)

--Create tracking table, populate initial state
CREATE TABLE #Lines(LineId INT IDENTITY, Line VARCHAR(MAX), StartingPosition1 INT, EndingPosition1 INT, StartingPosition2 VARCHAR(1), EndingPosition2 VARCHAR(1))
INSERT INTO #Lines(Line)
    SELECT Line
    FROM #Input
UPDATE #Lines
    SET StartingPosition1 = 5
        ,StartingPosition2 = '5'
    WHERE LineId = 1

--Create lookup tables for part 2 moves
CREATE Table #MoveLookup2(Step VARCHAR(1), StartingPosition VARCHAR(1), EndingPosition VARCHAR(1), CONSTRAINT PK_Move2Lookup PRIMARY KEY CLUSTERED (Step,StartingPosition))
INSERT INTO #MoveLookup2(Step,StartingPosition,EndingPosition) 
VALUES
	('U','3','1'),
    ('U','6','2'),
    ('U','7','3'),
    ('U','8','4'),
    ('U','A','6'),
    ('U','B','7'),
    ('U','C','8'),
    ('U','D','B'),
    ('D','1','3'),
    ('D','2','6'),
    ('D','3','7'),
    ('D','4','8'),
    ('D','6','A'),
    ('D','7','B'),
    ('D','8','C'),
    ('D','B','D'),
    ('L','3','2'),
    ('L','4','3'),
    ('L','6','5'),
    ('L','7','6'),
    ('L','8','7'),
    ('L','9','8'),
    ('L','B','A'),
    ('L','C','B'),
    ('R','2','3'),
    ('R','3','4'),
    ('R','5','6'),
    ('R','6','7'),
    ('R','7','8'),
    ('R','8','9'),
    ('R','A','B'),
    ('R','B','C');

--Loop through lines to process
SET @TotalLines = (SELECT COUNT(LineId) FROM #Lines)
WHILE @CurrentLineId <= @TotalLines
BEGIN
    --Table to track each step of the line
    CREATE TABLE #LineSteps(LineStepId INT IDENTITY, LineStep VARCHAR(1), StartingPosition1 INT, EndingPosition1 INT, StartingPosition2 VARCHAR(1), EndingPosition2 VARCHAR(1))
    
    --Loop through all the steps of the line to process
    SET @TotalLineSteps = (SELECT LEN(Line) FROM #Lines WHERE LineId = @CurrentLineId)
    SET @CurrentLineStepId = 1
    WHILE @CurrentLineStepId <= @TotalLineSteps
    BEGIN
        --Track this step
        INSERT INTO #LineSteps (LineStep)
            SELECT SUBSTRING((SELECT Line FROM #Lines WHERE LineId = @CurrentLineId),@CurrentLineStepId,1)

        --Populate starting position of this line
        IF @CurrentLineStepId = 1
        BEGIN
            --First step uses the starting position of the line
            UPDATE #LineSteps
                SET StartingPosition1 = (SELECT StartingPosition1 FROM #Lines WHERE LineId = @CurrentLineId)
                    ,StartingPosition2 = (SELECT StartingPosition2 FROM #Lines WHERE LineId = @CurrentLineId)
                WHERE LineStepId = @CurrentLineStepId
        END
        ELSE
        BEGIN
            --Other steps use the ending position of the previous step
            UPDATE #LineSteps
                SET StartingPosition1 = (SELECT EndingPosition1 FROM #LineSteps WHERE LineStepId = @CurrentLineStepId - 1)
                    ,StartingPosition2 = (SELECT EndingPosition2 FROM #LineSteps WHERE LineStepId = @CurrentLineStepId - 1)
                WHERE LineStepId = @CurrentLineStepId
        
        END

        --Populate the ending position of this step
        UPDATE #LineSteps
            SET EndingPosition1 = (
                    SELECT 
                        CASE
                            WHEN LineStep = 'U' AND StartingPosition1 IN (4,5,6,7,8,9) THEN StartingPosition1 - 3
                            WHEN LineStep = 'D' AND StartingPosition1 IN (1,2,3,4,5,6) THEN StartingPosition1 + 3
                            WHEN LineStep = 'L' AND StartingPosition1 IN (2,3,5,6,8,9) THEN StartingPosition1 - 1
                            WHEN LineStep = 'R' AND StartingPosition1 IN (1,2,4,5,7,8) THEN StartingPosition1 + 1
                            ELSE StartingPosition1
                        END
                    FROM #LineSteps
                    WHERE LineStepId = @CurrentLineStepId)
                ,EndingPosition2 = (
                    SELECT ml2.EndingPosition
                    FROM #LineSteps ls 
                        INNER JOIN #MoveLookup2 ml2
                            ON ml2.Step = ls.LineStep
                                AND ml2.StartingPosition = ls.StartingPosition2
                    WHERE LineStepId = @CurrentLineStepId)
            WHERE LineStepId = @CurrentLineStepId

        --Remain in same position if the lookup failed
        IF (SELECT EndingPosition2 FROM #LineSteps WHERE LineStepId = @CurrentLineStepId) IS NULL
        BEGIN
            UPDATE #LineSteps
            SET EndingPosition2 = StartingPosition2
            WHERE LineStepId = @CurrentLineStepId
        END

        SET @CurrentLineStepId += 1
    END

    --The line ends at the ending position of the last step
    UPDATE #Lines
        SET EndingPosition1 = (
                SELECT EndingPosition1
                FROM #LineSteps 
                WHERE LineStepId = @CurrentLineStepId - 1)
            ,EndingPosition2 = (
                SELECT EndingPosition2
                FROM #LineSteps 
                WHERE LineStepId = @CurrentLineStepId - 1)
        WHERE LineId = @CurrentLineId

    --Increment to the next line
    DROP TABLE #LineSteps
    SET @CurrentLineId += 1

    --This line starts where the previous line ended
    UPDATE #Lines
        SET StartingPosition1 = (
                SELECT EndingPosition1
                FROM #Lines
                WHERE LineId = @CurrentLineId - 1)
            ,StartingPosition2 = (
                SELECT EndingPosition2
                FROM #Lines
                WHERE LineId = @CurrentLineId - 1)
        WHERE LineId = @CurrentLineId
END

--Return results
SELECT EndingPosition1
    ,EndingPosition2 
FROM #Lines

--Cleanup
DROP TABLE #Lines
DROP TABLE #MoveLookup2