select * from coviddeaths;

-- Select data that need to be used

select location, date, total_cases, new_cases, total_deaths, population
from coviddeaths;

-- Total Deaths vs Total Cases

select location, date, total_cases, total_deaths, ((total_deaths/total_cases) * 100) as "Death Percentage"
from coviddeaths
where location like 'In%';

-- Total Cases vs Population

select location, date, total_cases, population, ((total_cases/population) * 100) as "Population Affection"
from coviddeaths
where location like 'In%';

-- Highest Infection Rate

select location, population, max(total_cases) as "Highest Infection Count", max((total_cases/population)) * 100 as "Highest Infection Rate"
from coviddeaths
group by location, population
order by max((total_cases/population)) * 100 desc;

-- Highest Death Count of Countries

select location, max(total_deaths) as "Highest Death Count"
from coviddeaths
where continent is not null
group by location
order by max(total_deaths) desc;

-- Death count by continents

select continent, max(total_deaths) as "Highest Death Count"
from coviddeaths
where continent is not null
group by continent
order by max(total_deaths) desc;

-- Showing continents with highest death count per population

select continent, max(total_deaths) as "Highest Death Count", max((total_deaths/population)) * 100
from coviddeaths
where continent is not null
group by continent
order by max(total_deaths) desc;

-- Global Numbers by Date

select date, sum(new_cases), sum(new_deaths), (sum(new_deaths)/sum(new_cases) * 100) as "Death Percentage"
from coviddeaths
where continent is not null
group by date;

-- Creating Joins

select * from coviddeaths 
join covid_vaccinations
on coviddeaths.location = covid_vaccinations.location
and coviddeaths.date = covid_vaccinations.date;

-- Looking at Total Population v Vaccinations
-- The rolling count adds new vaccination but then starts over from zero when a new country begins

select coviddeaths.continent, coviddeaths.date, coviddeaths.location, coviddeaths.population, covid_vaccinations.new_vaccinations,
sum(covid_vaccinations.new_vaccinations) over (partition by coviddeaths.location order by coviddeaths.location, coviddeaths.date) as "Rolling Count" 
from coviddeaths 
join covid_vaccinations
on coviddeaths.location = covid_vaccinations.location
and coviddeaths.date = covid_vaccinations.date;

-- CTE

with popvsvac
as 
(
select coviddeaths.continent, coviddeaths.date, coviddeaths.location, coviddeaths.population, covid_vaccinations.new_vaccinations,
sum(covid_vaccinations.new_vaccinations) over (partition by coviddeaths.location order by coviddeaths.location, coviddeaths.date) as RollingCount
from coviddeaths 
inner join covid_vaccinations
on coviddeaths.location = covid_vaccinations.location
and coviddeaths.date = covid_vaccinations.date
where coviddeaths.continent is not null
)
select *, (RollingCount/population) * 100
from popvsvac;


-- Temp Table
drop table if exists percentpopulationvaccinated;

-- Create the temporary table
CREATE TEMPORARY TABLE percentpopulationvaccinated (
    continent VARCHAR(255),
    date DATE,
    location VARCHAR(255),
    population NUMERIC,
    new_vaccinations decimal(20,2),
    RollingCount decimal(20,2)
);

-- Insert data into the temporary table
insert into percentpopulationvaccinated
select
    coviddeaths.continent,
    str_to_date(coviddeaths.date, '%d-%m-%Y'),
    coviddeaths.location,
    coviddeaths.population,
    nullif(covid_vaccinations.new_vaccinations, ''),
    (sum(nullif(covid_vaccinations.new_vaccinations, '')) over (partition by coviddeaths.location order by coviddeaths.location, str_to_date(coviddeaths.date, '%d-%m-%Y'))) as RollingCount
from coviddeaths
inner join covid_vaccinations 
on coviddeaths.location = covid_vaccinations.location
and coviddeaths.date = covid_vaccinations.date
where coviddeaths.continent is not null;

-- Select all rows from the temporary table
select *, (RollingCount/Population) * 100
from percentpopulationvaccinated;

-- Creating View to store data for later visualizations


drop view if exists percentpopulationvaccinated;
create view percentpopulationvaccinated 
as
select
    coviddeaths.continent,
    str_to_date(coviddeaths.date, '%d-%m-%Y'),
    coviddeaths.location,
    coviddeaths.population,
    nullif(covid_vaccinations.new_vaccinations, ''),
    (sum(nullif(covid_vaccinations.new_vaccinations, '')) over (partition by coviddeaths.location order by coviddeaths.location, str_to_date(coviddeaths.date, '%d-%m-%Y'))) as RollingCount
from coviddeaths
inner join covid_vaccinations 
on coviddeaths.location = covid_vaccinations.location
and coviddeaths.date = covid_vaccinations.date
where coviddeaths.continent is not null;

