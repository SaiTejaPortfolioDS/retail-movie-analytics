/*
Project: MavenMovies Retail Analytics & Insights

This script solves several business problems by querying the MavenMovies database, which is organized with interconnected tables using foreign key relationships.

Key Relationships:
- Each store is linked to a manager in the staff table via store.manager_staff_id -> staff.staff_id.
- Store locations are resolved via address_id linked to address table, further linked to city and country.
- Inventory links each stocked item to its film via inventory.film_id -> film.film_id.
- Films are categorized through film_category and category tables using film.film_id and category.category_id.
- Customers are linked to rentals and payments via customer_id and rental_id.
- Investors and advisors are captured in separate tables and combined in queries.
- Actor awards are tracked in actor_award, linked to films via actor_id and film_id (not shown explicitly here).

All queries below leverage these relationships to provide comprehensive business insights.
*/


/* 
Problem 1: List all store managers with their full store addresses
Relationships used:
- store.manager_staff_id => staff.staff_id (Manager of store)
- store.address_id => address.address_id (Store location)
- address.city_id => city.city_id, city.country_id => country.country_id (Location hierarchy)
*/
SELECT 
	staff.first_name AS manager_first_name, 
    staff.last_name AS manager_last_name,
    address.address, 
    address.district, 
    city.city, 
    country.country
FROM store
	LEFT JOIN staff ON store.manager_staff_id = staff.staff_id
    LEFT JOIN address ON store.address_id = address.address_id
    LEFT JOIN city ON address.city_id = city.city_id
    LEFT JOIN country ON city.country_id = country.country_id
;


/*
Problem 2: List inventory per store with film details
Relationships used:
- inventory.film_id => film.film_id (Inventory links to film metadata)
*/
SELECT 
	inventory.store_id, 
    inventory.inventory_id, 
    film.title, 
    film.rating, 
    film.rental_rate, 
    film.replacement_cost
FROM inventory
	LEFT JOIN film ON inventory.film_id = film.film_id
;


/*
Problem 3: Count inventory items by film rating and store
Relationships used:
- Same join as previous keeping store and rating context
*/
SELECT 
	inventory.store_id, 
    film.rating, 
    COUNT(inventory.inventory_id) AS inventory_items
FROM inventory
	LEFT JOIN film ON inventory.film_id = film.film_id
GROUP BY 
	inventory.store_id,
    film.rating
;


/*
Problem 4: Summarize inventory financial risk by film category
Relationships used:
- inventory.film_id => film.film_id
- film.film_id => film_category.film_id => category.category_id (Many-to-many relation between films and categories)
*/
SELECT 
	store_id, 
    category.name AS category, 
	COUNT(inventory.inventory_id) AS films, 
    AVG(film.replacement_cost) AS avg_replacement_cost, 
    SUM(film.replacement_cost) AS total_replacement_cost
FROM inventory
	LEFT JOIN film ON inventory.film_id = film.film_id
	LEFT JOIN film_category ON film.film_id = film_category.film_id
	LEFT JOIN category ON category.category_id = film_category.category_id
GROUP BY 
	store_id, 
    category.name
ORDER BY 
	SUM(film.replacement_cost) DESC
;


/*
Problem 5: List customers with store and address details
Relationships used:
- customer.address_id => address.address_id
- address.city_id => city.city_id
- city.country_id => country.country_id
*/
SELECT 
	customer.first_name, 
    customer.last_name, 
    customer.store_id,
    customer.active, 
    address.address, 
    city.city, 
    country.country
FROM customer
	LEFT JOIN address ON customer.address_id = address.address_id
    LEFT JOIN city ON address.city_id = city.city_id
    LEFT JOIN country ON city.country_id = country.country_id
;


/*
Problem 6: Calculate customer rental counts and payment sums
Relationships used:
- customer.customer_id => rental.customer_id
- rental.rental_id => payment.rental_id
*/
SELECT 
	customer.first_name, 
    customer.last_name, 
    COUNT(rental.rental_id) AS total_rentals, 
    SUM(payment.amount) AS total_payment_amount
FROM customer
	LEFT JOIN rental ON customer.customer_id = rental.customer_id
    LEFT JOIN payment ON rental.rental_id = payment.rental_id
GROUP BY 
	customer.first_name,
    customer.last_name
ORDER BY 
	SUM(payment.amount) DESC
;


/*
Problem 7: Combine investor and advisor lists with type indicator
*/
SELECT
	'investor' AS type, 
    first_name, 
    last_name, 
    company_name
FROM investor

UNION 

SELECT 
	'advisor' AS type, 
    first_name, 
    last_name, 
    NULL
FROM advisor
;


/*
Problem 8: Analyze actor award coverage in films
*/
SELECT
	CASE 
		WHEN actor_award.awards = 'Emmy, Oscar, Tony ' THEN '3 awards'
        WHEN actor_award.awards IN ('Emmy, Oscar','Emmy, Tony', 'Oscar, Tony') THEN '2 awards'
		ELSE '1 award'
	END AS number_of_awards, 
    AVG(CASE WHEN actor_award.actor_id IS NULL THEN 0 ELSE 1 END) AS pct_w_one_film	
FROM actor_award
GROUP BY 
	CASE 
		WHEN actor_award.awards = 'Emmy, Oscar, Tony ' THEN '3 awards'
        WHEN actor_award.awards IN ('Emmy, Oscar','Emmy, Tony', 'Oscar, Tony') THEN '2 awards'
		ELSE '1 award'
	END
;
