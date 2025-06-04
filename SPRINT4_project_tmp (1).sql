/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: 
 * Дата: 
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT COUNT(id) AS total_users,
SUM(payer) AS total_payers,
ROUND(AVG(payer) * 100, 2) AS payer_users_share
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT r.race,
SUM(u.payer) AS total_payers,
COUNT(DISTINCT u.id) AS total_users,
ROUND(AVG(u.payer) * 100, 2) AS payer_users_share
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id=r.race_id
GROUP BY r.race
ORDER BY total_payers DESC;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT COUNT(DISTINCT transaction_id) AS total_purchases,
SUM(amount) AS total_amount,
MIN(amount) AS min_amount,
MAX(amount) AS max_amount,
AVG(amount) AS avg_amount,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS perc_amount,
STDDEV(amount) AS stddev_amount
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
SELECT SUM(CASE WHEN amount=0 THEN 1 ELSE 0 END) AS null_amount,
SUM(CASE WHEN amount=0 THEN 1 ELSE 0 END)::numeric/COUNT(transaction_id)::numeric AS null_amount_share
FROM fantasy.events;

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
WITH cte AS (SELECT
CASE 
	WHEN u.payer=1 THEN 'платящий'
	ELSE 'неплатящий'
END AS payers,
COUNT(DISTINCT u.id) AS total_users,
COUNT(e.transaction_id) AS total_transaction,
SUM(e.amount) AS total_amount
FROM fantasy.users AS u
LEFT JOIN fantasy.events AS e ON u.id=e.id
WHERE e.amount <> 0
GROUP BY u.payer)
SELECT payers, total_users,
ROUND((total_transaction::numeric/total_users::NUMERIC),2) AS tran_per_user,
ROUND(total_amount::numeric/total_users::numeric,2) AS amount_per_user
FROM cte;

-- 2.4: Популярные эпические предметы:
WITH sales_items AS (
	SELECT e.item_code, 
	i.game_items,
	COUNT(e.item_code) AS purchase_items,
COUNT(DISTINCT e.id) AS users
FROM fantasy.events AS e
JOIN fantasy.items AS i ON e.item_code=i.item_code
GROUP BY e.item_code, i.game_items
),
total_stats AS (
	SELECT 
SUM(purchase_items) AS total_sales,
SUM(users) AS total_users
FROM sales_items)
SELECT si.item_code, si.game_items,
si.purchase_items,
ROUND(si.purchase_items::NUMERIC/ts.total_sales * 100,2) AS purchase_share,
ROUND(si.users::NUMERIC/ts.total_users * 100, 2) AS users_share
FROM sales_items AS si
CROSS JOIN total_stats AS ts
ORDER BY purchase_items DESC;


-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
WITH race_users AS (
SELECT u.race_id,
r.race, 
COUNT(u.race_id) AS total_users
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id=r.race_id
GROUP BY u.race_id,r.race
),
race_customer_share AS (
SELECT u.race_id,
COUNT(DISTINCT e.id) AS total_customers,
ROUND(COUNT(DISTINCT u.id) FILTER(WHERE payer=1)::numeric/COUNT(DISTINCT e.id)::NUMERIC * 100,2) AS payers_share
FROM fantasy.users AS u
LEFT JOIN fantasy.events AS e ON u.id=e.id
GROUP BY u.race_id
),
avg_purchases AS (
SELECT u.race_id,
COUNT(e.transaction_id)/COUNT(DISTINCT u.id)::NUMERIC AS avg_purch_per_users,
SUM(e.amount) / COUNT(DISTINCT e.transaction_id) AS avg_amount_per_users,
SUM(e.amount) / COUNT(DISTINCT u.id) AS avg_total_amount_per_user
FROM fantasy.users AS u
JOIN fantasy.events AS e ON u.id=e.id
WHERE amount <> 0
GROUP BY u.race_id
)
SELECT ru.race_id, 
ru.race,
ru.total_users,
rcu.total_customers,
rcu.payers_share,
ROUND(ap.avg_purch_per_users,2) AS avg_purch_per_users,
ROUND(ap.avg_amount_per_users::numeric,2) AS avg_amount_per_users,
ROUND(ap.avg_total_amount_per_user::numeric,2) AS avg_total_amount_per_user
FROM race_users AS ru
JOIN race_customer_share AS rcu USING(race_id)
JOIN avg_purchases AS ap USING (race_id)
ORDER BY total_customers DESC;


-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь