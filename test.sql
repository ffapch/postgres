SELECT DISTINCT first_name
FROM employees
ORDER BY first_name;

SELECT COUNT(1) AS count_employees
FROM employees

SELECT department_id, COUNT(1) AS count_employees
FROM employees
GROUP BY department_id
HAVING department_id IS NOT NULL
ORDER BY count_employees DESC


///////////////// 5 //////////////////////////////////
SELECT E.department_id, D.city, COUNT(1) AS count_employees
FROM employees AS E
INNER JOIN departments AS D ON D.id = E.department_id
GROUP BY E.department_id, D.city
ORDER BY D.city

///////////////// 6 /////////////////////////////////////
SELECT city
FROM departments
WHERE city LIKE 'L%'

//////////////// 7 //////////////////////////////////////
SELECT D.city, COUNT(E.department_id) AS count_employees
FROM departments AS D
LEFT OUTER JOIN employees AS E ON D.id = E.department_id
GROUP BY D.city
HAVING D.city LIKE '%n%'

/////////////// 8 /////////////////////////////////////
SELECT first_name, last_name
FROM employees
WHERE last_name in (
	SELECT last_name
	FROM employees
	GROUP BY last_name
  	HAVING COUNT(last_name) > 1)
ORDER BY first_name, last_name

/////////////// 9 ////////////////////////////////////////
SELECT E.first_name, E.last_name
FROM employees AS E
INNER JOIN departments AS D ON D.id = E.department_id AND D.city = 'Lviv' 
INNER JOIN (
  SELECT first_name, last_name
  FROM employees
  GROUP BY first_name, last_name
  HAVING COUNT(*) > 1) AS Tmp ON E.first_name = Tmp.first_name AND E.last_name = Tmp.last_name
ORDER BY E.first_name 

////////////// 10 ////////////////////////////////////////
SELECT E.department_id, D.city
FROM departments AS D
INNER JOIN employees AS E ON D.id = E.department_id
WHERE E.last_name = 'Kloba'
GROUP BY E.department_id, D.city
HAVING COUNT(*) > 5
ORDER BY E.department_id

////////////////////////////////////////////////////////////
База даних: 
Hostname: 35.198.169.75
Post: 5432
Database: fpaysv
User name: andrey.dovbnya
Password: 3SEyqrkNjQm76ATs

psql -h [HOSTNAME] -p [PORT] -U [USERNAME] -W -d [DATABASENAME]

psql postgres://[USERNAME]:[PASSWORD]@[HOSTNAME]:[PORT]/[DATABASENAME]?sslmode=require

psql postgres://andrey.dovbnya:3SEyqrkNjQm76ATs@35.198.169.75:5432/fpaysv?sslmode=require


docker run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -d postgres
docker exec -it some-postgres bash
apt update
apt install curl