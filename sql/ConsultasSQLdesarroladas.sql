/* ==================================================
   CONSULTAS SELECT
   ================================================== */

-- 1. Mostrar todos los huespedes
SELECT * FROM huesped;

-- 2. Mostrar habitaciones disponibles
SELECT *
FROM habitacion
WHERE estado_actual = 'DISPONIBLE';

-- 3. Mostrar habitaciones ocupadas
SELECT *
FROM habitacion
WHERE estado_actual = 'OCUPADA';

-- 4. Mostrar huespedes de El Salvador
SELECT *
FROM huesped
WHERE pais = 'El Salvador';

-- 5. Mostrar tipos de habitacion ordenados por precio
SELECT *
FROM tipo_habitacion
ORDER BY precio DESC;

-- 6. Cantidad de huespedes por pais
SELECT pais, COUNT(*) AS cantidad_huespedes
FROM huesped
GROUP BY pais
ORDER BY cantidad_huespedes DESC;

-- 7. Reservaciones con nombre del huesped
SELECT r.id_reservacion,
       h.nombre,
       r.fecha_inicio,
       r.fecha_fin
FROM reservacion r
INNER JOIN huesped h
ON r.id_huesped = h.id_huesped;

-- 8. Habitaciones con su tipo
SELECT h.num_habitacion,
       h.estado_actual,
       t.nombre AS tipo_habitacion,
       t.precio
FROM habitacion h
INNER JOIN tipo_habitacion t
ON h.id_tipo = t.id_tipo;

-- 9. Mostrar todas las facturas
SELECT *
FROM factura;

-- 10. Total por factura
SELECT
    f.id_factura,
    SUM(df.cantidad * df.precio_unitario) AS total_factura
FROM factura f
INNER JOIN detalle_factura df
ON f.id_factura = df.id_factura
GROUP BY f.id_factura
ORDER BY f.id_factura;

-- 11. Habitaciones disponibles en un rango de fechas
SELECT h.*
FROM habitacion h
WHERE h.id_habitacion NOT IN (
    SELECT r.id_habitacion
    FROM reservacion r
    WHERE r.fecha_inicio <= '2026-07-15'
      AND r.fecha_fin >= '2026-07-10'
);

-- 12. Huespedes con mayor gasto historico
SELECT
    hu.id_huesped,
    hu.nombre,
    SUM(df.cantidad * df.precio_unitario) AS total_gastado
FROM huesped hu
INNER JOIN estancia e
    ON hu.id_huesped = e.id_huesped
INNER JOIN factura f
    ON e.id_estancia = f.id_estancia
INNER JOIN detalle_factura df
    ON f.id_factura = df.id_factura
GROUP BY hu.id_huesped, hu.nombre
ORDER BY total_gastado DESC;

-- 13. Servicios mas consumidos por tipo de habitacion
SELECT
    th.nombre AS tipo_habitacion,
    s.nombre AS servicio,
    SUM(df.cantidad) AS total_consumido
FROM detalle_factura df
INNER JOIN servicio s
    ON df.id_servicio = s.id_servicio
INNER JOIN factura f
    ON df.id_factura = f.id_factura
INNER JOIN estancia e
    ON f.id_estancia = e.id_estancia
INNER JOIN habitacion h
    ON e.id_habitacion = h.id_habitacion
INNER JOIN tipo_habitacion th
    ON h.id_tipo = th.id_tipo
GROUP BY th.nombre, s.nombre
ORDER BY total_consumido DESC;

-- 14. Tasa de ocupacion mensual por tipo de habitacion
SELECT
    th.nombre AS tipo_habitacion,
    EXTRACT(MONTH FROM e.fecha_checkin) AS mes,
    COUNT(*) AS ocupaciones
FROM estancia e
INNER JOIN habitacion h
    ON e.id_habitacion = h.id_habitacion
INNER JOIN tipo_habitacion th
    ON h.id_tipo = th.id_tipo
GROUP BY th.nombre,
         EXTRACT(MONTH FROM e.fecha_checkin)
ORDER BY mes;

-- 15. Ingresos totales por mes en el ano en curso
SELECT
    EXTRACT(MONTH FROM f.fecha_emision) AS mes,
    SUM(df.cantidad * df.precio_unitario) AS ingresos_totales
FROM factura f
INNER JOIN detalle_factura df
    ON f.id_factura = df.id_factura
WHERE EXTRACT(YEAR FROM f.fecha_emision) =
      EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY EXTRACT(MONTH FROM f.fecha_emision)
ORDER BY mes;


/* ==================================================
   CONSULTAS UPDATE
   ================================================== */

-- 1. Actualizar precio de habitacion Simple
UPDATE tipo_habitacion
SET precio = 60.00
WHERE nombre = 'Simple';

-- 2. Actualizar precio de habitacion Doble
UPDATE tipo_habitacion
SET precio = 90.00
WHERE nombre = 'Doble';

-- 3. Actualizar telefono de empleado
UPDATE empleado
SET telefono = '+503 7999 8888'
WHERE carnet = 'E001';

-- 4. Actualizar email de empleado
UPDATE empleado
SET email = 'rodrigo.nuevo@hotel.com'
WHERE carnet = 'E002';

-- 5. Actualizar pais de huesped
UPDATE huesped
SET pais = 'Canada'
WHERE id_huesped = 1;

-- 6. Actualizar telefono de huesped
UPDATE huesped
SET telefono = '+503 7777 1111'
WHERE id_huesped = 2;

-- 7. Actualizar precio de servicio
UPDATE servicio
SET precio = 18.00
WHERE nombre = 'Room Service';

-- 8. Cambiar estado de habitacion
UPDATE habitacion
SET estado_actual = 'OCUPADA'
WHERE num_habitacion = '100';

-- 9. Actualizar monto inicial de reservacion
UPDATE reservacion
SET monto_inicial = 100.00
WHERE id_reservacion = 1;

-- 10. Actualizar fecha de emision de factura
UPDATE factura
SET fecha_emision = CURRENT_DATE
WHERE id_factura = 1;


/* ==================================================
   CONSULTAS DELETE
   ================================================== */

-- 1. Eliminar un huesped especifico
DELETE FROM huesped
WHERE id_huesped = 10;

-- 2. Eliminar una habitacion especifica
DELETE FROM habitacion
WHERE num_habitacion = '120';

-- 3. Eliminar una reservacion
DELETE FROM reservacion
WHERE id_reservacion = 10;

-- 4. Eliminar un empleado
DELETE FROM empleado
WHERE carnet = 'E010';

-- 5. Eliminar un servicio
DELETE FROM servicio
WHERE nombre = 'Spa Premium';

-- 6. Eliminar huespedes de Honduras
DELETE FROM huesped
WHERE pais = 'Honduras';

-- 7. Eliminar habitaciones disponibles
DELETE FROM habitacion
WHERE estado_actual = 'DISPONIBLE';

-- 8. Eliminar reservaciones con monto inicial menor a 20
DELETE FROM reservacion
WHERE monto_inicial < 20;

-- 9. Eliminar una factura especifica
DELETE FROM factura
WHERE id_factura = 10;

-- 10. Eliminar un tipo de habitacion
DELETE FROM tipo_habitacion
WHERE nombre = 'Suite';