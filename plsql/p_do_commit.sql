CREATE OR REPLACE PROCEDURE p_do_commit (
    p_contexto IN VARCHAR2 DEFAULT 'General'
) AS
    /**
     * =========================================================================
     * Objeto      : p_do_commit
     * Propósito   : Procedimiento institucional centralizado para la ejecución de
     *               COMMIT controlado en la plataforma CORE.
     *               Reemplaza el uso directo de 'COMMIT;' garantizando auditoría,
     *               trazabilidad y control del punto de confirmación.
     * 
     * Parámetros  :
     *   @param p_contexto (IN VARCHAR2) : Identificador calificado del paquete o
     *                                    subprograma que solicita la confirmación
     *                                    (ej. 'pkgln_usuarios.p_crear_usuario').
     * 
     * Excepciones :
     *   Re-lanza cualquier excepción ocurrida durante el COMMIT hacia el llamador.
     * 
     * Historial de Modificaciones:
     *   -----------------------------------------------------------------------
     *   FECHA       | AUTOR                  | DESCRIPCIÓN DEL CAMBIO
     *   -----------------------------------------------------------------------
     *   2026-10-07  | Orlando Valverde       | Creación inicial del procedimiento.
     *   2026-10-10  | Equipo Core            | Estandarización arquitectónica.
     * =========================================================================
     */
BEGIN
    -- Lógica de control, auditoría o telemetría previa al commit
    DBMS_OUTPUT.PUT_LINE('Ejecutando COMMIT controlado para: ' || p_contexto);
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        -- Control de errores en caso de que el commit falle
        DBMS_OUTPUT.PUT_LINE('Error al ejecutar COMMIT en ' || p_contexto || ': ' || SQLERRM);
        RAISE;
END p_do_commit;
/
