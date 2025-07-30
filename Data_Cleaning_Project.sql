-- Data Cleaning Project


-- Creating the dataset 

create database if not exists world_layoffs;
use world_layoffs;
create table if not exists layoffs
(
company varchar(50),
location varchar(50),
industry varchar(50),
total_laid_off int,
percentage_laid_off varchar(10),
`date` date,
stage varchar(50),
country varchar(50),
funds_raised_millions int
);

LOAD DATA LOCAL INFILE '/Users/devanshupadhyay/PDs/Workspace/Data Analysis/MySQL/Projects/layoffs.csv'
INTO TABLE layoffs
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from layoffs;
---------------------------------------------------------------------------------------------------------------------------------------------------------


-- 1. Remove duplicates

create table if not exists layoffs_staging 
like layoffs;

select * from layoffs_staging;

insert into layoffs_staging
select * from layoffs;

select *, row_number() 
over(partition by company, industry, total_laid_off, percentage_laid_off, `date`) row_num
from layoffs_staging;

with duplicate_CTE as
(
select *, row_number() 
over
(
partition by 
	company, 
    location, 
    industry, 
    total_laid_off, 
    percentage_laid_off, 
	`date`, 
    stage, 
    country, 
    funds_raised_millions
) row_num
from layoffs_staging
)
select * 
from duplicate_CTE 
where row_num > 1;

select * 
from layoffs_staging
where company = "Casper";

with duplicate_CTE as
(
select *, row_number() 
over
(
partition by 
	company, 
    location, 
    industry, 
    total_laid_off, 
    percentage_laid_off, 
    `date`, 
    stage, 
    country, 
    funds_raised_millions
) row_num
from layoffs_staging
)
delete 
from duplicate_CTE 
where row_num > 1; # Will not work

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select *
from layoffs_staging2;

insert into layoffs_staging2
select *, row_number() 
over
(
partition by 
	company, 
    location, 
    industry, 
    total_laid_off, 
    percentage_laid_off, 
    `date`, 
    stage, 
    country, 
    funds_raised_millions
) row_num
from layoffs_staging;

delete
from layoffs_staging2
where row_num > 1;

select *
from layoffs_staging2;
---------------------------------------------------------------------------------------------------------------------------------------------------------


-- 2. Standardize the data

select company, trim(company)
from layoffs_staging2;

update layoffs_staging2
set company = trim(company);

select *
from layoffs_staging2
where industry like "Crypto%";

update layoffs_staging2 
set industry = "Crypto"
where industry like "Crypto%";

select distinct(industry)
from layoffs_staging2;

select distinct(country)
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = "United States"
where country = "United States.";

select `date`,
str_to_date(`date`, '%m/%d/%Y')
from layoffs_staging2;

update layoffs_staging2
set date = str_to_date(`date`, '%m/%d/%Y');

alter table layoffs_staging2
modify column `date` date;
---------------------------------------------------------------------------------------------------------------------------------------------------------


-- 3. Null Values or Blank Values

select * 
from layoffs_staging2
where industry = "";

update layoffs_staging2
set industry = null
where industry = "";

select *
from layoffs_staging2
where industry is null;

select * from layoffs_staging2
where company = "Airbnb";

select * from layoffs_staging2
where company = "Carvana";

select * from layoffs_staging2
where company = "Juul";

select t1.company, t1.industry, t2.industry from layoffs_staging2 t1 
join layoffs_staging2 t2
	on t1.company = t2.company
where t1.industry is null
and t2.industry is not null;

update layoffs_staging2 t1
join layoffs_staging2 t2 
	on t1.company = t2.company 
set t1.industry = t2.industry
where t1.industry is null 
and t2.industry is not null;

select * from layoffs_staging2;
---------------------------------------------------------------------------------------------------------------------------------------------------------


-- 4. Remove any columns or rows which aren't necessary

select * 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

delete 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select * 
from layoffs_staging2;

alter table layoffs_staging2
drop column row_num;

select * 
from layoffs_staging2;

-- 5. Exporting to csv

(SELECT 'company', 'location', 'industry', 'total_laid_off', 'percentage_laid_off', 'date', 'stage', 'country', 'funds_raised_millions')
UNION ALL
(SELECT 
    IFNULL(company,''), 
    IFNULL(location,''), 
    IFNULL(industry,''), 
    IFNULL(total_laid_off, ''), 
    IFNULL(percentage_laid_off, ''), 
    IFNULL(`date`, ''), 
    IFNULL(stage,''), 
    IFNULL(country,''), 
    IFNULL(funds_raised_millions, '')
FROM layoffs_staging2)
INTO OUTFILE '/Users/Shared/layoffs_cleaned.csv'
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
