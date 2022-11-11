CREATE TABLE IF NOT EXISTS clientes_banco (
    codigo      INT,
    dni         INT UNIQUE NOT NULL CHECK ( dni > 0 ),
    telefono    VARCHAR(100),
    nombre      VARCHAR(100) NOT NULL,
    direccion   VARCHAR(100),
    PRIMARY KEY (codigo)
);

CREATE TABLE IF NOT EXISTS prestamos_banco (
    codigo          INT,
    fecha           DATE NOT NULL,
    codigo_cliente  INT NOT NULL,
    importe         INT NOT NULL CHECK ( importe > 0 ),
    FOREIGN KEY (codigo_cliente) REFERENCES clientes_banco(codigo) ON DELETE CASCADE, /*ON UPDATE RESTRICT?*/
    PRIMARY KEY (codigo)
);

CREATE TABLE IF NOT EXISTS pagos_cuotas (
    nro_cuota       INT,            /* TODO: check if not null is necesary*/
    codigo_prestamo INT,            /* TODO: check if not null is necesary*/
    importe         INT NOT NULL CHECK ( importe > 0 ),
    fecha           DATE NOT NULL,
    FOREIGN KEY (codigo_prestamo) REFERENCES prestamos_banco(codigo) ON DELETE CASCADE, /*ON UPDATE RESTRICT?*/
    PRIMARY KEY (codigo_prestamo, nro_cuota)
);

-- Load using `psql -h bd1.it.itba.edu.ar -U <user> PROOF` inside pampero in the directory <dir>
-- get the .csv files to pampero by using `scp *.csv <user>@pampero.itba.edu.ar:<dir>`
-- after loading the files and running `psql` run the following 3 lines inside the console
-- \COPY clientes_banco(codigo, dni, telefono, nombre, direccion) FROM './clientes_banco.csv' DELIMITER ',' CSV HEADER;
-- \COPY prestamos_banco(codigo, fecha, codigo_cliente, importe) FROM './prestamos_banco.csv' DELIMITER ',' CSV HEADER;
-- \COPY pagos_cuotas(nro_cuota, codigo_prestamo, importe, fecha) FROM './pagos_cuotas.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE IF NOT EXISTS backup (
    dni                  INT CHECK ( dni > 0 ), -- dni cliente
    nombre               VARCHAR,               -- nombre cliente
    telefono             VARCHAR,               -- telefono cliente
    cant_prestamos       INT,                   -- cantidad de prestamos otorgados
    monto_prestamos      INT,                   -- monto total de prestamos otorgados
    monto_pago_cuotas    INT,                   -- monto total de pagos realizados
    ind_pagos_pendientes BOOLEAN,               -- indicador de pagos pentientes (true if monto_prestamos > monto_pago_cuotas)
    PRIMARY KEY (dni)
);

-- trigger function to save data in the backup table
CREATE OR REPLACE FUNCTION backup_before_delete_client() RETURNS TRIGGER AS $$
DECLARE
    monto_prestamos_aux      INT;
    monto_pago_cuotas_aux    INT;
    cant_prestamos_aux       INT;
    ind_pagos_pendientes_aux BOOLEAN;
BEGIN
    monto_prestamos_aux := (SELECT SUM(importe) FROM prestamos_banco WHERE codigo_cliente = OLD.codigo);
    monto_pago_cuotas_aux := (SELECT COALESCE(SUM(importe), 0) FROM pagos_cuotas WHERE codigo_prestamo IN (SELECT codigo FROM prestamos_banco WHERE codigo_cliente = OLD.codigo));
    cant_prestamos_aux := (SELECT COUNT(*) FROM prestamos_banco WHERE codigo_cliente = OLD.codigo);
    ind_pagos_pendientes_aux := (monto_prestamos_aux > monto_pago_cuotas_aux);

    INSERT INTO backup (dni, nombre, telefono, cant_prestamos, monto_prestamos, monto_pago_cuotas, ind_pagos_pendientes)
    VALUES (OLD.dni, OLD.nombre, OLD.telefono, cant_prestamos_aux, monto_prestamos_aux, monto_pago_cuotas_aux, ind_pagos_pendientes_aux);
    RETURN OLD; -- TODO: revisar
END;
$$ LANGUAGE plpgsql;

-- trigger to call function before deleting a client
CREATE TRIGGER backup_before_delete_client
    BEFORE DELETE ON clientes_banco                     -- before deleting on the client table
    FOR EACH ROW                                        -- for every deleted row
    EXECUTE PROCEDURE backup_before_delete_client();    -- execute backup

-- TESTING - CHECKING TRIGGER WORK COMPARING WITH THE TASK EXAMPLE
DELETE FROM clientes_banco WHERE codigo = 1;
DELETE FROM clientes_banco WHERE codigo = 2;
DELETE FROM clientes_banco WHERE codigo = 4;
DELETE FROM clientes_banco WHERE codigo = 5;
DELETE FROM clientes_banco WHERE codigo =  36;
DELETE FROM clientes_banco WHERE codigo =  37;


-- TESTING - CLEANUP
DROP TRIGGER  IF EXISTS backup_before_delete_client ON clientes_banco;
DROP FUNCTION IF EXISTS backup_before_delete_client();
DROP TABLE    IF EXISTS backup;
DROP TABLE    IF EXISTS pagos_cuotas;
DROP TABLE    IF EXISTS prestamos_banco;
DROP TABLE    IF EXISTS clientes_banco;
