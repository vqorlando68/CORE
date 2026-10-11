-- ============================================================================
-- PLATAFORMA SAAS MULTI-APLICACIONES
-- CORE TRANSVERSAL & MOTOR DE PRUEBAS AUTOMATIZADAS & TELEMETRÍA (JSON IN/OUT)
-- TOTAL: 38 TABLAS MULTI-TENANT CON DICCIONARIO DE DATOS COMPLETO
--
-- Base de Datos: Oracle AI Database 23ai / 26ai
-- Charset: AL32UTF8 (UTF-8)
-- Prefijo Oficial de Tablas: core_
-- Convención de Claves Foráneas: id_<tabla_referenciada>
-- Estándar de Fechas: Tipo DATE con hora oficial de Bogotá (America/Bogota)
-- Expresión Default: CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE)
-- Estándar Booleano / Banderas: Tipo NUMBER(1) con valores (0, 1) y CHECK constraints
-- Convención de Nomenclatura: Columnas en español estricto (conservando tenant, oidc)
-- Triggers Autonuméricos: TRG_BI_<TABLA> asignando :new.id := <tabla>_seq.NEXTVAL si es NULL
-- Firma Invocación Frontend: p_json_entrada (IN CLOB) / p_json_salida (OUT CLOB)
-- Fecha de Actualización: 2026-10-07
-- ============================================================================

-- ============================================================================
-- SECCIÓN 0: GLOBAL — TENANTS (1 TABLA)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 1/38: CORE_TENANT
-- ----------------------------------------------------------------------------
CREATE TABLE core_tenant (
    id NUMBER(12) PRIMARY KEY,
    codigo VARCHAR2(50) NOT NULL UNIQUE,
    nombre VARCHAR2(255) NOT NULL,
    id_plan VARCHAR2(50),
    nit_empresa VARCHAR2(20),
    contacto_correo VARCHAR2(100),
    contacto_telefono VARCHAR2(20),
    pais CHAR(2) DEFAULT 'CO',
    estado NUMBER(1) DEFAULT 1 CHECK (estado IN (0, 1, 2)),
    fecha_contratacion DATE,
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE)
);
CREATE SEQUENCE core_tenant_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_tenant
BEFORE INSERT ON core_tenant
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_tenant_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_tenant IS 'Clientes u Organizaciones SaaS — datos globales maestros y aislamiento multi-tenant';
COMMENT ON COLUMN core_tenant.id IS 'Identificador único global del tenant (clave primaria)';
COMMENT ON COLUMN core_tenant.codigo IS 'Código alfanumérico mnemotécnico o subdominio único del tenant';
COMMENT ON COLUMN core_tenant.nombre IS 'Razón social o nombre comercial del tenant';
COMMENT ON COLUMN core_tenant.id_plan IS 'Identificador o nivel de suscripción contratado (STARTER, PRO, ENTERPRISE)';
COMMENT ON COLUMN core_tenant.nit_empresa IS 'Número de identificación tributaria o fiscal del tenant';
COMMENT ON COLUMN core_tenant.contacto_correo IS 'Correo electrónico corporativo principal de contacto';
COMMENT ON COLUMN core_tenant.contacto_telefono IS 'Número telefónico de contacto administrativo';
COMMENT ON COLUMN core_tenant.pais IS 'Código ISO 3166-1 alpha-2 del país del tenant (por defecto CO)';
COMMENT ON COLUMN core_tenant.estado IS 'Estado operativo del tenant: 1=Activo, 0=Inactivo, 2=Suspendido';
COMMENT ON COLUMN core_tenant.fecha_contratacion IS 'Fecha formal de inicio contractual del servicio SaaS (hora Bogotá)';
COMMENT ON COLUMN core_tenant.fecha_creacion IS 'Fecha y hora en que se registró el tenant en la plataforma (hora Bogotá)';
COMMENT ON COLUMN core_tenant.fecha_modificacion IS 'Fecha y hora de la última modificación de los datos del tenant (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 1: USUARIOS, AUTENTICACIÓN & SESIONES ACTIVAS (3 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 2/38: CORE_PERSONA
-- ----------------------------------------------------------------------------
CREATE TABLE core_persona (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    tipo CHAR(1) NOT NULL,
    identificacion VARCHAR2(20) NOT NULL,
    nombre_completo VARCHAR2(255) NOT NULL,
    correo_principal VARCHAR2(100),
    telefono_principal VARCHAR2(20),
    ciudad VARCHAR2(100),
    pais CHAR(2) DEFAULT 'CO',
    es_activo NUMBER(1) DEFAULT 1 CHECK (es_activo IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_persona PRIMARY KEY (id),
    CONSTRAINT fk_core_persona_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT ck_core_persona_tipo CHECK (tipo IN ('N', 'J'))
);
CREATE SEQUENCE core_persona_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_persona_ident ON core_persona(id_tenant, identificacion);

CREATE OR REPLACE TRIGGER trg_bi_core_persona
BEFORE INSERT ON core_persona
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_persona_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_persona IS 'Datos personales y de contacto de personas naturales o jurídicas asociadas al tenant';
COMMENT ON COLUMN core_persona.id_tenant IS 'Identificador del tenant propietario del registro (FK a core_tenant)';
COMMENT ON COLUMN core_persona.id IS 'Identificador secuencial de la persona dentro del tenant (PK)';
COMMENT ON COLUMN core_persona.tipo IS 'Naturaleza jurídica: N = Natural, J = Jurídica';
COMMENT ON COLUMN core_persona.identificacion IS 'Documento de identidad o número fiscal (Cédula, NIT, Pasaporte)';
COMMENT ON COLUMN core_persona.nombre_completo IS 'Nombre y apellidos completos o razón social de la entidad';
COMMENT ON COLUMN core_persona.correo_principal IS 'Dirección de correo electrónico personal o institucional';
COMMENT ON COLUMN core_persona.telefono_principal IS 'Número de teléfono móvil o fijo de contacto';
COMMENT ON COLUMN core_persona.ciudad IS 'Ciudad de residencia o sede de la persona';
COMMENT ON COLUMN core_persona.pais IS 'Código ISO de país de residencia (por defecto CO)';
COMMENT ON COLUMN core_persona.es_activo IS 'Bandera de vigencia funcional: 1=Vigente, 0=No vigente';
COMMENT ON COLUMN core_persona.estado_registro IS 'Estado del registro en auditoría: 1=Activo, 0=Borrado lógico';
COMMENT ON COLUMN core_persona.fecha_creacion IS 'Fecha y hora de inserción del registro (hora Bogotá)';
COMMENT ON COLUMN core_persona.fecha_modificacion IS 'Fecha y hora de última actualización del registro (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 3/38: CORE_USUARIO
-- ----------------------------------------------------------------------------
CREATE TABLE core_usuario (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_persona NUMBER(12) NOT NULL,
    nombre_usuario VARCHAR2(100) NOT NULL,
    correo_electronico VARCHAR2(100) NOT NULL,
    oidc_sub VARCHAR2(500),
    oidc_provider VARCHAR2(50),
    id_contexto_actual NUMBER(12),
    primer_ingreso DATE,
    ultimo_ingreso DATE,
    intentos_fallidos NUMBER(3) DEFAULT 0,
    bloqueado NUMBER(1) DEFAULT 0 CHECK (bloqueado IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_usuario PRIMARY KEY (id),
    CONSTRAINT fk_core_usuario_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_usuario_persona FOREIGN KEY (id_persona) REFERENCES core_persona(id),
    CONSTRAINT uk_core_usuario_correo UNIQUE (id_tenant, correo_electronico)
);
CREATE SEQUENCE core_usuario_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_usuario
BEFORE INSERT ON core_usuario
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_usuario_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_usuario IS 'Cuentas de acceso, credenciales federadas y seguridad de usuarios';
COMMENT ON COLUMN core_usuario.id_tenant IS 'Identificador del tenant al que pertenece el usuario (FK a core_tenant)';
COMMENT ON COLUMN core_usuario.id IS 'Identificador único del usuario dentro del tenant (PK)';
COMMENT ON COLUMN core_usuario.id_persona IS 'Referencia a los datos personales de la persona (FK a core_persona)';
COMMENT ON COLUMN core_usuario.nombre_usuario IS 'Nombre de usuario único para inicio de sesión en el sistema';
COMMENT ON COLUMN core_usuario.correo_electronico IS 'Correo electrónico corporativo y canal de autenticación';
COMMENT ON COLUMN core_usuario.oidc_sub IS 'Subject identifier único emitido por el Identity Provider OIDC (Auth0, Azure AD, Cognito)';
COMMENT ON COLUMN core_usuario.oidc_provider IS 'Nombre del proveedor de identidad federado (GOOGLE, AZURE_AD, KEYCLOAK)';
COMMENT ON COLUMN core_usuario.id_contexto_actual IS 'Identificador del contexto/sucursal seleccionado activamente en la sesión';
COMMENT ON COLUMN core_usuario.primer_ingreso IS 'Fecha y hora en que el usuario ingresó por primera vez (hora Bogotá)';
COMMENT ON COLUMN core_usuario.ultimo_ingreso IS 'Fecha y hora del acceso más reciente registrado (hora Bogotá)';
COMMENT ON COLUMN core_usuario.intentos_fallidos IS 'Contador consecutivo de intentos fallidos de autenticación';
COMMENT ON COLUMN core_usuario.bloqueado IS 'Indica si la cuenta está bloqueada por seguridad: 1=Sí, 0=No';
COMMENT ON COLUMN core_usuario.estado_registro IS 'Estado del registro: 1=Activo, 0=Inactivo o eliminado';
COMMENT ON COLUMN core_usuario.fecha_creacion IS 'Fecha y hora de alta del usuario en la base de datos (hora Bogotá)';
COMMENT ON COLUMN core_usuario.fecha_modificacion IS 'Fecha y hora de última actualización del usuario (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 4/38: CORE_APLICACION
-- ----------------------------------------------------------------------------
CREATE TABLE core_aplicacion (
    id NUMBER(12) PRIMARY KEY,
    codigo VARCHAR2(100) NOT NULL UNIQUE,
    nombre VARCHAR2(255) NOT NULL,
    descripcion VARCHAR2(1000),
    version VARCHAR2(20),
    estado VARCHAR2(50) DEFAULT 'ACTIVA',
    icono VARCHAR2(50),
    url_documentacion VARCHAR2(500),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE)
);
CREATE SEQUENCE core_aplicacion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_aplicacion
BEFORE INSERT ON core_aplicacion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_aplicacion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_aplicacion IS 'Catálogo global de aplicaciones y subsistemas SaaS soportados por el core';
COMMENT ON COLUMN core_aplicacion.id IS 'Identificador único global de la aplicación (PK)';
COMMENT ON COLUMN core_aplicacion.codigo IS 'Código alfanumérico único de la app (CRM, ERP, CLINIC, INVENTORY)';
COMMENT ON COLUMN core_aplicacion.nombre IS 'Nombre comercial del producto o subsistema SaaS';
COMMENT ON COLUMN core_aplicacion.descripcion IS 'Alcance y funcionalidades provistas por el subsistema';
COMMENT ON COLUMN core_aplicacion.version IS 'Versión semántica actual de la aplicación (2.4.0)';
COMMENT ON COLUMN core_aplicacion.estado IS 'Estado operativo: ACTIVA, MANTENIMIENTO, DEPRECADA';
COMMENT ON COLUMN core_aplicacion.icono IS 'Clase CSS o recurso gráfico para el dashboard';
COMMENT ON COLUMN core_aplicacion.url_documentacion IS 'Enlace a la documentación técnica y funcional';
COMMENT ON COLUMN core_aplicacion.fecha_creacion IS 'Fecha y hora de registro de la aplicación (hora Bogotá)';
COMMENT ON COLUMN core_aplicacion.fecha_modificacion IS 'Fecha y hora de última actualización de la definición (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 5/38: CORE_CONTEXTO
-- ----------------------------------------------------------------------------
CREATE TABLE core_contexto (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    tipo VARCHAR2(50) NOT NULL,
    nombre VARCHAR2(255) NOT NULL,
    descripcion VARCHAR2(1000),
    habilitado NUMBER(1) DEFAULT 1 CHECK (habilitado IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_contexto PRIMARY KEY (id),
    CONSTRAINT fk_core_contexto_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id)
);
CREATE SEQUENCE core_contexto_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_contexto
BEFORE INSERT ON core_contexto
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_contexto_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_contexto IS 'Unidades organizacionales, sucursales, sedes o centros de costo';
COMMENT ON COLUMN core_contexto.id_tenant IS 'Identificador del tenant propietario de la unidad (FK a core_tenant)';
COMMENT ON COLUMN core_contexto.id IS 'Identificador secuencial del contexto dentro del tenant (PK)';
COMMENT ON COLUMN core_contexto.tipo IS 'Clasificación: SUCURSAL, SEDE, DEPARTAMENTO, CENTRO_COSTOS';
COMMENT ON COLUMN core_contexto.nombre IS 'Nombre descriptivo de la sede o unidad de trabajo';
COMMENT ON COLUMN core_contexto.descripcion IS 'Detalles operativos y alcance de la unidad organizacional';
COMMENT ON COLUMN core_contexto.habilitado IS 'Disponibilidad para selección y operaciones: 1=Habilitado, 0=Deshabilitado';
COMMENT ON COLUMN core_contexto.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Borrado lógico';
COMMENT ON COLUMN core_contexto.fecha_creacion IS 'Fecha y hora de registro del contexto (hora Bogotá)';
COMMENT ON COLUMN core_contexto.fecha_modificacion IS 'Fecha y hora de última modificación del contexto (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 6/38: CORE_SESION_ACTIVA
-- ----------------------------------------------------------------------------
CREATE TABLE core_sesion_activa (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12),
    id_contexto NUMBER(12),
    hash_token_sesion VARCHAR2(128) NOT NULL,
    ip_origen VARCHAR2(50),
    agente_usuario VARCHAR2(500),
    dispositivo VARCHAR2(100),
    sistema_operativo VARCHAR2(100),
    navegador VARCHAR2(100),
    es_activa NUMBER(1) DEFAULT 1 CHECK (es_activa IN (0, 1)),
    fecha_inicio DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE) NOT NULL,
    fecha_expiracion DATE NOT NULL,
    ultimo_acceso DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_cierre DATE,
    motivo_cierre VARCHAR2(100),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_sesion_activa PRIMARY KEY (id),
    CONSTRAINT fk_core_sesact_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_sesact_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT fk_core_sesact_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT fk_core_sesact_contexto FOREIGN KEY (id_contexto) REFERENCES core_contexto(id),
    CONSTRAINT uk_core_sesact_token UNIQUE (id_tenant, hash_token_sesion)
);
CREATE SEQUENCE core_sesion_activa_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_sesact_usr ON core_sesion_activa(id_tenant, id_usuario, es_activa);
CREATE INDEX idx_core_sesact_exp ON core_sesion_activa(fecha_expiracion, es_activa);

CREATE OR REPLACE TRIGGER trg_bi_core_sesion_activa
BEFORE INSERT ON core_sesion_activa
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_sesion_activa_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_sesion_activa IS 'Control de sesiones activas, tokens de autenticación, concurrencia y revocación';
COMMENT ON COLUMN core_sesion_activa.id_tenant IS 'Identificador del tenant al que pertenece la sesión (FK a core_tenant)';
COMMENT ON COLUMN core_sesion_activa.id IS 'Identificador secuencial único de la sesión activa (PK)';
COMMENT ON COLUMN core_sesion_activa.id_usuario IS 'Usuario titular de la sesión activa (FK a core_usuario)';
COMMENT ON COLUMN core_sesion_activa.id_aplicacion IS 'Aplicación donde se inició la sesión (FK a core_aplicacion)';
COMMENT ON COLUMN core_sesion_activa.id_contexto IS 'Contexto o sucursal seleccionada activamente (FK a core_contexto)';
COMMENT ON COLUMN core_sesion_activa.hash_token_sesion IS 'Hash criptográfico SHA-256 del token o JWT de sesión emitido';
COMMENT ON COLUMN core_sesion_activa.ip_origen IS 'Dirección IP desde la que se inició la sesión';
COMMENT ON COLUMN core_sesion_activa.agente_usuario IS 'Cadena User-Agent del navegador o cliente HTTP';
COMMENT ON COLUMN core_sesion_activa.dispositivo IS 'Tipo o modelo de dispositivo (DESKTOP, MOBILE, TABLET)';
COMMENT ON COLUMN core_sesion_activa.sistema_operativo IS 'Sistema operativo del usuario (Windows, Android, iOS, macOS)';
COMMENT ON COLUMN core_sesion_activa.navegador IS 'Navegador web utilizado (Chrome, Firefox, Safari, Edge)';
COMMENT ON COLUMN core_sesion_activa.es_activa IS 'Indica si la sesión es válida actualmente: 1=Activa, 0=Cerrada o expirada';
COMMENT ON COLUMN core_sesion_activa.fecha_inicio IS 'Fecha y hora exacta de inicio de sesión (hora Bogotá)';
COMMENT ON COLUMN core_sesion_activa.fecha_expiracion IS 'Fecha y hora límite de caducidad del token (hora Bogotá)';
COMMENT ON COLUMN core_sesion_activa.ultimo_acceso IS 'Fecha y hora del último request o actividad registrada (hora Bogotá)';
COMMENT ON COLUMN core_sesion_activa.fecha_cierre IS 'Fecha y hora de finalización o revocación (hora Bogotá)';
COMMENT ON COLUMN core_sesion_activa.motivo_cierre IS 'Causa de cierre: LOGOUT, TIMEOUT, REVOCADA_ADMIN, CONCURRENCIA_MAXIMA';
COMMENT ON COLUMN core_sesion_activa.estado_registro IS 'Estado del registro: 1=Activo';
COMMENT ON COLUMN core_sesion_activa.fecha_creacion IS 'Fecha y hora de creación del registro de sesión (hora Bogotá)';
COMMENT ON COLUMN core_sesion_activa.fecha_modificacion IS 'Fecha y hora de última actualización del estado (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 2: CONTEXTOS (2 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 7/38: CORE_USUARIO_CONTEXTO
-- ----------------------------------------------------------------------------
CREATE TABLE core_usuario_contexto (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario NUMBER(12) NOT NULL,
    id_contexto NUMBER(12) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    habilitado NUMBER(1) DEFAULT 1 CHECK (habilitado IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_usuario_contexto PRIMARY KEY (id),
    CONSTRAINT fk_core_uc_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_uc_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT fk_core_uc_contexto FOREIGN KEY (id_contexto) REFERENCES core_contexto(id)
);
CREATE SEQUENCE core_usuario_contexto_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_usuario_contexto
BEFORE INSERT ON core_usuario_contexto
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_usuario_contexto_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_usuario_contexto IS 'Asignación de contextos habilitados y vigencias temporales por usuario';
COMMENT ON COLUMN core_usuario_contexto.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_usuario_contexto.id IS 'Identificador único de la asignación usuario-contexto (PK)';
COMMENT ON COLUMN core_usuario_contexto.id_usuario IS 'Usuario asignado al contexto (FK a core_usuario)';
COMMENT ON COLUMN core_usuario_contexto.id_contexto IS 'Contexto o sucursal autorizada (FK a core_contexto)';
COMMENT ON COLUMN core_usuario_contexto.fecha_inicio IS 'Fecha a partir de la cual el usuario puede operar en el contexto';
COMMENT ON COLUMN core_usuario_contexto.fecha_fin IS 'Fecha límite de vigencia (NULL indica acceso indefinido)';
COMMENT ON COLUMN core_usuario_contexto.habilitado IS 'Bandera de autorización activa: 1=Permitido, 0=Revocado';
COMMENT ON COLUMN core_usuario_contexto.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_usuario_contexto.fecha_creacion IS 'Fecha y hora de vinculación del usuario al contexto (hora Bogotá)';
COMMENT ON COLUMN core_usuario_contexto.fecha_modificacion IS 'Fecha y hora de última actualización del permiso contextual (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 3: ROLES & PERMISOS (3 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 8/38: CORE_ROL
-- ----------------------------------------------------------------------------
CREATE TABLE core_rol (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    codigo VARCHAR2(50) NOT NULL,
    nombre VARCHAR2(255) NOT NULL,
    descripcion VARCHAR2(1000),
    alcance CHAR(1) NOT NULL,
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_rol PRIMARY KEY (id),
    CONSTRAINT fk_core_rol_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT uk_core_rol_codigo UNIQUE (id_tenant, codigo)
);
CREATE SEQUENCE core_rol_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_rol
BEFORE INSERT ON core_rol
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_rol_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_rol IS 'Definición de roles de seguridad por tenant';
COMMENT ON COLUMN core_rol.id_tenant IS 'Identificador del tenant propietario del rol (FK a core_tenant)';
COMMENT ON COLUMN core_rol.id IS 'Identificador numérico secuencial del rol (PK)';
COMMENT ON COLUMN core_rol.codigo IS 'Código nemotécnico único del rol (ADMIN_GENERAL, AUDITOR, MEDICO)';
COMMENT ON COLUMN core_rol.nombre IS 'Nombre representativo del perfil o rol de acceso';
COMMENT ON COLUMN core_rol.descripcion IS 'Descripción del alcance de responsabilidades asignadas al rol';
COMMENT ON COLUMN core_rol.alcance IS 'Ámbito: G = Global al tenant, C = Limitado al contexto activo';
COMMENT ON COLUMN core_rol.estado_registro IS 'Estado del rol: 1=Activo, 0=Inactivo';
COMMENT ON COLUMN core_rol.fecha_creacion IS 'Fecha y hora de alta del rol en la plataforma (hora Bogotá)';
COMMENT ON COLUMN core_rol.fecha_modificacion IS 'Fecha y hora de última modificación del rol (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 9/38: CORE_PERMISO
-- ----------------------------------------------------------------------------
CREATE TABLE core_permiso (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_rol NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12),
    modulo VARCHAR2(100) NOT NULL,
    accion VARCHAR2(100) NOT NULL,
    descripcion VARCHAR2(500),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_permiso PRIMARY KEY (id),
    CONSTRAINT fk_core_permiso_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_permiso_rol FOREIGN KEY (id_rol) REFERENCES core_rol(id),
    CONSTRAINT fk_core_permiso_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT uk_core_permiso UNIQUE (id_tenant, id_rol, id_aplicacion, modulo, accion)
);
CREATE SEQUENCE core_permiso_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_permiso
BEFORE INSERT ON core_permiso
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_permiso_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_permiso IS 'Matriz de privilegios detallada por aplicación, módulo y acción para cada rol';
COMMENT ON COLUMN core_permiso.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_permiso.id IS 'Identificador secuencial del permiso (PK)';
COMMENT ON COLUMN core_permiso.id_rol IS 'Rol al que se le confiere el privilegio (FK a core_rol)';
COMMENT ON COLUMN core_permiso.id_aplicacion IS 'Aplicación sobre la que aplica el privilegio (FK a core_aplicacion)';
COMMENT ON COLUMN core_permiso.modulo IS 'Código del módulo funcional (FACTURACION, PACIENTES, CITAS)';
COMMENT ON COLUMN core_permiso.accion IS 'Operación atómica permitida (CREAR, CONSULTAR, EDITAR, ANULAR, EXPORTAR)';
COMMENT ON COLUMN core_permiso.descripcion IS 'Justificación y explicación funcional de la regla de acceso';
COMMENT ON COLUMN core_permiso.estado_registro IS 'Estado del permiso: 1=Habilitado, 0=Deshabilitado';
COMMENT ON COLUMN core_permiso.fecha_creacion IS 'Fecha y hora de creación de la regla de acceso (hora Bogotá)';
COMMENT ON COLUMN core_permiso.fecha_modificacion IS 'Fecha y hora de última actualización del privilegio (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 10/38: CORE_USUARIO_ROL
-- ----------------------------------------------------------------------------
CREATE TABLE core_usuario_rol (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario NUMBER(12) NOT NULL,
    id_rol NUMBER(12) NOT NULL,
    id_contexto NUMBER(12),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    habilitado NUMBER(1) DEFAULT 1 CHECK (habilitado IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_usuario_rol PRIMARY KEY (id),
    CONSTRAINT fk_core_usuariorol_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_usuariorol_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT fk_core_usuariorol_rol FOREIGN KEY (id_rol) REFERENCES core_rol(id),
    CONSTRAINT fk_core_usuariorol_contexto FOREIGN KEY (id_contexto) REFERENCES core_contexto(id)
);
CREATE SEQUENCE core_usuario_rol_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_usuario_rol_hab ON core_usuario_rol(id_tenant, id_usuario, habilitado);

CREATE OR REPLACE TRIGGER trg_bi_core_usuario_rol
BEFORE INSERT ON core_usuario_rol
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_usuario_rol_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_usuario_rol IS 'Asociación de usuarios a roles con vigencia y contexto';
COMMENT ON COLUMN core_usuario_rol.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_usuario_rol.id IS 'Identificador único de la asignación del rol al usuario (PK)';
COMMENT ON COLUMN core_usuario_rol.id_usuario IS 'Usuario al que se le confiere el rol (FK a core_usuario)';
COMMENT ON COLUMN core_usuario_rol.id_rol IS 'Rol asignado al usuario (FK a core_rol)';
COMMENT ON COLUMN core_usuario_rol.id_contexto IS 'Contexto específico donde aplica el rol (NULL si es global)';
COMMENT ON COLUMN core_usuario_rol.fecha_inicio IS 'Fecha inicial de vigencia de la asignación';
COMMENT ON COLUMN core_usuario_rol.fecha_fin IS 'Fecha final de vigencia (NULL para indefinido)';
COMMENT ON COLUMN core_usuario_rol.habilitado IS 'Indica si el rol está activo en el momento: 1=Sí, 0=No';
COMMENT ON COLUMN core_usuario_rol.estado_registro IS 'Estado del registro: 1=Activo, 0=Borrado lógico';
COMMENT ON COLUMN core_usuario_rol.fecha_creacion IS 'Fecha y hora de concesión del rol (hora Bogotá)';
COMMENT ON COLUMN core_usuario_rol.fecha_modificacion IS 'Fecha y hora de última modificación en la membresía (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 4: AUDITORÍA DE CAMBIOS EN SEGURIDAD (1 TABLA)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 11/38: CORE_AUDITORIA_USUARIO_ROL
-- ----------------------------------------------------------------------------
CREATE TABLE core_auditoria_usuario_rol (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario_rol NUMBER(12) NOT NULL,
    id_usuario NUMBER(12) NOT NULL,
    id_admin NUMBER(12),
    accion VARCHAR2(50) NOT NULL,
    descripcion VARCHAR2(500),
    valor_anterior VARCHAR2(100),
    valor_nuevo VARCHAR2(100),
    direccion_ip VARCHAR2(50),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_audit_rol PRIMARY KEY (id),
    CONSTRAINT fk_core_audit_rol_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_audit_rol_usuario_rol FOREIGN KEY (id_usuario_rol) REFERENCES core_usuario_rol(id),
    CONSTRAINT fk_core_audit_rol_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT fk_core_audit_rol_admin FOREIGN KEY (id_admin) REFERENCES core_usuario(id),
    CONSTRAINT ck_core_audit_accion CHECK (accion IN ('ACTIVADO', 'DESACTIVADO', 'VIGENCIA_MODIFICADA', 'CREADO', 'ELIMINADO'))
);
CREATE SEQUENCE core_auditoria_usuario_rol_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_audit_rol_usuario ON core_auditoria_usuario_rol(id_tenant, id_usuario, fecha_creacion);

CREATE OR REPLACE TRIGGER trg_bi_core_auditoria_usuario_rol
BEFORE INSERT ON core_auditoria_usuario_rol
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_auditoria_usuario_rol_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_auditoria_usuario_rol IS 'Pista de auditoría forense para cambios de roles y permisos';
COMMENT ON COLUMN core_auditoria_usuario_rol.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_auditoria_usuario_rol.id IS 'Identificador de la traza de auditoría (PK)';
COMMENT ON COLUMN core_auditoria_usuario_rol.id_usuario_rol IS 'Asignación de usuario-rol afectada (FK a core_usuario_rol)';
COMMENT ON COLUMN core_auditoria_usuario_rol.id_usuario IS 'Usuario final afectado por la modificación de seguridad (FK a core_usuario)';
COMMENT ON COLUMN core_auditoria_usuario_rol.id_admin IS 'Usuario administrador que ejecutó la acción (FK a core_usuario)';
COMMENT ON COLUMN core_auditoria_usuario_rol.accion IS 'Operación efectuada: CREADO, ACTIVADO, DESACTIVADO, VIGENCIA_MODIFICADA, ELIMINADO';
COMMENT ON COLUMN core_auditoria_usuario_rol.descripcion IS 'Motivo o detalle explicativo de la alteración de seguridad';
COMMENT ON COLUMN core_auditoria_usuario_rol.valor_anterior IS 'Valor previo del atributo modificado';
COMMENT ON COLUMN core_auditoria_usuario_rol.valor_nuevo IS 'Valor resultante asignado al atributo';
COMMENT ON COLUMN core_auditoria_usuario_rol.direccion_ip IS 'Dirección IP de origen desde donde se realizó la gestión';
COMMENT ON COLUMN core_auditoria_usuario_rol.fecha_creacion IS 'Fecha y hora exacta del cambio en zona horaria Bogotá';

-- ============================================================================
-- SECCIÓN 5: MENÚ DINÁMICO (1 TABLA)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 12/38: CORE_MENU_DINAMICO
-- ----------------------------------------------------------------------------
CREATE TABLE core_menu_dinamico (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_rol NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12),
    modulo VARCHAR2(100),
    nombre_opcion VARCHAR2(255) NOT NULL,
    icono VARCHAR2(50),
    url_relativa VARCHAR2(500),
    orden NUMBER(5),
    habilitado NUMBER(1) DEFAULT 1 CHECK (habilitado IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_menu PRIMARY KEY (id),
    CONSTRAINT fk_core_menu_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_menu_rol FOREIGN KEY (id_rol) REFERENCES core_rol(id),
    CONSTRAINT fk_core_menu_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id)
);
CREATE SEQUENCE core_menu_dinamico_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_menu_rol ON core_menu_dinamico(id_tenant, id_rol, habilitado);

CREATE OR REPLACE TRIGGER trg_bi_core_menu_dinamico
BEFORE INSERT ON core_menu_dinamico
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_menu_dinamico_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_menu_dinamico IS 'Estructura de navegación frontal dinámica filtrada por rol y aplicación';
COMMENT ON COLUMN core_menu_dinamico.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_menu_dinamico.id IS 'Identificador de la opción de navegación del menú (PK)';
COMMENT ON COLUMN core_menu_dinamico.id_rol IS 'Rol con visibilidad autorizada sobre esta opción (FK a core_rol)';
COMMENT ON COLUMN core_menu_dinamico.id_aplicacion IS 'Aplicación dueña de la opción de navegación (FK a core_aplicacion)';
COMMENT ON COLUMN core_menu_dinamico.modulo IS 'Módulo funcional al que pertenece el enlace';
COMMENT ON COLUMN core_menu_dinamico.nombre_opcion IS 'Texto de visualización en la barra lateral o barra de navegación';
COMMENT ON COLUMN core_menu_dinamico.icono IS 'Clase CSS o identificador del icono de la interfaz gráfica';
COMMENT ON COLUMN core_menu_dinamico.url_relativa IS 'Ruta de enrutamiento frontend o endpoint web';
COMMENT ON COLUMN core_menu_dinamico.orden IS 'Posición secuencial de ordenamiento en la interfaz';
COMMENT ON COLUMN core_menu_dinamico.habilitado IS 'Disponibilidad visual: 1=Visible, 0=Oculto temporalmente';
COMMENT ON COLUMN core_menu_dinamico.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_menu_dinamico.fecha_creacion IS 'Fecha y hora de alta de la opción de menú (hora Bogotá)';
COMMENT ON COLUMN core_menu_dinamico.fecha_modificacion IS 'Fecha y hora de última modificación del menú (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 6: NOTIFICACIONES & VARIABLES (4 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 13/38: CORE_PLANTILLA_NOTIFICACION
-- ----------------------------------------------------------------------------
CREATE TABLE core_plantilla_notificacion (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12),
    id_plantilla_padre NUMBER(12),
    es_layout NUMBER(1) DEFAULT 0 CHECK (es_layout IN (0, 1)),
    etiqueta_incrustacion VARCHAR2(50) DEFAULT '{{cuerpo_mensaje}}',
    estilo_css CLOB,
    tiene_auditoria NUMBER(1) DEFAULT 1 CHECK (tiene_auditoria IN (0, 1)),
    tipo_evento VARCHAR2(100),
    nombre VARCHAR2(255) NOT NULL,
    asunto VARCHAR2(500),
    contenido CLOB NOT NULL,
    canal VARCHAR2(50) NOT NULL,
    idioma CHAR(2) DEFAULT 'ES',
    activa NUMBER(1) DEFAULT 1 CHECK (activa IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_plantilla_notif PRIMARY KEY (id),
    CONSTRAINT fk_core_plantilla_notif_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_plantilla_notif_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT fk_core_plantilla_notif_padre FOREIGN KEY (id_plantilla_padre) REFERENCES core_plantilla_notificacion(id)
);
CREATE SEQUENCE core_plantilla_notificacion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_plantilla_padre ON core_plantilla_notificacion(id_plantilla_padre);

CREATE OR REPLACE TRIGGER trg_bi_core_plantilla_notificacion
BEFORE INSERT ON core_plantilla_notificacion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_plantilla_notificacion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_plantilla_notificacion IS 'Plantillas de mensajes parametrizables para correo, SMS o WhatsApp';
COMMENT ON COLUMN core_plantilla_notificacion.id IS 'Identificador único de la plantilla de mensaje (PK)';
COMMENT ON COLUMN core_plantilla_notificacion.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_plantilla_notificacion.id_aplicacion IS 'Aplicación que utiliza la plantilla (FK a core_aplicacion)';
COMMENT ON COLUMN core_plantilla_notificacion.id_plantilla_padre IS 'Plantilla padre o layout envolvente con los estilos corporativos (FK reflexiva)';
COMMENT ON COLUMN core_plantilla_notificacion.es_layout IS 'Indica si es un layout maestro/marco visual: 1=Sí, 0=No/Hija';
COMMENT ON COLUMN core_plantilla_notificacion.etiqueta_incrustacion IS 'Tag comodín reservado en el padre donde se inyecta el contenido hijo (ej. {{cuerpo_mensaje}})';
COMMENT ON COLUMN core_plantilla_notificacion.estilo_css IS 'Hojas de estilo CSS o variables de tema inyectadas por la plantilla padre';
COMMENT ON COLUMN core_plantilla_notificacion.tiene_auditoria IS 'Bandera de auditoría: 1=Generar registro de auditoría en despachos, 0=Sin auditoría';
COMMENT ON COLUMN core_plantilla_notificacion.tipo_evento IS 'Código del evento originador (RECORDATORIO_CITA, BIENVENIDA_USUARIO)';
COMMENT ON COLUMN core_plantilla_notificacion.nombre IS 'Nombre comercial o técnico de la plantilla';
COMMENT ON COLUMN core_plantilla_notificacion.asunto IS 'Línea de asunto del mensaje (aplica para EMAIL)';
COMMENT ON COLUMN core_plantilla_notificacion.contenido IS 'Cuerpo del mensaje en HTML o texto con variables dinámicas {{nombre}}';
COMMENT ON COLUMN core_plantilla_notificacion.canal IS 'Canal de envío: EMAIL, SMS, WHATSAPP, PUSH_NOTIFICATION';
COMMENT ON COLUMN core_plantilla_notificacion.idioma IS 'Código ISO 639-1 del idioma de la plantilla (por defecto ES)';
COMMENT ON COLUMN core_plantilla_notificacion.activa IS 'Indica si la plantilla está habilitada para despacho: 1=Sí, 0=No';
COMMENT ON COLUMN core_plantilla_notificacion.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_plantilla_notificacion.fecha_creacion IS 'Fecha y hora de diseño de la plantilla (hora Bogotá)';
COMMENT ON COLUMN core_plantilla_notificacion.fecha_modificacion IS 'Fecha y hora de última modificación del diseño (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 14/38: CORE_PLANTILLA_VARIABLE
-- ----------------------------------------------------------------------------
CREATE TABLE core_plantilla_variable (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_plantilla NUMBER(12) NOT NULL,
    nombre_variable VARCHAR2(60) NOT NULL,
    etiqueta_variable VARCHAR2(70) NOT NULL,
    descripcion VARCHAR2(255),
    tipo_dato VARCHAR2(30) DEFAULT 'STRING' CHECK (tipo_dato IN ('STRING', 'NUMBER', 'DATE', 'BOOLEAN', 'URL', 'MONEDA')),
    es_obligatoria NUMBER(1) DEFAULT 1 CHECK (es_obligatoria IN (0, 1)),
    valor_defecto VARCHAR2(500),
    ejemplo_valor VARCHAR2(500),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_plantilla_var PRIMARY KEY (id),
    CONSTRAINT fk_core_plantilla_var_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_plantilla_var_plnt FOREIGN KEY (id_plantilla) REFERENCES core_plantilla_notificacion(id),
    CONSTRAINT uk_core_plantilla_var UNIQUE (id_tenant, id_plantilla, nombre_variable)
);
CREATE SEQUENCE core_plantilla_variable_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_plantilla_var ON core_plantilla_variable(id_tenant, id_plantilla);

CREATE OR REPLACE TRIGGER trg_bi_core_plantilla_variable
BEFORE INSERT ON core_plantilla_variable
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_plantilla_variable_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_plantilla_variable IS 'Variables dinámicas requeridas por plantilla para validación previa al envío';
COMMENT ON COLUMN core_plantilla_variable.id IS 'Identificador único de la variable de plantilla (PK)';
COMMENT ON COLUMN core_plantilla_variable.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_plantilla_variable.id_plantilla IS 'Plantilla que utiliza la variable (FK a core_plantilla_notificacion)';
COMMENT ON COLUMN core_plantilla_variable.nombre_variable IS 'Nombre técnico de la variable sin delimitadores (ej. nombre_usuario, fecha_cita)';
COMMENT ON COLUMN core_plantilla_variable.etiqueta_variable IS 'Tag comodín exacto dentro de la plantilla (ej. {{nombre_usuario}})';
COMMENT ON COLUMN core_plantilla_variable.descripcion IS 'Descripción del propósito y origen de la variable en el mensaje';
COMMENT ON COLUMN core_plantilla_variable.tipo_dato IS 'Tipo de dato esperado: STRING, NUMBER, DATE, BOOLEAN, URL, MONEDA';
COMMENT ON COLUMN core_plantilla_variable.es_obligatoria IS 'Validación previa: 1=Obligatoria (impide envío si falta), 0=Opcional';
COMMENT ON COLUMN core_plantilla_variable.valor_defecto IS 'Valor predeterminado si es opcional y no se proporciona en el payload';
COMMENT ON COLUMN core_plantilla_variable.ejemplo_valor IS 'Valor de ejemplo para previsualización y pruebas del template';
COMMENT ON COLUMN core_plantilla_variable.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_plantilla_variable.fecha_creacion IS 'Fecha de configuración de la variable (hora Bogotá)';
COMMENT ON COLUMN core_plantilla_variable.fecha_modificacion IS 'Fecha de última modificación (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 15/38: CORE_MODULO_APP
-- ----------------------------------------------------------------------------
CREATE TABLE core_modulo_app (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12) NOT NULL,
    codigo VARCHAR2(100) NOT NULL,
    nombre VARCHAR2(255) NOT NULL,
    descripcion VARCHAR2(1000),
    habilitado_por_defecto NUMBER(1) DEFAULT 1 CHECK (habilitado_por_defecto IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_modulo_app PRIMARY KEY (id),
    CONSTRAINT fk_core_modulo_app_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_modulo_app_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT uk_core_modulo_app UNIQUE (id_tenant, id_aplicacion, codigo)
);
CREATE SEQUENCE core_modulo_app_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_modulo_app
BEFORE INSERT ON core_modulo_app
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_modulo_app_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_modulo_app IS 'Módulos funcionales desagregados pertenecientes a una aplicación';
COMMENT ON COLUMN core_modulo_app.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_modulo_app.id IS 'Identificador único del módulo funcional (PK)';
COMMENT ON COLUMN core_modulo_app.id_aplicacion IS 'Aplicación padre a la que pertenece el módulo (FK a core_aplicacion)';
COMMENT ON COLUMN core_modulo_app.codigo IS 'Código funcional único del módulo (CITAS, FACTURAS, HISTORIA)';
COMMENT ON COLUMN core_modulo_app.nombre IS 'Nombre comercial del módulo para los usuarios';
COMMENT ON COLUMN core_modulo_app.descripcion IS 'Detalle de casos de uso cubiertos por el módulo';
COMMENT ON COLUMN core_modulo_app.habilitado_por_defecto IS 'Indica si se activa automáticamente al contratar la app: 1=Sí, 0=No';
COMMENT ON COLUMN core_modulo_app.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_modulo_app.fecha_creacion IS 'Fecha y hora de alta del módulo (hora Bogotá)';
COMMENT ON COLUMN core_modulo_app.fecha_modificacion IS 'Fecha y hora de última modificación del módulo (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 11: MOTOR DE PRUEBAS DE OBJETOS PL/SQL (7 TABLAS)
-- Estándar: Invocación frontend con p_json_entrada (CLOB) y p_json_salida (CLOB)
-- ============================================================================

-- 11.1 Catálogo de Objetos/Endpoints Testeables

-- ----------------------------------------------------------------------------
-- TABLA 16/38: CORE_TEST_OBJETO
-- ----------------------------------------------------------------------------
CREATE TABLE core_test_objeto (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
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
    CONSTRAINT pk_core_test_objeto PRIMARY KEY (id),
    CONSTRAINT fk_core_test_obj_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_test_obj_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT fk_core_test_obj_mod FOREIGN KEY (id_modulo) REFERENCES core_modulo_app(id),
    CONSTRAINT uk_core_test_objeto UNIQUE (id_tenant, esquema, nombre_paquete, nombre_metodo),
    CONSTRAINT ck_core_test_obj_tipo CHECK (tipo_objeto IN ('PROCEDURE', 'FUNCTION', 'PACKAGE_BODY')),
    CONSTRAINT ck_core_test_schema_in CHECK (json_schema_entrada IS NULL OR json_schema_entrada IS JSON (LAX)),
    CONSTRAINT ck_core_test_schema_out CHECK (json_schema_salida IS NULL OR json_schema_salida IS JSON (LAX)),
    CONSTRAINT ck_core_test_ejemplo_in CHECK (ejemplo_json_entrada IS NULL OR ejemplo_json_entrada IS JSON (LAX))
);
CREATE SEQUENCE core_test_objeto_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_test_obj_pkg ON core_test_objeto(id_tenant, nombre_paquete, nombre_metodo);

CREATE OR REPLACE TRIGGER trg_bi_core_test_objeto
BEFORE INSERT ON core_test_objeto
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_test_objeto_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_test_objeto IS 'Catálogo de procedimientos y funciones PL/SQL invocables desde el frontend con firma estándar JSON';
COMMENT ON COLUMN core_test_objeto.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_test_objeto.id IS 'Identificador único del objeto en el catálogo de pruebas (PK)';
COMMENT ON COLUMN core_test_objeto.id_aplicacion IS 'Aplicación SaaS a la que pertenece el endpoint (FK a core_aplicacion)';
COMMENT ON COLUMN core_test_objeto.id_modulo IS 'Módulo funcional de pertenencia del procedimiento (FK a core_modulo_app)';
COMMENT ON COLUMN core_test_objeto.esquema IS 'Esquema de Oracle donde reside el objeto (por defecto USER)';
COMMENT ON COLUMN core_test_objeto.nombre_paquete IS 'Nombre del paquete PL/SQL orquestador (pkgln_usuarios, pkgln_citas)';
COMMENT ON COLUMN core_test_objeto.nombre_metodo IS 'Nombre del procedimiento expuesto (p_crear_usuario, p_iniciar_sesion)';
COMMENT ON COLUMN core_test_objeto.tipo_objeto IS 'Tipo de objeto: PROCEDURE, FUNCTION, PACKAGE_BODY';
COMMENT ON COLUMN core_test_objeto.tipo_invocacion IS 'Mecanismo de interfaz: JSON_IN_OUT (estándar frontend)';
COMMENT ON COLUMN core_test_objeto.param_entrada_nombre IS 'Nombre del parámetro formal CLOB de entrada (estándar: p_json_entrada)';
COMMENT ON COLUMN core_test_objeto.param_salida_nombre IS 'Nombre del parámetro formal CLOB de salida (estándar: p_json_salida)';
COMMENT ON COLUMN core_test_objeto.descripcion IS 'Explicación del caso de uso y propósito del subprograma PL/SQL';
COMMENT ON COLUMN core_test_objeto.json_schema_entrada IS 'Definición formal JSON Schema para validar la estructura esperada de entrada';
COMMENT ON COLUMN core_test_objeto.json_schema_salida IS 'Definición formal JSON Schema para validar la estructura de respuesta';
COMMENT ON COLUMN core_test_objeto.ejemplo_json_entrada IS 'Payload JSON de ejemplo listo para ser inyectado en pruebas manuales';
COMMENT ON COLUMN core_test_objeto.requiere_transaccion IS 'Indica si ejecuta p_do_commit controlado: 1=Sí, 0=Solo consulta';
COMMENT ON COLUMN core_test_objeto.es_activo IS 'Bandera de disponibilidad para el runner: 1=Habilitado, 0=Inactivo';
COMMENT ON COLUMN core_test_objeto.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_test_objeto.fecha_creacion IS 'Fecha y hora de registro del objeto en el catálogo (hora Bogotá)';
COMMENT ON COLUMN core_test_objeto.fecha_modificacion IS 'Fecha y hora de última modificación del objeto (hora Bogotá)';

-- 11.2 Baterías y Suites de Pruebas

-- ----------------------------------------------------------------------------
-- TABLA 17/38: CORE_TRAZA_CONFIG
-- ----------------------------------------------------------------------------
CREATE TABLE core_traza_config (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
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
    CONSTRAINT pk_core_traza_config PRIMARY KEY (id),
    CONSTRAINT fk_core_trazas_cfg_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_trazas_cfg_obj FOREIGN KEY (id_objeto) REFERENCES core_test_objeto(id),
    CONSTRAINT fk_core_trazas_cfg_usr FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT ck_core_trazas_cfg_det CHECK (nivel_detalle IN ('CABECERA_SOLO', 'COMPLETO', 'SOLO_ERRORES'))
);
CREATE SEQUENCE core_traza_config_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_trazas_cfg_filtro ON core_traza_config(id_tenant, nombre_paquete, nombre_metodo, es_activo);

CREATE OR REPLACE TRIGGER trg_bi_core_traza_config
BEFORE INSERT ON core_traza_config
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_traza_config_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_traza_config IS 'Reglas de activación dinámica de seguimiento y telemetría por objeto, usuario o ventana temporal';
COMMENT ON COLUMN core_traza_config.id_tenant IS 'Identificador del tenant propietario de la regla (FK a core_tenant)';
COMMENT ON COLUMN core_traza_config.id IS 'Identificador único de la regla de seguimiento (PK)';
COMMENT ON COLUMN core_traza_config.id_objeto IS 'Objeto específico a seguir (FK a core_test_objeto, NULL = evalúa por nombre)';
COMMENT ON COLUMN core_traza_config.id_usuario IS 'Usuario específico a monitorear (FK a core_usuario, NULL = todos los usuarios)';
COMMENT ON COLUMN core_traza_config.nombre_paquete IS 'Filtro por nombre de paquete (e.g. pkgln_usuarios, pkgcn_citas o comodín %)';
COMMENT ON COLUMN core_traza_config.nombre_metodo IS 'Filtro por nombre de subprograma (e.g. p_crear_usuario o comodín %)';
COMMENT ON COLUMN core_traza_config.fecha_desde IS 'Fecha y hora inicial en que el seguimiento se activa (hora Bogotá, opcional)';
COMMENT ON COLUMN core_traza_config.fecha_hasta IS 'Fecha y hora final de vigencia del seguimiento (hora Bogotá, opcional)';
COMMENT ON COLUMN core_traza_config.nivel_detalle IS 'Nivel de captura: CABECERA_SOLO (tiempos), COMPLETO (con llamados), SOLO_ERRORES';
COMMENT ON COLUMN core_traza_config.grabar_payloads IS 'Indica si persiste los CLOBs de entrada y salida: 1=Sí, 0=No (solo métricas)';
COMMENT ON COLUMN core_traza_config.es_activo IS 'Bandera de activación de la regla: 1=Monitoreo activo, 0=Pausado';
COMMENT ON COLUMN core_traza_config.descripcion IS 'Motivo o ticket del requerimiento de auditoría o profiling';
COMMENT ON COLUMN core_traza_config.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_traza_config.fecha_creacion IS 'Fecha y hora de creación de la regla de configuración (hora Bogotá)';
COMMENT ON COLUMN core_traza_config.fecha_modificacion IS 'Fecha y hora de última modificación de la regla (hora Bogotá)';

-- 12.2 Cabecera de Ejecución de Trazas (Trace Header & Root Invocations)

-- ----------------------------------------------------------------------------
-- TABLA 18/38: CORE_TRAZA_EJECUCION
-- ----------------------------------------------------------------------------
CREATE TABLE core_traza_ejecucion (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
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
    CONSTRAINT pk_core_traza_ejecucion PRIMARY KEY (id),
    CONSTRAINT fk_core_trazas_ejec_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_trazas_ejec_cfg FOREIGN KEY (id_config) REFERENCES core_traza_config(id),
    CONSTRAINT fk_core_trazas_ejec_obj FOREIGN KEY (id_objeto) REFERENCES core_test_objeto(id),
    CONSTRAINT fk_core_trazas_ejec_usr FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT ck_core_trazas_ejec_est CHECK (estado IN ('EN_PROCESO', 'EXITO', 'ERROR', 'TIMEOUT')),
    CONSTRAINT ck_core_trazas_in_json CHECK (json_entrada IS NULL OR json_entrada IS JSON (LAX)),
    CONSTRAINT ck_core_trazas_out_json CHECK (json_salida IS NULL OR json_salida IS JSON (LAX))
);
CREATE SEQUENCE core_traza_ejecucion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_trazas_ejec_obj ON core_traza_ejecucion(id_tenant, nombre_paquete, nombre_metodo, fecha_inicio);
CREATE INDEX idx_core_trazas_ejec_usr ON core_traza_ejecucion(id_tenant, id_usuario, fecha_inicio);
CREATE INDEX idx_core_trazas_ejec_trid ON core_traza_ejecucion(codigo_traza);

CREATE OR REPLACE TRIGGER trg_bi_core_traza_ejecucion
BEFORE INSERT ON core_traza_ejecucion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_traza_ejecucion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_traza_ejecucion IS 'Cabecera de ejecuciones monitoreadas: tiempos de inicio/fin, payloads entrada/salida y estado global';
COMMENT ON COLUMN core_traza_ejecucion.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_traza_ejecucion.id IS 'Identificador único de la sesión de seguimiento de ejecución (PK)';
COMMENT ON COLUMN core_traza_ejecucion.id_config IS 'Regla de configuración que detonó la captura de esta traza (FK a core_traza_config)';
COMMENT ON COLUMN core_traza_ejecucion.id_objeto IS 'Objeto o procedimiento principal invocado (FK a core_test_objeto)';
COMMENT ON COLUMN core_traza_ejecucion.id_usuario IS 'Usuario autenticado que detonó la transacción (FK a core_usuario)';
COMMENT ON COLUMN core_traza_ejecucion.nombre_paquete IS 'Nombre del paquete raíz ejecutado (e.g. pkgln_usuarios)';
COMMENT ON COLUMN core_traza_ejecucion.nombre_metodo IS 'Nombre del procedimiento raíz ejecutado (e.g. p_crear_usuario)';
COMMENT ON COLUMN core_traza_ejecucion.codigo_traza IS 'Identificador único de correlación global / UUID emitido por el Gateway o TraceContext';
COMMENT ON COLUMN core_traza_ejecucion.ip_origen IS 'Dirección IP del cliente que realizó la petición';
COMMENT ON COLUMN core_traza_ejecucion.id_sesion_oracle IS 'Identificador de sesión interna de Oracle Database (SID / Audsid)';
COMMENT ON COLUMN core_traza_ejecucion.fecha_inicio IS 'Fecha y hora exacta en que comenzó la ejecución del objeto (hora Bogotá)';
COMMENT ON COLUMN core_traza_ejecucion.fecha_fin IS 'Fecha y hora exacta en que culminó la ejecución del objeto (hora Bogotá)';
COMMENT ON COLUMN core_traza_ejecucion.duracion_ms IS 'Duración total de la transacción en milisegundos';
COMMENT ON COLUMN core_traza_ejecucion.estado IS 'Veredicto de ejecución: EN_PROCESO, EXITO, ERROR, TIMEOUT';
COMMENT ON COLUMN core_traza_ejecucion.codigo_error IS 'SQLCODE o código de error capturado en caso de fallo';
COMMENT ON COLUMN core_traza_ejecucion.mensaje_error IS 'Mensaje de error descriptivo o traza ORA-XXXXX';
COMMENT ON COLUMN core_traza_ejecucion.json_entrada IS 'Payload CLOB exacto inyectado en el parámetro p_json_entrada';
COMMENT ON COLUMN core_traza_ejecucion.json_salida IS 'Payload CLOB devuelto en el parámetro p_json_salida';
COMMENT ON COLUMN core_traza_ejecucion.total_llamados IS 'Cantidad total de subprogramas invocados registrados en el detalle';
COMMENT ON COLUMN core_traza_ejecucion.estado_registro IS 'Estado del registro: 1=Activo';
COMMENT ON COLUMN core_traza_ejecucion.fecha_creacion IS 'Fecha y hora de inserción del registro en la base de datos (hora Bogotá)';

-- 12.3 Detalle Secuencial y Pila de Sub-Llamados (Trace Spans / Call Stack)

-- ----------------------------------------------------------------------------
-- TABLA 19/38: CORE_NOTIFICACION
-- ----------------------------------------------------------------------------
CREATE TABLE core_notificacion (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario NUMBER(12),
    id_plantilla NUMBER(12) NOT NULL,
    destinatario VARCHAR2(500) NOT NULL,
    asunto VARCHAR2(500),
    contenido_final CLOB NOT NULL,
    variables_json CLOB,
    canal VARCHAR2(50) NOT NULL,
    estado VARCHAR2(50) DEFAULT 'PENDIENTE',
    referencia_externa VARCHAR2(200),
    tiene_auditoria NUMBER(1) DEFAULT 1 CHECK (tiene_auditoria IN (0, 1)),
    id_traza_ejecucion NUMBER(12),
    codigo_traza VARCHAR2(100),
    fecha_entrega DATE,
    fecha_lectura DATE,
    fecha_respuesta DATE,
    respuesta CLOB,
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_notificacion PRIMARY KEY (id),
    CONSTRAINT fk_core_notif_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_notif_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT fk_core_notif_plantilla FOREIGN KEY (id_plantilla) REFERENCES core_plantilla_notificacion(id),
    CONSTRAINT fk_core_notif_traza FOREIGN KEY (id_traza_ejecucion) REFERENCES core_traza_ejecucion(id)
);
CREATE SEQUENCE core_notificacion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_notif_usuario ON core_notificacion(id_tenant, id_usuario, fecha_creacion);

CREATE OR REPLACE TRIGGER trg_bi_core_notificacion
BEFORE INSERT ON core_notificacion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_notificacion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_notificacion IS 'Bandeja y log transaccional de notificaciones enviadas y pendientes';
COMMENT ON COLUMN core_notificacion.id IS 'Identificador del mensaje generado (PK)';
COMMENT ON COLUMN core_notificacion.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_notificacion.id_usuario IS 'Usuario receptor en el sistema (FK a core_usuario, opcional)';
COMMENT ON COLUMN core_notificacion.id_plantilla IS 'Plantilla base utilizada para la composición (FK a core_plantilla_notificacion)';
COMMENT ON COLUMN core_notificacion.destinatario IS 'Dirección de destino (correo electrónico, número celular E.164)';
COMMENT ON COLUMN core_notificacion.asunto IS 'Asunto final compilado con variables resueltas';
COMMENT ON COLUMN core_notificacion.contenido_final IS 'Texto o HTML exacto entregado al cliente tras sustituir variables e incrustar en plantilla padre';
COMMENT ON COLUMN core_notificacion.variables_json IS 'Payload JSON con los valores utilizados para sustituir las variables dinámicas';
COMMENT ON COLUMN core_notificacion.canal IS 'Canal de entrega: EMAIL, SMS, WHATSAPP, PUSH';
COMMENT ON COLUMN core_notificacion.estado IS 'Ciclo de vida: PENDIENTE, ENVIADO, ENTREGADO, LEIDO, FALLIDO, RESPONDIDO';
COMMENT ON COLUMN core_notificacion.referencia_externa IS 'Message ID provisto por la pasarela (SendGrid, Twilio, Meta)';
COMMENT ON COLUMN core_notificacion.tiene_auditoria IS 'Bandera de auditoría: 1=Registrar trazabilidad en core_auditoria, 0=Omitir';
COMMENT ON COLUMN core_notificacion.id_traza_ejecucion IS 'Identificador de la traza de ejecución en base de datos (FK a core_traza_ejecucion)';
COMMENT ON COLUMN core_notificacion.codigo_traza IS 'Identificador único de correlación / Trace ID (UUID) para observabilidad distribuida (APM)';
COMMENT ON COLUMN core_notificacion.fecha_entrega IS 'Fecha y hora en que el gateway confirmó entrega exitosa (hora Bogotá)';
COMMENT ON COLUMN core_notificacion.fecha_lectura IS 'Fecha y hora en que el destinatario abrió el mensaje (hora Bogotá)';
COMMENT ON COLUMN core_notificacion.fecha_respuesta IS 'Fecha y hora de la interacción del usuario (hora Bogotá)';
COMMENT ON COLUMN core_notificacion.respuesta IS 'Texto o payload recibido como contestación del destinatario';
COMMENT ON COLUMN core_notificacion.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_notificacion.fecha_creacion IS 'Fecha y hora de generación de la notificación (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 20/38: CORE_PREFERENCIA_NOTIFICACION
-- ----------------------------------------------------------------------------
CREATE TABLE core_preferencia_notificacion (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario NUMBER(12) NOT NULL,
    canal VARCHAR2(50) NOT NULL,
    habilitado NUMBER(1) DEFAULT 1 CHECK (habilitado IN (0, 1)),
    horario_inicio CHAR(5),
    horario_fin CHAR(5),
    consentimiento_gdpr NUMBER(1) DEFAULT 0 CHECK (consentimiento_gdpr IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_pref_notif PRIMARY KEY (id),
    CONSTRAINT fk_core_pref_notif_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_pref_notif_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT uk_core_pref_notif UNIQUE (id_tenant, id_usuario, canal)
);
CREATE SEQUENCE core_preferencia_notificacion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_preferencia_notificacion
BEFORE INSERT ON core_preferencia_notificacion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_preferencia_notificacion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_preferencia_notificacion IS 'Canales y horarios permitidos por cada usuario para recepción de alertas';
COMMENT ON COLUMN core_preferencia_notificacion.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_preferencia_notificacion.id IS 'Identificador único de la preferencia (PK)';
COMMENT ON COLUMN core_preferencia_notificacion.id_usuario IS 'Usuario titular de las preferencias (FK a core_usuario)';
COMMENT ON COLUMN core_preferencia_notificacion.canal IS 'Canal regulado: EMAIL, SMS, WHATSAPP, PUSH';
COMMENT ON COLUMN core_preferencia_notificacion.habilitado IS 'Autorización del usuario: 1=Permitido, 0=Bloqueado por usuario';
COMMENT ON COLUMN core_preferencia_notificacion.horario_inicio IS 'Hora inicial permitida en formato HH:MM (e.g. 08:00)';
COMMENT ON COLUMN core_preferencia_notificacion.horario_fin IS 'Hora final permitida en formato HH:MM (e.g. 20:00)';
COMMENT ON COLUMN core_preferencia_notificacion.consentimiento_gdpr IS 'Consentimiento explícito conforme normativas GDPR/Habeas Data: 1=Otorgado, 0=No otorgado';
COMMENT ON COLUMN core_preferencia_notificacion.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_preferencia_notificacion.fecha_creacion IS 'Fecha y hora de registro de la preferencia (hora Bogotá)';
COMMENT ON COLUMN core_preferencia_notificacion.fecha_modificacion IS 'Fecha y hora de última modificación de la preferencia (hora Bogotá)';


-- ============================================================================
-- SECCIÓN 7: PROCESOS DEL SISTEMA & DESPACHO DINÁMICO (3 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 21/38: CORE_PROCESO
-- ----------------------------------------------------------------------------
CREATE TABLE core_proceso (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12),
    codigo VARCHAR2(60) NOT NULL,
    nombre VARCHAR2(255) NOT NULL,
    objeto_bd VARCHAR2(120) NOT NULL,
    descripcion VARCHAR2(1000),
    activo NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_proceso PRIMARY KEY (id),
    CONSTRAINT fk_core_proceso_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_proceso_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT uk_core_proceso_cod UNIQUE (id_tenant, codigo)
);
CREATE SEQUENCE core_proceso_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_proceso_obj ON core_proceso(id_tenant, objeto_bd);

CREATE OR REPLACE TRIGGER trg_bi_core_proceso
BEFORE INSERT ON core_proceso
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_proceso_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_proceso IS 'Catálogo de operaciones y procesos funcionales vinculados a subprogramas PL/SQL';
COMMENT ON COLUMN core_proceso.id IS 'Identificador único del proceso (PK)';
COMMENT ON COLUMN core_proceso.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_proceso.id_aplicacion IS 'Aplicación a la que pertenece el proceso (FK a core_aplicacion)';
COMMENT ON COLUMN core_proceso.codigo IS 'Código mnemotécnico único del proceso por tenant (ej. CREACION_CITA)';
COMMENT ON COLUMN core_proceso.nombre IS 'Nombre representativo funcional del proceso';
COMMENT ON COLUMN core_proceso.objeto_bd IS 'Paquete y subprograma PL/SQL ejecutor (ej. pkgln_citas.p_crear_cita)';
COMMENT ON COLUMN core_proceso.descripcion IS 'Explicación del alcance de negocio del proceso';
COMMENT ON COLUMN core_proceso.activo IS 'Disponibilidad operativa: 1=Activo, 0=Inactivo';
COMMENT ON COLUMN core_proceso.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_proceso.fecha_creacion IS 'Fecha de alta del proceso (hora Bogotá)';
COMMENT ON COLUMN core_proceso.fecha_modificacion IS 'Fecha de última modificación del proceso (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 22/38: CORE_PROCESO_PLANTILLA
-- ----------------------------------------------------------------------------
CREATE TABLE core_proceso_plantilla (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_proceso NUMBER(12) NOT NULL,
    id_plantilla NUMBER(12) NOT NULL,
    es_obligatoria NUMBER(1) DEFAULT 1 CHECK (es_obligatoria IN (0, 1)),
    orden_despacho NUMBER(3) DEFAULT 1,
    activo NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_proceso_plantilla PRIMARY KEY (id),
    CONSTRAINT fk_core_proc_plnt_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_proc_plnt_proc FOREIGN KEY (id_proceso) REFERENCES core_proceso(id),
    CONSTRAINT fk_core_proc_plnt_plnt FOREIGN KEY (id_plantilla) REFERENCES core_plantilla_notificacion(id),
    CONSTRAINT uk_core_proc_plnt UNIQUE (id_tenant, id_proceso, id_plantilla)
);
CREATE SEQUENCE core_proceso_plantilla_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_proc_plnt_proc ON core_proceso_plantilla(id_tenant, id_proceso);

CREATE OR REPLACE TRIGGER trg_bi_core_proceso_plantilla
BEFORE INSERT ON core_proceso_plantilla
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_proceso_plantilla_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_proceso_plantilla IS 'Asociación de plantillas de notificación a disparar por cada proceso';
COMMENT ON COLUMN core_proceso_plantilla.id IS 'Identificador único de la asignación (PK)';
COMMENT ON COLUMN core_proceso_plantilla.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_proceso_plantilla.id_proceso IS 'Proceso de negocio que detona la notificación (FK a core_proceso)';
COMMENT ON COLUMN core_proceso_plantilla.id_plantilla IS 'Plantilla de mensaje a despachar (FK a core_plantilla_notificacion)';
COMMENT ON COLUMN core_proceso_plantilla.es_obligatoria IS 'Carácter del envío: 1=Transaccional obligatoria, 0=Respeta preferencias de usuario';
COMMENT ON COLUMN core_proceso_plantilla.orden_despacho IS 'Secuencia de encolamiento de las notificaciones';
COMMENT ON COLUMN core_proceso_plantilla.activo IS 'Habilitación de la regla de despacho: 1=Activa, 0=Pausada';
COMMENT ON COLUMN core_proceso_plantilla.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_proceso_plantilla.fecha_creacion IS 'Fecha de asociación (hora Bogotá)';
COMMENT ON COLUMN core_proceso_plantilla.fecha_modificacion IS 'Fecha de última modificación (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 23/38: CORE_PROCESO_DESTINATARIO
-- ----------------------------------------------------------------------------
CREATE TABLE core_proceso_destinatario (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_proceso_plantilla NUMBER(12) NOT NULL,
    tipo_destinatario VARCHAR2(30) NOT NULL,
    id_rol NUMBER(12),
    id_usuario NUMBER(12),
    correo_fijo VARCHAR2(255),
    activo NUMBER(1) DEFAULT 1 CHECK (activo IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_proc_destinatario PRIMARY KEY (id),
    CONSTRAINT fk_core_proc_dest_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_proc_dest_plnt FOREIGN KEY (id_proceso_plantilla) REFERENCES core_proceso_plantilla(id),
    CONSTRAINT fk_core_proc_dest_rol FOREIGN KEY (id_rol) REFERENCES core_rol(id),
    CONSTRAINT fk_core_proc_dest_usr FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT ck_core_proc_dest_tipo CHECK (tipo_destinatario IN ('ROL', 'USUARIO', 'TITULAR_PROCESO', 'CORREO_FIJO'))
);
CREATE SEQUENCE core_proceso_destinatario_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_proc_dest_plnt ON core_proceso_destinatario(id_tenant, id_proceso_plantilla);

CREATE OR REPLACE TRIGGER trg_bi_core_proceso_destinatario
BEFORE INSERT ON core_proceso_destinatario
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_proceso_destinatario_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_proceso_destinatario IS 'Destinatarios configurados por proceso y plantilla (usuario puntual, todos los de un rol o titular)';
COMMENT ON COLUMN core_proceso_destinatario.id IS 'Identificador único de la regla de destinatario (PK)';
COMMENT ON COLUMN core_proceso_destinatario.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_proceso_destinatario.id_proceso_plantilla IS 'Asociación proceso-plantilla vinculada (FK a core_proceso_plantilla)';
COMMENT ON COLUMN core_proceso_destinatario.tipo_destinatario IS 'Estrategia: ROL (todos con ese rol), USUARIO (usuario específico), TITULAR_PROCESO (el paciente/cliente de la transacción), CORREO_FIJO';
COMMENT ON COLUMN core_proceso_destinatario.id_rol IS 'Rol cuyos usuarios recibirán la notificación (FK a core_rol, si aplica)';
COMMENT ON COLUMN core_proceso_destinatario.id_usuario IS 'Usuario puntual destinatario (FK a core_usuario, si aplica)';
COMMENT ON COLUMN core_proceso_destinatario.correo_fijo IS 'Dirección de correo fija opcional para buzones compartidos';
COMMENT ON COLUMN core_proceso_destinatario.activo IS 'Estado de la regla: 1=Activa, 0=Pausada';
COMMENT ON COLUMN core_proceso_destinatario.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_proceso_destinatario.fecha_creacion IS 'Fecha de configuración (hora Bogotá)';
COMMENT ON COLUMN core_proceso_destinatario.fecha_modificacion IS 'Fecha de última modificación (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 8: AUDITORÍA GENERAL DEL SISTEMA (1 TABLA)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 24/38: CORE_AUDITORIA
-- ----------------------------------------------------------------------------
CREATE TABLE core_auditoria (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario NUMBER(12),
    id_aplicacion NUMBER(12),
    tabla_afectada VARCHAR2(100) NOT NULL,
    tipo_operacion VARCHAR2(20) NOT NULL,
    id_registro_modificado NUMBER(12),
    antes_json CLOB,
    despues_json CLOB,
    direccion_ip VARCHAR2(50),
    agente_usuario VARCHAR2(500),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_auditoria PRIMARY KEY (id),
    CONSTRAINT fk_core_auditoria_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_auditoria_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT fk_core_auditoria_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT ck_core_operacion CHECK (tipo_operacion IN ('INSERT', 'UPDATE', 'DELETE')),
    CONSTRAINT ck_core_audit_antes_json CHECK (antes_json IS NULL OR antes_json IS JSON (LAX)),
    CONSTRAINT ck_core_audit_despues_json CHECK (despues_json IS NULL OR despues_json IS JSON (LAX))
);
CREATE SEQUENCE core_auditoria_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_auditoria_usuario ON core_auditoria(id_tenant, id_usuario, fecha_creacion);
CREATE INDEX idx_core_auditoria_tabla ON core_auditoria(id_tenant, tabla_afectada, fecha_creacion);

CREATE OR REPLACE TRIGGER trg_bi_core_auditoria
BEFORE INSERT ON core_auditoria
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_auditoria_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_auditoria IS 'Auditoría integral con estado anterior y posterior en JSON nativo';
COMMENT ON COLUMN core_auditoria.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_auditoria.id IS 'Identificador secuencial del evento auditado (PK)';
COMMENT ON COLUMN core_auditoria.id_usuario IS 'Usuario autor de la transacción (FK a core_usuario)';
COMMENT ON COLUMN core_auditoria.id_aplicacion IS 'Aplicación donde ocurrió la operación (FK a core_aplicacion)';
COMMENT ON COLUMN core_auditoria.tabla_afectada IS 'Nombre de la tabla física alterada (e.g. CORE_USUARIO)';
COMMENT ON COLUMN core_auditoria.tipo_operacion IS 'Tipo de sentencia ejecutada: INSERT, UPDATE, DELETE';
COMMENT ON COLUMN core_auditoria.id_registro_modificado IS 'Valor de la clave primaria del registro afectado';
COMMENT ON COLUMN core_auditoria.antes_json IS 'Snapshot previo a la modificación en JSON nativo (NULL en INSERT)';
COMMENT ON COLUMN core_auditoria.despues_json IS 'Snapshot posterior a la modificación en JSON nativo (NULL en DELETE)';
COMMENT ON COLUMN core_auditoria.direccion_ip IS 'Dirección IP de origen del cliente';
COMMENT ON COLUMN core_auditoria.agente_usuario IS 'Identificación del navegador o dispositivo que consumió el API';
COMMENT ON COLUMN core_auditoria.estado_registro IS 'Estado de auditoría: 1=Activo';
COMMENT ON COLUMN core_auditoria.fecha_creacion IS 'Fecha y hora exacta de la transacción en hora de Bogotá';

-- ============================================================================
-- SECCIÓN 9: PARÁMETROS DINÁMICOS (1 TABLA)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 25/38: CORE_PARAMETRO
-- ----------------------------------------------------------------------------
CREATE TABLE core_parametro (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12),
    categoria VARCHAR2(50) NOT NULL,
    clave VARCHAR2(100) NOT NULL,
    valor_texto VARCHAR2(4000),
    valor_numero NUMBER(15,2),
    valor_fecha DATE,
    valor_booleano NUMBER(1) CHECK (valor_booleano IS NULL OR valor_booleano IN (0, 1)),
    tipo_valor VARCHAR2(50) NOT NULL,
    descripcion VARCHAR2(1000),
    editable_por_usuario NUMBER(1) DEFAULT 0 CHECK (editable_por_usuario IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_parametro PRIMARY KEY (id),
    CONSTRAINT fk_core_parametro_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_parametro_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT uk_core_parametro UNIQUE (id_tenant, id_aplicacion, categoria, clave)
);
CREATE SEQUENCE core_parametro_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_parametro_categoria ON core_parametro(id_tenant, categoria);

CREATE OR REPLACE TRIGGER trg_bi_core_parametro
BEFORE INSERT ON core_parametro
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_parametro_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_parametro IS 'Constantes y parámetros funcionales dinámicos tipados';
COMMENT ON COLUMN core_parametro.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_parametro.id IS 'Identificador único del parámetro (PK)';
COMMENT ON COLUMN core_parametro.id_aplicacion IS 'Aplicación a la que pertenece el parámetro (FK a core_aplicacion)';
COMMENT ON COLUMN core_parametro.categoria IS 'Agrupación semántica (SEGURIDAD, FACTURACION, GENERAL)';
COMMENT ON COLUMN core_parametro.clave IS 'Nombre mnemotécnico o clave única del parámetro';
COMMENT ON COLUMN core_parametro.valor_texto IS 'Almacén del valor cuando el tipo es STRING o TEXTO';
COMMENT ON COLUMN core_parametro.valor_numero IS 'Almacén del valor numérico cuando el tipo es NUMBER';
COMMENT ON COLUMN core_parametro.valor_fecha IS 'Almacén del valor de fecha cuando el tipo es DATE';
COMMENT ON COLUMN core_parametro.valor_booleano IS 'Almacén del valor booleano: 1=True, 0=False';
COMMENT ON COLUMN core_parametro.tipo_valor IS 'Tipo formal: STRING, NUMBER, DATE, BOOLEAN, JSON';
COMMENT ON COLUMN core_parametro.descripcion IS 'Explicación del uso y efectos del parámetro en el negocio';
COMMENT ON COLUMN core_parametro.editable_por_usuario IS 'Indica si puede editarse desde la interfaz por el administrador: 1=Sí, 0=No';
COMMENT ON COLUMN core_parametro.estado_registro IS 'Estado del parámetro: 1=Activo, 0=Inactivo';
COMMENT ON COLUMN core_parametro.fecha_creacion IS 'Fecha y hora de alta del parámetro (hora Bogotá)';
COMMENT ON COLUMN core_parametro.fecha_modificacion IS 'Fecha y hora de última actualización del valor (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 10: GESTIÓN DE APLICACIONES & MÓDULOS (3 TABLAS)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 26/38: CORE_APP_TENANT
-- ----------------------------------------------------------------------------
CREATE TABLE core_app_tenant (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12) NOT NULL,
    habilitada NUMBER(1) DEFAULT 1 CHECK (habilitada IN (0, 1)),
    fecha_activacion DATE,
    fecha_desactivacion DATE,
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_app_tenant PRIMARY KEY (id),
    CONSTRAINT fk_core_app_tenant_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_app_tenant_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT uk_core_app_tenant UNIQUE (id_tenant, id_aplicacion)
);
CREATE SEQUENCE core_app_tenant_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_app_tenant
BEFORE INSERT ON core_app_tenant
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_app_tenant_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_app_tenant IS 'Suscripción y habilitación de aplicaciones específicas por tenant';
COMMENT ON COLUMN core_app_tenant.id_tenant IS 'Identificador del tenant suscriptor (FK a core_tenant)';
COMMENT ON COLUMN core_app_tenant.id IS 'Identificador único del registro de suscripción (PK)';
COMMENT ON COLUMN core_app_tenant.id_aplicacion IS 'Aplicación suscrita por el tenant (FK a core_aplicacion)';
COMMENT ON COLUMN core_app_tenant.habilitada IS 'Bandera de acceso activo: 1=Habilitada, 0=Suspendida';
COMMENT ON COLUMN core_app_tenant.fecha_activacion IS 'Fecha a partir de la cual el tenant puede utilizar la app (hora Bogotá)';
COMMENT ON COLUMN core_app_tenant.fecha_desactivacion IS 'Fecha de corte o expiración de la suscripción (hora Bogotá)';
COMMENT ON COLUMN core_app_tenant.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_app_tenant.fecha_creacion IS 'Fecha y hora de contratación de la aplicación (hora Bogotá)';
COMMENT ON COLUMN core_app_tenant.fecha_modificacion IS 'Fecha y hora de última actualización de la suscripción (hora Bogotá)';

-- ----------------------------------------------------------------------------
-- TABLA 27/38: CORE_TEST_SUITE
-- ----------------------------------------------------------------------------
CREATE TABLE core_test_suite (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_aplicacion NUMBER(12),
    codigo VARCHAR2(50) NOT NULL,
    nombre VARCHAR2(255) NOT NULL,
    descripcion VARCHAR2(1000),
    tipo_suite VARCHAR2(50) DEFAULT 'UNITARIA',
    es_activo NUMBER(1) DEFAULT 1 CHECK (es_activo IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_test_suite PRIMARY KEY (id),
    CONSTRAINT fk_core_test_suit_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_test_suit_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT uk_core_test_suite_cod UNIQUE (id_tenant, codigo),
    CONSTRAINT ck_core_test_suite_tipo CHECK (tipo_suite IN ('UNITARIA', 'INTEGRACION', 'REGRESION', 'SMOKE', 'SEGURIDAD'))
);
CREATE SEQUENCE core_test_suite_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_test_suite
BEFORE INSERT ON core_test_suite
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_test_suite_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_test_suite IS 'Agrupación lógica de pruebas (Suites de Regresión, Smoke Tests, Módulo de Autenticación)';
COMMENT ON COLUMN core_test_suite.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_test_suite.id IS 'Identificador único de la suite de pruebas (PK)';
COMMENT ON COLUMN core_test_suite.id_aplicacion IS 'Aplicación evaluada por la suite (FK a core_aplicacion)';
COMMENT ON COLUMN core_test_suite.codigo IS 'Código nemotécnico (SUITE_SMOKE_CORE, SUITE_AUTH_TEST)';
COMMENT ON COLUMN core_test_suite.nombre IS 'Nombre representativo de la suite de pruebas';
COMMENT ON COLUMN core_test_suite.descripcion IS 'Objetivo y cobertura funcional evaluada';
COMMENT ON COLUMN core_test_suite.tipo_suite IS 'Categoría: UNITARIA, INTEGRACION, REGRESION, SMOKE, SEGURIDAD';
COMMENT ON COLUMN core_test_suite.es_activo IS 'Bandera de ejecución activa: 1=Habilitada, 0=Pausada';
COMMENT ON COLUMN core_test_suite.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_test_suite.fecha_creacion IS 'Fecha y hora de configuración de la suite (hora Bogotá)';
COMMENT ON COLUMN core_test_suite.fecha_modificacion IS 'Fecha y hora de última edición de la suite (hora Bogotá)';

-- 11.3 Casos de Prueba Parametrizados (Payloads CLOB)

-- ----------------------------------------------------------------------------
-- TABLA 28/38: CORE_TEST_CASO
-- ----------------------------------------------------------------------------
CREATE TABLE core_test_caso (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
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
    CONSTRAINT pk_core_test_caso PRIMARY KEY (id),
    CONSTRAINT fk_core_test_cas_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_test_cas_objeto FOREIGN KEY (id_objeto) REFERENCES core_test_objeto(id),
    CONSTRAINT fk_core_test_cas_suite FOREIGN KEY (id_suite) REFERENCES core_test_suite(id),
    CONSTRAINT uk_core_test_caso_cod UNIQUE (id_tenant, id_objeto, codigo_caso),
    CONSTRAINT ck_core_test_caso_cat CHECK (categoria IN ('HAPPY_PATH', 'ERROR_VALIDACION', 'ERROR_NEGOCIO', 'EDGE_CASE', 'SEGURIDAD', 'STRESS')),
    CONSTRAINT ck_core_test_caso_in_json CHECK (json_entrada IS JSON (LAX)),
    CONSTRAINT ck_core_test_caso_exp_json CHECK (json_esperado IS NULL OR json_esperado IS JSON (LAX))
);
CREATE SEQUENCE core_test_caso_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_test_caso_obj ON core_test_caso(id_tenant, id_objeto, orden_ejecucion);

CREATE OR REPLACE TRIGGER trg_bi_core_test_caso
BEFORE INSERT ON core_test_caso
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_test_caso_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_test_caso IS 'Escenarios y casos de prueba individuales con inyección de p_json_entrada y resultado esperado';
COMMENT ON COLUMN core_test_caso.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_test_caso.id IS 'Identificador único del caso de prueba (PK)';
COMMENT ON COLUMN core_test_caso.id_objeto IS 'Objeto o procedimiento PL/SQL bajo prueba (FK a core_test_objeto)';
COMMENT ON COLUMN core_test_caso.id_suite IS 'Suite a la que pertenece el caso (FK a core_test_suite, opcional)';
COMMENT ON COLUMN core_test_caso.codigo_caso IS 'Código único del caso (TC_AUTH_001, TC_USR_EMAIL)';
COMMENT ON COLUMN core_test_caso.nombre IS 'Nombre descriptivo del escenario de prueba';
COMMENT ON COLUMN core_test_caso.descripcion IS 'Premisas, datos inyectados y comportamiento esperado';
COMMENT ON COLUMN core_test_caso.categoria IS 'Tipo: HAPPY_PATH, ERROR_VALIDACION, ERROR_NEGOCIO, EDGE_CASE, SEGURIDAD, STRESS';
COMMENT ON COLUMN core_test_caso.orden_ejecucion IS 'Secuencia de invocación dentro de la batería de pruebas';
COMMENT ON COLUMN core_test_caso.json_entrada IS 'Payload CLOB inyectado directamente en el parámetro p_json_entrada';
COMMENT ON COLUMN core_test_caso.json_esperado IS 'Payload CLOB modelo de salida esperado para comparación estructural';
COMMENT ON COLUMN core_test_caso.codigo_error_esperado IS 'Código de negocio esperado en el payload o SQLCODE esperado (0 = Éxito)';
COMMENT ON COLUMN core_test_caso.tiempo_max_ms IS 'Tiempo de respuesta máximo tolerado en milisegundos (SLA de rendimiento)';
COMMENT ON COLUMN core_test_caso.es_activo IS 'Indica si el caso se incluye en ejecuciones: 1=Sí, 0=No';
COMMENT ON COLUMN core_test_caso.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_test_caso.fecha_creacion IS 'Fecha y hora de alta del caso de prueba (hora Bogotá)';
COMMENT ON COLUMN core_test_caso.fecha_modificacion IS 'Fecha y hora de última edición del caso (hora Bogotá)';

-- 11.4 Reglas de Aserción Granular sobre p_json_salida

-- ----------------------------------------------------------------------------
-- TABLA 29/38: CORE_TEST_ASERCION
-- ----------------------------------------------------------------------------
CREATE TABLE core_test_asercion (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_caso NUMBER(12) NOT NULL,
    ruta_json VARCHAR2(255) NOT NULL,
    operador VARCHAR2(30) DEFAULT 'EQUALS',
    valor_esperado VARCHAR2(4000),
    descripcion VARCHAR2(500),
    es_critica NUMBER(1) DEFAULT 1 CHECK (es_critica IN (0, 1)),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_test_asercion PRIMARY KEY (id),
    CONSTRAINT fk_core_test_asercion_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_test_asercion_caso FOREIGN KEY (id_caso) REFERENCES core_test_caso(id),
    CONSTRAINT ck_core_test_aser_op CHECK (operador IN ('EQUALS', 'NOT_EQUALS', 'EXISTS', 'NOT_EXISTS', 'IS_NULL', 'NOT_NULL', 'IS_ARRAY', 'CONTAINS', 'GREATER_THAN', 'LESS_THAN', 'REGEX'))
);
CREATE SEQUENCE core_test_asercion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_test_aser_caso ON core_test_asercion(id_tenant, id_caso);

CREATE OR REPLACE TRIGGER trg_bi_core_test_asercion
BEFORE INSERT ON core_test_asercion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_test_asercion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_test_asercion IS 'Validaciones puntuales sobre nodos específicos del JSON de salida mediante JSON Path';
COMMENT ON COLUMN core_test_asercion.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_test_asercion.id IS 'Identificador único de la aserción (PK)';
COMMENT ON COLUMN core_test_asercion.id_caso IS 'Caso de prueba al que aplica la regla de aserción (FK a core_test_caso)';
COMMENT ON COLUMN core_test_asercion.ruta_json IS 'Ruta JSONPath evaluada en p_json_salida ($.codigo, $.datos.id)';
COMMENT ON COLUMN core_test_asercion.operador IS 'Operador de aserción: EQUALS, EXISTS, CONTAINS, REGEX, etc.';
COMMENT ON COLUMN core_test_asercion.valor_esperado IS 'Valor literal esperado en el nodo evaluado';
COMMENT ON COLUMN core_test_asercion.descripcion IS 'Explicación del criterio de aceptación verificado';
COMMENT ON COLUMN core_test_asercion.es_critica IS 'Indica si un fallo marca el test como FALLIDO: 1=Sí, 0=Warning';
COMMENT ON COLUMN core_test_asercion.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_test_asercion.fecha_creacion IS 'Fecha y hora de definición de la aserción (hora Bogotá)';

-- 11.5 Historial de Corridas / Ejecuciones de Pruebas (Test Runs)

-- ----------------------------------------------------------------------------
-- TABLA 30/38: CORE_TEST_EJECUCION
-- ----------------------------------------------------------------------------
CREATE TABLE core_test_ejecucion (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
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
    CONSTRAINT pk_core_test_ejecucion PRIMARY KEY (id),
    CONSTRAINT fk_core_test_ejec_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_test_ejec_suite FOREIGN KEY (id_suite) REFERENCES core_test_suite(id),
    CONSTRAINT fk_core_test_ejec_obj FOREIGN KEY (id_objeto) REFERENCES core_test_objeto(id),
    CONSTRAINT fk_core_test_ejec_usr FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT ck_core_test_ejec_env CHECK (entorno IN ('DEV', 'QA', 'STAGING', 'PROD', 'CI_CD')),
    CONSTRAINT ck_core_test_ejec_estado CHECK (estado_global IN ('EN_PROCESO', 'EXITOSO', 'FALLIDO', 'CANCELADO', 'TIMEOUT')),
    CONSTRAINT ck_core_test_ejec_disp CHECK (disparador IN ('MANUAL_FRONT', 'PIPELINE_CI', 'CRON_JOB', 'API_REST', 'UNIT_TEST_RUNNER'))
);
CREATE SEQUENCE core_test_ejecucion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_test_ejec_fecha ON core_test_ejecucion(id_tenant, fecha_inicio);

CREATE OR REPLACE TRIGGER trg_bi_core_test_ejecucion
BEFORE INSERT ON core_test_ejecucion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_test_ejecucion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_test_ejecucion IS 'Cabecera de ejecuciones y trazabilidad de corridas de prueba en el entorno';
COMMENT ON COLUMN core_test_ejecucion.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_test_ejecucion.id IS 'Identificador de la corrida de pruebas (PK)';
COMMENT ON COLUMN core_test_ejecucion.id_suite IS 'Suite ejecutada (FK a core_test_suite, NULL si fue corrida ad-hoc)';
COMMENT ON COLUMN core_test_ejecucion.id_objeto IS 'Objeto específico ejecutado en pruebas aisladas (FK a core_test_objeto)';
COMMENT ON COLUMN core_test_ejecucion.id_usuario IS 'Usuario o desarrollador que detonó la prueba (FK a core_usuario)';
COMMENT ON COLUMN core_test_ejecucion.entorno IS 'Ambiente de pruebas: DEV, QA, STAGING, PROD, CI_CD';
COMMENT ON COLUMN core_test_ejecucion.fecha_inicio IS 'Fecha y hora en que comenzó el test runner (hora Bogotá)';
COMMENT ON COLUMN core_test_ejecucion.fecha_fin IS 'Fecha y hora en que finalizó la ejecución completa (hora Bogotá)';
COMMENT ON COLUMN core_test_ejecucion.duracion_total_ms IS 'Tiempo total transcurrido acumulado en milisegundos';
COMMENT ON COLUMN core_test_ejecucion.total_casos IS 'Número total de casos de prueba incluidos en la corrida';
COMMENT ON COLUMN core_test_ejecucion.casos_exitosos IS 'Número de casos que cumplieron todas sus aserciones (PASÓ)';
COMMENT ON COLUMN core_test_ejecucion.casos_fallidos IS 'Número de casos que tuvieron discrepancias en aserciones (FALLÓ)';
COMMENT ON COLUMN core_test_ejecucion.casos_con_error IS 'Número de casos que arrojaron excepciones inesperadas de Oracle';
COMMENT ON COLUMN core_test_ejecucion.estado_global IS 'Resultado: EN_PROCESO, EXITOSO, FALLIDO, CANCELADO, TIMEOUT';
COMMENT ON COLUMN core_test_ejecucion.disparador IS 'Origen: MANUAL_FRONT, PIPELINE_CI, CRON_JOB, API_REST, UNIT_TEST_RUNNER';
COMMENT ON COLUMN core_test_ejecucion.estado_registro IS 'Estado del registro: 1=Activo';

-- 11.6 Detalle y Evidencia de Ejecución por Caso

-- ----------------------------------------------------------------------------
-- TABLA 31/38: CORE_TEST_DETALLE_EJECUCION
-- ----------------------------------------------------------------------------
CREATE TABLE core_test_detalle_ejecucion (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
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
    CONSTRAINT pk_core_test_det_ejec PRIMARY KEY (id),
    CONSTRAINT fk_core_test_det_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_test_det_ejec FOREIGN KEY (id_ejecucion) REFERENCES core_test_ejecucion(id),
    CONSTRAINT fk_core_test_det_caso FOREIGN KEY (id_caso) REFERENCES core_test_caso(id),
    CONSTRAINT fk_core_test_det_obj FOREIGN KEY (id_objeto) REFERENCES core_test_objeto(id),
    CONSTRAINT ck_core_test_det_est CHECK (estado IN ('PASO', 'FALLO', 'ERROR_ORACLE', 'TIMEOUT', 'OMITIDO')),
    CONSTRAINT ck_core_test_det_in_json CHECK (json_entrada_enviado IS JSON (LAX)),
    CONSTRAINT ck_core_test_det_out_json CHECK (json_salida_obtenido IS NULL OR json_salida_obtenido IS JSON (LAX)),
    CONSTRAINT ck_core_test_det_diff_json CHECK (diferencias_detectadas IS NULL OR diferencias_detectadas IS JSON (LAX))
);
CREATE SEQUENCE core_test_detalle_ejecucion_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_test_det_ejec ON core_test_detalle_ejecucion(id_tenant, id_ejecucion, estado);

CREATE OR REPLACE TRIGGER trg_bi_core_test_detalle_ejecucion
BEFORE INSERT ON core_test_detalle_ejecucion
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_test_detalle_ejecucion_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_test_detalle_ejecucion IS 'Registro individual de cada caso probado: payload inyectado, CLOB recibido, tiempos y diferencias';
COMMENT ON COLUMN core_test_detalle_ejecucion.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_test_detalle_ejecucion.id IS 'Identificador único del detalle de ejecución (PK)';
COMMENT ON COLUMN core_test_detalle_ejecucion.id_ejecucion IS 'Corrida de pruebas a la que pertenece la evidencia (FK a core_test_ejecucion)';
COMMENT ON COLUMN core_test_detalle_ejecucion.id_caso IS 'Caso de prueba ejecutado (FK a core_test_caso)';
COMMENT ON COLUMN core_test_detalle_ejecucion.id_objeto IS 'Objeto PL/SQL probado (FK a core_test_objeto)';
COMMENT ON COLUMN core_test_detalle_ejecucion.json_entrada_enviado IS 'Payload exacto transmitido en el parámetro p_json_entrada en la corrida';
COMMENT ON COLUMN core_test_detalle_ejecucion.json_salida_obtenido IS 'Respuesta exacta CLOB recibida en el parámetro p_json_salida';
COMMENT ON COLUMN core_test_detalle_ejecucion.estado IS 'Resultado: PASO, FALLO, ERROR_ORACLE, TIMEOUT, OMITIDO';
COMMENT ON COLUMN core_test_detalle_ejecucion.tiempo_ejecucion_ms IS 'Tiempo de latencia neta del objeto en milisegundos';
COMMENT ON COLUMN core_test_detalle_ejecucion.codigo_error_oracle IS 'SQLCODE de Oracle capturado en caso de excepción (-20000, -1, etc.)';
COMMENT ON COLUMN core_test_detalle_ejecucion.mensaje_error_oracle IS 'SQLERRM detallado o traza de excepción de Oracle';
COMMENT ON COLUMN core_test_detalle_ejecucion.diferencias_detectadas IS 'Diferencias en JSON (Diff) entre lo esperado y lo obtenido en la prueba';
COMMENT ON COLUMN core_test_detalle_ejecucion.fecha_ejecucion IS 'Fecha y hora precisa de ejecución del caso (hora Bogotá)';

-- 11.7 Mocks y Pre-Condiciones de Prueba

-- ----------------------------------------------------------------------------
-- TABLA 32/38: CORE_TEST_MOCK_DATO
-- ----------------------------------------------------------------------------
CREATE TABLE core_test_mock_dato (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_caso NUMBER(12) NOT NULL,
    tipo_mock VARCHAR2(50) NOT NULL,
    orden NUMBER(3) DEFAULT 1,
    script_sql CLOB,
    payload_contexto CLOB,
    descripcion VARCHAR2(500),
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_test_mock PRIMARY KEY (id),
    CONSTRAINT fk_core_test_mock_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_test_mock_caso FOREIGN KEY (id_caso) REFERENCES core_test_caso(id),
    CONSTRAINT ck_core_test_mock_tipo CHECK (tipo_mock IN ('PRE_SETUP_SQL', 'POST_TEARDOWN_SQL', 'HEADERS_SESION', 'ESTADO_INICIAL')),
    CONSTRAINT ck_core_test_mock_ctx CHECK (payload_contexto IS NULL OR payload_contexto IS JSON (LAX))
);
CREATE SEQUENCE core_test_mock_dato_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_bi_core_test_mock_dato
BEFORE INSERT ON core_test_mock_dato
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_test_mock_dato_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_test_mock_dato IS 'Semillas de datos SQL y contexto de sesión para preparar y limpiar el entorno de cada prueba';
COMMENT ON COLUMN core_test_mock_dato.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_test_mock_dato.id IS 'Identificador del mock de datos o precondición (PK)';
COMMENT ON COLUMN core_test_mock_dato.id_caso IS 'Caso de prueba al que aplica el mock (FK a core_test_caso)';
COMMENT ON COLUMN core_test_mock_dato.tipo_mock IS 'Tipo de preparación: PRE_SETUP_SQL, POST_TEARDOWN_SQL, HEADERS_SESION, ESTADO_INICIAL';
COMMENT ON COLUMN core_test_mock_dato.orden IS 'Orden secuencial de aplicación del script';
COMMENT ON COLUMN core_test_mock_dato.script_sql IS 'Bloque SQL o PL/SQL de semilla o limpieza (INSERT / DELETE de prueba)';
COMMENT ON COLUMN core_test_mock_dato.payload_contexto IS 'Variables de contexto de sesión inyectadas (Tenant, Roles simulados, Headers)';
COMMENT ON COLUMN core_test_mock_dato.descripcion IS 'Explicación de la condición requerida para que el test funcione';
COMMENT ON COLUMN core_test_mock_dato.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_test_mock_dato.fecha_creacion IS 'Fecha y hora de creación del mock (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 12: TELEMETRÍA, SEGUIMIENTO DE OBJETOS & ESTADÍSTICAS (4 TABLAS)
-- Monitoreo dinámico condicional por usuario, tiempo u objeto con call-stack
-- ============================================================================

-- 12.1 Parametrización y Reglas de Activación de Seguimiento (Profiling Rules)

-- ----------------------------------------------------------------------------
-- TABLA 33/38: CORE_TRAZA_LLAMADO
-- ----------------------------------------------------------------------------
CREATE TABLE core_traza_llamado (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
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
    CONSTRAINT pk_core_traza_llamado PRIMARY KEY (id),
    CONSTRAINT fk_core_trazas_llm_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_trazas_llm_ejec FOREIGN KEY (id_ejecucion) REFERENCES core_traza_ejecucion(id),
    CONSTRAINT fk_core_trazas_llm_padre FOREIGN KEY (id_llamado_padre) REFERENCES core_traza_llamado(id),
    CONSTRAINT ck_core_trazas_llm_est CHECK (estado IN ('EXITO', 'ERROR', 'OMITIDO')),
    CONSTRAINT ck_core_trazas_llm_tipo CHECK (tipo_llamado IN ('ORQUESTADOR_PKGLN', 'LOGICA_PKGCN', 'DAO', 'FUNCION', 'REST_API', 'PLSQL_SUBPROGRAM')),
    CONSTRAINT ck_core_trazas_param_in_json CHECK (parametros_enviados IS NULL OR parametros_enviados IS JSON (LAX)),
    CONSTRAINT ck_core_trazas_param_out_json CHECK (parametros_recibidos IS NULL OR parametros_recibidos IS JSON (LAX))
);
CREATE SEQUENCE core_traza_llamado_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_trazas_llm_ejec ON core_traza_llamado(id_tenant, id_ejecucion, orden_llamado);

CREATE OR REPLACE TRIGGER trg_bi_core_traza_llamado
BEFORE INSERT ON core_traza_llamado
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_traza_llamado_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_traza_llamado IS 'Detalle secuencial y pila de sub-llamados internos con argumentos pasados y recibidos en orden';
COMMENT ON COLUMN core_traza_llamado.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_traza_llamado.id IS 'Identificador único del sub-llamado / span (PK)';
COMMENT ON COLUMN core_traza_llamado.id_ejecucion IS 'Cabecera de ejecución a la que pertenece este llamado (FK a core_traza_ejecucion)';
COMMENT ON COLUMN core_traza_llamado.id_llamado_padre IS 'Identificador del llamado que detonó este sub-llamado (FK reflexiva para call-tree)';
COMMENT ON COLUMN core_traza_llamado.orden_llamado IS 'Secuencia ordinal estricta de ejecución dentro de la transacción (1, 2, 3...)';
COMMENT ON COLUMN core_traza_llamado.nivel_anidamiento IS 'Profundidad jerárquica en la pila de llamadas (1=Primer nivel, 2=Hijo, etc.)';
COMMENT ON COLUMN core_traza_llamado.tipo_llamado IS 'Naturaleza del objeto invocado: ORQUESTADOR_PKGLN, LOGICA_PKGCN, DAO, FUNCION, REST_API';
COMMENT ON COLUMN core_traza_llamado.paquete_llamado IS 'Nombre del paquete destino invocado (e.g. pkgcn_usuarios, pkgcore_usuario_dao)';
COMMENT ON COLUMN core_traza_llamado.metodo_llamado IS 'Nombre de la función o procedimiento invocado (e.g. p_insertar, f_traer)';
COMMENT ON COLUMN core_traza_llamado.parametros_enviados IS 'Argumentos y datos suministrados al invocar el objeto en formato JSON nativo';
COMMENT ON COLUMN core_traza_llamado.parametros_recibidos IS 'Valores retornados o parámetros OUT obtenidos del objeto en formato JSON nativo';
COMMENT ON COLUMN core_traza_llamado.fecha_inicio IS 'Fecha y hora de inicio del sub-llamado en hora de Bogotá';
COMMENT ON COLUMN core_traza_llamado.fecha_fin IS 'Fecha y hora de término del sub-llamado en hora de Bogotá';
COMMENT ON COLUMN core_traza_llamado.duracion_ms IS 'Tiempo de ejecución consumido exclusivamente por este subprograma (en ms)';
COMMENT ON COLUMN core_traza_llamado.estado IS 'Resultado del sub-llamado: EXITO, ERROR, OMITIDO';
COMMENT ON COLUMN core_traza_llamado.codigo_error IS 'Código de excepción capturado si este llamado particular falló';
COMMENT ON COLUMN core_traza_llamado.mensaje_error IS 'Detalle o SQLERRM específico del fallo en el sub-llamado';
COMMENT ON COLUMN core_traza_llamado.estado_registro IS 'Estado del registro: 1=Activo';
COMMENT ON COLUMN core_traza_llamado.fecha_creacion IS 'Fecha y hora de grabación de la traza (hora Bogotá)';

-- 12.4 Estadísticas y Agregaciones de Rendimiento (Performance Metrics / APM Summary)

-- ----------------------------------------------------------------------------
-- TABLA 34/38: CORE_TRAZA_ESTADISTICA
-- ----------------------------------------------------------------------------
CREATE TABLE core_traza_estadistica (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
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
    CONSTRAINT pk_core_traza_estadistica PRIMARY KEY (id),
    CONSTRAINT fk_core_trazas_stat_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_trazas_stat_obj FOREIGN KEY (id_objeto) REFERENCES core_test_objeto(id),
    CONSTRAINT uk_core_trazas_stat UNIQUE (id_tenant, nombre_paquete, nombre_metodo, fecha_periodo)
);
CREATE SEQUENCE core_traza_estadistica_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_trazas_stat_obj ON core_traza_estadistica(id_tenant, id_objeto, fecha_periodo);

CREATE OR REPLACE TRIGGER trg_bi_core_traza_estadistica
BEFORE INSERT ON core_traza_estadistica
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_traza_estadistica_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_traza_estadistica IS 'Métricas agregadas de telemetría y rendimiento periódico por objeto PL/SQL para analítica';
COMMENT ON COLUMN core_traza_estadistica.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_traza_estadistica.id IS 'Identificador único del resumen estadístico (PK)';
COMMENT ON COLUMN core_traza_estadistica.id_objeto IS 'Objeto PL/SQL catalogado (FK a core_test_objeto, opcional)';
COMMENT ON COLUMN core_traza_estadistica.nombre_paquete IS 'Nombre del paquete evaluado (e.g. pkgln_usuarios)';
COMMENT ON COLUMN core_traza_estadistica.nombre_metodo IS 'Nombre del procedimiento evaluado (e.g. p_crear_usuario)';
COMMENT ON COLUMN core_traza_estadistica.fecha_periodo IS 'Ventana de agregación temporal (truncada por hora o día en hora de Bogotá)';
COMMENT ON COLUMN core_traza_estadistica.total_ejecuciones IS 'Número total de invocaciones registradas en el período';
COMMENT ON COLUMN core_traza_estadistica.ejecuciones_exitosas IS 'Cantidad de invocaciones que culminaron satisfactoriamente';
COMMENT ON COLUMN core_traza_estadistica.ejecuciones_fallidas IS 'Cantidad de invocaciones que terminaron con error o excepción';
COMMENT ON COLUMN core_traza_estadistica.tiempo_min_ms IS 'Tiempo mínimo de latencia observado en milisegundos';
COMMENT ON COLUMN core_traza_estadistica.tiempo_max_ms IS 'Tiempo máximo de latencia observado en milisegundos';
COMMENT ON COLUMN core_traza_estadistica.tiempo_prom_ms IS 'Tiempo promedio de respuesta en milisegundos';
COMMENT ON COLUMN core_traza_estadistica.tiempo_p95_ms IS 'Percentil 95 de tiempo de respuesta (SLA de experiencia)';
COMMENT ON COLUMN core_traza_estadistica.fecha_ultima_ejecucion IS 'Fecha y hora de la corrida más reciente en el período (hora Bogotá)';
COMMENT ON COLUMN core_traza_estadistica.estado_registro IS 'Estado del registro: 1=Activo';
COMMENT ON COLUMN core_traza_estadistica.fecha_creacion IS 'Fecha y hora de consolidación del registro estadístico (hora Bogotá)';
COMMENT ON COLUMN core_traza_estadistica.fecha_modificacion IS 'Fecha y hora de última actualización del consolidado (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 13: SEGURIDAD API & TOKENS M2M (1 TABLA)
-- Autenticación programática, API Keys con hashing, alcances y límite de peticiones
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 35/38: CORE_API_TOKEN
-- ----------------------------------------------------------------------------
CREATE TABLE core_api_token (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario NUMBER(12),
    id_aplicacion NUMBER(12),
    nombre VARCHAR2(100) NOT NULL,
    prefijo_clave VARCHAR2(12) NOT NULL,
    hash_token VARCHAR2(128) NOT NULL,
    alcances_json CLOB NOT NULL,
    tipo_token VARCHAR2(30) DEFAULT 'API_KEY',
    ips_permitidas VARCHAR2(500),
    limite_peticiones_min NUMBER(6) DEFAULT 60,
    fecha_expiracion DATE,
    ultimo_uso DATE,
    ip_ultimo_uso VARCHAR2(50),
    revocado NUMBER(1) DEFAULT 0 CHECK (revocado IN (0, 1)),
    motivo_revocacion VARCHAR2(255),
    fecha_revocacion DATE,
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_api_token PRIMARY KEY (id),
    CONSTRAINT fk_core_api_token_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_api_token_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT fk_core_api_token_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT uk_core_api_token_hash UNIQUE (id_tenant, hash_token),
    CONSTRAINT ck_core_api_token_tipo CHECK (tipo_token IN ('API_KEY', 'SERVICE_ACCOUNT', 'WEBHOOK_SECRET', 'REFRESH_TOKEN')),
    CONSTRAINT ck_core_api_token_alcances CHECK (alcances_json IS JSON (LAX))
);
CREATE SEQUENCE core_api_token_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_api_token_prefijo ON core_api_token(id_tenant, prefijo_clave, revocado);
CREATE INDEX idx_core_api_token_usr ON core_api_token(id_tenant, id_usuario);

CREATE OR REPLACE TRIGGER trg_bi_core_api_token
BEFORE INSERT ON core_api_token
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_api_token_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_api_token IS 'Credenciales de acceso programático M2M (Machine-to-Machine), API Keys y Service Accounts';
COMMENT ON COLUMN core_api_token.id_tenant IS 'Identificador del tenant propietario de la credencial (FK a core_tenant)';
COMMENT ON COLUMN core_api_token.id IS 'Identificador único del token de API (PK)';
COMMENT ON COLUMN core_api_token.id_usuario IS 'Usuario responsable o titular de la clave (FK a core_usuario, NULL para cuentas de servicio)';
COMMENT ON COLUMN core_api_token.id_aplicacion IS 'Aplicación autorizada para este token (FK a core_aplicacion)';
COMMENT ON COLUMN core_api_token.nombre IS 'Etiqueta o nombre mnemotécnico de la integración (ej. Webhook Facturación, ERP Externo)';
COMMENT ON COLUMN core_api_token.prefijo_clave IS 'Primeros 8-12 caracteres públicos del token para identificación visual en consola (ej. ak_live_3f9)';
COMMENT ON COLUMN core_api_token.hash_token IS 'Resumen criptográfico SHA-256 / SHA-512 del token secreto (el secreto plano nunca se almacena)';
COMMENT ON COLUMN core_api_token.alcances_json IS 'Lista de privilegios y permisos en formato JSON (ej. ["read:pacientes", "write:citas"])';
COMMENT ON COLUMN core_api_token.tipo_token IS 'Clasificación: API_KEY, SERVICE_ACCOUNT, WEBHOOK_SECRET, REFRESH_TOKEN';
COMMENT ON COLUMN core_api_token.ips_permitidas IS 'Lista blanca de direcciones IP o bloques CIDR autorizados (separados por coma)';
COMMENT ON COLUMN core_api_token.limite_peticiones_min IS 'Límite máximo de solicitudes por minuto permitido (Rate Limiting)';
COMMENT ON COLUMN core_api_token.fecha_expiracion IS 'Fecha límite de vigencia del token (hora Bogotá, NULL = sin caducidad)';
COMMENT ON COLUMN core_api_token.ultimo_uso IS 'Fecha y hora de la última autenticación exitosa (hora Bogotá)';
COMMENT ON COLUMN core_api_token.ip_ultimo_uso IS 'Dirección IP desde la que se registró el último acceso';
COMMENT ON COLUMN core_api_token.revocado IS 'Indica si el token fue invalidado manualmente: 1=Revocado, 0=Activo';
COMMENT ON COLUMN core_api_token.motivo_revocacion IS 'Causa o justificación de la revocación del token';
COMMENT ON COLUMN core_api_token.fecha_revocacion IS 'Fecha y hora en que se revocó el acceso (hora Bogotá)';
COMMENT ON COLUMN core_api_token.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_api_token.fecha_creacion IS 'Fecha y hora de generación de la clave (hora Bogotá)';
COMMENT ON COLUMN core_api_token.fecha_modificacion IS 'Fecha y hora de última edición de la credencial (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 14: GESTIÓN DE ARCHIVOS & OBJETOS DIGITALES (1 TABLA)
-- Repositorio de metadatos, almacenamiento en S3/OCI Object Storage y adjuntos
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 36/38: CORE_ARCHIVO
-- ----------------------------------------------------------------------------
CREATE TABLE core_archivo (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario NUMBER(12),
    id_aplicacion NUMBER(12),
    entidad_asociada VARCHAR2(100),
    id_registro_asociado NUMBER(12),
    nombre_original VARCHAR2(255) NOT NULL,
    nombre_almacenamiento VARCHAR2(255) NOT NULL,
    extension VARCHAR2(20),
    tipo_mime VARCHAR2(100) NOT NULL,
    tamano_bytes NUMBER(14) NOT NULL,
    hash_sha256 VARCHAR2(64),
    tipo_almacenamiento VARCHAR2(30) DEFAULT 'S3_COMPATIBLE',
    ruta_almacenamiento VARCHAR2(1000) NOT NULL,
    url_archivo VARCHAR2(2000),
    contenido_blob BLOB,
    es_publico NUMBER(1) DEFAULT 0 CHECK (es_publico IN (0, 1)),
    metadatos_json CLOB,
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_archivo PRIMARY KEY (id),
    CONSTRAINT fk_core_archivo_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_archivo_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT fk_core_archivo_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT ck_core_archivo_storage CHECK (tipo_almacenamiento IN ('S3_COMPATIBLE', 'OCI_OBJECT_STORAGE', 'LOCAL_DISK', 'BLOB_DATABASE')),
    CONSTRAINT ck_core_archivo_meta_json CHECK (metadatos_json IS NULL OR metadatos_json IS JSON (LAX))
);
CREATE SEQUENCE core_archivo_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_archivo_entidad ON core_archivo(id_tenant, entidad_asociada, id_registro_asociado);
CREATE INDEX idx_core_archivo_hash ON core_archivo(id_tenant, hash_sha256);

CREATE OR REPLACE TRIGGER trg_bi_core_archivo
BEFORE INSERT ON core_archivo
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_archivo_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_archivo IS 'Repositorio centralizado de metadatos de documentos, adjuntos, reportes e imágenes';
COMMENT ON COLUMN core_archivo.id_tenant IS 'Identificador del tenant propietario del archivo (FK a core_tenant)';
COMMENT ON COLUMN core_archivo.id IS 'Identificador único del archivo o documento digital (PK)';
COMMENT ON COLUMN core_archivo.id_usuario IS 'Usuario que cargó o generó el archivo (FK a core_usuario)';
COMMENT ON COLUMN core_archivo.id_aplicacion IS 'Aplicación SaaS en cuyo contexto se originó el archivo (FK a core_aplicacion)';
COMMENT ON COLUMN core_archivo.entidad_asociada IS 'Nombre de la entidad de negocio vinculada (ej. PACIENTES, FACTURAS, CONTRATOS)';
COMMENT ON COLUMN core_archivo.id_registro_asociado IS 'Clave primaria del registro en la entidad vinculada';
COMMENT ON COLUMN core_archivo.nombre_original IS 'Nombre original del archivo suministrado por el cliente o sistema';
COMMENT ON COLUMN core_archivo.nombre_almacenamiento IS 'Identificador único físico o UUID con el que se almacena en el backend';
COMMENT ON COLUMN core_archivo.extension IS 'Extensión normalizada del archivo sin punto (pdf, png, docx, xml)';
COMMENT ON COLUMN core_archivo.tipo_mime IS 'Tipo MIME oficial IANA (ej. application/pdf, image/jpeg)';
COMMENT ON COLUMN core_archivo.tamano_bytes IS 'Tamaño del archivo expresado en bytes';
COMMENT ON COLUMN core_archivo.hash_sha256 IS 'Firma criptográfica SHA-256 para verificación de integridad y deduplicación';
COMMENT ON COLUMN core_archivo.tipo_almacenamiento IS 'Destino: S3_COMPATIBLE, OCI_OBJECT_STORAGE, LOCAL_DISK, BLOB_DATABASE';
COMMENT ON COLUMN core_archivo.ruta_almacenamiento IS 'Ruta relativa, URI o Key del objeto dentro del bucket de almacenamiento';
COMMENT ON COLUMN core_archivo.url_archivo IS 'Ruta o URL completa pública/pre-firmada para visualización o descarga directa desde internet';
COMMENT ON COLUMN core_archivo.contenido_blob IS 'Contenido binario directo en base de datos (utilizado solo para BLOB_DATABASE)';
COMMENT ON COLUMN core_archivo.es_publico IS 'Indica si el recurso es accesible públicamente sin token: 1=Público, 0=Privado';
COMMENT ON COLUMN core_archivo.metadatos_json IS 'Metadatos adicionales en formato JSON (dimensiones de imagen, autor, tags)';
COMMENT ON COLUMN core_archivo.estado_registro IS 'Estado del registro: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_archivo.fecha_creacion IS 'Fecha y hora de subida del archivo (hora Bogotá)';
COMMENT ON COLUMN core_archivo.fecha_modificacion IS 'Fecha y hora de última modificación del registro (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 15: REGISTRO CENTRALIZADO DE EXCEPCIONES Y ERRORES (1 TABLA)
-- Repositorio persistente autónomo para uti_ge_excepciones_pkg (reemplazo oficial de TKR_ERRORES)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 37/38: CORE_ERROR
-- ----------------------------------------------------------------------------
CREATE TABLE core_error (
    id NUMBER(12) NOT NULL,
    id_tenant NUMBER(12) NOT NULL,
    id_usuario NUMBER(12),
    id_aplicacion NUMBER(12),
    id_traza_ejecucion NUMBER(12),
    codigo_traza VARCHAR2(100),
    id_sesion_oracle VARCHAR2(50),
    codigo_error NUMBER(10) NOT NULL,
    mensaje_error VARCHAR2(4000) NOT NULL,
    nombre_programa VARCHAR2(100),
    nombre_metodo VARCHAR2(100),
    objeto_error VARCHAR2(200),
    linea_error NUMBER(8),
    traza_error CLOB,
    pila_llamadas CLOB,
    parametros CLOB,
    payload_entrada CLOB,
    contexto_adicional CLOB,
    direccion_ip VARCHAR2(50),
    severidad VARCHAR2(20) DEFAULT 'ERROR',
    resuelto NUMBER(1) DEFAULT 0 CHECK (resuelto IN (0, 1)),
    id_usuario_resolucion NUMBER(12),
    fecha_resolucion DATE,
    estado_registro NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_error PRIMARY KEY (id),
    CONSTRAINT fk_core_error_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_error_usuario FOREIGN KEY (id_usuario) REFERENCES core_usuario(id),
    CONSTRAINT fk_core_error_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT fk_core_error_traza FOREIGN KEY (id_traza_ejecucion) REFERENCES core_traza_ejecucion(id),
    CONSTRAINT fk_core_error_usr_res FOREIGN KEY (id_usuario_resolucion) REFERENCES core_usuario(id),
    CONSTRAINT ck_core_error_sev CHECK (severidad IN ('INFO', 'WARN', 'ERROR', 'FATAL', 'CRITICAL')),
    CONSTRAINT ck_core_error_in_json CHECK (payload_entrada IS NULL OR payload_entrada IS JSON (LAX)),
    CONSTRAINT ck_core_error_ctx_json CHECK (contexto_adicional IS NULL OR contexto_adicional IS JSON (LAX))
);
CREATE SEQUENCE core_error_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_error_fecha ON core_error(id_tenant, fecha_creacion);
CREATE INDEX idx_core_error_cod ON core_error(id_tenant, codigo_error);
CREATE INDEX idx_core_error_trid ON core_error(id_tenant, codigo_traza);
CREATE INDEX idx_core_error_obj ON core_error(id_tenant, nombre_programa, nombre_metodo);

CREATE OR REPLACE TRIGGER trg_bi_core_error
BEFORE INSERT ON core_error
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_error_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_error IS 'Registro forense autónomo y centralizado de excepciones y fallos del sistema (reemplazo oficial de TKR_ERRORES)';
COMMENT ON COLUMN core_error.id_tenant IS 'Identificador del tenant donde se produjo el error (FK a core_tenant)';
COMMENT ON COLUMN core_error.id IS 'Identificador único del registro de error (PK)';
COMMENT ON COLUMN core_error.id_usuario IS 'Usuario activo cuya transacción detonó el fallo (FK a core_usuario)';
COMMENT ON COLUMN core_error.id_aplicacion IS 'Aplicación en cuyo contexto se produjo la excepción (FK a core_aplicacion)';
COMMENT ON COLUMN core_error.id_traza_ejecucion IS 'Identificador de la traza de ejecución donde ocurrió el error (FK a core_traza_ejecucion)';
COMMENT ON COLUMN core_error.codigo_traza IS 'Identificador de correlación global (UUID) de la solicitud que produjo el fallo';
COMMENT ON COLUMN core_error.id_sesion_oracle IS 'Identificador de sesión interna de Oracle (SID o audsid)';
COMMENT ON COLUMN core_error.codigo_error IS 'Código numérico de error de Oracle o código controlado (SQLCODE)';
COMMENT ON COLUMN core_error.mensaje_error IS 'Mensaje de error descriptivo o traza ORA-XXXXX (SQLERRM)';
COMMENT ON COLUMN core_error.nombre_programa IS 'Nombre del paquete o artefacto emisor de la excepción (ej. pkgln_usuarios)';
COMMENT ON COLUMN core_error.nombre_metodo IS 'Nombre del procedimiento o función donde falló la ejecución (ej. p_crear_usuario)';
COMMENT ON COLUMN core_error.objeto_error IS 'Nombre calificado completo del objeto causante (ej. pkgln_usuarios.p_crear_usuario)';
COMMENT ON COLUMN core_error.linea_error IS 'Número de línea de código PL/SQL causante de la excepción';
COMMENT ON COLUMN core_error.traza_error IS 'Traza detallada de ejecución provista por DBMS_UTILITY.FORMAT_ERROR_BACKTRACE';
COMMENT ON COLUMN core_error.pila_llamadas IS 'Pila de subprogramas provista por DBMS_UTILITY.FORMAT_CALL_STACK';
COMMENT ON COLUMN core_error.parametros IS 'Texto o cadena con los parámetros pasados al subprograma al momento del error';
COMMENT ON COLUMN core_error.payload_entrada IS 'Copia de seguridad del parámetro p_json_entrada al momento del fallo en JSON';
COMMENT ON COLUMN core_error.contexto_adicional IS 'Variables locales o estado de la sesión serializado en JSON';
COMMENT ON COLUMN core_error.direccion_ip IS 'Dirección IP del cliente que originó la petición';
COMMENT ON COLUMN core_error.severidad IS 'Nivel de impacto: INFO, WARN, ERROR, FATAL, CRITICAL';
COMMENT ON COLUMN core_error.resuelto IS 'Bandera de gestión de incidentes: 1=Solucionado/Atendido, 0=Pendiente';
COMMENT ON COLUMN core_error.id_usuario_resolucion IS 'Usuario administrador o ingeniero que resolvió la incidencia (FK a core_usuario)';
COMMENT ON COLUMN core_error.fecha_resolucion IS 'Fecha y hora en que se dio por cerrado el incidente (hora Bogotá)';
COMMENT ON COLUMN core_error.estado_registro IS 'Estado del registro: 1=Activo';
COMMENT ON COLUMN core_error.fecha_creacion IS 'Fecha y hora de ocurrencia y captura del fallo (hora Bogotá)';

-- ============================================================================
-- SECCIÓN 16: CATÁLOGO Y DOCUMENTACIÓN DE ORQUESTADORES EN LENGUAJE NATURAL (1 TABLA)
-- Metadatos descriptivos paso a paso para visualizadores gráficos e integradores
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLA 38/38: CORE_DOCUMENTACION_METODO
-- ----------------------------------------------------------------------------
CREATE TABLE core_documentacion_metodo (
    id                             NUMBER(12) NOT NULL,
    id_tenant                      NUMBER(12) NOT NULL,
    id_aplicacion                  NUMBER(12),
    id_modulo                      NUMBER(12),
    nombre_paquete                 VARCHAR2(60) NOT NULL,
    nombre_metodo                  VARCHAR2(60) NOT NULL,
    titulo_funcional               VARCHAR2(255) NOT NULL,
    resumen_ejecutivo              VARCHAR2(500) NOT NULL,
    descripcion_negocio            CLOB NOT NULL,
    actor_principal                VARCHAR2(100),
    flujo_funcional_pasos          CLOB,
    reglas_validacion              CLOB,
    descripcion_entrada_natural    CLOB NOT NULL,
    ejemplo_json_entrada           CLOB NOT NULL,
    descripcion_salida_natural     CLOB NOT NULL,
    ejemplo_json_salida            CLOB NOT NULL,
    excepciones_negocio            CLOB,
    requiere_autenticacion         NUMBER(1) DEFAULT 1 CHECK (requiere_autenticacion IN (0, 1)),
    permiso_requerido              VARCHAR2(100),
    version_metodo                 VARCHAR2(20) DEFAULT '1.0.0',
    estado_publicacion             VARCHAR2(30) DEFAULT 'PUBLICADO' CHECK (estado_publicacion IN ('BORRADOR', 'PUBLICADO', 'DEPRECADO')),
    categoria_visual               VARCHAR2(50) DEFAULT 'OPERATIVO',
    icono_interfaz                 VARCHAR2(50) DEFAULT 'lucide-cpu',
    color_distintivo               VARCHAR2(30) DEFAULT '#3b82f6',
    etiquetas_busqueda             VARCHAR2(500),
    estado_registro                NUMBER(1) DEFAULT 1 CHECK (estado_registro IN (0, 1)),
    fecha_creacion                 DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    fecha_modificacion             DATE DEFAULT CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
    CONSTRAINT pk_core_doc_metodo PRIMARY KEY (id),
    CONSTRAINT fk_core_doc_metodo_tenant FOREIGN KEY (id_tenant) REFERENCES core_tenant(id),
    CONSTRAINT fk_core_doc_metodo_app FOREIGN KEY (id_aplicacion) REFERENCES core_aplicacion(id),
    CONSTRAINT fk_core_doc_metodo_mod FOREIGN KEY (id_modulo) REFERENCES core_modulo_app(id),
    CONSTRAINT uk_core_doc_metodo UNIQUE (id_tenant, nombre_paquete, nombre_metodo),
    CONSTRAINT ck_core_doc_in_json CHECK (ejemplo_json_entrada IS JSON (LAX)),
    CONSTRAINT ck_core_doc_out_json CHECK (ejemplo_json_salida IS JSON (LAX))
);

CREATE SEQUENCE core_documentacion_metodo_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE INDEX idx_core_doc_metodo_cat ON core_documentacion_metodo(id_tenant, categoria_visual, estado_publicacion);

CREATE OR REPLACE TRIGGER trg_bi_core_documentacion_metodo
BEFORE INSERT ON core_documentacion_metodo
FOR EACH ROW
BEGIN
    IF :new.id IS NULL THEN
        :new.id := core_documentacion_metodo_seq.NEXTVAL;
    END IF;
END;
/

COMMENT ON TABLE core_documentacion_metodo IS 'Catálogo explicativo en lenguaje natural de los métodos orquestadores pkgln_ para visualización gráfica e integración frontal';
COMMENT ON COLUMN core_documentacion_metodo.id IS 'Identificador único del registro de documentación (PK)';
COMMENT ON COLUMN core_documentacion_metodo.id_tenant IS 'Identificador del tenant (FK a core_tenant)';
COMMENT ON COLUMN core_documentacion_metodo.id_aplicacion IS 'Aplicación a la que pertenece el orquestador (FK a core_aplicacion)';
COMMENT ON COLUMN core_documentacion_metodo.id_modulo IS 'Módulo funcional de la aplicación (FK a core_modulo_app)';
COMMENT ON COLUMN core_documentacion_metodo.nombre_paquete IS 'Nombre físico del paquete orquestador (ej. pkgln_usuarios)';
COMMENT ON COLUMN core_documentacion_metodo.nombre_metodo IS 'Nombre del procedimiento expuesto (ej. p_crear_usuario)';
COMMENT ON COLUMN core_documentacion_metodo.titulo_funcional IS 'Título amigable para el usuario en la interfaz (ej. Creación y Alta de Nuevo Usuario)';
COMMENT ON COLUMN core_documentacion_metodo.resumen_ejecutivo IS 'Breve descripción en una sola frase para listas y tarjetas del catálogo';
COMMENT ON COLUMN core_documentacion_metodo.descripcion_negocio IS 'Explicación detallada en lenguaje natural del propósito, impacto y reglas de negocio del servicio';
COMMENT ON COLUMN core_documentacion_metodo.actor_principal IS 'Rol o usuario que típicamente dispara este flujo (ej. Administrador de Recursos Humanos, Paciente)';
COMMENT ON COLUMN core_documentacion_metodo.flujo_funcional_pasos IS 'Secuencia de pasos explicada en lenguaje natural (ej. 1. Valida datos, 2. Inserta persona, 3. Dispara notificación)';
COMMENT ON COLUMN core_documentacion_metodo.reglas_validacion IS 'Condiciones de validación que se exigen antes de procesar el servicio explicadas textualmente';
COMMENT ON COLUMN core_documentacion_metodo.descripcion_entrada_natural IS 'Explicación de qué significa cada campo del payload de entrada p_json_entrada para un usuario de negocio';
COMMENT ON COLUMN core_documentacion_metodo.ejemplo_json_entrada IS 'Ejemplo funcional listo para copiar del parámetro p_json_entrada';
COMMENT ON COLUMN core_documentacion_metodo.descripcion_salida_natural IS 'Explicación de los datos que retorna el servicio en p_json_salida y cómo interpretarlos';
COMMENT ON COLUMN core_documentacion_metodo.ejemplo_json_salida IS 'Ejemplo real en JSON de la respuesta devuelta por el servicio';
COMMENT ON COLUMN core_documentacion_metodo.excepciones_negocio IS 'Listado de posibles errores controlados y qué debe hacer el usuario en caso de ocurrir';
COMMENT ON COLUMN core_documentacion_metodo.requiere_autenticacion IS 'Indica si se necesita sesión activa o token M2M: 1=Sí, 0=Público';
COMMENT ON COLUMN core_documentacion_metodo.permiso_requerido IS 'Código del permiso de acceso exigido para ejecutar el método';
COMMENT ON COLUMN core_documentacion_metodo.version_metodo IS 'Versión funcional del endpoint (ej. 1.0.0, 2.1.0)';
COMMENT ON COLUMN core_documentacion_metodo.estado_publicacion IS 'Visibilidad en el visor gráfico: BORRADOR, PUBLICADO, DEPRECADO';
COMMENT ON COLUMN core_documentacion_metodo.categoria_visual IS 'Agrupador gráfico: SEGURIDAD, CONFIGURACION, OPERATIVO, FACTURACION, TELEMETRIA';
COMMENT ON COLUMN core_documentacion_metodo.icono_interfaz IS 'Nombre del icono (Lucide / FontAwesome) para renderizar en la UI gráfica';
COMMENT ON COLUMN core_documentacion_metodo.color_distintivo IS 'Color hexadecimal o token de diseño para resaltar el método en tarjetas del visor';
COMMENT ON COLUMN core_documentacion_metodo.etiquetas_busqueda IS 'Palabras clave separadas por comas para búsqueda rápida en el buscador de la interfaz';
COMMENT ON COLUMN core_documentacion_metodo.estado_registro IS 'Estado de auditoría: 1=Activo, 0=Eliminado';
COMMENT ON COLUMN core_documentacion_metodo.fecha_creacion IS 'Fecha de registro de la documentación (hora Bogotá)';
COMMENT ON COLUMN core_documentacion_metodo.fecha_modificacion IS 'Fecha de última modificación de la documentación (hora Bogotá)';

-- ============================================================================
-- FIN DDL CORE (38 TABLAS, 38 SECUENCIAS, TRIGGERS E ÍNDICES)
-- ORDEN TOPOLÓGICO ESTRICTO SIN DEPENDENCIAS PREVIAS NO CREADAS
-- ============================================================================
