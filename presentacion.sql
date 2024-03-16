USE coderhouse_gamers;

-- El equipo de marketing quiere saber la cantidad
-- de tipos de usuarios que tienen en la tabla de gamers

/*
SELECT 
	COUNT( DISTINCT id_user_type) AS total_de_user_type
FROM  USER_TYPE; 
*/

CREATE OR REPLACE VIEW vw_total_user_types 
	AS (SELECT 
			COUNT( DISTINCT id_user_type) AS total_de_user_type
		FROM  USER_TYPE);
 

SELECT 
	*
FROM vw_total_user_types;

-- Modificacion de tabla original

INSERT INTO USER_TYPE
	VALUES
    (505,"Este es un nuevo usuario");
	
-- Ventas -> 
-- 2015 - 2018
-- El equipo de ventas quiere tener los jueos que esten entre las fechas del 2015 y 2018
-- con menor cantidad de comentarios (si tiene 1 comentario solo esos juegos con 1 solo comentario)

-- posterior con el equipo de marketing conocer los nombres de los juegos

CREATE OR REPLACE VIEW  vw_ventas_games_comment (juego)
AS
	(SELECT 

		id_game
	-- ,	COUNT(1) AS cantidad_comentarios -- comento esta linea por que no la voy a usar

	FROM COMMENT
	WHERE 
		last_date BETWEEN '2018-01-01' AND '2019-12-31'
	GROUP BY 	id_game  
	HAVING		COUNT(1) = 1
    )
	;    
    
SELECT 
*
FROM vw_ventas_games_comment ;


CREATE OR REPLACE VIEW  vw_marketing_games
AS 
	(
    SELECT 
		id_game
	,	name
    ,	description
    FROM GAME
    );

SELECT *
FROM vw_marketing_games;


-- ventas y equipo de marketing

SELECT
	vw_vg.juego
,	vw_mg.name
,	vw_mg.description 
FROM vw_ventas_games_comment as vw_vg
INNER JOIN vw_marketing_games as vw_mg
		ON vw_vg.juego = vw_mg.id_game ;



-- CODIGO AUTO GENERADO 

CREATE  OR REPLACE 
    ALGORITHM = UNDEFINED 
    DEFINER = `root`@`%` 
    SQL SECURITY DEFINER
VIEW `coderhouse_gamers`.`vw_ventas_games_comment` (`juego`) AS
    SELECT 
        `coderhouse_gamers`.`COMMENT`.`id_game` AS `id_game`
    FROM
        `coderhouse_gamers`.`COMMENT`
    WHERE
        (`coderhouse_gamers`.`COMMENT`.`last_date` BETWEEN '2015-01-01' AND '2018-12-31')
    GROUP BY `coderhouse_gamers`.`COMMENT`.`id_game`
    HAVING (COUNT(1) IN (1, 2));


-- alamacenado de info <tabla staging datos ventas 2015 - 2018>

RENAME TABLE staging_data_2015_2018  TO staging_data; 
CREATE TABLE staging_data_2015_2018 AS
	SELECT
		curdate() AS fecha_ingesta
	,	vw_vg.juego
	,	vw_mg.name
	,	vw_mg.description 
	FROM vw_ventas_games_comment as vw_vg
	INNER JOIN vw_marketing_games as vw_mg
			ON vw_vg.juego = vw_mg.id_game ;

SELECT * 
FROM staging_data;

DROP VIEW vw_marketing_games;
DROP VIEW vw_ventas_games_comment;


INSERT INTO staging_data 
	SELECT
		curdate() + INTERVAL 1 DAY AS fecha_ingesta
	,	vw_vg.juego
	,	vw_mg.name
	,	vw_mg.description 
	FROM vw_ventas_games_comment as vw_vg
	INNER JOIN vw_marketing_games as vw_mg
			ON vw_vg.juego = vw_mg.id_game ;



-- Segunda parte 



/*
### Problema:
Nuestro equipo de desarrollo está trabajando en un sistema de gestión de reservas para restaurantes,
y nos enfrentamos a la necesidad de diseñar una base de datos eficiente que pueda manejar todas las operaciones 
relacionadas con las reservas de manera óptima.
### Descripción del Problema:
1. **Gestión de Clientes y Empleados**: 
Necesitamos una base de datos que nos permita registrar la información de los clientes que realizan reservas,
así como de los empleados involucrados en el proceso de reserva, como los camareros o encargados de atención al cliente.
2. **Gestión de Tipos de Reserva**: 
Es importante poder clasificar las reservas según su tipo, ya sea una reserva estándar,
una reserva para eventos especiales o reservas de grupos grandes.
Esto nos ayudará a organizar mejor el flujo de trabajo y adaptar nuestros servicios según las necesidades del cliente.
3. **Gestión de Mesas y Disponibilidad**: 
La base de datos debe permitirnos registrar la disponibilidad de mesas en cada restaurante,
así como gestionar su capacidad y estado (ocupado o disponible).
 Esto es fundamental para garantizar una asignación eficiente de mesas y evitar conflictos de reservas.
4. **Registro de Reservas**: 
Necesitamos un sistema que pueda registrar de manera detallada cada reserva realizada, 
incluyendo la fecha y hora de la reserva, el cliente que la realizó, la mesa reservada,
el empleado que atendió la reserva y el tipo de reserva.
### Objetivo:
Diseñar e implementar una base de datos relacional que satisfaga todas las necesidades de gestión de reservas 
para nuestro sistema de gestión de restaurantes. 
Esta base de datos deberá ser eficiente, escalable y fácil de mantener,
permitiendo una gestión ágil y precisa de todas las operaciones relacionadas con las reservas.
*/


/*
				TIPO_DE_RESERVA
				* - 1
CLIENTE  1-* 	RESERVA *-1	RESTAURANTE * - 1 DUENO
				1 - 1 		1 - *
                MESA		EMPLEADO
*/

/*
## Descripción de la Base de Datos - Gestión de Reservas en Restaurantes
### ENTIDADES | ACTORES QUE INTERVIENEN EN ESTA BASE DE DATOS:
1. **CLIENTE**:
   - Almacena información sobre los clientes que realizan reservas.
   - Atributos: 
            IDCLIENTE   INT NOT NULL PK AI
        ,   NOMBRE      VARCHAR(100)    DEFAULT 'DESCONOCIDO'
        ,   TELEFONO    VARCHAR(20)     DEFAULT '000-000-000'
        ,   CORREO      VARCHAR(50)		UNIQUE NOT NULL
2. **EMPLEADO**:
   - Contiene información sobre los empleados involucrados en el proceso de reservas.
   - Atributos: 
			IDEMPLEADO 	INT NOT NULL PK AI
		, 	NOMBRE		VARCHAR(100)    DEFAULT 'DESCONOCIDO'
        , 	TELEFONO
        , 	CORREO
        , 	IDRESTAURANTE
        
3. **DUEÑO**:
   - Guarda datos sobre los dueños de los restaurantes (no se utiliza explícitamente en el proceso de reservas).
4. **TIPORESERVA**:
   - Define diferentes tipos de reserva para clasificarlas según su propósito o requisitos específicos.
   - Atributos: IDTIPORESERVA, TIPO.
5. **RESTAURANTE**:
   - Almacena información sobre los restaurantes disponibles.
   - Atributos: IDRESTAURANTE, NOMBRE, DIRECCION, TELEFONO.
6. **MESA**:
   - Contiene información sobre las mesas disponibles en cada restaurante.
   - Atributos: IDMESA, IDRESTAURANTE, CAPACIDAD, DISPONIBLE.
7. **RESERVA**:
   - Registra las reservas realizadas por los clientes.
   - Atributos: IDRESERVA, IDCLIENTE, IDMESA, IDEMPLEADO, IDTIPORESERVA, FECHA.

DER --> DIAGRAMA ENTIDAD RELACION DE: CHIPARICAS.SA
   
   
                             +-------------------+
                             |   TipoReserva     |
                             +-------------------+
                             | idTipoReserva(PK) |
                             | tipo              |
                             +-------------------+
										|
+------------------+        +-----------------------+        +------------------+
|      CLIENTE     |        |       RESERVA         |        |     RESTAURANTE  |
+------------------+   1-*  +-----------------------+   *-1  +------------------+
| idCliente (PK)   |<>-----o| idReserva (PK)        |o-------| idRestaurante(PK)|
| nombre           |        | idCliente (FK)        |        | nombre           |
| telefono         |        | idMesa (FK)           |        | direccion        |
| correo           |        | idEmpleado (FK)       |        | telefono         |
+------------------+        | idTipoReserva (FK)    |        +------------------+
                            | fecha                 |				   |
                            | cancelcion            |                  |
                            +-----------------------+                  |
                                    |                                  |
                                    |   1-* | 1-1                      |
                                    v                                  v
+------------------+        +------------------+             +-------------------+
|     Empleado     |        |      Mesa        |             |     Dueño         |
+------------------+        +------------------+             +-------------------+
| idEmpleado (PK)  |        | idMesa (PK)      |             | idDueño (PK)      |
| nombre           |        | idRestaurante(FK)|             | nombre            |
| telefono         |        | capacidad        |             | correo            |
| correo           |        | disponible       |             | telefono          |
| idRestaurante(FK)|        +------------------+             +-------------------+
+------------------+                  

   
*/










    
    