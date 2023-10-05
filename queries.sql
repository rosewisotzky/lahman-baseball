-- 1. 
-- What range of years for baseball games played does the provided database cover?
SELECT MIN(year) AS first_year, MAX(year) AS last_year
FROM homegames;
-- 1871 to 2016

---------------------------------------------------------------------------------------------------------------------------
-- 2. 
-- Find the name and height of the shortest player in the database. 
SELECT namefirst, height
FROM people 
WHERE height = (SELECT MIN(height)
			   FROM people);

-- How many games did he play in? What is the name of the team for which he played?
SELECT namefirst, namelast, teamid, a.g_all
FROM people
	INNER JOIN appearances a
		USING(playerid)
WHERE namefirst = 'Eddie'
	AND  height = (SELECT MIN(height)
			   	   FROM people);
-- He played in 1 game for the team SLA

---------------------------------------------------------------------------------------------------------------------------
-- 3. 
-- Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. 
-- Sort this list in descending order by the total salary earned. 
-- Which Vanderbilt player earned the most money in the majors?
WITH vandy_players AS (SELECT DISTINCT(playerid), 
					   		  namefirst, 
					   		  namelast
					   FROM people p 
						   INNER JOIN collegeplaying c
						       USING(playerid)
						   INNER JOIN schools s
						   	   USING(schoolid)
					   WHERE schoolname = 'Vanderbilt University')
SELECT namefirst, namelast, SUM(salary) AS total_salary
FROM vandy_players
	INNER JOIN salaries
		USING(playerid)
GROUP BY namefirst, namelast
ORDER BY total_salary DESC NULLS LAST;

---------------------------------------------------------------------------------------------------------------------------
-- 4. 
-- Using the fielding table, group players into three groups based on their position: 
-- label players with position OF as "Outfield", those with position "SS", "1B", "2B", 
-- and "3B" as "Infield", and those with position "P" or "C" as "Battery". 
-- Determine the number of putouts made by each of these three groups in 2016.
SELECT SUM(po),
	   CASE WHEN pos = 'OF' THEN 'Outfield'
			WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
			WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
			END AS position
FROM fielding
WHERE yearid = 2016
GROUP BY position;

---------------------------------------------------------------------------------------------------------------------------
-- 5. 
-- Find the average number of strikeouts per game by decade since 1920. 
-- Round the numbers you report to 2 decimal places. Do the same for home runs per game. 
-- Do you see any trends?
SELECT ROUND(SUM(so::decimal)/SUM(g::decimal), 2) AS avg_so_per_game_batters,
	   ROUND(SUM(soa::decimal)/SUM(g::decimal), 2) AS avg_so_per_game_pitchers,
	   CASE WHEN yearid BETWEEN 1920 AND 1929 THEN '1920s'
			WHEN yearid BETWEEN 1930 AND 1939 THEN '1930s'
			WHEN yearid BETWEEN 1940 AND 1949 THEN '1940s'
			WHEN yearid BETWEEN 1950 AND 1959 THEN '1950s'
			WHEN yearid BETWEEN 1960 AND 1969 THEN '1960s'
			WHEN yearid BETWEEN 1970 AND 1979 THEN '1970s'
			WHEN yearid BETWEEN 1980 AND 1989 THEN '1980s'
			WHEN yearid BETWEEN 1990 AND 1999 THEN '1990s'
			WHEN yearid BETWEEN 2000 AND 2009 THEN '2000s'
			WHEN yearid BETWEEN 2010 AND 2019 THEN '2010s'
			ELSE 'before 1920' END AS decades
FROM teams p
GROUP BY decades
ORDER BY decades;

---------------------------------------------------------------------------------------------------------------------------
-- 6. 
-- Find the player who had the most success stealing bases in 2016, 
-- where success is measured as the percentage of stolen base attempts which are successful. 
-- (A stolen base attempt results either in a stolen base or being caught stealing.) 
-- Consider only players who attempted at least 20 stolen bases.
WITH stealing_bases_2016 AS (SELECT namefirst, 
								    namelast, 
								    SUM(sb::decimal) AS stolen, 
								    SUM(cs::decimal) AS caught_stolen, 
								    SUM(sb::decimal) + SUM(cs::decimal) AS attempted_to_steal
							 FROM batting b
								 INNER JOIN people p 
									 USING(playerid)
							 WHERE yearid = 2016
							 GROUP BY namefirst, namelast)

SELECT namefirst, 
	   namelast,
	   stolen,
	   attempted_to_steal,
	   ROUND(stolen/attempted_to_steal * 100, 2) AS percent_successful
FROM stealing_bases_2016
WHERE attempted_to_steal >= 20
ORDER BY percent_successful DESC;

---------------------------------------------------------------------------------------------------------------------------
-- 7a.
-- From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 

-- From the final table, select year, team, and max_wins
SELECT max_wins_by_year.yearid, teamid, max_wins

-- This is the table with the year, teamid, and total wins for each year/team combination (only for teams that did not win the world series that year)
FROM (WITH teams_year_name AS (SELECT yearid, 
									  teamid, 
									  SUM(w) total_wins, 
									  SUM(CASE WHEN wswin = 'Y' THEN 1
											   ELSE 0 END) AS wswins
							   FROM teams
							   GROUP BY teamid, yearid
							   ORDER BY yearid, teamid)

	  SELECT yearid, teamid, total_wins
	  FROM teams_year_name
	  WHERE wswins <> 1) year_team_wins

-- This is the team with the year and max total wins for that year (only for teams that did not win the world series that year)
INNER JOIN (WITH teams_year_name AS (SELECT yearid, 
										    teamid, 
										    SUM(w) total_wins, 
										    SUM(CASE WHEN wswin = 'Y' THEN 1
												     ELSE 0 END) AS wswins
								     FROM teams
								     GROUP BY teamid, yearid
								     ORDER BY yearid, teamid)

			SELECT yearid, MAX(total_wins) max_wins
			FROM teams_year_name
			WHERE wswins <> 1
			GROUP BY yearid) max_wins_by_year

-- We join the two tables on the year AND wins columns
ON year_team_wins.yearid = max_wins_by_year.yearid
	AND year_team_wins.total_wins = max_wins_by_year.max_wins

-- Now that we joined the two tables, we can filter for the years we need, and order by year
WHERE max_wins_by_year.yearid BETWEEN 1970 AND 2016
ORDER BY max_wins_by_year.yearid;

---------------------------------------------------------------------------------------------------------------------------
-- 7b. 
-- What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually 
-- small number of wins for a world series champion – determine why this is the case.
SELECT yearid, 
	   teamid, 
	   w AS total_wins
FROM teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1970 AND 2016
ORDER BY total_wins
LIMIT 1;
-- The smallest number of wins for a team that did win the world series is 63.
-- This happened in 1981 when there was a player strike


-- 7c.
-- Then redo your query, excluding the problem year.
SELECT yearid, 
	   teamid, 
	   w AS total_wins
FROM teams
WHERE wswin = 'Y'
	AND yearid BETWEEN 1970 AND 2016
	AND yearid <> 1981
ORDER BY total_wins
LIMIT 1;
---------------------------------------------------------------------------------------------------------------------------
-- 7d.
-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
WITH big_table AS (SELECT year_wins_team.yearid,
						   most_wins,
						   teamid, 
						   world_series_winner,
						   CASE WHEN teamid = world_series_winner THEN 1
								ELSE 0 END AS most_wins_and_won_worldseries

					-- This table contains the year and the most wins for each year
					FROM (SELECT yearid,
								 MAX(w) AS most_wins
						  FROM teams
						  WHERE yearid BETWEEN 1970 AND 2016
						  GROUP BY yearid) year_and_max_wins

					-- This table has the year, teamid and total wins per year, per team
					INNER JOIN (SELECT yearid,
									  teamid,
									  w AS total_wins
							   FROM teams
							   WHERE yearid BETWEEN 1970 AND 2016) year_wins_team

					-- We are joining on the year and the wins columns
					ON year_and_max_wins.yearid = year_wins_team.yearid
						AND year_and_max_wins.most_wins = year_wins_team.total_wins

					-- Join the world series winners
					LEFT JOIN (SELECT teamid AS world_series_winner, yearid
							  FROM teams
							  WHERE wswin = 'Y' 
								  AND yearid BETWEEN 1970 AND 2016) AS world_series_winners
						ON year_wins_team.yearid = world_series_winners.yearid)

-- Take the average of the most_wins_and_won_worldseries column
SELECT ROUND(AVG(most_wins_and_won_worldseries), 2) * 100 AS percent_of_most_wins_that_won_worldseries
FROM big_table;
-- from 1970 – 2016, a team with the most wins also won the world series 23% of the time.

---------------------------------------------------------------------------------------------------------------------------
-- 8. 
-- Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 
-- (where average attendance is defined as total attendance divided by number of games). 
-- Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. 

SELECT team, park, attendance/games AS average_attendance
FROM homegames
WHERE year = 2016 AND games >= 10
ORDER BY average_attendance DESC
LIMIT 5;

-- Repeat for the lowest 5 average attendance.
SELECT team, park, attendance/games AS average_attendance
FROM homegames
WHERE year = 2016 AND games >= 10
ORDER BY average_attendance
LIMIT 5;

---------------------------------------------------------------------------------------------------------------------------
-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
-- Give their full name and the teams that they were managing when they won the award.

WITH manager AS (SELECT *
			  -- 20 Managers who have won the TSN manager of the year award in NL
			  FROM (SELECT DISTINCT(playerid)
				   FROM awardsmanagers
				   WHERE awardid = 'TSN Manager of the Year'
					   AND (lgid = 'NL')) AS NL_awards

			  -- 23 Managers who have won the TSN manager of the year award in AL
			  INNER JOIN (SELECT DISTINCT(playerid)
					     FROM awardsmanagers
					     WHERE awardid = 'TSN Manager of the Year'
						     AND (lgid = 'AL')) AS AL_awards
			  USING(playerid))

SELECT namefirst, namelast
FROM manager m
	LEFT JOIN people p
		USING(playerid)



