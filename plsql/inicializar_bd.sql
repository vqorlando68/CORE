-- ============================================================================
-- PLATAFORMA SAAS MULTI-APLICACIONES — REINICIALIZACIÓN TOTAL DE BASE DE DATOS
-- ARCHIVO: inicializar_bd.sql
-- PROPÓSITO: Borrar todos los objetos creados por la plataforma CORE
--            (Tablas con CASCADE CONSTRAINTS PURGE, Secuencias, Triggers,
--             Paquetes, Procedimientos y Contextos de Aplicación)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
WHENEVER SQLERROR CONTINUE;

PROMPT ============================================================================
PROMPT INICIANDO LIMPIEZA Y REINICIALIZACIÓN TOTAL DEL ESQUEMA CORE...
PROMPT ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ELIMINACIÓN DE PAQUETES Y PROCEDIMIENTOS PL/SQL
-- ----------------------------------------------------------------------------
PROMPT Borrando paquetes y procedimientos utilitarios...

BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE uti_paquetes_pkg';
    DBMS_OUTPUT.PUT_LINE('Paquete uti_paquetes_pkg eliminado.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE uti_manejo_trazas_pkg';
    DBMS_OUTPUT.PUT_LINE('Paquete uti_manejo_trazas_pkg eliminado.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE uti_ge_excepciones_pkg';
    DBMS_OUTPUT.PUT_LINE('Paquete uti_ge_excepciones_pkg eliminado.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE pkgcore_error_dao';
    DBMS_OUTPUT.PUT_LINE('Paquete pkgcore_error_dao eliminado.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE p_do_commit';
    DBMS_OUTPUT.PUT_LINE('Procedimiento p_do_commit eliminado.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ----------------------------------------------------------------------------
-- 2. ELIMINACIÓN DE CONTEXTO DE APLICACIÓN MULTI-TENANT
-- ----------------------------------------------------------------------------
PROMPT Borrando contexto de aplicación CORE_CTX...

BEGIN
    EXECUTE IMMEDIATE 'DROP CONTEXT core_ctx';
    DBMS_OUTPUT.PUT_LINE('Contexto core_ctx eliminado.');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ----------------------------------------------------------------------------
-- 3. ELIMINACIÓN DE TABLAS (38 TABLAS EN ORDEN INVERSO CON CASCADE Y PURGE)
-- ----------------------------------------------------------------------------
PROMPT Borrando las 38 tablas del Core...

-- Catálogo de Métodos y Documentación Gráfica
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_documentacion_metodo CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Auditoría, Errores y Observabilidad
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_error CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_traza_estadistica CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_traza_llamado CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_traza_ejecucion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_traza_config CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_auditoria CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Motor de Pruebas Automatizadas
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_test_mock_dato CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_test_detalle_ejecucion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_test_ejecucion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_test_asercion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_test_caso CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_test_suite CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_test_objeto CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Archivos y Tokens API
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_archivo_version CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_archivo CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_tipo_archivo CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_api_token CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Procesos y Notificaciones
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_notificacion_adjunto CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_notificacion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_proceso_destinatario CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_proceso_plantilla CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_proceso CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_plantilla_variable CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_plantilla_notificacion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_preferencia_notificacion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_tipo_notificacion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_proveedor_notificacion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Parámetros y Temas
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_parametro_tenant CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_parametro_sistema CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_parametro CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_tema_tenant CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_tema_visual CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Módulos y Aplicaciones
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_modulo_app CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_app_tenant CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_menu_dinamico CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_aplicacion CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Roles, Permisos y Seguridad
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_auditoria_usuario_rol CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_usuario_rol CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_rol_permiso CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_permiso CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_rol CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Sesiones y Contextos
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_historial_acceso CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_sesion_activa CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_usuario_contexto CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_contexto CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Usuarios, Personas y Tenants Raíz
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_usuario CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_persona CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE core_tenant CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ----------------------------------------------------------------------------
-- 4. ELIMINACIÓN DE SECUENCIAS
-- ----------------------------------------------------------------------------
PROMPT Borrando secuencias del Core...

DECLARE
    TYPE t_nombres IS TABLE OF VARCHAR2(60);
    v_secuencias t_nombres := t_nombres(
        'core_tenant_seq', 'core_persona_seq', 'core_usuario_seq',
        'core_sesion_activa_seq', 'core_historial_acceso_seq',
        'core_contexto_seq', 'core_usuario_contexto_seq',
        'core_rol_seq', 'core_permiso_seq', 'core_usuario_rol_seq',
        'core_rol_permiso_seq', 'core_auditoria_usuario_rol_seq',
        'core_menu_dinamico_seq', 'core_plantilla_notificacion_seq',
        'core_plantilla_variable_seq', 'core_notificacion_seq',
        'core_notificacion_adjunto_seq', 'core_preferencia_notificacion_seq',
        'core_tipo_notificacion_seq', 'core_proveedor_notificacion_seq',
        'core_proceso_seq', 'core_proceso_plantilla_seq',
        'core_proceso_destinatario_seq', 'core_auditoria_seq',
        'core_parametro_seq', 'core_parametro_sistema_seq',
        'core_parametro_tenant_seq', 'core_tema_visual_seq',
        'core_tema_tenant_seq', 'core_aplicacion_seq',
        'core_app_tenant_seq', 'core_modulo_app_seq',
        'core_test_objeto_seq', 'core_test_suite_seq',
        'core_test_caso_seq', 'core_test_asercion_seq',
        'core_test_ejecucion_seq', 'core_test_detalle_ejecucion_seq',
        'core_test_mock_dato_seq', 'core_traza_config_seq',
        'core_traza_ejecucion_seq', 'core_traza_llamado_seq',
        'core_traza_estadistica_seq', 'core_api_token_seq',
        'core_tipo_archivo_seq', 'core_archivo_seq',
        'core_archivo_version_seq', 'core_error_seq',
        'core_documentacion_metodo_seq'
    );
BEGIN
    FOR i IN 1..v_secuencias.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP SEQUENCE ' || v_secuencias(i);
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Secuencias eliminadas.');
END;
/

-- ----------------------------------------------------------------------------
-- 5. BARRIDO FINAL DINÁMICO DE SEGURIDAD (POR SI EXISTEN RESTOS)
-- ----------------------------------------------------------------------------
PROMPT Ejecutando barrido dinámico de seguridad para objetos remanentes...

DECLARE
    v_sql VARCHAR2(500);
BEGIN
    -- Tablas remanentes core_*
    FOR c IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'CORE_%') LOOP
        BEGIN
            v_sql := 'DROP TABLE ' || c.table_name || ' CASCADE CONSTRAINTS PURGE';
            EXECUTE IMMEDIATE v_sql;
            DBMS_OUTPUT.PUT_LINE('Tabla remanente eliminada: ' || c.table_name);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;

    -- Secuencias remanentes core_*_seq
    FOR c IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'CORE_%') LOOP
        BEGIN
            v_sql := 'DROP SEQUENCE ' || c.sequence_name;
            EXECUTE IMMEDIATE v_sql;
            DBMS_OUTPUT.PUT_LINE('Secuencia remanente eliminada: ' || c.sequence_name);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;

    -- Paquetes remanentes pkgcore_* o uti_*
    FOR c IN (SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE' AND (object_name LIKE 'PKGCORE_%' OR object_name LIKE 'UTI_%')) LOOP
        BEGIN
            v_sql := 'DROP PACKAGE ' || c.object_name;
            EXECUTE IMMEDIATE v_sql;
            DBMS_OUTPUT.PUT_LINE('Paquete remanente eliminado: ' || c.object_name);
        EXCEPTION WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

PROMPT ============================================================================
PROMPT LIMPIEZA COMPLETADA CON ÉXITO. EL ESQUEMA ESTÁ TOTALMENTE REINICIALIZADO.
PROMPT ============================================================================
