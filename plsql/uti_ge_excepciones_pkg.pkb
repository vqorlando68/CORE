CREATE OR REPLACE PACKAGE BODY uti_ge_excepciones_pkg AS

    PROCEDURE p_grabar_log (
        pro_error IN OUT core_error%ROWTYPE
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_id_error NUMBER(12);
    BEGIN
        IF pro_error.id IS NULL THEN
            SELECT core_error_seq.NEXTVAL INTO v_id_error FROM DUAL;
            pro_error.id := v_id_error;
        END IF;

        IF pro_error.codigo_error IS NULL OR pro_error.codigo_error = 0 THEN
            pro_error.codigo_error := SQLCODE;
        END IF;

        IF pro_error.mensaje_error IS NULL THEN
            pro_error.mensaje_error := SUBSTR(SQLERRM, 1, 4000);
        END IF;

        IF pro_error.traza_error IS NULL THEN
            pro_error.traza_error := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        END IF;

        IF pro_error.pila_llamadas IS NULL THEN
            pro_error.pila_llamadas := DBMS_UTILITY.FORMAT_CALL_STACK;
        END IF;

        IF pro_error.fecha_creacion IS NULL THEN
            pro_error.fecha_creacion := CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE);
        END IF;

        IF pro_error.estado_registro IS NULL THEN
            pro_error.estado_registro := 1;
        END IF;

        IF pro_error.resuelto IS NULL THEN
            pro_error.resuelto := 0;
        END IF;

        IF pro_error.severidad IS NULL THEN
            pro_error.severidad := 'ERROR';
        END IF;

        -- Construcción o ajuste del nombre calificado del objeto
        IF pro_error.objeto_error IS NULL AND (pro_error.nombre_programa IS NOT NULL OR pro_error.nombre_metodo IS NOT NULL) THEN
            pro_error.objeto_error := SUBSTR(TRIM(pro_error.nombre_programa || '.' || pro_error.nombre_metodo), 1, 200);
        END IF;

        -- Sincronización bidireccional entre parametros y payload_entrada
        IF pro_error.payload_entrada IS NULL AND pro_error.parametros IS NOT NULL THEN
            pro_error.payload_entrada := pro_error.parametros;
        ELSIF pro_error.parametros IS NULL AND pro_error.payload_entrada IS NOT NULL THEN
            pro_error.parametros := pro_error.payload_entrada;
        END IF;

        -- Invocación obligatoria al DAO oficial (sin sentencias directas INSERT)
        pkgcore_error_dao.p_insertar(pro_error);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Fallo al registrar error autónomo en core_error: ' || SQLERRM);
    END p_grabar_log;

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
    ) IS
        vro_error core_error%ROWTYPE;
    BEGIN
        vro_error.id_tenant       := p_id_tenant;
        vro_error.nombre_programa := p_nombre_programa;
        vro_error.nombre_metodo   := p_nombre_metodo;
        vro_error.objeto_error    := p_nombre_programa || '.' || p_nombre_metodo;
        vro_error.payload_entrada := p_payload_entrada;
        vro_error.parametros      := p_payload_entrada;
        vro_error.id_usuario      := p_id_usuario;
        vro_error.id_aplicacion   := p_id_aplicacion;
        vro_error.codigo_traza    := p_id_traza;
        vro_error.severidad       := p_severidad;
        vro_error.codigo_error    := SQLCODE;
        vro_error.mensaje_error   := SUBSTR(SQLERRM, 1, 4000);
        vro_error.traza_error     := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
        vro_error.pila_llamadas   := DBMS_UTILITY.FORMAT_CALL_STACK;

        p_grabar_log(vro_error);
        p_id_error_out := vro_error.id;
    END p_grabar_log;

END uti_ge_excepciones_pkg;
/
