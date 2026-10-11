/**
 * =============================================================================
 * CUERPO DEL PAQUETE DAO: PKGCORE_ERROR_DAO
 * =============================================================================
 * Implementación de los 20 métodos estándar para la tabla core_error.
 * =============================================================================
 */
CREATE OR REPLACE PACKAGE BODY PKGCORE_ERROR_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_core_error IN core_error%ROWTYPE
    ) IS
        vro_core_error core_error%ROWTYPE := pro_core_error;
    BEGIN
        IF vro_core_error.id_tenant IS NULL THEN
            vro_core_error.id_tenant := TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        END IF;
        INSERT INTO core_error VALUES vro_core_error;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id        IN core_error.id%TYPE,
        pty_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    ) RETURN core_error%ROWTYPE IS
        vro_core_error core_error%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_core_error
          FROM core_error
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN vro_core_error;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        p_id_tenant   IN  core_error.id_tenant%TYPE DEFAULT NULL,
        pta_core_error OUT PKGCORE_ERROR_DAO.ta_core_error
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_core_error
          FROM core_error
         WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_consultar_registros;

    -- 4. Eliminar registro por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM core_error
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_eliminar_rowid;

    -- 5. Eliminar registro por PK
    PROCEDURE p_eliminar (
        pty_id        IN core_error.id%TYPE,
        pty_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    ) IS
    BEGIN
        DELETE FROM core_error
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_eliminar;

    -- 6. Eliminar todos los registros (Enfoque B: acotado al tenant activo)
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM core_error
         WHERE id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id        IN core_error.id%TYPE,
        pty_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM core_error
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  core_error.id%TYPE,
        pty_id_tenant  IN  core_error.id_tenant%TYPE DEFAULT NULL,
        pro_core_error OUT core_error%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_core_error
          FROM core_error
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  core_error.id%TYPE,
        pty_id_tenant  IN  core_error.id_tenant%TYPE DEFAULT NULL,
        pro_core_error OUT core_error%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT t.*, t.ROWID
          INTO pro_core_error, p_rowid
          FROM core_error t
         WHERE t.id = pty_id AND t.id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM core_error
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_core_error OUT core_error%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_core_error
          FROM core_error
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_core_error IN core_error%ROWTYPE
    ) IS
    BEGIN
        UPDATE core_error
           SET ROW = pro_core_error
         WHERE id = pro_core_error.id AND id_tenant = NVL(pro_core_error.id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_core_error IN core_error%ROWTYPE,
        pty_id         IN core_error.id%TYPE,
        pty_id_tenant  IN core_error.id_tenant%TYPE DEFAULT NULL
    ) IS
    BEGIN
        UPDATE core_error
           SET ROW = pro_core_error
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_core_error IN core_error%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE core_error
           SET ROW = pro_core_error
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros (Enfoque B: acotado al tenant activo)
    PROCEDURE p_actualizar_registros (
        pro_core_error IN core_error%ROWTYPE
    ) IS
    BEGIN
        UPDATE core_error
           SET ROW = pro_core_error
         WHERE id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_core_error IN OUT core_error%ROWTYPE
    ) IS
    BEGIN
        pro_core_error.id_tenant := TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        -- Sin valores por defecto especiales declarados
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id              IN  core_error.id%TYPE,
        p_id_tenant       IN  core_error.id_tenant%TYPE DEFAULT NULL,
        p_json_core_error OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_core_error
          FROM core_error t
         WHERE t.id = p_id AND t.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_core_error := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK (VARCHAR2 o CLOB según tamaño)
    FUNCTION f_json (
        p_id        IN core_error.id%TYPE,
        p_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM core_error t
         WHERE t.id = p_id AND t.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas para paginación recibiendo JSON con campo "registros"
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
        v_id_tenant            NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        v_id_tenant := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.id_tenant')), TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        SELECT COUNT(1)
          INTO v_total_registros
          FROM core_error
         WHERE id_tenant = v_id_tenant;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON con información correspondiente
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER,
        p_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
        v_tenant NUMBER;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;
        v_tenant := NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));

        SELECT NVL(
                   JSON_ARRAYAGG(
                       JSON_OBJECT(t.*)
                       RETURNING CLOB
                   ),
                   TO_CLOB('[]')
               )
          INTO v_json
          FROM (
              SELECT *
                FROM core_error
               WHERE id_tenant = v_tenant
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGCORE_ERROR_DAO;
/
