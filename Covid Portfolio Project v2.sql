Select *
From PortfolioProject..CovidDeaths
WHERE continent is null
order by 3,4

select *
From PortfolioProject..CovidVaccinations
order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2 


-- Because of the query next is giving result of '0' all the time instead of percentage, chanced the data type of the columns.


ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_cases float;

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN total_deaths float;


-- Looking at Total Cases vs Total Deaths in Turkey and likelihood of dying if you contract Covid


SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) *100  as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'turkey'
ORDER BY 1,2 


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid


SELECT location, date, death.population, total_cases,  (total_cases/death.population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths as death
WHERE location like 'turkey'
ORDER BY 1,2 


-- Looking at countries with Highest Infection Rate compared to population


SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like 'turkey'
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc


-- Looking at countries with Highest Death Rate compared to population


SELECT location, population, MAX(total_deaths) as HighestDeathCount, MAX((total_deaths/population))*100 as PercentPopulationDeath
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY HighestDeathCount desc


--Let's break things down by continent
-- Showing the continents with the highest death count


SELECT location, population, MAX(total_deaths) as HighestDeathCount, MAX((total_deaths/population))*100 as PercentPopulationDeath
FROM PortfolioProject..CovidDeaths
WHERE continent is null and location not like 'High income' and location not like 'Upper middle income' and location not like 'Lower middle income' and location not like 'Low income'
GROUP BY location, population
ORDER BY population desc


-- Global Numbers


SELECT date, SUM(new_cases) as TotalNewCases, SUM(new_deaths) as TotalNewDeaths, 
	SUM(new_cases)/ (SELECT SUM(new_deaths) FROM PortfolioProject..CovidDeaths WHERE new_deaths is not null) *100 as Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--to check out result
SELECT date, location, SUM(new_cases)
FROM PortfolioProject..CovidDeaths
WHERE date like '2020-01-22' and continent is not null
GROUP BY date, location
ORDER BY 1,2


-- Looking at total population vs vaccinations


SELECT Deaths.continent, Deaths.location, Deaths.date, population, Vac.new_vaccinations, 
	SUM(CONVERT(bigint, Vac.new_vaccinations)) OVER (Partition by Deaths.location ORDER BY Deaths.location, Deaths.date ) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths as Deaths
JOIN PortfolioProject..CovidVaccinations as Vac
	ON Deaths.location = Vac.location and Deaths.date = Vac.date
WHERE Deaths.continent is not null
ORDER BY 2,3


-- Looking at Vaccination percentage by using temp table


DROP TABLE IF EXISTS #temp_vac
CREATE TABLE #temp_vac (
continent varchar(50),
location varchar(50),
date date,
population int,
new_vacs bigint,
rolling_vac bigint)

INSERT INTO #temp_vac
SELECT Deaths.continent, Deaths.location, Deaths.date, population, Vac.new_vaccinations, 
	SUM(CONVERT(bigint, Vac.new_vaccinations)) OVER (Partition by Deaths.location ORDER BY Deaths.location, Deaths.date ) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths as Deaths
JOIN PortfolioProject..CovidVaccinations as Vac
	ON Deaths.location = Vac.location and Deaths.date = Vac.date
WHERE Deaths.continent is not null
ORDER BY 2,3

SELECT location, date, population, new_vacs, rolling_vac, 
	(CAST(rolling_vac as float)/(cast(population as float)))*100 as PercentageVaccinated
FROM #temp_vac
ORDER BY location, date


-- Looking at Vaccination percentage by using CTE


WITH PopvsVac (Continent, Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
AS
(
SELECT Deaths.continent, Deaths.location, Deaths.date, population, Vac.new_vaccinations, 
	SUM(CONVERT(bigint, Vac.new_vaccinations)) OVER (Partition by Deaths.location ORDER BY Deaths.location, Deaths.date ) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths as Deaths
JOIN PortfolioProject..CovidVaccinations as Vac
	ON Deaths.location = Vac.location and Deaths.date = Vac.date
WHERE Deaths.continent is not null
)
SELECT *, RollingPeopleVaccinated/Population *100
FROM PopvsVac
ORDER BY Location,Date


-- Looking for maximum vacs per country


WITH PopvsVac (Location, Date, Population, NewVaccinations, RollingPeopleVaccinated)
AS
(
SELECT Deaths.location, Deaths.date, population, Vac.new_vaccinations, 
	SUM(CONVERT(bigint, Vac.new_vaccinations)) OVER (Partition by Deaths.location ORDER BY Deaths.location, Deaths.date ) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths as Deaths
JOIN PortfolioProject..CovidVaccinations as Vac
	ON Deaths.location = Vac.location and Deaths.date = Vac.date
WHERE Deaths.continent is not null
)
SELECT MAX(RollingPeopleVaccinated), Location
FROM PopvsVac
GROUP BY Location
ORDER BY 1 desc


-- Creating View to store data for later visializations


CREATE VIEW PercentPopulationVaccinated as
SELECT Deaths.continent, Deaths.location, Deaths.date, population, Vac.new_vaccinations, 
	SUM(CONVERT(bigint, Vac.new_vaccinations)) OVER (Partition by Deaths.location ORDER BY Deaths.location, Deaths.date ) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths as Deaths
JOIN PortfolioProject..CovidVaccinations as Vac
	ON Deaths.location = Vac.location and Deaths.date = Vac.date
WHERE Deaths.continent is not null
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated