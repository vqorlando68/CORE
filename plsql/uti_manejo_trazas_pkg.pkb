CREATE OR REPLACE PACKAGE BODY uti_manejo_trazas_pkg AS

    FUNCTION f_debe_trazar (
        p_id_tenant       IN  NUMBER,
        p_nombre_paquete  IN  VARCHAR2,
        p_nombre_metodo   IN  VARCHAR2,
        p_id_usuario      IN  NUMBER   DEFAULT NULL,
        p_id_config_out   OUT NUMBER,
        p_nivel_out       OUT VARCHAR2,
        p_grabar_pay_out  OUT NUMBER
    ) RETURN BOOLEAN IS
        v_id_config NUMBER(12);
        v_nivel     VARCHAR2(30);
        v_payload   NUMBER(1);
    BEGIN
        SELECT c.id,
               c.nivel_detalle,
               c.grabar_payloads
          INTO v_id_config,
               v_nivel,
               v_payload
          FROM core_traza_config c
         WHERE c.id_tenant = p_id_tenant
           AND c.es_activo = 1
           AND c.estado_registro = 1
           AND (c.nombre_paquete = p_nombre_paquete OR c.nombre_paquete = '%')
           AND (c.nombre_metodo  = p_nombre_metodo  OR c.nombre_metodo = '%')
           AND (c.id_usuario IS NULL OR c.id_usuario = p_id_usuario)
           AND (c.fecha_desde IS NULL OR CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE) >= c.fecha_desde)
           AND (c.fecha_hasta IS NULL OR CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE) <= c.fecha_hasta)
           AND ROWNUM = 1;

        p_id_config_out  := v_id_config;
        p_nivel_out      := v_nivel;
        p_grabar_pay_out := v_payload;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_id_config_out  := NULL;
            p_nivel_out      := 'COMPLETO';
            p_grabar_pay_out := 1;
            RETURN FALSE;
        WHEN OTHERS THEN
            p_id_config_out  := NULL;
            p_nivel_out      := 'COMPLETO';
            p_grabar_pay_out := 1;
            RETURN FALSE;
    END f_debe_trazar;

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
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_id_ejec     NUMBER(12);
        v_cod_traza   VARCHAR2(100);
        v_ip          VARCHAR2(50);
    BEGIN
        v_cod_traza := NVL(p_codigo_traza, RAWTOHEX(SYS_GUID()));
        v_ip        := NVL(p_ip_origen, SYS_CONTEXT('USERENV', 'IP_ADDRESS'));

        INSERT INTO core_traza_ejecucion (
            id,
            id_tenant,
            id_config,
            id_usuario,
            codigo_traza,
            nombre_paquete,
            nombre_metodo,
            fecha_inicio,
            estado,
            ip_cliente,
            json_entrada,
            estado_registro
        ) VALUES (
            core_traza_ejecucion_seq.NEXTVAL,
            p_id_tenant,
            p_id_config,
            p_id_usuario,
            v_cod_traza,
            p_nombre_paquete,
            p_nombre_metodo,
            CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
            'EN_PROCESO',
            v_ip,
            CASE WHEN NVL(p_grabar_payload, 1) = 1 THEN p_json_entrada ELSE NULL END,
            1
        ) RETURNING id INTO v_id_ejec;

        COMMIT;
        p_id_ejecucion_out := v_id_ejec;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_id_ejecucion_out := NULL;
    END p_iniciar_traza;

    PROCEDURE p_finalizar_traza (
        p_id_tenant          IN  NUMBER,
        p_id_ejecucion       IN  NUMBER,
        p_fecha_inicio       IN  TIMESTAMP,
        p_json_salida        IN  CLOB     DEFAULT NULL,
        p_grabar_payload     IN  NUMBER   DEFAULT 1
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_duracion_ms NUMBER(12);
        v_fin         TIMESTAMP;
    BEGIN
        v_fin := SYSTIMESTAMP;
        v_duracion_ms := ROUND(EXTRACT(SECOND FROM (v_fin - p_fecha_inicio)) * 1000 +
                               EXTRACT(MINUTE FROM (v_fin - p_fecha_inicio)) * 60000 +
                               EXTRACT(HOUR   FROM (v_fin - p_fecha_inicio)) * 3600000);

        UPDATE core_traza_ejecucion
           SET fecha_fin     = CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
               duracion_ms   = v_duracion_ms,
               estado        = 'EXITO',
               json_salida   = CASE WHEN NVL(p_grabar_payload, 1) = 1 THEN p_json_salida ELSE NULL END
         WHERE id = p_id_ejecucion
           AND id_tenant = p_id_tenant;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END p_finalizar_traza;

    PROCEDURE p_finalizar_traza_error (
        p_id_tenant          IN  NUMBER,
        p_id_ejecucion       IN  NUMBER,
        p_fecha_inicio       IN  TIMESTAMP,
        p_codigo_error       IN  NUMBER,
        p_mensaje_error      IN  VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_duracion_ms NUMBER(12);
        v_fin         TIMESTAMP;
    BEGIN
        v_fin := SYSTIMESTAMP;
        v_duracion_ms := ROUND(EXTRACT(SECOND FROM (v_fin - p_fecha_inicio)) * 1000 +
                               EXTRACT(MINUTE FROM (v_fin - p_fecha_inicio)) * 60000 +
                               EXTRACT(HOUR   FROM (v_fin - p_fecha_inicio)) * 3600000);

        UPDATE core_traza_ejecucion
           SET fecha_fin     = CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
               duracion_ms   = v_duracion_ms,
               estado        = 'ERROR',
               codigo_error  = p_codigo_error,
               mensaje_error = SUBSTR(p_mensaje_error, 1, 4000)
         WHERE id = p_id_ejecucion
           AND id_tenant = p_id_tenant;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END p_finalizar_traza_error;

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
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_orden NUMBER(6);
    BEGIN
        SELECT NVL(MAX(orden_llamado), 0) + 1
          INTO v_orden
          FROM core_traza_llamado
         WHERE id_tenant = p_id_tenant
           AND id_ejecucion = p_id_ejecucion;

        INSERT INTO core_traza_llamado (
            id,
            id_tenant,
            id_ejecucion,
            id_llamado_padre,
            orden_llamado,
            tipo_llamado,
            paquete_llamado,
            metodo_llamado,
            parametros_enviados,
            parametros_recibidos,
            fecha_inicio,
            fecha_fin,
            duracion_ms,
            estado,
            codigo_error,
            mensaje_error,
            estado_registro
        ) VALUES (
            core_traza_llamado_seq.NEXTVAL,
            p_id_tenant,
            p_id_ejecucion,
            p_id_llamado_padre,
            v_orden,
            p_tipo_llamado,
            p_paquete_llamado,
            p_metodo_llamado,
            p_parametros_enviados,
            p_parametros_recibidos,
            CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
            CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE),
            p_duracion_ms,
            p_estado,
            p_codigo_error,
            SUBSTR(p_mensaje_error, 1, 4000),
            1
        );

        UPDATE core_traza_ejecucion
           SET total_llamados = NVL(total_llamados, 0) + 1
         WHERE id = p_id_ejecucion
           AND id_tenant = p_id_tenant;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END p_registrar_llamado;

    -- -------------------------------------------------------------------------
    -- IMPLEMENTACIÓN DE ENDPOINTS TIPO pkgln_
    -- -------------------------------------------------------------------------

    PROCEDURE p_iniciar_traza (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    ) IS
        v_obj_in      JSON_OBJECT_T;
        v_id_tenant   NUMBER(12);
        v_paquete     VARCHAR2(60);
        v_metodo      VARCHAR2(60);
        v_usuario     NUMBER(12);
        v_cod_traza   VARCHAR2(100);
        v_ip          VARCHAR2(50);
        v_payload     CLOB;
        v_id_ejec     NUMBER(12);
    BEGIN
        v_obj_in    := JSON_OBJECT_T.parse(p_json_entrada);
        v_id_tenant := v_obj_in.get_number('id_tenant');
        v_paquete   := v_obj_in.get_string('nombre_paquete');
        v_metodo    := v_obj_in.get_string('nombre_metodo');

        IF v_obj_in.has('id_usuario') THEN
            v_usuario := v_obj_in.get_number('id_usuario');
        END IF;

        IF v_obj_in.has('codigo_traza') THEN
            v_cod_traza := v_obj_in.get_string('codigo_traza');
        ELSE
            v_cod_traza := RAWTOHEX(SYS_GUID());
        END IF;

        IF v_obj_in.has('direccion_ip') THEN
            v_ip := v_obj_in.get_string('direccion_ip');
        END IF;

        IF v_obj_in.has('payload') THEN
            v_payload := v_obj_in.get_clob('payload');
        END IF;

        p_iniciar_traza(
            p_id_tenant        => v_id_tenant,
            p_nombre_paquete   => v_paquete,
            p_nombre_metodo    => v_metodo,
            p_id_usuario       => v_usuario,
            p_codigo_traza     => v_cod_traza,
            p_ip_origen        => v_ip,
            p_json_entrada     => v_payload,
            p_grabar_payload   => 1,
            p_id_ejecucion_out => v_id_ejec
        );

        SELECT JSON_OBJECT(
                   'codigo'  VALUE 0,
                   'mensaje' VALUE 'Traza iniciada exitosamente',
                   'datos'   VALUE JSON_OBJECT(
                                  'id_ejecucion' VALUE v_id_ejec,
                                  'codigo_traza' VALUE v_cod_traza
                              )
                   RETURNING CLOB
               )
          INTO p_json_salida
          FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            p_json_salida := JSON_OBJECT(
                                 'codigo'  VALUE SQLCODE,
                                 'mensaje' VALUE 'Error al iniciar traza: ' || SQLERRM,
                                 'datos'   VALUE NULL
                                 RETURNING CLOB
                             );
    END p_iniciar_traza;

    PROCEDURE p_finalizar_traza (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    ) IS
        v_obj_in      JSON_OBJECT_T;
        v_id_tenant   NUMBER(12);
        v_id_ejec     NUMBER(12);
        v_estado      VARCHAR2(30);
        v_payload     CLOB;
        v_cod_error   NUMBER;
        v_msg_error   VARCHAR2(4000);
    BEGIN
        v_obj_in    := JSON_OBJECT_T.parse(p_json_entrada);
        v_id_tenant := v_obj_in.get_number('id_tenant');
        v_id_ejec   := v_obj_in.get_number('id_ejecucion');
        v_estado    := v_obj_in.get_string('estado');

        IF v_obj_in.has('payload') THEN
            v_payload := v_obj_in.get_clob('payload');
        END IF;

        IF v_estado = 'ERROR' THEN
            IF v_obj_in.has('codigo_error') THEN
                v_cod_error := v_obj_in.get_number('codigo_error');
            END IF;
            IF v_obj_in.has('mensaje_error') THEN
                v_msg_error := v_obj_in.get_string('mensaje_error');
            END IF;

            p_finalizar_traza_error(
                p_id_tenant     => v_id_tenant,
                p_id_ejecucion  => v_id_ejec,
                p_fecha_inicio  => SYSTIMESTAMP,
                p_codigo_error  => v_cod_error,
                p_mensaje_error => v_msg_error
            );
        ELSE
            p_finalizar_traza(
                p_id_tenant      => v_id_tenant,
                p_id_ejecucion   => v_id_ejec,
                p_fecha_inicio   => SYSTIMESTAMP,
                p_json_salida    => v_payload,
                p_grabar_payload => 1
            );
        END IF;

        SELECT JSON_OBJECT(
                   'codigo'  VALUE 0,
                   'mensaje' VALUE 'Traza finalizada exitosamente',
                   'datos'   VALUE JSON_OBJECT('id_ejecucion' VALUE v_id_ejec)
                   RETURNING CLOB
               )
          INTO p_json_salida
          FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            p_json_salida := JSON_OBJECT(
                                 'codigo'  VALUE SQLCODE,
                                 'mensaje' VALUE 'Error al finalizar traza: ' || SQLERRM,
                                 'datos'   VALUE NULL
                                 RETURNING CLOB
                             );
    END p_finalizar_traza;

    PROCEDURE p_configurar_regla (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    ) IS
        v_obj_in    JSON_OBJECT_T;
        v_id_tenant NUMBER(12);
        v_paquete   VARCHAR2(60);
        v_metodo    VARCHAR2(60);
        v_activo    NUMBER(1) := 1;
        v_id_regla  NUMBER(12);
    BEGIN
        v_obj_in    := JSON_OBJECT_T.parse(p_json_entrada);
        v_id_tenant := v_obj_in.get_number('id_tenant');
        v_paquete   := v_obj_in.get_string('nombre_paquete');
        v_metodo    := v_obj_in.get_string('nombre_metodo');

        IF v_obj_in.has('es_activo') THEN
            v_activo := v_obj_in.get_number('es_activo');
        END IF;

        INSERT INTO core_traza_config (
            id,
            id_tenant,
            nombre_paquete,
            nombre_metodo,
            es_activo,
            nivel_detalle,
            grabar_payloads,
            estado_registro
        ) VALUES (
            core_traza_config_seq.NEXTVAL,
            v_id_tenant,
            v_paquete,
            v_metodo,
            v_activo,
            'COMPLETO',
            1,
            1
        ) RETURNING id INTO v_id_regla;

        p_do_commit('uti_manejo_trazas_pkg.p_configurar_regla');

        SELECT JSON_OBJECT(
                   'codigo'  VALUE 0,
                   'mensaje' VALUE 'Regla de trazabilidad configurada exitosamente',
                   'datos'   VALUE JSON_OBJECT('id_regla' VALUE v_id_regla)
                   RETURNING CLOB
               )
          INTO p_json_salida
          FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_json_salida := JSON_OBJECT(
                                 'codigo'  VALUE SQLCODE,
                                 'mensaje' VALUE 'Error al configurar regla: ' || SQLERRM,
                                 'datos'   VALUE NULL
                                 RETURNING CLOB
                             );
    END p_configurar_regla;

    PROCEDURE p_consultar_trazas (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    ) IS
        v_obj_in    JSON_OBJECT_T;
        v_id_tenant NUMBER(12);
        v_paquete   VARCHAR2(60) := '%';
    BEGIN
        v_obj_in    := JSON_OBJECT_T.parse(p_json_entrada);
        v_id_tenant := v_obj_in.get_number('id_tenant');
        IF v_obj_in.has('nombre_paquete') THEN
            v_paquete := v_obj_in.get_string('nombre_paquete');
        END IF;

        SELECT JSON_OBJECT(
                   'codigo'  VALUE 0,
                   'mensaje' VALUE 'Consulta exitosa de trazas',
                   'datos'   VALUE (
                       SELECT JSON_ARRAYAGG(
                                  JSON_OBJECT(
                                      'id'             VALUE t.id,
                                      'nombre_paquete' VALUE t.nombre_paquete,
                                      'nombre_metodo'  VALUE t.nombre_metodo,
                                      'codigo_traza'   VALUE t.codigo_traza,
                                      'estado'         VALUE t.estado,
                                      'duracion_ms'    VALUE t.duracion_ms,
                                      'fecha_inicio'   VALUE TO_CHAR(t.fecha_inicio, 'YYYY-MM-DD HH24:MI:SS'),
                                      'fecha_fin'      VALUE TO_CHAR(t.fecha_fin, 'YYYY-MM-DD HH24:MI:SS')
                                  )
                                  RETURNING CLOB
                              )
                         FROM core_traza_ejecucion t
                        WHERE t.id_tenant = v_id_tenant
                          AND (v_paquete = '%' OR t.nombre_paquete LIKE v_paquete)
                          AND ROWNUM <= 100
                   )
                   RETURNING CLOB
               )
          INTO p_json_salida
          FROM DUAL;
    EXCEPTION
        WHEN OTHERS THEN
            p_json_salida := JSON_OBJECT(
                                 'codigo'  VALUE SQLCODE,
                                 'mensaje' VALUE 'Error al consultar trazas: ' || SQLERRM,
                                 'datos'   VALUE NULL
                                 RETURNING CLOB
                             );
    END p_consultar_trazas;

END uti_manejo_trazas_pkg;
/
