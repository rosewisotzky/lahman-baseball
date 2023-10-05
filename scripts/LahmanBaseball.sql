-- 1. range of years for baseball games played does the provided database cover? 1871-2016 

SELECT 
	MIN(yearID),
	MAX(yearID)
FROM appearances;

SELECT 
	MIN(yearID),
	MAX(yearID)
FROM batting;
-- 2.Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

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

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

SELECT 
	CONCAT(namefirst,' ',namelast) AS fullname,
	SUM(salary)::text::money AS total_salary
FROM people
	INNER JOIN collegeplaying USING(playerID)
	INNER JOIN schools USING (schoolID)
	INNER JOIN salaries USING(playerID)
WHERE schools.schoolname ILIKE '%vand%'
GROUP BY namefirst, namelast 
ORDER BY total_salary DESC;


