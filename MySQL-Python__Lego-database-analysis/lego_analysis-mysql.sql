use lego_database;

-- 1. Which is the theme and year of the most popular lego sets (by the number of parts included)?
select distinct
	themes.name as lego_theme,
	sets.name as lego_set,
    sets.year,
    sets.num_parts as lego_parts
from sets
	inner join themes on themes.id = sets.theme_id
order by sets.num_parts desc
limit 5;


-- 2. Which LEGO themes have the highest average number of parts per set?
select distinct
	themes.name,
    round(avg(sets.num_parts)) as avg_parts_per_set
from sets
	inner join themes on themes.id = sets.theme_id
group by themes.name
order by avg_parts_per_set desc;


-- 3. What is the distribution of LEGO sets across the first and last 5 years?
with ranking_sets as (
	select
		sets.year,
		row_number() over(order by sets.year asc) as first_years,
		row_number() over(order by sets.year desc) as last_years,
		count(set_num) as total_sets_launched,
        max(num_parts) as biggest_set
    from sets
    group by sets.year)

		select
			year, total_sets_launched, biggest_set
		from ranking_sets
		where first_years <= 5
        
union all

		select
			year, total_sets_launched, biggest_set
		from ranking_sets
		where last_years <= 5
        
order by year;


-- 4. What is the difference between lego sets launched between each year and the previous year?
with previous_data as (
	select
		year,
        lag(year) over (order by year) as previous_year,
        count(set_num) as year_count,
        lag(count(set_num)) over (order by year) as previous_year_count
    from sets
    group by year)

select  
	previous_year,
    year,
    (year_count - previous_year_count) as difference
from previous_data
order by abs(difference) desc;


-- 5. How many unique LEGO parts are there in the dataset, per category?
select distinct
	part_categories.name as category_name,
	count(parts.part_num) as parts
from parts
	inner join part_categories on part_categories.id = parts.part_cat_id
group by part_categories.name
order by parts desc;


-- 6. Which are the sets that have the parts of the least frequent category?
with least_freq_cat as (
	select distinct
		part_categories.name as category_name,
		count(parts.part_num) as parts
	from parts
		inner join part_categories on part_categories.id = parts.part_cat_id
	group by part_categories.name
	order by parts asc
    limit 1
)

select distinct
	part_categories.name as category_name,
    themes.name as lego_theme,
    sets.name as lego_set,
    count(parts.part_num) as total_parts
from parts
	inner join part_categories on part_categories.id = parts.part_cat_id
    inner join inventory_parts on inventory_parts.part_num = parts.part_num
    inner join inventories on inventories.id = inventory_parts.inventory_id
    inner join sets on sets.set_num = inventories.set_num
    inner join themes on themes.id = sets.theme_id
where part_categories.name = (select category_name from least_freq_cat)
group by category_name, themes.name, sets.name
order by total_parts desc, lego_theme;


-- 7. Are there any LEGO parts that are used as spares more frequently than others?
select
	parts.name as piece_name,
    sum(inventory_parts.quantity) as amount_spare_pieces
from parts
	inner join inventory_parts on inventory_parts.part_num = parts.part_num
where inventory_parts.is_spare = "true"
group by parts.name
order by amount_spare_pieces desc;


-- 8. Which are the 10 most common colors for lego parts?
select distinct
	concat(colors.name, ' (', colors.rgb, ')') as color_RGB,
    sum(inventory_parts.quantity) as total_parts
from inventory_parts
	inner join colors on colors.id = inventory_parts.color_id
group by colors.rgb, colors.name
order by total_parts desc
limit 10;


-- 9. Which are the sets that have the 5 least used colors for lego parts?
with least_used_colors as (
	select distinct
    colors.id,
    sum(inventory_parts.quantity) as total_parts,
    dense_rank() over (order by sum(inventory_parts.quantity)) as color_rank
	from inventory_parts
		inner join colors on colors.id = inventory_parts.color_id
	group by colors.id, colors.name
	order by total_parts asc
    limit 5)

select distinct
	least_used_colors.color_rank,
    least_used_colors.total_parts,
	concat(colors.name, ' (', colors.rgb, ')') as color_RGB,
    sets.name as lego_set
from inventory_parts
	inner join colors on colors.id = inventory_parts.color_id
    inner join inventories on inventories.id = inventory_parts.inventory_id
    inner join sets on sets.set_num = inventories.set_num
    inner join least_used_colors on colors.id = least_used_colors.id
order by least_used_colors.color_rank, color_rgb;


-- 10. How does the distribution of transparent and non-transparent colors vary across LEGO parts?
select 
	case 
		when colors.is_transparent = 'True' then 'Transparent'
		else 'Non-Transparent'
	end as color_type,
    sum(inventory_parts.quantity) as total_parts
from inventory_parts
	inner join colors on colors.id = inventory_parts.color_id
group by colors.is_transparent
order by total_parts desc;