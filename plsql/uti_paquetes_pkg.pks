CREATE OR REPLACE PACKAGE uti_paquetes_pkg
AUTHID CURRENT_USER
AS
    /*
    || =========================================================================
    || Paquete   : UTI_PAQUETES_PKG
    || Propósito : Generador y compilador automatizado de paquetes DAO (PKG<TABLA>_DAO)
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    ||             Aislamiento Multi-Tenant (Enfoque B - SYS_CONTEXT('CORE_CTX', 'ID_TENANT'))
    || Autor     : Equipo Core Transversal
    || =========================================================================
    */

    /**
     * =========================================================================
     * Objeto      : p_crear_dao
     * Propósito   : Genera dinámicamente y compila en base de datos la especificación
     *               (.pks) y el cuerpo (.pkb) del paquete DAO estándar (20 métodos)
     *               para la tabla indicada. Si el parámetro es nulo, itera y
     *               construye los DAOs de todas las tablas CORE_% del esquema.
     * 
     * Parámetros  :
     *   @param p_nombre_tabla (IN VARCHAR2 DEFAULT NULL) : Nombre de la tabla
     *          (ej. 'core_usuario', 'core_error'). Si es NULL, procesa todas las
     *          tablas del esquema cuyo nombre inicie por 'CORE_'.
     * 
     * Excepciones :
     *   - ORA-20001 : Tabla especificada no existe en el catálogo de base de datos.
     *   - ORA-20002 : Error durante la compilación dinámica del paquete DAO.
     * 
     * Historial de Modificaciones:
     *   -----------------------------------------------------------------------
     *   FECHA       | AUTOR                  | DESCRIPCIÓN DEL CAMBIO
     *   -----------------------------------------------------------------------
     *   2026-10-10  | Orlando Valverde       | Creación inicial del generador DAO.
     * =========================================================================
     */
    PROCEDURE p_crear_dao (
        p_nombre_tabla IN VARCHAR2 DEFAULT NULL
    );

END uti_paquetes_pkg;
/
