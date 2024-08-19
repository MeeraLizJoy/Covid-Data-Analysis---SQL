SELECT * 
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


--SELECT * FROM Covid..CovidVaccinations
--ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--SELECT total_deaths 
--FROM Covid..CovidDeaths
--WHERE total_deaths = NULL;

DELETE FROM Covid..CovidDeaths
WHERE total_cases IS NULL;

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country
SELECT location, 
       date, 
       total_cases, 
       total_deaths, 
       (CAST(total_deaths AS DECIMAL(20, 10)) / CAST(total_cases AS DECIMAL(20, 10))) * 100 AS DeathPercentage
FROM Covid..CovidDeaths
WHERE location like '%India%'
AND continent IS NOT NULL
ORDER BY 1, 2;


-- Looking at Total cases vs Population

SELECT location, date, total_cases, population, (total_cases/population)*100 AS PercentOfPopulationInfected
FROM Covid..CovidDeaths
--WHERE location like '%India%'
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- Looking at Countries with Highest infection rahe compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercentOfPopulationInfected
FROM Covid..CovidDeaths
--WHERE location like '%India%'
GROUP BY population, location
ORDER BY PercentOfPopulationInfected DESC;

-- Showing the countries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid..CovidDeaths
--WHERE location like '%India%'
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Breaking things up by continent

-- Showing continents with highest death count per population

SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid..CovidDeaths
--WHERE location like '%India%'
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM Covid..CovidDeaths
--WHERE location like '%India%'
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Global Numbers
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
       SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM Covid..CovidDeaths
--WHERE location like '%India%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2;

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
       SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM Covid..CovidDeaths
--WHERE location like '%India%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1, 2;


-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
, --(RollingPeopleVaccinated/Population)  * 100
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;


-- USING CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/Population)  * 100
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)
SELECT * , (RollingPeopleVaccinated/population)*100
FROM PopvsVac


-- TEMP TABLE

DROP TABLE IF EXISTS #PercentePopulationVaccinated
CREATE TABLE #PercentePopulationVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date date,
    population numeric,
    new_vaccinations numeric,
    RollingPeopleVaccinated numeric
)

INSERT INTO #PercentePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/Population)  * 100
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT * , (RollingPeopleVaccinated/population)*100
FROM #PercentePopulationVaccinated



-- Creating View to store data for later visualizations

DROP VIEW IF EXISTS PercentePopulationVaccinated;

CREATE VIEW PercentePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
--(RollingPeopleVaccinated/Population)  * 100
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT * FROM PercentePopulationVaccinated