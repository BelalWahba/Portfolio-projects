--the purpose of these queries is to find some interesting values in the covid data we have and prepare some views for visualizations later on

-- exploring the data we have
USE CovidProject;

SELECT * 
FROM CovidDeaths

------------
SELECT * 
FROM CovidVac

--insights we are interested at
-- 1-total deaths global and per continent and per country "only top 10" // 2- total cases global and per continent and per country "only top 10"
-- 3-Percent death to Population global and per continent and per country "only top 10" // 4-percent total cases to Population global and per continent and per country "only top 10"
-- 5-percent death to total cases global and per continent and per country "only top 10" //6- percent total vaccination to population global and per continenet

-- For the global and continent data we will only extract the answer but we will not visualize it per day 
-- we will join the two tables 'coviddeaths' and 'covidvac' to get some insight on the data later on


-- the global numbers query 
-- data needed /total deaths/percent death per population/total cases/percent total cases to population/percent deaths to total cases/percent total vaccination to population
-- we will not use the ready data in the table as there is a WORLD field in the location column that has the data already needed and we will not use to total deaths or the total cases columns

SELECT location, SUM(new_cases) TotalCasesCountry, SUM(CAST(new_deaths AS INT)) TotalDeathsCountry , AVG(population) CountryPopulation
FROM CovidDeaths
Where continent is not NULL
GROUP BY location
order by 3 desc


--some intersting thing i found while testing the query below is that the column new_vaccinations or the total_vaccination column doesnt mean the total people vaccinated and if u run the query 
--commented u will see that the total_vaccinations exceeds china`s population 

--SELECT location , MAX(CAST(total_vaccinations AS FLOAT))
--FROM CovidVac
--Where continent is not NULL
--GROUP BY location
--order by 2 desc



SELECT location , MAX(CAST(people_vaccinated AS INT)) peoplevac
FROM CovidVac
Where continent is not NULL
GROUP BY location
order by 2 desc


-- now we have some options to combine the data above / the first is to to just joine them normally the easy and the optimized way / the sec is to join using a temp table and CTEs
-- but if we are using CTEs we will have to change the query every time we need to get different results and its not really optimum as u only have one query under the cte definition 
-- I will be using BOTH CTEs and TEMP table to showcase how it`s done then we will do it once again with the optimizd way of just joining the two tables


-- TEMP TABLE
DROP TABLE IF EXISTS #countrydeath
CREATE TABLE #countrydeath
(
continent nvarchar(50),
country nvarchar(50),
TotalCasesCountry numeric,
TotalDeathsCountry numeric,
CountryPopulation numeric)

INSERT INTO #countrydeath 
SELECT continent,location, SUM(new_cases) TotalCasesCountry, SUM(CAST(new_deaths AS INT)) TotalDeathsCountry , AVG(population) CountryPopulation
FROM CovidDeaths
Where continent is not NULL
GROUP BY location , continent

Select * from #countrydeath


-- joining the temp with the vaccination query

-- USING CTE with the temp table
-- this contains the global numbers per country , continent and the world 

WITH vac_cte (Location ,TotalVacCountry ) AS
	( 
	SELECT dbo.CovidVac.location , MAX(CAST(dbo.CovidVac.people_vaccinated AS INT)) peoplevac
	FROM dbo.CovidVac
	Where continent is not NULL
	GROUP BY location
	)
	select #countrydeath.continent,vac_cte.Location , #countrydeath.CountryPopulation ,vac_cte.TotalVacCountry,#countrydeath.TotalCasesCountry,#countrydeath.TotalDeathsCountry
	from vac_cte , #countrydeath
	where vac_cte.Location = #countrydeath.country
	ORDER BY CountryPopulation desc



	--- please notice that the above views and temp tables are not the optimized way of doing these queries and i just do them that way to show case them
	--- but if i`m going to approach this data normally i will join the two tables from the start and save them into a temp table as i will do now 


--- getting the global numbers the easy way 

DROP TABLE IF EXISTS #globalnumbers 
CREATE TABLE #globalnumbers
(
continent nvarchar(50),
country nvarchar(50),
Date date,
population numeric,
new_cases numeric,
new_deaths numeric,
vaccinated numeric
)

INSERT INTO #globalnumbers
SELECT CovidDeaths.continent, CovidDeaths.location , CovidDeaths.date , CovidDeaths.population, new_cases, new_deaths, CovidVac.people_vaccinated 
FROM CovidDeaths,CovidVac
where CovidDeaths.continent IS NOT NULL 
and CovidDeaths.date=CovidVac.date
and CovidDeaths.location = CovidVac.location



select * from #globalnumbers


--- Then i will just query this one temp table to get the same results without doing all these fancy CTEs and other temp tables

select continent,country , MAX(population) population, SUM(new_cases) totalcases,SUM(new_deaths)totaldeaths, MAX(vaccinated) vaccinated
from #globalnumbers
group by country,continent
order by population desc


-- and we will get the same result as the cte before in line 78
-- the time series data is already in the temp table as well so we will not need to create any additional views
-- Now that we have all the data we need arranged and ready for our use let`s answer the the questions we had at the beginning

----insights we are interested at
-- 1-total deaths global and per continent and per country "only top 10" // 2- total cases global and per continent and per country "only top 10"
-- 3-Percent death to Population global and per continent and per country "only top 10" // 4-percent total cases to Population global and per continent and per country "only top 10"
-- 5-percent death to total cases global and per continent and per country "only top 10" //6- percent total vaccination to population global and per continenet



--- WORLD GLOBAL NUMBERS USING SUBQUERIES

select SUM(globe.population) worldpop,SUM(globe.totalcases) worldcases,SUM(globe.totaldeaths) worlddeaths,SUM(globe.vaccinated) worldvac , 
SUM(globe.totalcases)/SUM(globe.population)*100 PercentCasesPopulation , SUM(globe.totaldeaths)/SUM(globe.population)*100 PercentDeathsPopulation,
SUM(globe.totaldeaths)/SUM(globe.totalcases)*100 PercentDeathsCases , SUM(globe.vaccinated)/SUM(globe.population)*100 PercentVacPopulation
from
(
select continent,country , MAX(population) population, SUM(new_cases) totalcases,SUM(new_deaths)totaldeaths, MAX(vaccinated) vaccinated
from #globalnumbers
group by country,continent) as globe


--- CONTINENT GLOBAL NUMBERS 

select continent,SUM(globe.population) continentpop,SUM(globe.totalcases) continentcases,SUM(globe.totaldeaths) continentdeaths,SUM(globe.vaccinated) continentvac , 
SUM(globe.totalcases)/SUM(globe.population)*100 PercentCasesPopulation , SUM(globe.totaldeaths)/SUM(globe.population)*100 PercentDeathsPopulation,
SUM(globe.totaldeaths)/SUM(globe.totalcases)*100 PercentDeathsCases , SUM(globe.vaccinated)/SUM(globe.population)*100 PercentVacPopulation
from
(
select continent,country , MAX(population) population, SUM(new_cases) totalcases,SUM(new_deaths)totaldeaths, MAX(vaccinated) vaccinated
from #globalnumbers
group by country,continent) as globe
group by continent



--- COUNTRY GLOBAL NUMBERS ordered by PercentDeathsCases

select country,SUM(globe.population) Countrypop,SUM(globe.totalcases) Countrycases,SUM(globe.totaldeaths) Countrydeaths,SUM(globe.vaccinated) Countryvac , 
SUM(globe.totalcases)/SUM(globe.population)*100 PercentCasesPopulation , SUM(globe.totaldeaths)/SUM(globe.population)*100 PercentDeathsPopulation,
SUM(globe.totaldeaths)/SUM(globe.totalcases)*100 PercentDeathsCases , SUM(globe.vaccinated)/SUM(globe.population)*100 PercentVacPopulation
from
(
select continent,country , MAX(population) population, SUM(new_cases) totalcases,SUM(new_deaths)totaldeaths, MAX(vaccinated) vaccinated
from #globalnumbers
group by country,continent) as globe
group by country
order by PercentDeathsCases desc


-- Time series insights
-- all the insights are per every day
---1-total deaths per country each day commulative // 2- total cases per country each day commulative
-- 3-Percent death to Population per country commulative  // 4-percent total cases to Population global and per country commulative
-- 5-percent death to total cases per country commulative 


select country ,Date , population , SUM(new_cases) over (PARTITION BY country ORDER BY Date asc) as cases_cumulative ,
SUM(new_deaths) over (PARTITION BY country ORDER BY Date asc) as deaths_cumulative
from #globalnumbers


-- to get the percentage insights we will need to use either CTEs or subqueries to further query the data 

select country, Date , population ,cases_cumulative,deaths_cumulative, countrycumulative.cases_cumulative/population*100 PercentCasesPop, countrycumulative.deaths_cumulative/population*100 as PercentDeathsPop
,countrycumulative.deaths_cumulative/countrycumulative.cases_cumulative*100 PercentDeathsCases
from (
select country ,Date , population , SUM(new_cases) over (PARTITION BY country ORDER BY Date asc) as cases_cumulative ,
SUM(new_deaths) over (PARTITION BY country ORDER BY Date asc) as deaths_cumulative
from #globalnumbers) as countrycumulative



--- IN the Tableau visualization we will use these queries for data we will use
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

--- WORLD GLOBAL NUMBERS USING SUBQUERIES

select SUM(globe.population) worldpop,SUM(globe.totalcases) worldcases,SUM(globe.totaldeaths) worlddeaths,SUM(globe.vaccinated) worldvac , 
SUM(globe.totalcases)/SUM(globe.population)*100 PercentCasesPopulation , SUM(globe.totaldeaths)/SUM(globe.population)*100 PercentDeathsPopulation,
SUM(globe.totaldeaths)/SUM(globe.totalcases)*100 PercentDeathsCases , SUM(globe.vaccinated)/SUM(globe.population)*100 PercentVacPopulation
from
(
select continent,country , MAX(population) population, SUM(new_cases) totalcases,SUM(new_deaths)totaldeaths, MAX(vaccinated) vaccinated
from #globalnumbers
group by country,continent) as globe


--- CONTINENT GLOBAL NUMBERS 

select continent,SUM(globe.population) continentpop,SUM(globe.totalcases) continentcases,SUM(globe.totaldeaths) continentdeaths,SUM(globe.vaccinated) continentvac , 
SUM(globe.totalcases)/SUM(globe.population)*100 PercentCasesPopulation , SUM(globe.totaldeaths)/SUM(globe.population)*100 PercentDeathsPopulation,
SUM(globe.totaldeaths)/SUM(globe.totalcases)*100 PercentDeathsCases , SUM(globe.vaccinated)/SUM(globe.population)*100 PercentVacPopulation
from
(
select continent,country , MAX(population) population, SUM(new_cases) totalcases,SUM(new_deaths)totaldeaths, MAX(vaccinated) vaccinated
from #globalnumbers
group by country,continent) as globe
group by continent



--- COUNTRY GLOBAL NUMBERS ordered by PercentDeathsCases

select country,SUM(globe.population) Countrypop,SUM(globe.totalcases) Countrycases,SUM(globe.totaldeaths) Countrydeaths,SUM(globe.vaccinated) Countryvac , 
SUM(globe.totalcases)/SUM(globe.population)*100 PercentCasesPopulation , SUM(globe.totaldeaths)/SUM(globe.population)*100 PercentDeathsPopulation,
SUM(globe.totaldeaths)/SUM(globe.totalcases)*100 PercentDeathsCases , SUM(globe.vaccinated)/SUM(globe.population)*100 PercentVacPopulation
from
(
select continent,country , MAX(population) population, SUM(new_cases) totalcases,SUM(new_deaths)totaldeaths, MAX(vaccinated) vaccinated
from #globalnumbers
group by country,continent) as globe
group by country
order by PercentDeathsCases desc


---------
--- Timeseries

select country, Date , population ,cases_cumulative,deaths_cumulative, countrycumulative.cases_cumulative/population*100 PercentCasesPop, countrycumulative.deaths_cumulative/population*100 as PercentDeathsPop
,countrycumulative.deaths_cumulative/countrycumulative.cases_cumulative*100 PercentDeathsCases
from (
select country ,Date , population , SUM(new_cases) over (PARTITION BY country ORDER BY Date asc) as cases_cumulative ,
SUM(new_deaths) over (PARTITION BY country ORDER BY Date asc) as deaths_cumulative
from #globalnumbers) as countrycumulative
