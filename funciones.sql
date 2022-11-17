-- ========== A ==========
-- Crear las tablas que alojaran los datos de los archivos

-- Tabla 1 clientes_banco
CREATE TABLE IF NOT EXISTS clientes_banco (
    codigo      INT,
    dni         INT UNIQUE NOT NULL CHECK ( dni > 0 ),
    telefono    TEXT,
    nombre      TEXT NOT NULL,
    direccion   TEXT,
    PRIMARY KEY (codigo)
);

-- Tabla 2 prestamos_banco
CREATE TABLE IF NOT EXISTS prestamos_banco (
    codigo          INT,
    fecha           DATE NOT NULL CHECK ( fecha <= CURRENT_DATE ),
    codigo_cliente  INT NOT NULL,
    importe         DECIMAL NOT NULL CHECK ( importe > 0 ),
    FOREIGN KEY (codigo_cliente) REFERENCES clientes_banco(codigo) ON DELETE CASCADE,
    PRIMARY KEY (codigo)
);

-- Tabla 3 pagos_cuotas
CREATE TABLE IF NOT EXISTS pagos_cuotas (
    nro_cuota       INT,
    codigo_prestamo INT,
    importe         DECIMAL NOT NULL CHECK ( importe > 0 ),
    fecha           DATE NOT NULL CHECK ( fecha <= CURRENT_DATE ),
    FOREIGN KEY (codigo_prestamo) REFERENCES prestamos_banco(codigo) ON DELETE CASCADE,
    PRIMARY KEY (codigo_prestamo, nro_cuota)
);

-- ========== B ==========
-- Crear la tabla de backup que permitira preservar la informacion que se perderia
-- ante la eliminacion de tuplas de la entidad dominante

-- Tabla 4 backup
CREATE TABLE IF NOT EXISTS backup (
    dni                  INT CHECK ( dni > 0 ),                     -- dni cliente
    nombre               TEXT NOT NULL,                             -- nombre cliente
    telefono             TEXT,                                      -- telefono cliente
    cant_prestamos       INT CHECK ( cant_prestamos >= 0 ),         -- cantidad de prestamos otorgados
    monto_prestamos      DECIMAL CHECK ( monto_prestamos >= 0 ),    -- monto total de prestamos otorgados
    monto_pago_cuotas    DECIMAL CHECK ( monto_pago_cuotas >= 0 ),  -- monto total de pagos realizados
    ind_pagos_pendientes BOOLEAN NOT NULL,                          -- indicador de pagos pentientes (true if monto_prestamos > monto_pago_cuotas)
    PRIMARY KEY (dni)
);

-- ========== C ==========
-- Importar los datos y cargar las tablas correspondientes

-- Load using `psql -h bd1.it.itba.edu.ar -U <user> PROOF` inside pampero in the directory <dir>
-- get the .csv files to pampero by using `scp *.csv <user>@pampero.itba.edu.ar:<dir>`
-- after loading the files and running `psql` run the following 3 lines inside the console
-- \COPY clientes_banco(codigo, dni, telefono, nombre, direccion) FROM './clientes_banco.csv' DELIMITER ',' CSV HEADER;
-- \COPY prestamos_banco(codigo, fecha, codigo_cliente, importe) FROM './prestamos_banco.csv' DELIMITER ',' CSV HEADER;
-- \COPY pagos_cuotas(nro_cuota, codigo_prestamo, importe, fecha) FROM './pagos_cuotas.csv' DELIMITER ',' CSV HEADER;

-- ========== D ==========
-- Interceptar el evento de borrado de la tabla de clientes
-- para hacer un backup de la informacion relevante

-- trigger function to save data in the backup table
CREATE OR REPLACE FUNCTION backup_before_delete_client() RETURNS TRIGGER AS $$
DECLARE
    prestamos_banco_cursor   CURSOR FOR SELECT * FROM prestamos_banco WHERE codigo_cliente = OLD.codigo;
    prestamo_banco           RECORD;
    cant_prestamos_aux       INT;
    monto_prestamos_aux      DECIMAL;
    monto_pago_cuotas_aux    DECIMAL;
    ind_pagos_pendientes_aux BOOLEAN;
BEGIN
    cant_prestamos_aux := 0;
    monto_prestamos_aux := 0;
    monto_pago_cuotas_aux := 0;

    FOR prestamo_banco IN prestamos_banco_cursor LOOP
        cant_prestamos_aux := cant_prestamos_aux + 1;
        monto_prestamos_aux := monto_prestamos_aux + prestamo_banco.importe;
        monto_pago_cuotas_aux := monto_pago_cuotas_aux + (SELECT COALESCE(SUM(importe), 0.0) FROM pagos_cuotas WHERE codigo_prestamo = prestamo_banco.codigo);
    END LOOP;

    ind_pagos_pendientes_aux := (monto_prestamos_aux > monto_pago_cuotas_aux);

    INSERT INTO backup (dni, nombre, telefono, cant_prestamos, monto_prestamos, monto_pago_cuotas, ind_pagos_pendientes)
    VALUES (OLD.dni, OLD.nombre, OLD.telefono, cant_prestamos_aux, monto_prestamos_aux, monto_pago_cuotas_aux, ind_pagos_pendientes_aux);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- trigger to call function before deleting a client
CREATE TRIGGER backup_before_delete_client
    BEFORE DELETE ON clientes_banco                     -- before deleting on the client table
    FOR EACH ROW                                        -- for every deleted row
    EXECUTE PROCEDURE backup_before_delete_client();    -- execute backup

-- TESTING - CHECKING TRIGGER WORK COMPARING WITH THE TASK EXAMPLE
/*
DELETE FROM clientes_banco WHERE codigo = 1;
DELETE FROM clientes_banco WHERE codigo = 2;
DELETE FROM clientes_banco WHERE codigo = 4;
DELETE FROM clientes_banco WHERE codigo = 5;
DELETE FROM clientes_banco WHERE codigo = 36;
DELETE FROM clientes_banco WHERE codigo = 37;
*/


-- TESTING - CLEANUP
/*
DROP TRIGGER  IF EXISTS backup_before_delete_client ON clientes_banco;
DROP FUNCTION IF EXISTS backup_before_delete_client();
DROP TABLE    IF EXISTS backup;
DROP TABLE    IF EXISTS pagos_cuotas;
DROP TABLE    IF EXISTS prestamos_banco;
DROP TABLE    IF EXISTS clientes_banco;
*/