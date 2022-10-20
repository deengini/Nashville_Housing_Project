/* This SQL file is part of a larger project which aims to analyze COVID deaths and vaccinations across the globe. 
Certain SQL queries have been designated for use in the creation a Tableau dashboard*/

select location, date, total_cases, new_cases, total_deaths, population
from coviddeaths
order by location, date


--looking at total cases vs total population
-- shows what percentage of population has covid
select location, date, total_cases, population, (total_cases/population)*100 as percentageinfection
from coviddeaths
where location like '%nigeria%'
order by location, date


--looking at countries with the highest infection rates compared to population 
select location, population, max(total_cases) as highestinfectioncount, max((total_cases/population))*100 as percentageinfection
from coviddeaths
where continent is not null
group by location, population
order by percentageinfection desc

-- looking at countries with the highest death counts per population 
select location, population, max(cast(total_deaths as bigint)) as highestdeathcount
from coviddeaths
where continent is not null
group by location
order by highestdeathcount desc

--look at continents with the highest death counts 
select continent, max(cast(total_deaths as bigint)) as highestdeathcount
from coviddeaths
where continent is not null
group by continent
order by highestdeathcount desc


-- global numbers 
--how many people who caught covid died from each daily infection by day 
select date, sum(new_cases) as totalcases, 
	   sum(cast(new_deaths as bigint)) as totaldeaths, 
	   sum(cast(new_deaths as bigint))/sum(new_cases) * 100 as deathpercentage
from coviddeaths
where continent is not null
group by date 
order by date, totalcases desc

--how many people who caught covid died from each daily infection globally 
select sum(new_cases) as totalcases, 
	   sum(cast(new_deaths as bigint)) as totaldeaths, 
	   sum(cast(new_deaths as bigint))/sum(new_cases) * 100 as deathpercentage
from coviddeaths
where continent is not null
order by totalcases, totaldeaths desc

-- total number of people that have been vaccinated in a country 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   sum(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location, dea.date) as rollingpeoplevaccinated
from coviddeaths dea
join covidvaccinations vac 
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by dea.location, dea.date


--using CTE to find percentage of rolling vacc per country 
with PopvsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated) 
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   sum(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from coviddeaths dea
join covidvaccinations vac 
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (rollingpeoplevaccinated/population) * 100 as percentagerollingvaccinated
from PopvsVac

--using a temp table to find percentage of rolling vacc per country 
drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255), 
date datetime,
population numeric, 
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)
insert into #percentpopulationvaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   sum(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from coviddeaths dea
join covidvaccinations vac 
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (rollingpeoplevaccinated/population) * 100 as percentagerollingvaccinated
from #percentpopulationvaccinated


--creating views for later visualizations 

--creating view for percentage vaccinations per country
create view percentagepopulationvaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   sum(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
from coviddeaths dea
join covidvaccinations vac 
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

--TO BE VISUALIZED IN TABLEAU

--1 --how many people who caught covid died from each daily infection globally 
select sum(new_cases) as total_cases, 
	   sum(cast(new_deaths as bigint)) as total_deaths, 
	   sum(cast(new_deaths as bigint))/sum(new_cases) * 100 as death_percentage
from coviddeaths
where continent is not null
order by total_cases, total_deaths desc

--2 -- looking at total death counts per continent
select location, sum(cast(new_deaths as bigint)) as totaldeathcount
from coviddeaths
where continent is null
and location not in ('World', 'European Union', 'International') 
and location not like ('%income%')
group by location
order by totaldeathcount desc

--3 --looking at countries with the highest infection rates compared to population 
select location, population, max(total_cases) as highestinfectioncount, max((total_cases/population))*100 as percentpopulationinfected
from coviddeaths
group by location, population
order by percentpopulationinfected desc

--4 --looking at countries with the highest infection rates compared to population 
select location, population, date, max(total_cases) as highestinfectioncount, max((total_cases/population))*100 as percentpopulationinfected
from coviddeaths
group by location, population, date
order by percentpopulationinfected desc
