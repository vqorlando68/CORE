CREATE OR REPLACE PACKAGE uti_ge_excepciones_pkg AS
    /**
     * =========================================================================
     * Paquete     : uti_ge_excepciones_pkg
     * Propósito   : Paquete utilitario transversal para el registro forense autónomo
     *               de excepciones e incidentes del sistema en core_error.
     *               Aplica PRAGMA AUTONOMOUS_TRANSACTION para persistir los fallos
     *               incluso si la transacción de negocio efectúa ROLLBACK.
     * =========================================================================
     */

    /**
     * =========================================================================
     * Objeto      : p_grabar_log (Sobrecarga Registro)
     * Propósito   : Graba una excepción de forma autónoma a partir de un registro
     *               core_error%ROWTYPE, delegando la inserción en pkgcore_error_dao.
     * 
     * Parámetros  :
     *   @param pro_error (IN OUT core_error%ROWTYPE) : Registro con los metadatos
     *                                                  completos del error.
     * 
     * Historial de Modificaciones:
     *   -----------------------------------------------------------------------
     *   FECHA       | AUTOR                  | DESCRIPCIÓN DEL CAMBIO
     *   -----------------------------------------------------------------------
     *   2026-10-07  | Orlando Valverde       | Creación inicial del subprograma.
     *   2026-10-10  | Equipo Core            | Estandarización y separación a plsql/.
     * =========================================================================
     */
    PROCEDURE p_grabar_log (
        pro_error IN OUT core_error%ROWTYPE
    );

    /**
     * =========================================================================
     * Objeto      : p_grabar_log (Sobrecarga Escalar)
     * Propósito   : Graba una excepción de forma autónoma a partir de parámetros
     *               escalares para facilitar su invocación en bloques WHEN OTHERS.
     * 
     * Parámetros  :
     *   @param p_id_tenant       (IN NUMBER)   : Identificador del tenant.
     *   @param p_nombre_programa (IN VARCHAR2) : Nombre del paquete emisor.
     *   @param p_nombre_metodo   (IN VARCHAR2) : Nombre del método emisor.
     *   @param p_payload_entrada (IN CLOB)     : Payload JSON de entrada.
     *   @param p_id_usuario      (IN NUMBER)   : Usuario que ejecutó la acción.
     *   @param p_id_aplicacion   (IN NUMBER)   : Identificador de la aplicación.
     *   @param p_id_traza        (IN VARCHAR2) : Código UUID / Trace ID.
     *   @param p_severidad       (IN VARCHAR2) : Severidad ('ERROR', 'FATAL', etc.).
     *   @param p_id_error_out    (OUT NUMBER)  : ID generado en core_error.
     * 
     * Historial de Modificaciones:
     *   -----------------------------------------------------------------------
     *   FECHA       | AUTOR                  | DESCRIPCIÓN DEL CAMBIO
     *   -----------------------------------------------------------------------
     *   2026-10-07  | Orlando Valverde       | Creación inicial de sobrecarga escalar.
     *   2026-10-10  | Equipo Core            | Estandarización arquitectónica.
     * =========================================================================
     */
    PROCEDURE p_grabar_log (
        p_id_tenant       IN  NUMBER,
        p_nombre_programa IN  VARCHAR2,
        p_nombre_metodo   IN  VARCHAR2,
        p_payload_entrada IN  CLOB     DEFAULT NULL,
        p_id_usuario      IN  NUMBER   DEFAULT NULL,
        p_id_aplicacion   IN  NUMBER   DEFAULT NULL,
        p_id_traza        IN  VARCHAR2 DEFAULT NULL,
        p_severidad       IN  VARCHAR2 DEFAULT 'ERROR',
        p_id_error_out    OUT NUMBER
    );

END uti_ge_excepciones_pkg;
/
