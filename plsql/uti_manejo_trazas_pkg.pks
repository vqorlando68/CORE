CREATE OR REPLACE PACKAGE uti_manejo_trazas_pkg AS
    /**
     * =========================================================================
     * Paquete     : uti_manejo_trazas_pkg
     * Propósito   : Paquete transversal para la gestión integral de telemetría y
     *               trazabilidad del sistema CORE (core_traza_config, core_traza_ejecucion,
     *               core_traza_llamado).
     * Comportamiento: Se comporta como orquestador pkgln_ (expone endpoints CLOB
     *               con p_json_entrada / p_json_salida) y provee métodos PL/SQL
     *               autónomos para ser consumidos por los demás paquetes pkgln_.
     * =========================================================================
     */

    -- -------------------------------------------------------------------------
    -- MÉTODOS PL/SQL INTERNOS PARA CONSUMO DESDE ORQUESTADORES pkgln_
    -- -------------------------------------------------------------------------

    /**
     * =========================================================================
     * Objeto      : f_debe_trazar
     * Propósito   : Evalúa si un objeto debe ser trazado consultando en caliente
     *               la tabla core_traza_config por tenant, paquete, método y usuario.
     * 
     * Parámetros  :
     *   @param p_id_tenant       (IN NUMBER)   : Identificador del inquilino.
     *   @param p_nombre_paquete  (IN VARCHAR2) : Paquete a consultar.
     *   @param p_nombre_metodo   (IN VARCHAR2) : Subprograma a consultar.
     *   @param p_id_usuario      (IN NUMBER)   : Usuario ejecutor (opcional).
     *   @param p_id_config_out   (OUT NUMBER)  : ID de la regla de configuración.
     *   @param p_nivel_out       (OUT VARCHAR2): Nivel de detalle ('BASICO', 'COMPLETO').
     *   @param p_grabar_pay_out  (OUT NUMBER)  : 1 si debe registrar payloads JSON, 0 si no.
     * 
     * Retorno     :
     *   @return BOOLEAN : TRUE si existe regla activa que habilite el trazado, FALSE si no.
     * =========================================================================
     */
    FUNCTION f_debe_trazar (
        p_id_tenant       IN  NUMBER,
        p_nombre_paquete  IN  VARCHAR2,
        p_nombre_metodo   IN  VARCHAR2,
        p_id_usuario      IN  NUMBER   DEFAULT NULL,
        p_id_config_out   OUT NUMBER,
        p_nivel_out       OUT VARCHAR2,
        p_grabar_pay_out  OUT NUMBER
    ) RETURN BOOLEAN;

    /**
     * =========================================================================
     * Objeto      : p_iniciar_traza (Sobrecarga PL/SQL Interna)
     * Propósito   : Inicia una traza de ejecución de forma autónoma (PRAGMA AUTONOMOUS_TRANSACTION)
     *               e inserta en core_traza_ejecucion con estado 'EN_PROCESO'.
     * =========================================================================
     */
    PROCEDURE p_iniciar_traza (
        p_id_tenant          IN  NUMBER,
        p_nombre_paquete     IN  VARCHAR2,
        p_nombre_metodo      IN  VARCHAR2,
        p_id_config          IN  NUMBER   DEFAULT NULL,
        p_id_usuario         IN  NUMBER   DEFAULT NULL,
        p_codigo_traza       IN  VARCHAR2 DEFAULT NULL,
        p_ip_origen          IN  VARCHAR2 DEFAULT NULL,
        p_json_entrada       IN  CLOB     DEFAULT NULL,
        p_grabar_payload     IN  NUMBER   DEFAULT 1,
        p_id_ejecucion_out   OUT NUMBER
    );

    /**
     * =========================================================================
     * Objeto      : p_finalizar_traza (Sobrecarga PL/SQL Interna)
     * Propósito   : Cierra exitosamente una traza de ejecución de forma autónoma.
     *               Actualiza core_traza_ejecucion con estado 'EXITO', fecha_fin y duracion_ms.
     * =========================================================================
     */
    PROCEDURE p_finalizar_traza (
        p_id_tenant          IN  NUMBER,
        p_id_ejecucion       IN  NUMBER,
        p_fecha_inicio       IN  TIMESTAMP,
        p_json_salida        IN  CLOB     DEFAULT NULL,
        p_grabar_payload     IN  NUMBER   DEFAULT 1
    );

    /**
     * =========================================================================
     * Objeto      : p_finalizar_traza_error (Sobrecarga PL/SQL Interna)
     * Propósito   : Cierra con estado 'ERROR' una traza de ejecución de forma autónoma.
     *               Actualiza core_traza_ejecucion con estado 'ERROR', SQLCODE y SQLERRM.
     * =========================================================================
     */
    PROCEDURE p_finalizar_traza_error (
        p_id_tenant          IN  NUMBER,
        p_id_ejecucion       IN  NUMBER,
        p_fecha_inicio       IN  TIMESTAMP,
        p_codigo_error       IN  NUMBER,
        p_mensaje_error      IN  VARCHAR2
    );

    /**
     * =========================================================================
     * Objeto      : p_registrar_llamado
     * Propósito   : Registra un sub-llamado / span en core_traza_llamado.
     * =========================================================================
     */
    PROCEDURE p_registrar_llamado (
        p_id_tenant           IN  NUMBER,
        p_id_ejecucion        IN  NUMBER,
        p_paquete_llamado     IN  VARCHAR2,
        p_metodo_llamado      IN  VARCHAR2,
        p_tipo_llamado        IN  VARCHAR2 DEFAULT 'PLSQL_SUBPROGRAM',
        p_parametros_enviados IN  CLOB     DEFAULT NULL,
        p_parametros_recibidos IN CLOB     DEFAULT NULL,
        p_duracion_ms         IN  NUMBER   DEFAULT NULL,
        p_estado              IN  VARCHAR2 DEFAULT 'EXITO',
        p_codigo_error        IN  NUMBER   DEFAULT NULL,
        p_mensaje_error       IN  VARCHAR2 DEFAULT NULL,
        p_id_llamado_padre    IN  NUMBER   DEFAULT NULL
    );

    -- -------------------------------------------------------------------------
    -- ENDPOINTS FORMALES TIPO pkgln_ (Firma CLOB IN / OUT para Frontend / APIs)
    -- -------------------------------------------------------------------------

    /**
     * =========================================================================
     * Objeto      : p_iniciar_traza (Endpoint Frontend)
     * Propósito   : Inicia una traza de observabilidad vía payload JSON.
     * 
     * Estructura JSON Entrada:
     *   {
     *     "id_tenant": NUMBER,
     *     "nombre_paquete": VARCHAR2(60),
     *     "nombre_metodo": VARCHAR2(60),
     *     "id_usuario": NUMBER (opcional),
     *     "codigo_traza": VARCHAR2(100) (opcional),
     *     "direccion_ip": VARCHAR2(50) (opcional),
     *     "payload": CLOB (opcional)
     *   }
     * 
     * Estructura JSON Salida:
     *   {
     *     "codigo": NUMBER,
     *     "mensaje": VARCHAR2,
     *     "datos": {
     *       "id_ejecucion": NUMBER,
     *       "codigo_traza": VARCHAR2
     *     }
     *   }
     * =========================================================================
     */
    PROCEDURE p_iniciar_traza (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    );

    /**
     * =========================================================================
     * Objeto      : p_finalizar_traza (Endpoint Frontend)
     * Propósito   : Cierra una traza abierta vía payload JSON.
     * =========================================================================
     */
    PROCEDURE p_finalizar_traza (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    );

    /**
     * =========================================================================
     * Objeto      : p_configurar_regla (Endpoint Frontend)
     * Propósito   : Habilita o modifica dinámicamente el profilado de un subprograma.
     * =========================================================================
     */
    PROCEDURE p_configurar_regla (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    );

    /**
     * =========================================================================
     * Objeto      : p_consultar_trazas (Endpoint Frontend)
     * Propósito   : Consulta las trazas recientes para tableros de observabilidad.
     * =========================================================================
     */
    PROCEDURE p_consultar_trazas (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    );

END uti_manejo_trazas_pkg;
/
