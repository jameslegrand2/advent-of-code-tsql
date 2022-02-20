--Set to the repository location on the local machine
DECLARE @RepositoryLocation VARCHAR(MAX) = 'C:\Users\Jim LeGrand\Documents\T-SQL\advent-of-code-tsql\advent-of-code-tsql'

--Variable declarations
DECLARE @InputFile VARCHAR(MAX) = @RepositoryLocation + '\2016\01\Input.txt'
DECLARE @SQL VARCHAR(MAX)
DECLARE @x INT = 0
DECLARE @y INT = 0
DECLARE @Direction VARCHAR(1) = 'N'
DECLARE @Turn VARCHAR(1)
DECLARE @Distance INT
DECLARE @RemainingDistance INT
DECLARE @firstDoubled BIT
DECLARE @foundDouble BIT = 0

--Cleanup in case of previous errors
DROP TABLE IF EXISTS #Directions
DROP TABLE IF EXISTS #VisitedLocations

--Load the file containing the input data
CREATE TABLE #Directions(direction varchar(4))
SET @SQL = 'BULK INSERT #Directions FROM ''' + @InputFile + ''' WITH (ROWTERMINATOR = '', '')'
EXEC(@SQL)

--Table for part 2
CREATE TABLE #VisitedLocations(
	x int
	,y int
	,firstDoubled bit
	,CONSTRAINT PK_VisitedLocations PRIMARY KEY CLUSTERED (x,y)
);

--Use a cursor to iterate through the directions
DECLARE run_directions CURSOR FOR 
    SELECT SUBSTRING(direction,1,1) AS Turn
        ,CAST(SUBSTRING(direction,2,3) AS INT) AS Distance
    FROM #Directions

--Get the first direction
OPEN run_directions
FETCH NEXT FROM run_directions INTO @Turn,@Distance

--Loop through the directions
WHILE @@FETCH_STATUS = 0
BEGIN
    --Find the new direction after turning
    SET @Direction = CASE 
        WHEN @Direction = 'N' AND @Turn = 'L' THEN 'W'
        WHEN @Direction = 'N' AND @Turn = 'R' THEN 'E'
        WHEN @Direction = 'E' AND @Turn = 'L' THEN 'N'
        WHEN @Direction = 'E' AND @Turn = 'R' THEN 'S'
        WHEN @Direction = 'S' AND @Turn = 'L' THEN 'E'
        WHEN @Direction = 'S' AND @Turn = 'R' THEN 'W'
        WHEN @Direction = 'W' AND @Turn = 'L' THEN 'S'
        WHEN @Direction = 'W' AND @Turn = 'R' THEN 'N'
        END;
	
	--Travel
	SET @RemainingDistance = @Distance
	WHILE @RemainingDistance > 0
	BEGIN
		--Does part 2 still need to be solved
		IF @foundDouble = 0
		BEGIN
			--Travel 1 x
			SET @x = CASE
				WHEN @Direction = 'W' THEN @x - 1
				WHEN @Direction = 'E' THEN @x + 1
				ELSE @x
				END;

			--Travel 1 y
			SET @y = CASE
				WHEN @Direction = 'S' THEN @y - 1
				WHEN @Direction = 'N' THEN @y + 1
				ELSE @y
				END;

			SET @RemainingDistance -= 1

			--Check if this is a solution to part 2
			IF EXISTS (SELECT 1 FROM #VisitedLocations WHERE x = @x and y = @y)
			BEGIN
				--Record that this is the solution
				UPDATE #VisitedLocations
				SET firstDoubled = 1
				WHERE x = @x AND y = @y

				--Record that a solution has been found
				SET @foundDouble = 1
			END
			ELSE
			BEGIN
				--Otherwise add it as a visited location
				INSERT INTO #VisitedLocations VALUES (@x,@y,0)
			END
		END
		ELSE --Part 2 is solved, can take next direction in one step
		BEGIN
			--Travel x
			SET @x = CASE
				WHEN @Direction = 'W' THEN @x - @Distance
				WHEN @Direction = 'E' THEN @x + @Distance
				ELSE @x
				END;

			--Travel y
			SET @y = CASE
				WHEN @Direction = 'S' THEN @y - @Distance
				WHEN @Direction = 'N' THEN @y + @Distance
				ELSE @y
				END;

			SET @RemainingDistance = 0
		END
	END

    --Get the next direction
    FETCH NEXT FROM run_directions INTO @Turn,@Distance
END;

--Output results
SELECT ABS(@x) + ABS(@y)
SELECT ABS(x) + ABS(y)
FROM #VisitedLocations
WHERE firstDoubled = 1

--Cleanup
CLOSE run_directions
DEALLOCATE run_directions
DROP TABLE #Directions
DROP TABLE #VisitedLocations