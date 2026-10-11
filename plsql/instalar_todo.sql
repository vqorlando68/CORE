-- ============================================================================
-- PLATAFORMA SAAS MULTI-APLICACIONES — SCRIPT MAESTRO DE INSTALACIÓN
-- ARCHIVO: instalar_todo.sql
-- SECUENCIA DE EJECUCIÓN:
--   1. DDL_CORE.sql (38 tablas, 38 secuencias, triggers autonuméricos, índices y comentarios)
--   2. Procedimiento utilitario (p_do_commit.sql)
--   3. Especificaciones de paquetes (*.pks)
--   4. Cuerpos de paquetes (*.pkb)
--   5. Carga de datos dummy (datos_dummy.sql)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 100;
SET ECHO OFF;
SET FEEDBACK ON;

PROMPT ============================================================================
PROMPT   INICIANDO DESPLIEGUE INTEGRAL DE LA PLATAFORMA CORE SAAS
PROMPT ============================================================================
PROMPT Fecha y hora de inicio: 
SELECT TO_CHAR(CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE), 'YYYY-MM-DD HH24:MI:SS') AS hora_inicio_bogota FROM DUAL;

-- NOTA: Si desea borrar y limpiar totalmente la base de datos antes de instalar,
-- descomente la siguiente línea:
-- @inicializar_bd.sql

-- ----------------------------------------------------------------------------
-- PASO 1: CREACIÓN DE ESTRUCTURAS DE DATOS (TABLAS, SECUENCIAS, TRIGGERS)
-- ----------------------------------------------------------------------------
PROMPT 
PROMPT >>> PASO 1/5: Ejecutando DDL_CORE.sql (38 Tablas, Secuencias, Triggers)...
@DDL_CORE.sql

-- ----------------------------------------------------------------------------
-- PASO 2: PROCEDIMIENTOS UTILITARIOS TRANSACCIONALES
-- ----------------------------------------------------------------------------
PROMPT 
PROMPT >>> PASO 2/5: Compilando Procedimiento Controlado de Commit (p_do_commit)...
@p_do_commit.sql

-- ----------------------------------------------------------------------------
-- PASO 3: ESPECIFICACIONES DE PAQUETES (.pks)
-- ----------------------------------------------------------------------------
PROMPT 
PROMPT >>> PASO 3/5: Compilando Especificaciones de Paquetes (.pks)...
PROMPT   - Compilando pkgcore_error_dao.pks...
@pkgcore_error_dao.pks

PROMPT   - Compilando uti_ge_excepciones_pkg.pks...
@uti_ge_excepciones_pkg.pks

PROMPT   - Compilando uti_manejo_trazas_pkg.pks...
@uti_manejo_trazas_pkg.pks

PROMPT   - Compilando uti_paquetes_pkg.pks...
@uti_paquetes_pkg.pks

-- ----------------------------------------------------------------------------
-- PASO 4: CUERPOS DE PAQUETES (.pkb)
-- ----------------------------------------------------------------------------
PROMPT 
PROMPT >>> PASO 4/5: Compilando Cuerpos de Paquetes (.pkb)...
PROMPT   - Compilando pkgcore_error_dao.pkb...
@pkgcore_error_dao.pkb

PROMPT   - Compilando uti_ge_excepciones_pkg.pkb...
@uti_ge_excepciones_pkg.pkb

PROMPT   - Compilando uti_manejo_trazas_pkg.pkb...
@uti_manejo_trazas_pkg.pkb

PROMPT   - Compilando uti_paquetes_pkg.pkb...
@uti_paquetes_pkg.pkb

-- ----------------------------------------------------------------------------
-- PASO 5: CARGA DE DATOS DUMMY DE PRUEBA
-- ----------------------------------------------------------------------------
PROMPT 
PROMPT >>> PASO 5/5: Ejecutando carga de datos iniciales y datos dummy (datos_dummy.sql)...
@datos_dummy.sql

-- ----------------------------------------------------------------------------
-- REPORTE Y VALIDACIÓN FINAL DE COMPILACIÓN
-- ----------------------------------------------------------------------------
PROMPT 
PROMPT ============================================================================
PROMPT RESUMEN DE OBJETOS CREADOS Y ESTADO DE COMPILACIÓN EN EL ESQUEMA:
PROMPT ============================================================================

SELECT object_type, COUNT(*) AS total_objetos
  FROM user_objects
 WHERE object_name LIKE 'CORE_%'
    OR object_name LIKE 'PKGCORE_%'
    OR object_name LIKE 'UTI_%'
    OR object_name LIKE 'TRG_BI_CORE_%'
    OR object_name = 'P_DO_COMMIT'
 GROUP BY object_type
 ORDER BY object_type;

PROMPT 
PROMPT Verificando si existen objetos INVALIDOS en el esquema...
SELECT object_type, object_name, status
  FROM user_objects
 WHERE status = 'INVALID'
 ORDER BY object_type, object_name;

PROMPT ============================================================================
PROMPT ¡DESPLIEGUE INTEGRAL FINALIZADO SATISFACTORIAMENTE!
PROMPT ============================================================================
