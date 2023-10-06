
--1,What range of years for baseball games played does the provided database cover? 
SELECT MIN(yearid)as min_year,MAX(yearid)_max_year
FROM teams; 
--1871-2016
_________________________________________________________________________________________________________________________________________
--2,Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
SELECT a.g_all as game_played,t.name,
	   MIN(p.height)as shortest,p.namefirst,p.namelast
FROM people as p
INNER JOIN appearances as a
 USING (playerid)
INNER JOIN teams as t
 USING (teamid)
GROUP BY t.name,p.namefirst,p.namelast,a.g_all
ORDER BY shortest
LIMIT 1;
-- EDDIE Gaedel shortest player, he played in 1 games for St.Louis Browns. 
____________________________________________________________________________________________________________________________________________________________________________
--3,Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names
--as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned.
--Which Vanderbilt player earned the most money in the majors?

WITH vandy_players AS (SELECT DISTINCT playerid, namefirst , namelast
					   FROM people as p
					   INNER JOIN collegeplaying as c
					    USING(playerid)
					   INNER JOIN schools as s
					    USING (schoolid)
					   WHERE schoolname='Vanderbilt University')
SELECT namefirst,namelast,sum(salary::numeric::money)as total_salary
FROM vandy_players
INNER join salaries
 USING(playerid)
GROUP BY namefirst,namelast
ORDER BY total_salary DESC;
--David Price earned the most 81,851,296. 
_________________________________________________________________________________________________________________________________________________________________________________
--4,Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", 
--those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery".
--Determine the number of putouts made by each of these three groups in 2016.

WITH grouped_players AS (SELECT SUM (PO) AS putouts, 
						CASE WHEN Pos = 'OF'THEN 'Outfield'
        	 				 WHEN Pos= 'SS' OR Pos='1B' OR Pos='2B' OR Pos='3B' THEN 'Infield'
	    					 WHEN Pos= 'P'OR Pos ='C' THEN 'Battery'
	  						 ELSE 'missing' END AS positions
							 FROM fielding
							 WHERE yearID=2016
	      					 GROUP BY Pos
						 	 ORDER BY putouts)
SELECT DISTINCT positions,SUM(putouts)as putouts
from grouped_players
GROUP BY positions;
-- Battery - 41424 putouts, Infield-58934 putouts ,Outfield-29560 putouts
______________________________________________________________________________________________________________________________________________________________________________________________________
--5,Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. 
--Do the same for home runs per game. Do you see any trends?
SELECT decade.decade,
	ROUND (sum(t.SO):: numeric/SUM(t.G/2), 2) AS avg_strikouts,
	ROUND (sum(t. HR):: numeric/sum(t.G/2), 2) AS avg_homeruns
FROM teams AS t
	INNER JOIN (SELECT yearid, CASE WHEN yearid BETWEEN 1920 AND 1929 THEN '1920s'
								   WHEN yearid BETWEEN 1930 AND 1939 THEN '1930s'
								   WHEN yearid BETWEEN 1940 AND 1949 THEN '1940s'
								   WHEN yearid BETWEEN 1950 AND 1959 THEN '1950s'
								   WHEN yearid BETWEEN 1960 AND 1969 THEN '1960s'
								   WHEN yearid BETWEEN 1970 AND 1979 THEN '1970s'
								   WHEN yearid BETWEEN 1980 AND 1989 THEN '1980s'
								   WHEN yearid BETWEEN 1990 AND 1999 THEN '1990s'
								   WHEN yearid BETWEEN 2000 AND 2009 THEN '2000s'
							       WHEN yearid BETWEEN 2010 AND 2019 THEN '2010s' END AS decade
				FROM teams) AS decade
	USING (yearid)
WHERE yearid >= 1920
GROUP BY decade
ORDER BY LEFT (decade, 4)::integer;
-- the avrage strikeouts and homeruns seem to increase over decades
_______________________________________________________________________________________________________________________________________________________________________________________________________________________
--6,Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. 
--(A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT sb,namefirst,namelast, ROUND(sb::numeric * 100/SUM (sb+cs),2)AS percentage
FROM batting as b
INNER JOIN people as p
 ON b.playerID = p.playerid
WHERE yearid=2016 AND sb+cs >=20
GROUP BY sb,namefirst,namelast
ORDER BY percentage DESC
LIMIT 1;
-- Chris Owings, 91.30
_______________________________________________________________________________________________________________________________________________________________________________________________________________________________-
--7, From 1970 – 2016, what is the largest number of wins for a team that did not win the world series?

SELECT yearid,w,WSwin,teamid,l
FROM teams
WHERE yearid BETWEEN 1970 and 2016 AND WSwin ='N'
order by W desc;
--116

--What is the smallest number of wins for a team that did win the world series? 
SELECT yearid,w,WSwin, name
FROM teams
WHERE yearid BETWEEN 1970 and 2016 AND WSwin ='Y' 
GROUP BY yearid,w,wswin, name
order by W;
--63 

--Then redo your query, excluding the problem year.  
SELECT yearid,w,WSwin, name
FROM teams
WHERE yearid BETWEEN 1970 and 2016 AND WSwin ='Y' AND yearid<>1981
GROUP BY yearid,w,wswin, name
order by W;
--83

--How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?

WITH count_of_w_ws AS (SELECT yearid, 
					    MAX(w) AS most_wins
						FROM teams
						WHERE yearid BETWEEN 1970 AND 2016
					    GROUP BY yearid)

SELECT ROUND(AVG(CASE WHEN wswin='Y'THEN 1 ELSE 0 END)*100,2) AS percentage ,
		count(case when wswin='Y'then 1 end)as count_ws_wins
      --100* COUNT (*):: numeric /(select count(distinct yearid)from count_of_w_ws)as percentage
FROM count_of_w_ws
INNER JOIN teams
  USING (yearid)
WHERE w = most_wins; --AND wswin = 'Y'
--12 times,22.64%
________________________________________________________________________________________________________________________________________________________________________________________________________________________
--8, Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016. Only consider parks where there were at least 10 games played.Report the park name, team name, and average attendance
SELECT t.name,p.park_name, SUM(hg.attendance)/hg.games as avg_attendance
FROM homegames as hg
INNER JOIN parks AS p
 USING (park)
INNER JOIN teams AS t
 USING (attendance)
WHERE year=2016 AND games >= '10'
Group by t.name,p.park_name,hg.games
ORDER BY avg_attendance DESC
LIMIT 5;
-- Top 5 average attendance

--Repeat for the lowest 5 average attendance.
SELECT t.name,p.park_name,Sum(hg.attendance)/hg.games as avg_attendance
FROM homegames as hg
INNER JOIN parks AS p
 USING (park)
INNER JOIN teams AS t
 USING (attendance)
WHERE year=2016 AND games >= '10'
GROUP BY t.name,p.park_name,hg.games
ORDER BY avg_attendance ASC
LIMIT 5;
-- lowest 5 average attendance 2016
___________________________________________________________________________________________________________________________________________________________________________________________________________
--9,Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? 
--Give their full name and the teams that they were managing when they won the award

WITH tsn_manager as ((SELECT DISTINCT playerid
						FROM awardsmanagers 
						WHERE awardid = 'TSN Manager of the Year' AND lgid ='NL'
						GROUP BY playerid
						ORDER BY playerid)
						 INTERSECT
						(SELECT DISTINCT playerid
						FROM awardsmanagers
						WHERE awardid = 'TSN Manager of the Year' AND lgid ='AL'
						GROUP BY playerid
						ORDER BY playerid))
SELECT namefirst,namelast,awardid,yearid,a.lgid,teamid
FROM tsn_manager
INNER JOIN people as p
	USING (playerid)
INNER JOIN managers
	USING (playerid)
INNER JOIN awardsmanagers AS a
	USING (playerid,yearid)
WHERE awardid='TSN Manager of the Year'
GROUP BY namefirst,namelast,yearid,a.lgid,teamid,awardid
ORDER BY yearid;
-- Davey Johnson 1997(BAL),2012(WAS)
-- JIM Leyland 1988,1990,1992(PIT),2006(DET)
_________________________________________________________________________________________________________________________________________________________________________________________________________
--10, Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years,
--and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

WITH hr_players AS (SELECT playerid, namefirst,namelast , finalgame, hr, yearid,debut,
						MAX(hr) OVER (PARTITION BY playerid) AS max_hr
					FROM batting 
					 INNER JOIN people 
					USING (playerid))

SELECT namefirst,namelast,hr,yearid
FROM hr_players
WHERE yearid = 2016 AND hr > 0 AND hr = max_hr AND (date(finalgame)-date(debut))/365 >=10 
ORDER BY playerid , yearid , hr DESC;
____________________________________________________________________________________________________________________________________________________________________________-

