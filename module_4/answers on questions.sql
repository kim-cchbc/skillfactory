-- Задание 4.1
-- База данных содержит список аэропортов практически всех крупных городов России. В большинстве городов есть только один аэропорт. Исключение составляет:

SELECT city,
       count(airport_code)
  FROM dst_project.airports
 GROUP BY city
 ORDER BY 2 DESC;

-- Задание 4.2

-- Вопрос 1. Таблица рейсов содержит всю информацию о прошлых, текущих и запланированных рейсах. Сколько всего статусов для рейсов определено в таблице?

SELECT DISTINCT status
  FROM dst_project.flights;

-- Вопрос 2. Какое количество самолетов находятся в воздухе на момент среза в базе (статус рейса «самолёт уже вылетел и находится в воздухе»).

SELECT count(DISTINCT f.flight_id)
  FROM dst_project.flights f
WHERE f.status = 'Departed';

-- Вопрос 3. Места определяют схему салона каждой модели. Сколько мест имеет самолет модели  (Boeing 777-300)?

SELECT count(DISTINCT s.seat_no)
  FROM dst_project.seats s
  JOIN dst_project.aircrafts "a" ON s.aircraft_code = a.aircraft_code
 WHERE a.model = 'Boeing 777-300'
 GROUP BY s.aircraft_code;

-- Вопрос 4. Сколько состоявшихся (фактических) рейсов было совершено между 1 апреля 2017 года и 1 сентября 2017 года?

SELECT count(f.flight_no)
  FROM dst_project.flights f
 WHERE (scheduled_arrival BETWEEN '2017-04-01 00:00:00+00' AND '2017-09-01 00:00:00+00')
   AND f.status = 'Arrived';

-- Задание 4.3
-- Вопрос 1. Сколько всего рейсов было отменено по данным базы?

SELECT count(DISTINCT flight_no)
  FROM dst_project.flights
 WHERE status = 'Cancelled';

-- Вопрос 2. Сколько самолетов моделей типа Boeing, Sukhoi Superjet, Airbus находится в базе авиаперевозок?

WITH b AS
     (SELECT *
        FROM dst_project.aircrafts a)

SELECT 'Boeing',
       count(DISTINCT b.aircraft_code)
  FROM b
 WHERE b.model like 'Boeing%'

 UNION

SELECT 'Sukhoi Superjet',
       count(DISTINCT b.aircraft_code)
  FROM b
 WHERE b.model like 'Sukhoi Superjet%'

 UNION

SELECT 'Airbus',
       count(DISTINCT b.aircraft_code)
  FROM b
 WHERE b.model like 'Airbus%';

-- Вопрос 3. В какой части (частях) света находится больше аэропортов?

WITH a AS
     (SELECT timezone,
             count(DISTINCT airport_code) cn
        FROM dst_project.airports a
       GROUP BY timezone)

SELECT 'Asia',
       sum(a.cn)
  FROM a
 WHERE a.timezone like 'Asia%'

 UNION

SELECT 'Europe',
       sum(a.cn)
  FROM a
 WHERE a.timezone like 'Europe%';

-- Вопрос 4. У какого рейса была самая большая задержка прибытия за все время сбора данных? Введите id рейса (flight_id).

SELECT actual_arrival - scheduled_arrival AS diff,
       flight_id
  FROM dst_project.flights f
 WHERE actual_arrival IS NOT NULL
 ORDER BY 1 DESC
 LIMIT 1;

-- Задание 4.4

-- Вопрос 1. Когда был запланирован самый первый вылет, сохраненный в базе данных?

SELECT scheduled_departure
  FROM dst_project.flights f
 ORDER BY 1
 LIMIT 1;

-- Вопрос 2. Сколько минут составляет запланированное время полета в самом длительном рейсе?

SELECT extract(HOUR
               FROM (scheduled_arrival - scheduled_departure))*60
               +
       extract(MIN
               FROM (scheduled_arrival - scheduled_departure)) AS diff
  FROM dst_project.flights f
 ORDER BY 1 DESC
 LIMIT 1;

-- Вопрос 3. Между какими аэропортами пролегает самый длительный по времени запланированный рейс?

SELECT extract(HOUR
               FROM (scheduled_arrival - scheduled_departure))*60
               +
       extract(MIN
               FROM (scheduled_arrival - scheduled_departure)) AS diff,
       departure_airport,
       arrival_airport
  FROM dst_project.flights f
 ORDER BY 1 DESC
 LIMIT 1;

-- Вопрос 4. Сколько составляет средняя дальность полета среди всех самолетов в минутах? Секунды округляются в меньшую сторону (отбрасываются до минут).

SELECT extract(HOUR
               FROM (avg(scheduled_arrival - scheduled_departure)))*60
               +
       extract(MIN
               FROM (avg(scheduled_arrival - scheduled_departure)))
  FROM dst_project.flights f
 ORDER BY 1 DESC;

-- Задание 4.5
-- Вопрос 1. Мест какого класса у SU9 больше всего?

SELECT count(s.seat_no),
       s.fare_conditions
  FROM dst_project.seats s
 WHERE s.aircraft_code = 'SU9'
 GROUP BY s.fare_conditions
 ORDER BY 1 DESC
 LIMIT 1;

-- Вопрос 2. Какую самую минимальную стоимость составило бронирование за всю историю?

SELECT total_amount
  FROM dst_project.bookings b
 ORDER BY 1
 LIMIT 1;

-- Вопрос 3. Какой номер места был у пассажира с id = 4313 788533?

SELECT bp.seat_no
  FROM dst_project.tickets t
  JOIN dst_project.boarding_passes bp
    ON t.ticket_no = bp.ticket_no
 WHERE t.passenger_id = '4313 788533';

-- Задание 5.1

-- Вопрос 1. Анапа — курортный город на юге России. Сколько рейсов прибыло в Анапу за 2017 год?

SELECT count(f.flight_id)
  FROM dst_project.flights f
 WHERE f.arrival_airport = 'AAQ'
   AND f.status = 'Arrived'
   AND date_part('year', actual_arrival)=2017;

-- Вопрос 2. Сколько рейсов из Анапы вылетело зимой 2017 года?

SELECT count(f.flight_id)
  FROM dst_project.flights f
 WHERE f.departure_airport = 'AAQ'
   AND date_part('year', f.actual_departure) = 2017
   AND (date_part('month', f.actual_departure) = 1
    OR date_part('month', f.actual_departure) = 2
    OR date_part('month', f.actual_departure) = 12);

-- Вопрос 3. Посчитайте количество отмененных рейсов из Анапы за все время.

SELECT count(f.flight_id)
  FROM dst_project.flights f
 WHERE f.departure_airport = 'AAQ'
   AND f.status = 'Cancelled';

-- Вопрос 4. Сколько рейсов из Анапы не летают в Москву?

SELECT count(f.flight_id)
  FROM dst_project.flights f
  JOIN dst_project.airports a
    ON f.arrival_airport = a.airport_code
 WHERE NOT a.city = 'Moscow'
   AND f.departure_airport = 'AAQ';

-- Вопрос 5. Какая модель самолета летящего на рейсах из Анапы имеет больше всего мест?

SELECT a.model,
       count(DISTINCT s.seat_no)
  FROM dst_project.flights f
  JOIN dst_project.seats s ON f.aircraft_code = s.aircraft_code
  JOIN dst_project.aircrafts a ON s.aircraft_code = a.aircraft_code WHERE f.departure_airport = 'AAQ'
 GROUP BY s.aircraft_code,
         a.model
 LIMIT 1;



