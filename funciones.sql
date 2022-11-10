CREATE TABLE clientes_banco (
    codigo   INT,
    dni      INT NOT NULL, /*TODO ADD CHECKS > 0? MAKE UNIQUE?*/
    telefono VARCHAR(100),
    nombre   VARCHAR(100) NOT NULL,
    direccion VARCHAR(100),
    PRIMARY KEY (codigo)
);
/*
\copy clientes_banco(codigo, dni, telefono, nombre, direccion) FROM './clientes_banco.csv' DELIMITER ',' CSV HEADER;
*/

CREATE TABLE prestamos_banco (
    codigo INT,
    fecha DATE NOT NULL,
    codigo_cliente INT NOT NULL,
    importe INT NOT NULL,
    FOREIGN KEY (codigo_cliente) REFERENCES clientes_banco(codigo) ON DELETE CASCADE, /*ON UPDATE RESTRICT?*/
    PRIMARY KEY (codigo)
);

/*
\copy prestamos_banco(codigo, fecha, codigo_cliente, importe) FROM './prestamos_banco.csv' DELIMITER ',' CSV HEADER;
*/

CREATE TABLE pagos_cuotas (
    nro_cuota INT,        /* TODO: check if not null is necesary*/
    codigo_prestamo INT, /* TODO: check if not null is necesary*/
    importe INT NOT NULL, /* >0 ?*/
    fecha DATE NOT NULL,
    FOREIGN KEY (codigo_prestamo) REFERENCES prestamos_banco(codigo) ON DELETE CASCADE, /*ON UPDATE RESTRICT?*/
    PRIMARY KEY (codigo_prestamo, nro_cuota)
);

/*
\copy pagos_cuotas(nro_cuota, codigo_prestamo, importe, fecha) FROM './pagos_cuotas.csv' DELIMITER ',' CSV HEADER;
*/

CREATE TABLE backup (
    dni                  INT,           -- dni cliente
    nombre               INT,           -- nombre cliente
    telefono             VARCHAR,       -- telefono cliente
    cant_prestamos       INT,           -- cantidad de prestamos otorgados
    monto_prestamos      INT,           -- monto total de prestamos otorgados
    monto_pago_cuotas    INT,           -- monto total de pagos realizados
    ind_pagos_pendientes BOOLEAN,       -- indicador de pagos pentientes (true if monto_prestamos != monto_pago_cuotas)
    PRIMARY KEY (dni)
);