-- ============================================================================
-- SISTEMA TKR — MOTOR DE PRUEBAS AUTOMATIZADAS & TELEMETRÍA (JSON IN/OUT)
-- TOTAL: 11 TABLAS (ESQUEMA MONO-TENANT / SIN ID_TENANT)
--
-- Prefijo Oficial de Tablas : tkr_
-- Convención de Claves Foráneas: id_<tabla_referenciada>
-- Estándar de Fechas        : Tipo DATE con hora oficial de Bogotá (America/Bogota)
-- Expresión Default         : CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE)
-- Estándar Booleano / Flags : Tipo NUMBER(1) con valores (0, 1) y CHECK constraints
-- Triggers Autonuméricos    : TRG_BI_<TABLA> asignando :new.id := <tabla>_seq.NEXTVAL si es NULL
-- Validación JSON           : Restricciones IS JSON (LAX) en payloads CLOB
-- ============================================================================

-- ============================================================================
-- SECCIÓN 1: MOTOR DE PRUEBAS DE OBJETOS PL/SQL (7 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 1/11: TKR_TEST_SUITE
-- Agrupación lógica de pruebas (Suites de Regresión, Smoke Tests, Seguridad)
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_test_suite (
    id NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12),
    codigo VARCHAR2(50) NOT NULL,
    nombre VARCHAR2(255) NOT NULL,
    descripcion VARCHAR2(1000),
    tipo_suite VARCHAR2(50) DEFAULT 'UNITARIA',
    es_activo NUMBER(1) DEFAULT 1 CHECK (es_activo IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_test_suite PRIMARY KEY (id),
    CONSTRAINT uk_tkr_test_suite_cod UNIQUE (codigo),
    CONSTRAINT ck_tkr_test_suite_tipo CHECK (tipo_suite IN ('UNITARIA', 'INTEGRACION', 'REGRESION', 'SMOKE', 'SEGURIDAD'))
);
CREATE SEQUENCE tkr_test_suite_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_tkr_test_suite
BEFORE INSERT ON tkr_test_suite
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_test_suite_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_test_suite IS 'Agrupación lógica de pruebas (Suites de Regresión, Smoke Tests, Módulo de Autenticación)';
COMMENT ON COLUMN tkr_test_suite.id IS 'Identificador único de la suite de pruebas (PK)';
COMMENT ON COLUMN tkr_test_suite.id_aplicacion IS 'Identificador de la aplicación evaluada por la suite';
COMMENT ON COLUMN tkr_test_suite.codigo IS 'Código nemotécnico (SUITE_SMOKE, SUITE_AUTH_TEST)';
COMMENT ON COLUMN tkr_test_suite.nombre IS 'Nombre representativo de la suite de pruebas';
COMMENT ON COLUMN tkr_test_suite.descripcion IS 'Objetivo y cobertura funcional evaluada';
COMMENT ON COLUMN tkr_test_suite.tipo_suite IS 'Categoría: UNITARIA, INTEGRACION, REGRESION, SMOKE, SEGURIDAD';
COMMENT ON COLUMN tkr_test_suite.es_activo IS 'Bandera de ejecución activa: 1=Habilitada, 0=Pausada';
COMMENT ON COLUMN tkr_test_suite.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN tkr_test_suite.fecha_creacion IS 'Fecha y hora de configuración de la suite (hora Bogotá)';
COMMENT ON COLUMN tkr_test_suite.fecha_modificacion IS 'Fecha y hora de última edición de la suite (hora Bogotá)';


-- ----------------------------------------------------------------------------
-- TABLA 2/11: TKR_TEST_OBJETO
-- Catálogo de procedimientos y funciones PL/SQL invocables con firma estándar JSON
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_test_objeto (
    id NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12),
    id_modulo NUMBER(12),
    esquema VARCHAR2(30) DEFAULT USER,
    nombre_paquete VARCHAR2(60) NOT NULL,
    nombre_metodo VARCHAR2(60) NOT NULL,
    tipo_objeto VARCHAR2(30) DEFAULT 'PROCEDURE',
    tipo_invocacion VARCHAR2(30) DEFAULT 'JSON_IN_OUT',
    param_entrada_nombre VARCHAR2(30) DEFAULT 'p_json_entrada',
    param_salida_nombre VARCHAR2(30) DEFAULT 'p_json_salida',
    descripcion VARCHAR2(1000),
    json_schema_entrada CLOB,
    json_schema_salida CLOB,
    ejemplo_json_entrada CLOB,
    requiere_transaccion NUMBER(1) DEFAULT 1 CHECK (requiere_transaccion IN (0, 1)),
    es_activo NUMBER(1) DEFAULT 1 CHECK (es_activo IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_test_objeto PRIMARY KEY (id),
    CONSTRAINT uk_tkr_test_objeto UNIQUE (esquema, nombre_paquete, nombre_metodo),
    CONSTRAINT ck_tkr_test_obj_tipo CHECK (tipo_objeto IN ('PROCEDURE', 'FUNCTION', 'PACKAGE_BODY')),
    CONSTRAINT ck_tkr_test_schema_in CHECK (json_schema_entrada IS NULL OR json_schema_entrada IS JSON (LAX)),
    CONSTRAINT ck_tkr_test_schema_out CHECK (json_schema_salida IS NULL OR json_schema_salida IS JSON (LAX)),
    CONSTRAINT ck_tkr_test_ejemplo_in CHECK (ejemplo_json_entrada IS NULL OR ejemplo_json_entrada IS JSON (LAX))
);
CREATE SEQUENCE tkr_test_objeto_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_tkr_test_obj_pkg ON tkr_test_objeto(nombre_paquete, nombre_metodo);

CREATE OR REPLACE TRIGGER trg_bi_tkr_test_objeto
BEFORE INSERT ON tkr_test_objeto
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_test_objeto_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_test_objeto IS 'Catálogo de procedimientos y funciones PL/SQL invocables desde el frontend con firma estándar JSON';
COMMENT ON COLUMN tkr_test_objeto.id IS 'Identificador único del objeto en el catálogo de pruebas (PK)';
COMMENT ON COLUMN tkr_test_objeto.id_aplicacion IS 'Identificador de la aplicación a la que pertenece el endpoint';
COMMENT ON COLUMN tkr_test_objeto.id_modulo IS 'Identificador del módulo funcional de pertenencia del procedimiento';
COMMENT ON COLUMN tkr_test_objeto.esquema IS 'Esquema de Oracle donde reside el objeto (por defecto USER)';
COMMENT ON COLUMN tkr_test_objeto.nombre_paquete IS 'Nombre del paquete PL/SQL orquestador (pkgln_usuarios, pkgln_citas)';
COMMENT ON COLUMN tkr_test_objeto.nombre_metodo IS 'Nombre del procedimiento expuesto (p_crear_usuario, p_iniciar_sesion)';
COMMENT ON COLUMN tkr_test_objeto.tipo_objeto IS 'Tipo de objeto: PROCEDURE, FUNCTION, PACKAGE_BODY';
COMMENT ON COLUMN tkr_test_objeto.tipo_invocacion IS 'Mecanismo de interfaz: JSON_IN_OUT (estándar frontend)';
COMMENT ON COLUMN tkr_test_objeto.param_entrada_nombre IS 'Nombre del parámetro formal CLOB de entrada (estándar: p_json_entrada)';
COMMENT ON COLUMN tkr_test_objeto.param_salida_nombre IS 'Nombre del parámetro formal CLOB de salida (estándar: p_json_salida)';
COMMENT ON COLUMN tkr_test_objeto.descripcion IS 'Explicación del caso de uso y propósito del subprograma PL/SQL';
COMMENT ON COLUMN tkr_test_objeto.json_schema_entrada IS 'Definición formal JSON Schema para validar la estructura esperada de entrada';
COMMENT ON COLUMN tkr_test_objeto.json_schema_salida IS 'Definición formal JSON Schema para validar la estructura de respuesta';
COMMENT ON COLUMN tkr_test_objeto.ejemplo_json_entrada IS 'Payload JSON de ejemplo listo para ser inyectado en pruebas manuales';
COMMENT ON COLUMN tkr_test_objeto.requiere_transaccion IS 'Indica si ejecuta p_do_commit controlado: 1=Sí, 0=Solo consulta';
COMMENT ON COLUMN tkr_test_objeto.es_activo IS 'Bandera de disponibilidad para el runner: 1=Habilitado, 0=Inactivo';
COMMENT ON COLUMN tkr_test_objeto.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN tkr_test_objeto.fecha_creacion IS 'Fecha y hora de registro del objeto en el catálogo (hora Bogotá)';
COMMENT ON COLUMN tkr_test_objeto.fecha_modificacion IS 'Fecha y hora de última modificación del objeto (hora Bogotá)';


-- ----------------------------------------------------------------------------
-- TABLA 3/11: TKR_TEST_CASO
-- Escenarios y casos de prueba individuales con payloads CLOB
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_test_caso (
    id NUMBER(12) NOT NULL,
    id_objeto NUMBER(12) NOT NULL,
    id_suite NUMBER(12),
    codigo_caso VARCHAR2(50) NOT NULL,
    nombre VARCHAR2(255) NOT NULL,
    descripcion VARCHAR2(1000),
    categoria VARCHAR2(50) DEFAULT 'HAPPY_PATH',
    orden_ejecucion NUMBER(5) DEFAULT 1,
    json_entrada CLOB NOT NULL,
    json_esperado CLOB,
    codigo_error_esperado NUMBER(6) DEFAULT 0,
    tiempo_max_ms NUMBER(8) DEFAULT 5000,
    es_activo NUMBER(1) DEFAULT 1 CHECK (es_activo IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_test_caso PRIMARY KEY (id),
    CONSTRAINT fk_tkr_test_cas_objeto FOREIGN KEY (id_objeto) REFERENCES tkr_test_objeto(id),
    CONSTRAINT fk_tkr_test_cas_suite FOREIGN KEY (id_suite) REFERENCES tkr_test_suite(id),
    CONSTRAINT uk_tkr_test_caso_cod UNIQUE (id_objeto, codigo_caso),
    CONSTRAINT ck_tkr_test_caso_cat CHECK (categoria IN ('HAPPY_PATH', 'ERROR_VALIDACION', 'ERROR_NEGOCIO', 'EDGE_CASE', 'SEGURIDAD', 'STRESS')),
    CONSTRAINT ck_tkr_test_caso_in_json CHECK (json_entrada IS JSON (LAX)),
    CONSTRAINT ck_tkr_test_caso_exp_json CHECK (json_esperado IS NULL OR json_esperado IS JSON (LAX))
);
CREATE SEQUENCE tkr_test_caso_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_tkr_test_caso_obj ON tkr_test_caso(id_objeto, orden_ejecucion);

CREATE OR REPLACE TRIGGER trg_bi_tkr_test_caso
BEFORE INSERT ON tkr_test_caso
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_test_caso_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_test_caso IS 'Escenarios y casos de prueba individuales con inyección de p_json_entrada y resultado esperado';
COMMENT ON COLUMN tkr_test_caso.id IS 'Identificador único del caso de prueba (PK)';
COMMENT ON COLUMN tkr_test_caso.id_objeto IS 'Objeto o procedimiento PL/SQL bajo prueba (FK a tkr_test_objeto)';
COMMENT ON COLUMN tkr_test_caso.id_suite IS 'Suite a la que pertenece el caso (FK a tkr_test_suite, opcional)';
COMMENT ON COLUMN tkr_test_caso.codigo_caso IS 'Código único del caso (TC_AUTH_001, TC_USR_EMAIL)';
COMMENT ON COLUMN tkr_test_caso.nombre IS 'Nombre descriptivo del escenario de prueba';
COMMENT ON COLUMN tkr_test_caso.descripcion IS 'Premisas, datos inyectados y comportamiento esperado';
COMMENT ON COLUMN tkr_test_caso.categoria IS 'Tipo: HAPPY_PATH, ERROR_VALIDACION, ERROR_NEGOCIO, EDGE_CASE, SEGURIDAD, STRESS';
COMMENT ON COLUMN tkr_test_caso.orden_ejecucion IS 'Secuencia de invocación dentro de la batería de pruebas';
COMMENT ON COLUMN tkr_test_caso.json_entrada IS 'Payload CLOB inyectado directamente en el parámetro p_json_entrada';
COMMENT ON COLUMN tkr_test_caso.json_esperado IS 'Payload CLOB modelo de salida esperado para comparación estructural';
COMMENT ON COLUMN tkr_test_caso.codigo_error_esperado IS 'Código de negocio esperado en el payload o SQLCODE esperado (0 = Éxito)';
COMMENT ON COLUMN tkr_test_caso.tiempo_max_ms IS 'Tiempo de respuesta máximo tolerado en milisegundos (SLA de rendimiento)';
COMMENT ON COLUMN tkr_test_caso.es_activo IS 'Indica si el caso se incluye en ejecuciones: 1=Sí, 0=No';
COMMENT ON COLUMN tkr_test_caso.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN tkr_test_caso.fecha_creacion IS 'Fecha y hora de alta del caso de prueba (hora Bogotá)';
COMMENT ON COLUMN tkr_test_caso.fecha_modificacion IS 'Fecha y hora de última edición del caso (hora Bogotá)';


-- ----------------------------------------------------------------------------
-- TABLA 4/11: TKR_TEST_ASERCION
-- Validaciones puntuales sobre nodos específicos del JSON de salida mediante JSON Path
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_test_asercion (
    id NUMBER(12) NOT NULL,
    id_caso NUMBER(12) NOT NULL,
    ruta_json VARCHAR2(255) NOT NULL,
    operador VARCHAR2(30) DEFAULT 'EQUALS',
    valor_esperado VARCHAR2(4000),
    descripcion VARCHAR2(500),
    es_critica NUMBER(1) DEFAULT 1 CHECK (es_critica IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_test_asercion PRIMARY KEY (id),
    CONSTRAINT fk_tkr_test_asercion_caso FOREIGN KEY (id_caso) REFERENCES tkr_test_caso(id),
    CONSTRAINT ck_tkr_test_aser_op CHECK (operador IN ('EQUALS', 'NOT_EQUALS', 'EXISTS', 'NOT_EXISTS', 'IS_NULL', 'NOT_NULL', 'IS_ARRAY', 'CONTAINS', 'GREATER_THAN', 'LESS_THAN', 'REGEX'))
);
CREATE SEQUENCE tkr_test_asercion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_tkr_test_aser_caso ON tkr_test_asercion(id_caso);

CREATE OR REPLACE TRIGGER trg_bi_tkr_test_asercion
BEFORE INSERT ON tkr_test_asercion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_test_asercion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_test_asercion IS 'Validaciones puntuales sobre nodos específicos del JSON de salida mediante JSON Path';
COMMENT ON COLUMN tkr_test_asercion.id IS 'Identificador único de la aserción (PK)';
COMMENT ON COLUMN tkr_test_asercion.id_caso IS 'Caso de prueba al que aplica la regla de aserción (FK a tkr_test_caso)';
COMMENT ON COLUMN tkr_test_asercion.ruta_json IS 'Ruta JSONPath evaluada en p_json_salida ($.codigo, $.datos.id)';
COMMENT ON COLUMN tkr_test_asercion.operador IS 'Operador de aserción: EQUALS, EXISTS, CONTAINS, REGEX, etc.';
COMMENT ON COLUMN tkr_test_asercion.valor_esperado IS 'Valor literal esperado en el nodo evaluado';
COMMENT ON COLUMN tkr_test_asercion.descripcion IS 'Explicación del criterio de aceptación verificado';
COMMENT ON COLUMN tkr_test_asercion.es_critica IS 'Indica si un fallo marca el test como FALLIDO: 1=Sí, 0=Warning';
COMMENT ON COLUMN tkr_test_asercion.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN tkr_test_asercion.fecha_creacion IS 'Fecha y hora de definición de la aserción (hora Bogotá)';


-- ----------------------------------------------------------------------------
-- TABLA 5/11: TKR_TEST_MOCK_DATO
-- Semillas de datos SQL y contexto de sesión para preparar y limpiar cada prueba
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_test_mock_dato (
    id NUMBER(12) NOT NULL,
    id_caso NUMBER(12) NOT NULL,
    tipo_mock VARCHAR2(50) NOT NULL,
    orden NUMBER(3) DEFAULT 1,
    script_sql CLOB,
    payload_contexto CLOB,
    descripcion VARCHAR2(500),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_test_mock PRIMARY KEY (id),
    CONSTRAINT fk_tkr_test_mock_caso FOREIGN KEY (id_caso) REFERENCES tkr_test_caso(id),
    CONSTRAINT ck_tkr_test_mock_tipo CHECK (tipo_mock IN ('PRE_SETUP_SQL', 'POST_TEARDOWN_SQL', 'HEADERS_SESION', 'ESTADO_INICIAL')),
    CONSTRAINT ck_tkr_test_mock_ctx CHECK (payload_contexto IS NULL OR payload_contexto IS JSON (LAX))
);
CREATE SEQUENCE tkr_test_mock_dato_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_tkr_test_mock_dato
BEFORE INSERT ON tkr_test_mock_dato
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_test_mock_dato_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_test_mock_dato IS 'Semillas de datos SQL y contexto de sesión para preparar y limpiar el entorno de cada prueba';
COMMENT ON COLUMN tkr_test_mock_dato.id IS 'Identificador del mock de datos o precondición (PK)';
COMMENT ON COLUMN tkr_test_mock_dato.id_caso IS 'Caso de prueba al que aplica el mock (FK a tkr_test_caso)';
COMMENT ON COLUMN tkr_test_mock_dato.tipo_mock IS 'Tipo de preparación: PRE_SETUP_SQL, POST_TEARDOWN_SQL, HEADERS_SESION, ESTADO_INICIAL';
COMMENT ON COLUMN tkr_test_mock_dato.orden IS 'Orden secuencial de aplicación del script';
COMMENT ON COLUMN tkr_test_mock_dato.script_sql IS 'Bloque SQL o PL/SQL de semilla o limpieza (INSERT / DELETE de prueba)';
COMMENT ON COLUMN tkr_test_mock_dato.payload_contexto IS 'Variables de contexto de sesión inyectadas (Roles simulados, Headers)';
COMMENT ON COLUMN tkr_test_mock_dato.descripcion IS 'Explicación de la condición requerida para que el test funcione';
COMMENT ON COLUMN tkr_test_mock_dato.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN tkr_test_mock_dato.fecha_creacion IS 'Fecha y hora de creación del mock (hora Bogotá)';


-- ----------------------------------------------------------------------------
-- TABLA 6/11: TKR_TEST_EJECUCION
-- Cabecera histórica de ejecuciones y trazabilidad de corridas de prueba (Test Runs)
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_test_ejecucion (
    id NUMBER(12) NOT NULL,
    id_suite NUMBER(12),
    id_objeto NUMBER(12),
    id_usuario NUMBER(12),
    entorno VARCHAR2(30) DEFAULT 'DEV',
    fecha_inicio DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_fin DATE,
    duracion_total_ms NUMBER(12,2),
    total_casos NUMBER(6) DEFAULT 0,
    casos_exitosos NUMBER(6) DEFAULT 0,
    casos_fallidos NUMBER(6) DEFAULT 0,
    casos_con_error NUMBER(6) DEFAULT 0,
    estado_global VARCHAR2(30) DEFAULT 'EN_PROCESO',
    disparador VARCHAR2(50) DEFAULT 'MANUAL_FRONT',
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    CONSTRAINT pk_tkr_test_ejecucion PRIMARY KEY (id),
    CONSTRAINT fk_tkr_test_ejec_suite FOREIGN KEY (id_suite) REFERENCES tkr_test_suite(id),
    CONSTRAINT fk_tkr_test_ejec_obj FOREIGN KEY (id_objeto) REFERENCES tkr_test_objeto(id),
    CONSTRAINT ck_tkr_test_ejec_env CHECK (entorno IN ('DEV', 'QA', 'STAGING', 'PROD', 'CI_CD')),
    CONSTRAINT ck_tkr_test_ejec_estado CHECK (estado_global IN ('EN_PROCESO', 'EXITOSO', 'FALLIDO', 'CANCELADO', 'TIMEOUT')),
    CONSTRAINT ck_tkr_test_ejec_disp CHECK (disparador IN ('MANUAL_FRONT', 'PIPELINE_CI', 'CRON_JOB', 'API_REST', 'UNIT_TEST_RUNNER'))
);
CREATE SEQUENCE tkr_test_ejecucion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_tkr_test_ejec_fecha ON tkr_test_ejecucion(fecha_inicio);

CREATE OR REPLACE TRIGGER trg_bi_tkr_test_ejecucion
BEFORE INSERT ON tkr_test_ejecucion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_test_ejecucion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_test_ejecucion IS 'Cabecera de ejecuciones y trazabilidad de corridas de prueba en el entorno';
COMMENT ON COLUMN tkr_test_ejecucion.id IS 'Identificador de la corrida de pruebas (PK)';
COMMENT ON COLUMN tkr_test_ejecucion.id_suite IS 'Suite ejecutada (FK a tkr_test_suite, NULL si fue corrida ad-hoc)';
COMMENT ON COLUMN tkr_test_ejecucion.id_objeto IS 'Objeto específico ejecutado en pruebas aisladas (FK a tkr_test_objeto)';
COMMENT ON COLUMN tkr_test_ejecucion.id_usuario IS 'Identificador del usuario o desarrollador que detonó la prueba';
COMMENT ON COLUMN tkr_test_ejecucion.entorno IS 'Ambiente de pruebas: DEV, QA, STAGING, PROD, CI_CD';
COMMENT ON COLUMN tkr_test_ejecucion.fecha_inicio IS 'Fecha y hora en que comenzó el test runner (hora Bogotá)';
COMMENT ON COLUMN tkr_test_ejecucion.fecha_fin IS 'Fecha y hora en que finalizó la ejecución completa (hora Bogotá)';
COMMENT ON COLUMN tkr_test_ejecucion.duracion_total_ms IS 'Tiempo total transcurrido acumulado en milisegundos';
COMMENT ON COLUMN tkr_test_ejecucion.total_casos IS 'Número total de casos de prueba incluidos en la corrida';
COMMENT ON COLUMN tkr_test_ejecucion.casos_exitosos IS 'Número de casos que cumplieron todas sus aserciones (PASÓ)';
COMMENT ON COLUMN tkr_test_ejecucion.casos_fallidos IS 'Número de casos que tuvieron discrepancias en aserciones (FALLÓ)';
COMMENT ON COLUMN tkr_test_ejecucion.casos_con_error IS 'Número de casos que arrojaron excepciones inesperadas de Oracle';
COMMENT ON COLUMN tkr_test_ejecucion.estado_global IS 'Resultado: EN_PROCESO, EXITOSO, FALLIDO, CANCELADO, TIMEOUT';
COMMENT ON COLUMN tkr_test_ejecucion.disparador IS 'Origen: MANUAL_FRONT, PIPELINE_CI, CRON_JOB, API_REST, UNIT_TEST_RUNNER';
COMMENT ON COLUMN tkr_test_ejecucion.estado_registro IS 'Estado del registro: 1=Activo';


-- ----------------------------------------------------------------------------
-- TABLA 7/11: TKR_TEST_DETALLE_EJECUCION
-- Registro individual y evidencia por cada caso probado (CLOB in/out, diffs, tiempos)
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_test_detalle_ejecucion (
    id NUMBER(12) NOT NULL,
    id_ejecucion NUMBER(12) NOT NULL,
    id_caso NUMBER(12) NOT NULL,
    id_objeto NUMBER(12) NOT NULL,
    json_entrada_enviado CLOB NOT NULL,
    json_salida_obtenido CLOB,
    estado VARCHAR2(30) NOT NULL,
    tiempo_ejecucion_ms NUMBER(10,2),
    codigo_error_oracle NUMBER(10),
    mensaje_error_oracle VARCHAR2(4000),
    diferencias_detectadas CLOB,
    fecha_ejecucion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_test_det_ejec PRIMARY KEY (id),
    CONSTRAINT fk_tkr_test_det_ejec FOREIGN KEY (id_ejecucion) REFERENCES tkr_test_ejecucion(id),
    CONSTRAINT fk_tkr_test_det_caso FOREIGN KEY (id_caso) REFERENCES tkr_test_caso(id),
    CONSTRAINT fk_tkr_test_det_obj FOREIGN KEY (id_objeto) REFERENCES tkr_test_objeto(id),
    CONSTRAINT ck_tkr_test_det_est CHECK (estado IN ('PASO', 'FALLO', 'ERROR_ORACLE', 'TIMEOUT', 'OMITIDO')),
    CONSTRAINT ck_tkr_test_det_in_json CHECK (json_entrada_enviado IS JSON (LAX)),
    CONSTRAINT ck_tkr_test_det_out_json CHECK (json_salida_obtenido IS NULL OR json_salida_obtenido IS JSON (LAX)),
    CONSTRAINT ck_tkr_test_det_diff_json CHECK (diferencias_detectadas IS NULL OR diferencias_detectadas IS JSON (LAX))
);
CREATE SEQUENCE tkr_test_detalle_ejecucion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_tkr_test_det_ejec ON tkr_test_detalle_ejecucion(id_ejecucion, estado);

CREATE OR REPLACE TRIGGER trg_bi_tkr_test_detalle_ejecucion
BEFORE INSERT ON tkr_test_detalle_ejecucion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_test_detalle_ejecucion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_test_detalle_ejecucion IS 'Registro individual de cada caso probado: payload inyectado, CLOB recibido, tiempos y diferencias';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.id IS 'Identificador único del detalle de ejecución (PK)';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.id_ejecucion IS 'Corrida de pruebas a la que pertenece la evidencia (FK a tkr_test_ejecucion)';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.id_caso IS 'Caso de prueba ejecutado (FK a tkr_test_caso)';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.id_objeto IS 'Objeto PL/SQL probado (FK a tkr_test_objeto)';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.json_entrada_enviado IS 'Payload exacto transmitido en el parámetro p_json_entrada en la corrida';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.json_salida_obtenido IS 'Respuesta exacta CLOB recibida en el parámetro p_json_salida';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.estado IS 'Resultado: PASO, FALLO, ERROR_ORACLE, TIMEOUT, OMITIDO';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.tiempo_ejecucion_ms IS 'Tiempo de latencia neta del objeto en milisegundos';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.codigo_error_oracle IS 'SQLCODE de Oracle capturado en caso de excepción (-20000, -1, etc.)';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.mensaje_error_oracle IS 'SQLERRM detallado o traza de excepción de Oracle';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.diferencias_detectadas IS 'Diferencias en JSON (Diff) entre lo esperado y lo obtenido en la prueba';
COMMENT ON COLUMN tkr_test_detalle_ejecucion.fecha_ejecucion IS 'Fecha y hora precisa de ejecución del caso (hora Bogotá)';


-- ============================================================================
-- SECCIÓN 2: TELEMETRÍA, SEGUIMIENTO DE OBJETOS & ESTADÍSTICAS (4 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 8/11: TKR_TRAZA_CONFIG
-- Reglas de activación dinámica de seguimiento y telemetría (Profiling Rules)
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_traza_config (
    id NUMBER(12) NOT NULL,
    id_objeto NUMBER(12),
    id_usuario NUMBER(12),
    nombre_paquete VARCHAR2(60),
    nombre_metodo VARCHAR2(60),
    fecha_desde DATE,
    fecha_hasta DATE,
    nivel_detalle VARCHAR2(30) DEFAULT 'COMPLETO',
    grabar_payloads NUMBER(1) DEFAULT 1 CHECK (grabar_payloads IN (0, 1)),
    es_activo NUMBER(1) DEFAULT 1 CHECK (es_activo IN (0, 1)),
    descripcion VARCHAR2(500),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_traza_config PRIMARY KEY (id),
    CONSTRAINT fk_tkr_trazas_cfg_obj FOREIGN KEY (id_objeto) REFERENCES tkr_test_objeto(id),
    CONSTRAINT ck_tkr_trazas_cfg_det CHECK (nivel_detalle IN ('CABECERA_SOLO', 'COMPLETO', 'SOLO_ERRORES'))
);
CREATE SEQUENCE tkr_traza_config_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_tkr_traza_cfg_filtro ON tkr_traza_config(nombre_paquete, nombre_metodo, es_activo);

CREATE OR REPLACE TRIGGER trg_bi_tkr_traza_config
BEFORE INSERT ON tkr_traza_config
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_traza_config_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_traza_config IS 'Reglas de activación dinámica de seguimiento y telemetría por objeto, usuario o ventana temporal';
COMMENT ON COLUMN tkr_traza_config.id IS 'Identificador único de la regla de seguimiento (PK)';
COMMENT ON COLUMN tkr_traza_config.id_objeto IS 'Objeto específico a seguir (FK a tkr_test_objeto, NULL = evalúa por nombre)';
COMMENT ON COLUMN tkr_traza_config.id_usuario IS 'Usuario específico a monitorear (NULL = todos los usuarios)';
COMMENT ON COLUMN tkr_traza_config.nombre_paquete IS 'Filtro por nombre de paquete (e.g. pkgln_usuarios, pkgcn_citas o comodín %)';
COMMENT ON COLUMN tkr_traza_config.nombre_metodo IS 'Filtro por nombre de subprograma (e.g. p_crear_usuario o comodín %)';
COMMENT ON COLUMN tkr_traza_config.fecha_desde IS 'Fecha y hora inicial en que el seguimiento se activa (hora Bogotá, opcional)';
COMMENT ON COLUMN tkr_traza_config.fecha_hasta IS 'Fecha y hora final de vigencia del seguimiento (hora Bogotá, opcional)';
COMMENT ON COLUMN tkr_traza_config.nivel_detalle IS 'Nivel de captura: CABECERA_SOLO (tiempos), COMPLETO (con llamados), SOLO_ERRORES';
COMMENT ON COLUMN tkr_traza_config.grabar_payloads IS 'Indica si persiste los CLOBs de entrada y salida: 1=Sí, 0=No (solo métricas)';
COMMENT ON COLUMN tkr_traza_config.es_activo IS 'Bandera de activación de la regla: 1=Monitoreo activo, 0=Pausado';
COMMENT ON COLUMN tkr_traza_config.descripcion IS 'Motivo o ticket del requerimiento de auditoría o profiling';
COMMENT ON COLUMN tkr_traza_config.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN tkr_traza_config.fecha_creacion IS 'Fecha y hora de creación de la regla de configuración (hora Bogotá)';
COMMENT ON COLUMN tkr_traza_config.fecha_modificacion IS 'Fecha y hora de última modificación de la regla (hora Bogotá)';


-- ----------------------------------------------------------------------------
-- TABLA 9/11: TKR_TRAZA_EJECUCION
-- Cabecera de ejecuciones monitoreadas (Trace Header & Root Invocations)
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_traza_ejecucion (
    id NUMBER(12) NOT NULL,
    id_config NUMBER(12),
    id_objeto NUMBER(12),
    id_usuario NUMBER(12),
    nombre_paquete VARCHAR2(60) NOT NULL,
    nombre_metodo VARCHAR2(60) NOT NULL,
    codigo_traza VARCHAR2(100),
    ip_origen VARCHAR2(50),
    id_sesion_oracle VARCHAR2(50),
    fecha_inicio DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE) NOT NULL,
    fecha_fin DATE,
    duracion_ms NUMBER(12,3),
    estado VARCHAR2(20) DEFAULT 'EN_PROCESO',
    codigo_error NUMBER(10),
    mensaje_error VARCHAR2(4000),
    json_entrada CLOB,
    json_salida CLOB,
    total_llamados NUMBER(6) DEFAULT 0,
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_traza_ejecucion PRIMARY KEY (id),
    CONSTRAINT fk_tkr_trazas_ejec_cfg FOREIGN KEY (id_config) REFERENCES tkr_traza_config(id),
    CONSTRAINT fk_tkr_trazas_ejec_obj FOREIGN KEY (id_objeto) REFERENCES tkr_test_objeto(id),
    CONSTRAINT ck_tkr_trazas_ejec_est CHECK (estado IN ('EN_PROCESO', 'EXITO', 'ERROR', 'TIMEOUT')),
    CONSTRAINT ck_tkr_trazas_in_json CHECK (json_entrada IS NULL OR json_entrada IS JSON (LAX)),
    CONSTRAINT ck_tkr_trazas_out_json CHECK (json_salida IS NULL OR json_salida IS JSON (LAX))
);
CREATE SEQUENCE tkr_traza_ejecucion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_tkr_trazas_ejec_obj ON tkr_traza_ejecucion(nombre_paquete, nombre_metodo, fecha_inicio);
CREATE INDEX idx_tkr_trazas_ejec_usr ON tkr_traza_ejecucion(id_usuario, fecha_inicio);
CREATE INDEX idx_tkr_trazas_ejec_trid ON tkr_traza_ejecucion(codigo_traza);

CREATE OR REPLACE TRIGGER trg_bi_tkr_traza_ejecucion
BEFORE INSERT ON tkr_traza_ejecucion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_traza_ejecucion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_traza_ejecucion IS 'Cabecera de ejecuciones monitoreadas: tiempos de inicio/fin, payloads entrada/salida y estado global';
COMMENT ON COLUMN tkr_traza_ejecucion.id IS 'Identificador único de la sesión de seguimiento de ejecución (PK)';
COMMENT ON COLUMN tkr_traza_ejecucion.id_config IS 'Regla de configuración que detonó la captura de esta traza (FK a tkr_traza_config)';
COMMENT ON COLUMN tkr_traza_ejecucion.id_objeto IS 'Objeto o procedimiento principal invocado (FK a tkr_test_objeto)';
COMMENT ON COLUMN tkr_traza_ejecucion.id_usuario IS 'Identificador del usuario que detonó la transacción';
COMMENT ON COLUMN tkr_traza_ejecucion.nombre_paquete IS 'Nombre del paquete raíz ejecutado (e.g. pkgln_usuarios)';
COMMENT ON COLUMN tkr_traza_ejecucion.nombre_metodo IS 'Nombre del procedimiento raíz ejecutado (e.g. p_crear_usuario)';
COMMENT ON COLUMN tkr_traza_ejecucion.codigo_traza IS 'Identificador único de correlación global / UUID emitido por el Gateway o TraceContext';
COMMENT ON COLUMN tkr_traza_ejecucion.ip_origen IS 'Dirección IP del cliente que realizó la petición';
COMMENT ON COLUMN tkr_traza_ejecucion.id_sesion_oracle IS 'Identificador de sesión interna de Oracle Database (SID / Audsid)';
COMMENT ON COLUMN tkr_traza_ejecucion.fecha_inicio IS 'Fecha y hora exacta en que comenzó la ejecución del objeto (hora Bogotá)';
COMMENT ON COLUMN tkr_traza_ejecucion.fecha_fin IS 'Fecha y hora exacta en que culminó la ejecución del objeto (hora Bogotá)';
COMMENT ON COLUMN tkr_traza_ejecucion.duracion_ms IS 'Duración total de la transacción en milisegundos';
COMMENT ON COLUMN tkr_traza_ejecucion.estado IS 'Veredicto de ejecución: EN_PROCESO, EXITO, ERROR, TIMEOUT';
COMMENT ON COLUMN tkr_traza_ejecucion.codigo_error IS 'SQLCODE o código de error capturado en caso de fallo';
COMMENT ON COLUMN tkr_traza_ejecucion.mensaje_error IS 'Mensaje de error descriptivo o traza ORA-XXXXX';
COMMENT ON COLUMN tkr_traza_ejecucion.json_entrada IS 'Payload CLOB exacto inyectado en el parámetro p_json_entrada';
COMMENT ON COLUMN tkr_traza_ejecucion.json_salida IS 'Payload CLOB devuelto en el parámetro p_json_salida';
COMMENT ON COLUMN tkr_traza_ejecucion.total_llamados IS 'Cantidad total de subprogramas invocados registrados en el detalle';
COMMENT ON COLUMN tkr_traza_ejecucion.estado_registro IS 'Estado del registro: 1=Activo';
COMMENT ON COLUMN tkr_traza_ejecucion.fecha_creacion IS 'Fecha y hora de inserción del registro en la base de datos (hora Bogotá)';


-- ----------------------------------------------------------------------------
-- TABLA 10/11: TKR_TRAZA_LLAMADO
-- Detalle secuencial y pila jerárquica de sub-llamados (Call Stack / Spans)
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_traza_llamado (
    id NUMBER(12) NOT NULL,
    id_ejecucion NUMBER(12) NOT NULL,
    id_llamado_padre NUMBER(12),
    orden_llamado NUMBER(6) NOT NULL,
    nivel_anidamiento NUMBER(3) DEFAULT 1,
    tipo_llamado VARCHAR2(30) DEFAULT 'PLSQL_SUBPROGRAM',
    paquete_llamado VARCHAR2(60) NOT NULL,
    metodo_llamado VARCHAR2(60) NOT NULL,
    parametros_enviados CLOB,
    parametros_recibidos CLOB,
    fecha_inicio DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE) NOT NULL,
    fecha_fin DATE,
    duracion_ms NUMBER(12,3),
    estado VARCHAR2(20) DEFAULT 'EXITO',
    codigo_error NUMBER(10),
    mensaje_error VARCHAR2(4000),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_traza_llamado PRIMARY KEY (id),
    CONSTRAINT fk_tkr_trazas_llm_ejec FOREIGN KEY (id_ejecucion) REFERENCES tkr_traza_ejecucion(id),
    CONSTRAINT fk_tkr_trazas_llm_padre FOREIGN KEY (id_llamado_padre) REFERENCES tkr_traza_llamado(id),
    CONSTRAINT ck_tkr_trazas_llm_est CHECK (estado IN ('EXITO', 'ERROR', 'OMITIDO')),
    CONSTRAINT ck_tkr_trazas_llm_tipo CHECK (tipo_llamado IN ('ORQUESTADOR_PKGLN', 'LOGICA_PKGCN', 'DAO', 'FUNCION', 'REST_API', 'PLSQL_SUBPROGRAM')),
    CONSTRAINT ck_tkr_trazas_param_in_json CHECK (parametros_enviados IS NULL OR parametros_enviados IS JSON (LAX)),
    CONSTRAINT ck_tkr_trazas_param_out_json CHECK (parametros_recibidos IS NULL OR parametros_recibidos IS JSON (LAX))
);
CREATE SEQUENCE tkr_traza_llamado_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_tkr_trazas_llm_ejec ON tkr_traza_llamado(id_ejecucion, orden_llamado);

CREATE OR REPLACE TRIGGER trg_bi_tkr_traza_llamado
BEFORE INSERT ON tkr_traza_llamado
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_traza_llamado_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_traza_llamado IS 'Detalle secuencial y pila de sub-llamados internos con argumentos pasados y recibidos en orden';
COMMENT ON COLUMN tkr_traza_llamado.id IS 'Identificador único del sub-llamado / span (PK)';
COMMENT ON COLUMN tkr_traza_llamado.id_ejecucion IS 'Cabecera de ejecución a la que pertenece este llamado (FK a tkr_traza_ejecucion)';
COMMENT ON COLUMN tkr_traza_llamado.id_llamado_padre IS 'Identificador del llamado que detonó este sub-llamado (FK reflexiva para call-tree)';
COMMENT ON COLUMN tkr_traza_llamado.orden_llamado IS 'Secuencia ordinal estricta de ejecución dentro de la transacción (1, 2, 3...)';
COMMENT ON COLUMN tkr_traza_llamado.nivel_anidamiento IS 'Profundidad jerárquica en la pila de llamadas (1=Primer nivel, 2=Hijo, etc.)';
COMMENT ON COLUMN tkr_traza_llamado.tipo_llamado IS 'Naturaleza del objeto invocado: ORQUESTADOR_PKGLN, LOGICA_PKGCN, DAO, FUNCION, REST_API';
COMMENT ON COLUMN tkr_traza_llamado.paquete_llamado IS 'Nombre del paquete destino invocado (e.g. pkgcn_usuarios, pkgtkr_usuario_dao)';
COMMENT ON COLUMN tkr_traza_llamado.metodo_llamado IS 'Nombre de la función o procedimiento invocado (e.g. p_insertar, f_traer)';
COMMENT ON COLUMN tkr_traza_llamado.parametros_enviados IS 'Argumentos y datos suministrados al invocar el objeto en formato JSON nativo';
COMMENT ON COLUMN tkr_traza_llamado.parametros_recibidos IS 'Valores retornados o parámetros OUT obtenidos del objeto en formato JSON nativo';
COMMENT ON COLUMN tkr_traza_llamado.fecha_inicio IS 'Fecha y hora de inicio del sub-llamado en hora de Bogotá';
COMMENT ON COLUMN tkr_traza_llamado.fecha_fin IS 'Fecha y hora de término del sub-llamado en hora de Bogotá';
COMMENT ON COLUMN tkr_traza_llamado.duracion_ms IS 'Tiempo de ejecución consumido exclusivamente por este subprograma (en ms)';
COMMENT ON COLUMN tkr_traza_llamado.estado IS 'Resultado del sub-llamado: EXITO, ERROR, OMITIDO';
COMMENT ON COLUMN tkr_traza_llamado.codigo_error IS 'Código de excepción capturado si este llamado particular falló';
COMMENT ON COLUMN tkr_traza_llamado.mensaje_error IS 'Detalle o SQLERRM específico del fallo en el sub-llamado';
COMMENT ON COLUMN tkr_traza_llamado.estado_registro IS 'Estado del registro: 1=Activo';
COMMENT ON COLUMN tkr_traza_llamado.fecha_creacion IS 'Fecha y hora de grabación de la traza (hora Bogotá)';


-- ----------------------------------------------------------------------------
-- TABLA 11/11: TKR_TRAZA_ESTADISTICA
-- Métricas agregadas de rendimiento periódico por objeto PL/SQL (APM Summary)
-- ----------------------------------------------------------------------------
CREATE TABLE tkr_traza_estadistica (
    id NUMBER(12) NOT NULL,
    id_objeto NUMBER(12),
    nombre_paquete VARCHAR2(60) NOT NULL,
    nombre_metodo VARCHAR2(60) NOT NULL,
    fecha_periodo DATE NOT NULL,
    total_ejecuciones NUMBER(10) DEFAULT 0,
    ejecuciones_exitosas NUMBER(10) DEFAULT 0,
    ejecuciones_fallidas NUMBER(10) DEFAULT 0,
    tiempo_min_ms NUMBER(12,3) DEFAULT 0,
    tiempo_max_ms NUMBER(12,3) DEFAULT 0,
    tiempo_prom_ms NUMBER(12,3) DEFAULT 0,
    tiempo_p95_ms NUMBER(12,3) DEFAULT 0,
    fecha_ultima_ejecucion DATE,
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_tkr_traza_estadistica PRIMARY KEY (id),
    CONSTRAINT fk_tkr_trazas_stat_obj FOREIGN KEY (id_objeto) REFERENCES tkr_test_objeto(id),
    CONSTRAINT uk_tkr_traza_stat UNIQUE (nombre_paquete, nombre_metodo, fecha_periodo)
);
CREATE SEQUENCE tkr_traza_estadistica_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_tkr_traza_stat_obj ON tkr_traza_estadistica(id_objeto, fecha_periodo);

CREATE OR REPLACE TRIGGER trg_bi_tkr_traza_estadistica
BEFORE INSERT ON tkr_traza_estadistica
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := tkr_traza_estadistica_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE tkr_traza_estadistica IS 'Métricas agregadas de telemetría y rendimiento periódico por objeto PL/SQL para analítica';
COMMENT ON COLUMN tkr_traza_estadistica.id IS 'Identificador único del resumen estadístico (PK)';
COMMENT ON COLUMN tkr_traza_estadistica.id_objeto IS 'Objeto PL/SQL catalogado (FK a tkr_test_objeto, opcional)';
COMMENT ON COLUMN tkr_traza_estadistica.nombre_paquete IS 'Nombre del paquete evaluado (e.g. pkgln_usuarios)';
COMMENT ON COLUMN tkr_traza_estadistica.nombre_metodo IS 'Nombre del procedimiento evaluado (e.g. p_crear_usuario)';
COMMENT ON COLUMN tkr_traza_estadistica.fecha_periodo IS 'Ventana de agregación temporal (truncada por hora o día en hora de Bogotá)';
COMMENT ON COLUMN tkr_traza_estadistica.total_ejecuciones IS 'Número total de invocaciones registradas en el período';
COMMENT ON COLUMN tkr_traza_estadistica.ejecuciones_exitosas IS 'Cantidad de invocaciones que culminaron satisfactoriamente';
COMMENT ON COLUMN tkr_traza_estadistica.ejecuciones_fallidas IS 'Cantidad de invocaciones que terminaron con error o excepción';
COMMENT ON COLUMN tkr_traza_estadistica.tiempo_min_ms IS 'Tiempo mínimo de latencia observado en milisegundos';
COMMENT ON COLUMN tkr_traza_estadistica.tiempo_max_ms IS 'Tiempo máximo de latencia observado en milisegundos';
COMMENT ON COLUMN tkr_traza_estadistica.tiempo_prom_ms IS 'Tiempo promedio de respuesta en milisegundos';
COMMENT ON COLUMN tkr_traza_estadistica.tiempo_p95_ms IS 'Percentil 95 de tiempo de respuesta (SLA de experiencia)';
COMMENT ON COLUMN tkr_traza_estadistica.fecha_ultima_ejecucion IS 'Fecha y hora de la corrida más reciente en el período (hora Bogotá)';
COMMENT ON COLUMN tkr_traza_estadistica.estado_registro IS 'Estado del registro: 1=Activo';
COMMENT ON COLUMN tkr_traza_estadistica.fecha_creacion IS 'Fecha y hora de consolidación del registro estadístico (hora Bogotá)';
COMMENT ON COLUMN tkr_traza_estadistica.fecha_modificacion IS 'Fecha y hora de última actualización del consolidado (hora Bogotá)';
