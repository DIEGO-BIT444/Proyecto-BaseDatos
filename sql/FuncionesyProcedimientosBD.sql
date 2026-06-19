
-- =============================================================
-- FUNCIONES 
-- =============================================================

-- 1 funcion para obtener el id de la habitacion de la estancia
create or replace function fn_obtener_habitacion_est(p_id_estancia bigint)
returns bigint 
language plpgsql
as $$
declare 
v_id_habitacion bigint;
begin
-- busca la habitacion al numero de estancia
	select id_habitacion into v_id_habitacion
	from estancia 
	where id_estancia = p_id_estancia;

-- si la variable es null, el id no existe
if v_id_habitacion is null then 

raise exception 'La estancia con ID % no existe. ', p_id_estancia;
end if;
return v_id_habitacion;
end;
$$ ;


-- 2 funcion para verificar si ya fue facturada la estancia
create or replace function fn_validar_factura_p(p_id_estancia bigint)
returns void 
language plpgsql
as $$
declare 
v_existe_factura int;
begin 
-- cuenta cuantas facturas se imitieron por id estancia
	select count(*) into v_existe_factura
	from factura 
	where id_estancia = p_id_estancia;

-- si es mayo a 0 el cliente ya pago 
if v_existe_factura > 0 then

raise exception 'La estancia % ya tiene una factura emitida. ', p_id_estancia;
end if;
end;
$$;


-- 3 funcion para calcular el total de la estancia
create or replace function fn_calcular_total_estancia(p_id_estancia bigint)
returns numeric(10,2)
language plpgsql
as $$
declare
    v_fecha_inicio date;
    v_precio_habitacion numeric(10,2);
    v_dias_estancia int;
    v_total_habitacion numeric(10,2) := 0;
    v_total_servicios numeric(10,2) := 0;

begin
    -- Obtener datos de hospedaje de estancia y reserva 
    select r.fecha_inicio, th.precio
    into v_fecha_inicio, v_precio_habitacion
    from estancia e
    join reservacion r on e.id_reservacion = r.id_reservacion
    join habitacion h on e.id_habitacion = h.id_habitacion
    join tipo_habitacion th on h.id_tipo = th.id_tipo
    where e.id_estancia = p_id_estancia;

    -- Calcular costo por días de habitación
    v_dias_estancia := current_date - v_fecha_inicio;
    if v_dias_estancia <= 0 then
        v_dias_estancia := 1;
    end if;
    v_total_habitacion := v_dias_estancia * v_precio_habitacion;

    --  Calcular lo consumido usando id_estancia
    select coalesce(sum(cantidad * precio_unitario), 0) into v_total_servicios
    from consumo_servicio
    where id_estancia = p_id_estancia;

    return v_total_habitacion + v_total_servicios;
end;
$$;

--=====================================================================================
-- PROCEDIMIENTOS
--=====================================================================================

-- 4 procedimiento para registrar fecha de salida y cambiar estado de habitacion
create or replace procedure pr_registrar_salida(p_id_estancia bigint, p_id_habitacion bigint)
language plpgsql
as $$
 begin
 	-- finalizacion de la estancia (checkout)
	 update estancia
	 set fecha_checkout = current_date,
	     hora_salida = current_time
	     where id_estancia = p_id_estancia;

-- cambio de estado la habitacion a disponible
update habitacion
set estado_actual = 'DISPONIBLE'
where id_habitacion = p_id_habitacion;
 end;
$$;

-- 5 procedimiento para generar la factura y detalle
create or replace procedure pr_generar_factura(p_id_estancia bigint)
language plpgsql
as $$
declare
    v_id_factura bigint;
    v_monto_total numeric(10,2);
begin
    -- Insertar en factura sin monto_total 
    insert into factura (id_estancia, fecha_emision)
    values (p_id_estancia, current_timestamp)
    returning id_factura into v_id_factura;

    -- detalle  consumido a la factura
    insert into detalle_factura (cantidad, precio_unitario, id_factura, id_servicio)
    select cantidad, precio_unitario, v_id_factura, id_servicio
    from consumo_servicio
    where id_estancia = p_id_estancia;

    -- Calcular el total 
    v_monto_total := fn_calcular_total_estancia(p_id_estancia);

    raise notice 'FACTURA Nº % EMITIDA CON ÉXITO | TOTAL A COBRAR: $% ', v_id_factura, v_monto_total;
end;
$$;


-- 6 procesar el checkout  del huesped (depende de todas la funciones y procedimientos)
create or replace procedure pr_procesar_checkout(p_id_estancia bigint)
language plpgsql
as $$
declare 
v_id_habitacion bigint;
begin
-- funcion de validar datos 
v_id_habitacion := fn_obtener_habitacion_est(p_id_estancia);
perform fn_validar_factura_p(p_id_estancia);

-- registra la salida y libera habitacion
call pr_registrar_salida(p_id_estancia, v_id_habitacion);

-- genera la factura y el detalle a cobrar
call pr_generar_factura(p_id_estancia);
raise notice 'procedimiento exitoso: estancia % fue ejecutada correctamente. ', p_id_estancia;
end;
$$;


-- =======================================================================
-- PRUEBA PARA FACTURA 
--========================================================================

insert into consumo_servicio (cantidad, precio_unitario, id_servicio, id_estancia)
values (2, 15.50, 2, 37);

insert into consumo_servicio (cantidad, precio_unitario, id_servicio, id_estancia)
values (1, 10.00, 1, 37);

CALL pr_procesar_checkout(37);

select fn_calcular_total_estancia(37);


-- verifica que la habitacion halla cambiado de estado
select id_habitacion, estado_actual 
from habitacion 
where id_habitacion = (select  id_habitacion from estancia where id_estancia = 37);



-- ======================================================================================
-- TRIGGER CHECKIN 
-- ======================================================================================

-- funcion de trigger para checkin
create or replace function fn_tgr_ocupar_habitacion()
returns trigger
language plpgsql
as $$
begin
update habitacion
set estado_actual = 'OCUPADA'
where id_habitacion = new.id_habitacion;

return new;
 end;
$$;

-- eliminar el trigger
drop trigger if exists tgr_checkin on estancia;

-- disparador
create trigger tgr_checkin
after insert on estancia
for each row
execute function fn_tgr_ocupar_habitacion();


-- =====================================================================
-- PRUEBA DISPARADOR 
-- =====================================================================

insert into reservacion (fecha_inicio, fecha_fin, monto_inicial, carnet, id_huesped, id_tipo)
values ('2026-07-20', '2026-07-25', '0.00', 'E002', 78, 2);

select id_reservacion, id_huesped, id_tipo 
from reservacion 
where id_huesped = 78;

insert into estancia (fecha_checkin, hora_llegada, id_habitacion, id_reservacion)
values ('2026-07-20', '13:00:00', 4, 40);


--************************************************************************
insert into reservacion (fecha_inicio, fecha_fin, monto_inicial, carnet, id_huesped, id_tipo)
values ('2026-06-18', '2026-06-19', '0.00', 'E003', 73, 1);

select id_reservacion, id_huesped, id_tipo 
from reservacion 
where id_huesped = 73;

insert into estancia (fecha_checkin, hora_llegada, id_habitacion, id_reservacion)
values ('2026-06-18', '10:00:00', 4, 44);

SELECT id_habitacion, estado_actual 
FROM habitacion 
WHERE id_habitacion = 4;

--**********************************************************************************



-- ========================================================================================
-- TRIGGER CHECKOUT 
-- ========================================================================================

-- funcion para el trigger de checkout
create or replace function fn_trg_disponibilidad()
returns trigger
language plpgsql
as $$
declare v_habitacion_total int;
v_habitacion_reserva int;
begin 
-- total de habitaciones existentes de un tipo
select count(*) into v_habitacion_total
from habitacion 
where id_tipo = new.id_tipo;

--contar los tipo de habitacion que ya estan reservadas
select count(*) into v_habitacion_reserva 
from reservacion
where id_tipo = new.id_tipo
and not(fecha_fin <= new.fecha_inicio or fecha_inicio >= new.fecha_fin);

if v_habitacion_reserva >= v_habitacion_total then
raise exception 'No hay habitaciones disponibles del tipo % para el periodo entre % y el %',
new.id_tipo, new.fecha_inicio, new.fecha_fin;
end if;
return new;
end;
$$;

-- disparador
create trigger trg_verificar_reserva_fecha
before insert on reservacion
for each row 
execute function fn_trg_disponibilidad();

-- ==========================================================================
-- PRUEBA DE DISPARADOR
--===========================================================================

-- prueba disparador 
insert into reservacion (fecha_inicio, fecha_fin, monto_inicial, carnet, id_huesped, id_tipo)
values ('2026-08-18', '2026-08-19', '0.00', 'E005', 94, 4);









