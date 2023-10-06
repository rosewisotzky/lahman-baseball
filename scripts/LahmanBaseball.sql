-- 1. range of years for baseball games played does the provided database cover? 1871-2016 

SELECT 
	MIN(yearID),
	MAX(yearID)
FROM appearances;

SELECT 
	MIN(yearID),
	MAX(yearID)
FROM batting;

SELECT 
	MIN(yearID),
	MAX(yearID)
FROM appearances;

-- 2.Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played? --NOTE TO SELF FINISH THIS!!!!!--

SELECT namefirst,
	   namelast,
	   SUM(appearances.g_all) AS total_games_played,
	   teams.name  
FROM people
	LEFT JOIN appearances USING(playerID)
	INNER JOIN teams ON appearances.teamID = teams.teamID
WHERE height = (SELECT MIN(height)
				 FROM people)
GROUP BY namefirst, namelast, teams.name;

SELECT * 
FROM appearances
WHERE playerID = 'gaedeed01';

SELECT playerID
FROM people
WHERE namelast = 'Gaedel';

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT 
	CONCAT(namefirst,' ',namelast) AS full_name,
	SUM(salary)::text::money AS total_salary
FROM people
	INNER JOIN collegeplaying USING(playerID)
	INNER JOIN schools USING (schoolID)
	INNER JOIN salaries USING(playerID)
WHERE schools.schoolname ILIKE '%vand%'
GROUP BY namefirst, namelast 
ORDER BY total_salary DESC;

-- 4.Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT 
	CASE WHEN PoS = 'OF' THEN 'Outfield'
		 WHEN PoS IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		 WHEN PoS IN ('P', 'C') THEN 'Battery'
		 END AS player_position,
	SUM(PO) AS number_of_putouts
FROM fielding
WHERE yearID = '2016'
GROUP BY player_position;

-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? ROEY NOTE: use the teams table!

SELECT 
	CASE WHEN yearID::text LIKE '192%' THEN '1920s'
		 WHEN yearID::text LIKE '193%' THEN '1930s'
		 WHEN yearID::text LIKE '194%' THEN '1940s'
		 WHEN yearID::text LIKE '195%' THEN '1950s'
		 WHEN yearID::text LIKE '196%' THEN '1960s'
		 WHEN yearID::text LIKE '197%' THEN '1970s'
		 WHEN yearID::text LIKE '198%' THEN '1980s'
		 WHEN yearID::text LIKE '199%' THEN '1990s'
		 WHEN yearID::text LIKE '200%' THEN '2000s'
		 WHEN yearID::text LIKE '201%' THEN '2010s'
		 WHEN yearID::text LIKE '202%' THEN '2020s'
		 ELSE 'no data'
		 END AS decade,
	ROUND(SUM((SO + SOA))/SUM(G), 2) AS avg_strikeout_per_game
-- 	SUM(G) AS total_games
FROM teams
GROUP BY decade
ORDER BY decade;



--  6. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases. **ROEY NOTE** Looking at batting post table? jk, batting table!

SELECT playerID, 
	   SUM(SB) AS stolen_bases,
	   SUM(CS) AS caught_stealing,
	   CASE WHEN (SUM(SB::decimal) > 0.00 AND SUM(CS::decimal)> 0.00) THEN ROUND(SUM(SB::decimal)/(SUM(CS::decimal) + SUM(SB::decimal)), 2) * 100 END AS percent_stolen
FROM batting
WHERE yearID = 2016
GROUP BY playerID
HAVING (SUM(SB) + SUM(CS) >= 20)
ORDER BY percent_stolen DESC NULLS LAST;


-- 7. From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 

SELECT
	DISTINCT yearID,
	MAX(W) OVER(PARTITION BY yearID)AS max_wins
FROM teams
WHERE yearID BETWEEN 1970 AND 2016
	AND WSWin = 'N'
ORDER BY max_wins DESC
LIMIT 1;

-- What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. (rose note: this was the 1981 players strike most likely) 


SELECT
	DISTINCT yearID,
	MIN(W) OVER(PARTITION BY yearID)AS wins
FROM teams
WHERE yearID BETWEEN 1970 AND 2016
	AND WSWin = 'Y'
ORDER BY wins
LIMIT 1;	
		
-- Then redo your query, excluding the problem year. 		
		
SELECT
	DISTINCT yearID,
	MIN(W) OVER(PARTITION BY yearID)AS wins
FROM teams
WHERE yearID BETWEEN 1970 AND 2016
	AND WSWin = 'Y'
	AND yearID <> 1981
ORDER BY wins
LIMIT 1; 			
		

--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
--what I want to find is the following: for each year between 1970 and 2016, see if the team with the most wins won the world series.

WITH wins_by_series AS(SELECT
							DISTINCT yearID,
							CASE WHEN wswin = 'Y' THEN MAX(W)END AS max_wins_series,
							CASE WHEN wswin <> 'Y' THEN MAX(W) END AS max_wins_no_series
						FROM teams
						WHERE yearID BETWEEN 1970 AND 2016
						GROUP BY yearID, wswin)
SELECT 
	COUNT(max_wins_series) AS max_wins_series_count,
	COUNT(max_wins_no_series) AS max_wins_no_series_count
FROM wins_by_series
WHERE max_wins_series IS NOT NULL;

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. 

SELECT 
	parks.park_name,
	teams.name,
	SUM(homegames.attendance)/SUM(homegames.games) AS avg_attendance
FROM homegames
	INNER JOIN parks USING(park)
	INNER JOIN teams ON teams.teamid = homegames.team
WHERE year = 2016
GROUP BY parks.park_name, teams.name
HAVING SUM(games) >= 10
ORDER BY avg_attendance DESC
LIMIT 5;

--Repeat for the lowest 5 average attendance. -- note to self, you're seeing some repeats. maybe a grouping set could help here?

SELECT 
	DISTINCT parks.park_name,
	teams.name,
	SUM(homegames.attendance)/SUM(homegames.games) AS avg_attendance
FROM homegames
	INNER JOIN parks USING(park)
	INNER JOIN teams ON teams.teamid = homegames.team
WHERE year = 2016
GROUP BY parks.park_name, teams.name
HAVING SUM(games) >= 10
ORDER BY avg_attendance
LIMIT 5;

-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.


SELECT 
	CONCAT(namefirst, ' ', namelast) AS full_name,
	awardsmanagers.yearID,
	teams.name,
	teams.teamID
FROM awardsmanagers
	INNER JOIN people USING(playerID)
	INNER JOIN managers ON awardsmanagers.playerID = managers.playerID AND awardsmanagers.yearID = managers.yearID
	INNER JOIN teams ON managers.teamID = teams.teamID AND awardsmanagers.yearID = teams.yearID
WHERE awardsmanagers.playerID IN(SELECT
								awardsmanagers.playerID
							FROM awardsmanagers
							WHERE awardsmanagers.lgid = 'NL'
								AND awardsmanagers.awardid = 'TSN Manager of the Year'
							INTERSECT
							SELECT
							awardsmanagers.playerID					 
							FROM awardsmanagers
							WHERE awardsmanagers.lgid = 'AL'
								AND awardsmanagers.awardid = 'TSN Manager of the Year')
GROUP BY namefirst, namelast, awardsmanagers.yearid, NAME, teams.teamid
ORDER BY full_name, yearid;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.


/* notes for me!
Things I'm looking for: highest career number of home runs.. MAX()? but this gotta be from all years....

WHERE year = 2016
debut <= 2013
HR >= 1 (batting table) year = 2016
*/

SELECT 
	CONCAT(namefirst, ' ', namelast) AS full_name,
	MAX(HR) AS max_homeruns,
	batting.yearID
FROM people
	INNER JOIN batting USING(playerID)
WHERE debut <= '2013-10-6' 
GROUP BY namefirst, namelast, batting.yearid
ORDER BY max_homeruns DESC;
