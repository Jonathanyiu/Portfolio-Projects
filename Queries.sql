SET search_path TO CovidProject;

ALTER TABLE Coviddeaths
ALTER COLUMN population TYPE bigint;

ALTER TABLE coviddeaths
ALTER COLUMN hosp_patients_per_million TYPE numeric;

CREATE TABLE CovidVaccinations (
	iso_code varchar(15),
	continent varchar(50),
	locations varchar(50),
	dates DATE,
	new_tests INT,
	total_tests INT,
	total_tests_per_thousand numeric,
	new_tests_per_thousand numeric,
	new_tests_smoothed INT,
	new_tests_smoothed_per_thousand numeric,
	positive_rate numeric,
	tests_per_case numeric,
	tests_units varchar(50),
	total_vaccinations INT,
	people_vaccinated INT,
	people_fully_vaccinated INT,
	new_vaccinations INT,
	new_vaccinations_smoothed INT,
	total_vaccinations_per_hundred numeric,
	people_vaccinated_per_hundred numeric,
	people_fully_vaccinated_per_hundred numeric,
	new_vaccinations_smoothed_per_million numeric,
	stringency_index numeric,
	population_density numeric,
	median_age numeric,
	aged_65_older numeric,
	aged_70_older numeric,
	gdp_per_capita numeric,
	extreme_poverty numeric,
	cardiovasc_death_rate numeric,
	diabetes_prevalence numeric,
	female_smokers numeric,
	male_smokers numeric,
	handwashing_facilities numeric,
	hospital_beds_per_thousand numeric,
	life_expectancy numeric,
	human_development_index numeric
);

SELECT *
FROM Coviddeaths;

SELECT Locations, dates, total_cases, new_cases, total_deaths, population
FROM Coviddeaths
ORDER BY locations, dates;

-- Total Cases vs Total Deaths
-- Likelihood of death if contracted in Canada
SELECT Locations, dates, total_cases, total_deaths, (100.0 * Total_deaths/total_cases) AS death_percent
FROM Coviddeaths
WHERE locations = 'Canada'
ORDER BY locations, dates;

-- Total Cases vs Population
-- Percentage of population that got Covid
SELECT Locations, dates, population, total_cases, (100.0 * total_cases/population) AS Population_PercentageInfected
FROM Coviddeaths
WHERE locations = 'Canada'
ORDER BY locations, dates;

-- Countries with highest infection rate compared to poplation
SELECT Locations, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases::numeric/population)*100.0) AS Population_PercentageInfected
FROM Coviddeaths
GROUP BY Locations, population
ORDER BY Population_PercentageInfected DESC;

-- Countries with highest Death Count per population
SELECT Locations, MAX(total_deaths) AS Total_Death_Count
FROM Coviddeaths
WHERE continent IS NOT null	
GROUP BY Locations
ORDER BY Total_Death_Count DESC; 

-- Continents with highest Death Count per population
SELECT continent, MAX(total_deaths) AS Total_Death_Count
FROM Coviddeaths
WHERE continent IS NOT null	
GROUP BY continent
ORDER BY Total_Death_Count DESC; 


SELECT
    dates,
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    SUM(100.0*new_deaths) / NULLIF(SUM(new_cases), 0) AS DeathPercentage
FROM
    (
        SELECT
            dates,
            new_cases,
            new_deaths
        FROM
            Coviddeaths
        WHERE
            continent IS NOT NULL
    ) AS subquery
GROUP BY
    dates
ORDER BY
    dates DESC;
	
SELECT
    dates,
	SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM
    CovidDeaths
WHERE
    continent IS NOT NULL
GROUP BY dates
ORDER BY dates DESC;

-- looking at Total Population vs Vaccinations in Canada
SELECT 
    dea.continent, 
    dea.locations, 
    dea.dates, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.locations ORDER BY dea.dates) AS cumulative_vaccinations
FROM 
    coviddeaths dea
JOIN 
    covidvaccinations vac ON dea.locations = vac.locations AND dea.dates = vac.dates
WHERE 
    dea.continent IS NOT NULL AND dea.locations = 'Canada'
ORDER BY 
    dea.continent, 
    dea.locations,
    dea.dates;

-- IF USING CTE
WITH PopvsVac (Continent, locations, dates, population, new_vaccinations, cumulative_vaccinations)
AS (
SELECT 
    dea.continent, 
    dea.locations, 
    dea.dates, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.locations ORDER BY dea.dates) AS cumulative_vaccinations
FROM 
    coviddeaths dea
JOIN 
    covidvaccinations vac ON dea.locations = vac.locations AND dea.dates = vac.dates
WHERE 
    dea.continent IS NOT NULL AND dea.locations = 'Canada'
)
SELECT *, (100.0*cumulative_vaccinations/Population) AS Percentage_Population_Vaccinated
FROM PopvsVac

-- IF using Temp Table
DROP TABLE IF EXISTS Percent_Population_Vaccinated
CREATE TABLE Percent_Population_Vaccinated
(
continent VARCHAR(255),
locations VARCHAR(255),
dates DATE,
population NUMERIC,
new_vaccinations NUMERIC,
cumulative_vaccinations NUMERIC
);

INSERT INTO Percent_Population_Vaccinated
SELECT 
    dea.continent, 
    dea.locations, 
    dea.dates, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.locations ORDER BY dea.dates) AS cumulative_vaccinations
FROM 
    coviddeaths dea
JOIN 
    covidvaccinations vac ON dea.locations = vac.locations AND dea.dates = vac.dates
WHERE 
    dea.continent IS NOT NULL AND dea.locations = 'Canada'
	
SELECT *, (100.0*cumulative_vaccinations/Population) AS Percentage_Population_Vaccinated
FROM Percent_Population_Vaccinated

-- Create View to store data for future visualizations
CREATE VIEW Percent_Population_Vaccinated AS
SELECT 
    dea.continent, 
    dea.locations, 
    dea.dates, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.locations ORDER BY dea.dates) AS cumulative_vaccinations
FROM 
    coviddeaths dea
JOIN 
    covidvaccinations vac ON dea.locations = vac.locations AND dea.dates = vac.dates
WHERE 
    dea.continent IS NOT NULL AND dea.locations = 'Canada'
	
	