 --1. What range of years for baseball games played does the provided database cover?
 SELECT MIN(year)
 FROM homegames;
   --1871
 SELECT MAX(year)
 FROM homegames;
    --2016
 
    --Range from 1871- 2016
 ----------------------------------------------------------------------------------
 --2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played
  
 SELECT namefirst, namelast,height,COUNT(g_all) AS gameall,teamid
 FROM people
     INNER JOIN appearances
 ON people.playerid = appearances.playerid
 WHERE height = (SELECT MIN(height) AS min_height
	             FROM people)
 GROUP BY teamid,namefirst,namelast,height;
 ---count game 1,SLA teamid
--------------------------------------------------------------------------------- 
 --3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?-
 

 ---I use CTE
 SELECT DISTINCT playerid,namefirst, namelast,schoolname
 FROM schools
	 LEFT JOIN collegeplaying
 USING(schoolid)
 	 LEFT JOIN people
 	 USING(playerid)
 WHERE schoolname = 'Vanderbilt University';
 
 WITH van_player AS( SELECT DISTINCT playerid,namefirst, namelast,schoolname
 					FROM schools
 					    INNER JOIN collegeplaying
 						USING(schoolid)
 					  	INNER JOIN people
						USING(playerid)
 					WHERE schoolname = 'Vanderbilt University')
 SELECT playerid,namefirst,namelast,SUM(salary)AS total_salary
 FROM salaries
 	INNER JOIN van_player
	USING(playerid)
 GROUP BY namefirst, namelast,playerid
 ORDER BY total_salary DESC; 
	
----david price  81851296
 -----------------------------------------------------------------------------------------
 --4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.-
 
 SELECT count(po) AS putout1,
           CASE WHEN pos ='OF'THEN 'Outfield'
		        WHEN pos ='SS'OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'INfield'
	            WHEN pos = 'P'OR pos = 'C' THEN 'Battery'ELSE 'Ignore' END AS spot
 FROM fielding
 WHERE yearid = '2016'	
 GROUP BY spot;
 
----------------------------------------------------------------------		 
--5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?         
 --For strikeouts,so and home runs, hr
 -- use CTE
WITH decades_all AS(SELECT yearid, 
				   CASE WHEN yearid between 1920 AND 1929 THEN '1920S'
             			WHEN yearid between 1930 AND 1939 THEN '1930S'
		            	WHEN yearid between 1940 AND 1949 THEN '1940S'
						WHEN yearid between 1950 AND 1959 THEN '1950S'
						WHEN yearid between 1960 AND 1969 THEN '1960S'
						WHEN yearid between 1970 AND 1979 THEN '1970S'
						WHEN yearid between 1980 AND 1989 THEN '1980S'
						WHEN yearid between 1990 AND 1999 THEN '1990S'
						WHEN yearid between 2000 AND 2009 THEN '2000S'
						WHEN yearid between 2010 AND 2019 THEN '2010S' END AS decades
				FROM pitching
				WHERE yearid >= '1920')
SELECT decades, 
      ROUND(avg(so/g),2) as avg_so, 
	  ROUND(avg(hr/g),2) as avg_hr
FROM pitching
INNER JOIN decades_all
USING(yearid)		
GROUP BY decades
ORDER BY decades;	 
			 
---Both averages have upward trends.
---Averdage Strikeouts,'so' seams increases faster than home runs,'hr'
			 
------------------------------------------------------------------------ 
--6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful.(A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases. 
 
WITH sb_success_attempt	AS
		 (SELECT playerid,(SUM(sb::numeric+cs::numeric)) AS sb_attempt,
			 			 ROUND((SUM(sb::numeric)/SUM(sb::numeric +cs::numeric))*100,2) AS percentage_sb_success
 			FROM batting
 			WHERE yearid = '2016' AND sb >= 20
 			GROUP BY playerid,sb,cs)
 SELECT namefirst,namelast,sb_attempt,percentage_sb_success
 FROM people
	 INNER JOIN sb_success_attempt
 	 USING (playerid)
 ORDER BY percentage_sb_success DESC;
  
 ---CHRIS OWING had the most success stealing bases in 2016.

 
 
 
 
 
 
 
 
 
 
 
 
 