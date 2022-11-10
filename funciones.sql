CREATE TABLE clientes_banco (
    codigo   INT,
    dni      INT,
    telefono varchar(100),
    nombre   VARCHAR(100),
    direccion VARCHAR(100),
    PRIMARY KEY (codigo)
);
/*
\copy clientes_banco(codigo, dni, telefono, nombre, direccion) FROM './clientes_banco.csv' DELIMITER ',' CSV HEADER;
*/

CREATE TABLE prestamos_banco (
    codigo INT,
    fecha DATE,
    codigo_cliente INT,
    importe INT,
    FOREIGN KEY (codigo_cliente) REFERENCES clientes_banco, /* ON DELETE CASCADE ON UPDATE RESTRICT?*/
    PRIMARY KEY (codigo)
);

/*
\copy prestamos_banco(codigo, fecha, codigo_cliente, importe) FROM './prestamos_banco.csv' DELIMITER ',' CSV HEADER;
*/

CREATE TABLE pagos_cuotas (
    nro_cuota INT,
    codigo_prestamo INT,
    importe INT,
    fecha DATE,
    FOREIGN KEY (codigo_prestamo) REFERENCES prestamos_banco,
    PRIMARY KEY (fecha, codigo_prestamo, nro_cuota) /* TODO: revisar */
);

/*
\copy pagos_cuotas(nro_cuota, codigo_prestamo, importe, fecha) FROM './pagos_cuotas.csv' DELIMITER ',' CSV HEADER;
*/
