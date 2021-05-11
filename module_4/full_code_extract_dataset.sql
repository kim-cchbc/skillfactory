WITH a AS -- general flights data
          (SELECT *
              FROM dst_project.flights f
           WHERE departure_airport = 'AAQ'
                 AND (date_trunc('month', scheduled_departure) IN ('2017-01-01',
                                                                                                    '2017-02-01',
                                                                                                    '2017-12-01'))
                AND status not in ('Cancelled')), 
		
     /* -- end a -- */
		 
     b AS --data of aircrafts #key = aircraft_code
     (WITH gen AS
                (SELECT a.aircraft_code,
                                a.total_seats,
                                ac.model,
                                ac.range
                   FROM
                               (SELECT aircraft_code,
                                               count(DISTINCT seat_no) total_seats
                                   FROM dst_project.seats
                                GROUP BY 1) a
			                                  JOIN dst_project.aircrafts ac 
			                                  ON a.aircraft_code = ac.aircraft_code),
	   
              b_seats AS
              (SELECT sb.aircraft_code AS b,
                              count(seat_no) bs
                  FROM dst_project.seats sb
               WHERE sb.fare_conditions = 'Business'
               GROUP BY sb.aircraft_code),
	   
              c_seats AS
              (SELECT sb.aircraft_code AS b,
                              count(seat_no) bs
                  FROM dst_project.seats sb
               WHERE sb.fare_conditions = 'Comfort'
               GROUP BY sb.aircraft_code),
	   
              e_seats AS
              (SELECT sb.aircraft_code AS b,
                              count(seat_no) bs
                  FROM dst_project.seats sb
               WHERE sb.fare_conditions = 'Economy'
               GROUP BY sb.aircraft_code)
	   
     SELECT gen.model,
                    gen.aircraft_code,
                    gen.total_seats,
                    b_s.bs bussines_seats,
                    coalesce(NULLIF(c_s.bs, 0), 0) comfort_seats,
                    e_s.bs economy_seats,
                    gen.range
        FROM gen
                    JOIN b_seats b_s 
                    ON b_s.b = gen.aircraft_code
                  
                    LEFT JOIN c_seats c_s 
                    ON c_s.b = gen.aircraft_code
                 
                    JOIN e_seats e_s 
                    ON e_s.b = gen.aircraft_code), 
			
     /* -- end b -- */		
			
     c AS -- ticket flights data #key = flight_id
     (WITH tf_b AS
                (SELECT flight_id,
                                count(fare_conditions) bus_seats,
                                sum(amount) bus_amount
                    FROM dst_project.ticket_flights tf
                 WHERE fare_conditions = 'Business'
                 GROUP BY flight_id),
	  
                tf_c AS
                (SELECT flight_id,
                                count(fare_conditions) com_seats,
                                sum(amount) com_amount
                    FROM dst_project.ticket_flights tf
                 WHERE fare_conditions = 'Comfort'
                 GROUP BY flight_id),
	  
                tf_e AS
                (SELECT flight_id,
                                count(fare_conditions) eco_seats,
                                sum(amount) eco_amount
                    FROM dst_project.ticket_flights tf
                 WHERE fare_conditions = 'Economy'
            GROUP BY flight_id),
	  
                am_sum AS
                (SELECT flight_id,
                                sum(amount) total_amount_flight
                    FROM dst_project.ticket_flights tf
                 GROUP BY flight_id) 
	  
	  SELECT tf_b.flight_id,
                     bus_seats,
                     coalesce(NULLIF(com_seats, 0), 0) com_seats,
                     eco_seats,
                     bus_amount,
                     coalesce(NULLIF(com_amount, 0), 0) com_amount,
                     eco_amount,
                     total_amount_flight
         FROM tf_b
                    LEFT JOIN tf_c 
	                ON tf_c.flight_id = tf_b.flight_id
	  
	                JOIN tf_e 
	                ON tf_e.flight_id = tf_b.flight_id
	  
	                JOIN am_sum 
	                ON am_sum.flight_id = tf_b.flight_id),
			 
     /* -- end c -- */			 
			 
     d AS -- departue airports info #key = airport_code
     (SELECT airport_code,
                     airport_name air_dep_name,
                     city city_dep,
                     longitude dep_long,
                     latitude dep_lat
         FROM dst_project.airports), 
		
	 /* -- end d -- */	
		
     e AS -- arrival airports info
     (SELECT airport_code,
                     airport_name air_arr_name,
                     city city_arrival,
                     longitude arr_long,
                     latitude arr_lat
         FROM dst_project.airports)
		
     /* -- end c -- */
		
SELECT a.flight_id,
               a.flight_no,
               a.scheduled_departure,
               a.scheduled_arrival,
               a.scheduled_arrival - a.scheduled_departure AS estimate_time,
               a.actual_departure,
               a.actual_arrival,
               a.actual_arrival - a.actual_departure AS real_time,
               a.departure_airport,
               d.air_dep_name,
               d.city_dep,
               d.dep_long,
               d.dep_lat,
               a.arrival_airport,
               e.air_arr_name,
               e.city_arrival,
               e.arr_long,
               e.arr_lat,
               c.bus_seats, -- number of business class tickets
               c.com_seats, -- number of comfort class tickets
               c.eco_seats, -- number of economy class tickets
               c.bus_amount, -- amount of business class
               c.com_amount, -- amount of comfort class
               c.eco_amount, -- amount of economy class
               c.total_amount_flight,
               b.model,
               b.aircraft_code,
               b.bussines_seats,
               b.comfort_seats,
               b.economy_seats,
               b.total_seats,
               b.range
   FROM a
               JOIN b 
               ON a.aircraft_code = b.aircraft_code -- aircrafts
	   
               LEFT JOIN c 
               ON a.flight_id = c.flight_id -- flights
	   
               LEFT JOIN d 
               ON d.airport_code = a.departure_airport -- airports
	   
               LEFT JOIN e 
               ON e.airport_code = a.arrival_airport -- airports
