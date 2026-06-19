--------------------------------------------
-- TABLAS PRINCIPALES
--------------------------------------------

-- Tipo de habitacion

create table tipo_habitacion (
id_tipo bigint generated always as identity,
nombre VARCHAR(80) not null,
descripcion TEXT,
precio numeric(10,2) NOT NULL,
constraint pk_tipo_habitacion primary key (id_tipo),
constraint uq_nombre unique (nombre),
constraint ck_precio_tipo_habitacion check (precio > 0)
);

-- Huesped
create table huesped (
id_huesped bigint generated always as identity,
nombre VARCHAR(150) not null,
email VARCHAR(100),
telefono VARCHAR(20),
pais VARCHAR(50),
constraint pk_huesped primary key (id_huesped),
constraint ck_email_huesped check (email like '%@%.%'),
constraint uq_email_huesped unique (email)
);

-- Empleado
CREATE TABLE empleado (
carnet CHAR(5),
nombre VARCHAR(100) not null,
telefono VARCHAR(20),
email VARCHAR(100),
constraint pk_empleado primary key (carnet),
constraint uq_email_empleado unique (email),
constraint ck_email_empleado check (email like '%@%.%')
);

--servicio
create table servicio (
id_servicio bigint generated always as identity,
nombre varchar(150) not null,
descripcion text,
precio numeric(10,2) not null,
constraint pk_servicio primary key (id_servicio),
constraint ck_precio_servicio check (precio > 0)
);

-- Habitacion
CREATE TABLE habitacion (
id_habitacion bigint generated always as identity,
num_habitacion varchar(10) not null,
estado_actual VARCHAR(20) default 'DISPONIBLE' not null,
piso int not null,
id_tipo bigint not null,
constraint pk_habitacion primary key (id_habitacion),
constraint fk_id_tipo_habitacion foreign key (id_tipo) references tipo_habitacion (id_tipo) on delete restrict on update cascade,
constraint ck_estado_habitacion check (estado_actual in ('DISPONIBLE', 'OCUPADA')),
constraint uq_num_habitacion unique(num_habitacion)
);

--reservacion
create table reservacion (
id_reservacion bigint generated always as identity,
fecha_inicio date not null,
fecha_fin date not null,
monto_inicial numeric (10,2) not null,
fecha_reserva timestamp not null default current_timestamp,
carnet char(5) not null,
id_huesped bigint not null,
id_tipo bigint not null,
constraint pk_reservacion primary key (id_reservacion),
constraint fk_carnet foreign key (carnet) references empleado(carnet) on update cascade on delete restrict,
constraint fk_id_huesped_reservacion foreign key (id_huesped) references huesped(id_huesped) on update cascade on delete restrict,
constraint fk_id_tipo_reservacion foreign key (id_tipo) references tipo_habitacion(id_tipo) on update cascade on delete restrict,
constraint ck_fechas_reservacion check (fecha_fin > fecha_inicio ),
constraint ck_monto_inicial check (monto_inicial >= 0)
);

--estancia
create table estancia (
id_estancia bigint generated always as identity,
fecha_checkin date not null,
hora_llegada time not null,
fecha_checkout date,
hora_salida time,
id_habitacion bigint not null,
id_reservacion bigint not null,
constraint pk_estancia primary key (id_estancia),
constraint fk_id_habitacion_estancia foreign key (id_habitacion) references habitacion(id_habitacion) on update cascade on delete restrict,
constraint fk_id_reservacion_estancia foreign key (id_reservacion) references reservacion(id_reservacion) on update cascade on delete restrict,
--una reservacion genera una unica estancia
constraint uq_estancia_reservacion unique(id_reservacion),
constraint ck_fechas_estancia check (fecha_checkout is null or  fecha_checkout >= fecha_checkin)
);

--consumo de servicio
create table consumo_servicio (
id_consumo bigint generated always as identity,
fecha_consumo date not null default current_date ,
cantidad int not null,
precio_unitario numeric(10,2) not null,
id_servicio bigint not null,
id_estancia bigint not null,
constraint pk_consumo_servicio primary key (id_consumo),
constraint fk_id_servicio foreign key (id_servicio) references servicio (id_servicio) on update cascade on delete restrict,
constraint fk_id_estancia_consumo foreign key (id_estancia) references estancia (id_estancia) on update cascade on delete restrict,
constraint ck_cantidad_consumo check (cantidad > 0),
constraint ck_precio_unitario_consumo check (precio_unitario > 0)
);

--factura
create table factura (
id_factura bigint generated always as identity,
fecha_emision timestamp not null default current_timestamp,
id_estancia bigint not null,
constraint pk_id_factura primary key (id_factura),
constraint fk_id_estancia_factura foreign key (id_estancia) references estancia(id_estancia) on update cascade on delete restrict,
--una estancia solo tendra una factura
constraint uq_id_estancia unique (id_estancia)
);

--detalle factura
create table detalle_factura(
id_detalle bigint generated always as identity,
cantidad int not null,
precio_unitario numeric(10,2) not null,
id_factura bigint not null,
id_servicio bigint not null,
constraint pk_id_detalle primary key (id_detalle),
constraint fk_id_factura_detalle foreign key (id_factura) references factura(id_factura) on update cascade on delete restrict,
constraint fk_id_servicio_detalle foreign key (id_servicio) references servicio(id_servicio) on update cascade on delete restrict,
constraint ck_cantidad_detalle check (cantidad > 0),
constraint ck_precio_unitario_detalle check (precio_unitario > 0)
);


