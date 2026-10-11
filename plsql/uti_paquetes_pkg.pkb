CREATE OR REPLACE PACKAGE BODY uti_paquetes_pkg
AS
    /*
    || =========================================================================
    || Paquete   : UTI_PAQUETES_PKG
    || Propósito : Implementación del generador y compilador automatizado de DAOs
    || =========================================================================
    */

    -- Subprograma privado: Genera y compila el DAO para una tabla específica
    PROCEDURE p_generar_compilar_tabla (
        p_tabla IN VARCHAR2
    ) IS
        v_tabla         VARCHAR2(128) := UPPER(TRIM(p_tabla));
        v_tab_low       VARCHAR2(128) := LOWER(v_tabla);
        v_pkg_name      VARCHAR2(128);
        v_tiene_tenant  BOOLEAN := FALSE;
        v_count_tenant  NUMBER;
        v_sql_pks       CLOB;
        v_sql_pkb       CLOB;
        v_cant_errores  NUMBER := 0;

        PROCEDURE p_append_pks(p_linea IN VARCHAR2) IS
        BEGIN
            v_sql_pks := v_sql_pks || p_linea || CHR(10);
        END p_append_pks;

        PROCEDURE p_append_pkb(p_linea IN VARCHAR2) IS
        BEGIN
            v_sql_pkb := v_sql_pkb || p_linea || CHR(10);
        END p_append_pkb;

    BEGIN
        v_pkg_name := 'PKG' || v_tabla || '_DAO';

        -- 1. Validar existencia de la tabla
        SELECT COUNT(1)
          INTO v_count_tenant
          FROM user_tables
         WHERE table_name = v_tabla;

        IF v_count_tenant = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'La tabla especificada no existe en el esquema: ' || v_tabla);
        END IF;

        -- 2. Detectar si la tabla posee columna id_tenant
        SELECT COUNT(1)
          INTO v_count_tenant
          FROM user_tab_cols
         WHERE table_name = v_tabla
           AND column_name = 'ID_TENANT';

        v_tiene_tenant := (v_count_tenant > 0);

        DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');
        IF v_tiene_tenant THEN
            DBMS_OUTPUT.PUT_LINE('Generando DAO: ' || v_pkg_name || ' (Multi-Tenant: SI)');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Generando DAO: ' || v_pkg_name || ' (Multi-Tenant: NO)');
        END IF;

        -- =====================================================================
        -- CONSTRUCCIÓN DE LA ESPECIFICACIÓN (.PKS)
        -- =====================================================================
        v_sql_pks := NULL;
        p_append_pks('CREATE OR REPLACE PACKAGE ' || v_pkg_name);
        p_append_pks('AS');
        p_append_pks('    /*');
        p_append_pks('    || =========================================================================');
        p_append_pks('    || Paquete   : ' || v_pkg_name);
        p_append_pks('    || Propósito : Capa de acceso a datos exclusiva para la tabla ' || v_tab_low);
        p_append_pks('    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)');
        IF v_tiene_tenant THEN
            p_append_pks('    || Seguridad : Aislamiento Multi-Tenant (Enfoque B - SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT''))');
        END IF;
        p_append_pks('    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.');
        p_append_pks('    ||             Consultas relacionales con sintaxis tradicional Oracle.');
        p_append_pks('    || =========================================================================');
        p_append_pks('    */');
        p_append_pks('');
        p_append_pks('    -- Colección estándar de registros');
        p_append_pks('    TYPE ta_' || v_tab_low || ' IS TABLE OF ' || v_tab_low || '%ROWTYPE INDEX BY BINARY_INTEGER;');
        p_append_pks('');
        p_append_pks('    -- 1. Insertar registro completo');
        p_append_pks('    PROCEDURE p_insertar (');
        p_append_pks('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE');
        p_append_pks('    );');
        p_append_pks('');
        p_append_pks('    -- 2. Traer registro por PK');
        p_append_pks('    FUNCTION f_traer (');
        IF v_tiene_tenant THEN
            p_append_pks('        pty_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pks('        pty_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pks('        pty_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pks('    ) RETURN ' || v_tab_low || '%ROWTYPE;');
        p_append_pks('');
        p_append_pks('    -- 3. Consultar todos los registros');
        p_append_pks('    PROCEDURE p_consultar_registros (');
        IF v_tiene_tenant THEN
            p_append_pks('        p_id_tenant   IN  ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL,');
        END IF;
        p_append_pks('        pta_' || v_tab_low || ' OUT ' || v_pkg_name || '.ta_' || v_tab_low);
        p_append_pks('    );');
        p_append_pks('');
        p_append_pks('    -- 4. Eliminar por ROWID');
        p_append_pks('    PROCEDURE p_eliminar_rowid (');
        p_append_pks('        p_rowid IN VARCHAR2');
        p_append_pks('    );');
        p_append_pks('');
        p_append_pks('    -- 5. Eliminar por PK');
        p_append_pks('    PROCEDURE p_eliminar (');
        IF v_tiene_tenant THEN
            p_append_pks('        pty_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pks('        pty_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pks('        pty_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pks('    );');
        p_append_pks('');
        p_append_pks('    -- 6. Eliminar todos los registros');
        IF v_tiene_tenant THEN
            p_append_pks('    PROCEDURE p_eliminar_registros (');
            p_append_pks('        p_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
            p_append_pks('    );');
        ELSE
            p_append_pks('    PROCEDURE p_eliminar_registros;');
        END IF;
        p_append_pks('');
        p_append_pks('    -- 7. Verificar existencia por PK');
        p_append_pks('    FUNCTION f_existe (');
        IF v_tiene_tenant THEN
            p_append_pks('        pty_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pks('        pty_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pks('        pty_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pks('    ) RETURN BOOLEAN;');
        p_append_pks('');
        p_append_pks('    -- 8. Verificar existencia y retornar registro');
        p_append_pks('    FUNCTION f_existe (');
        p_append_pks('        pty_id         IN  ' || v_tab_low || '.id%TYPE,');
        IF v_tiene_tenant THEN
            p_append_pks('        pty_id_tenant  IN  ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL,');
        END IF;
        p_append_pks('        pro_' || v_tab_low || ' OUT ' || v_tab_low || '%ROWTYPE');
        p_append_pks('    ) RETURN BOOLEAN;');
        p_append_pks('');
        p_append_pks('    -- 9. Verificar existencia, retornar registro y ROWID');
        p_append_pks('    FUNCTION f_existe (');
        p_append_pks('        pty_id         IN  ' || v_tab_low || '.id%TYPE,');
        IF v_tiene_tenant THEN
            p_append_pks('        pty_id_tenant  IN  ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL,');
        END IF;
        p_append_pks('        pro_' || v_tab_low || ' OUT ' || v_tab_low || '%ROWTYPE,');
        p_append_pks('        p_rowid        OUT VARCHAR2');
        p_append_pks('    ) RETURN BOOLEAN;');
        p_append_pks('');
        p_append_pks('    -- 10. Verificar existencia por ROWID');
        p_append_pks('    FUNCTION f_existe_rowid (');
        p_append_pks('        p_rowid IN VARCHAR2');
        p_append_pks('    ) RETURN BOOLEAN;');
        p_append_pks('');
        p_append_pks('    -- 11. Verificar existencia por ROWID y retornar registro');
        p_append_pks('    FUNCTION f_existe_rowid (');
        p_append_pks('        p_rowid        IN  VARCHAR2,');
        p_append_pks('        pro_' || v_tab_low || ' OUT ' || v_tab_low || '%ROWTYPE');
        p_append_pks('    ) RETURN BOOLEAN;');
        p_append_pks('');
        p_append_pks('    -- 12. Actualizar registro completo por PK en ROWTYPE');
        p_append_pks('    PROCEDURE p_actualizar (');
        p_append_pks('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE');
        p_append_pks('    );');
        p_append_pks('');
        p_append_pks('    -- 13. Actualizar indicando PK explícita');
        p_append_pks('    PROCEDURE p_actualizar (');
        p_append_pks('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE,');
        IF v_tiene_tenant THEN
            p_append_pks('        pty_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pks('        pty_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pks('        pty_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pks('    );');
        p_append_pks('');
        p_append_pks('    -- 14. Actualizar por ROWID');
        p_append_pks('    PROCEDURE p_actualizar_rowid (');
        p_append_pks('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE,');
        p_append_pks('        p_rowid        IN VARCHAR2');
        p_append_pks('    );');
        p_append_pks('');
        p_append_pks('    -- 15. Actualizar todos los registros');
        p_append_pks('    PROCEDURE p_actualizar_registros (');
        IF v_tiene_tenant THEN
            p_append_pks('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE,');
            p_append_pks('        p_id_tenant    IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pks('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE');
        END IF;
        p_append_pks('    );');
        p_append_pks('');
        p_append_pks('    -- 16. Obtener valores por defecto');
        p_append_pks('    PROCEDURE p_valores_defecto (');
        p_append_pks('        pro_' || v_tab_low || ' IN OUT ' || v_tab_low || '%ROWTYPE');
        p_append_pks('    );');
        p_append_pks('');
        p_append_pks('    -- 17. Verificar existencia y retornar JSON CLOB');
        p_append_pks('    FUNCTION f_existe_json (');
        p_append_pks('        p_id          IN  ' || v_tab_low || '.id%TYPE,');
        IF v_tiene_tenant THEN
            p_append_pks('        p_id_tenant   IN  ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL,');
        END IF;
        p_append_pks('        p_json_' || v_tab_low || ' OUT CLOB');
        p_append_pks('    ) RETURN NUMBER;');
        p_append_pks('');
        p_append_pks('    -- 18. Obtener JSON por PK');
        p_append_pks('    FUNCTION f_json (');
        IF v_tiene_tenant THEN
            p_append_pks('        p_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pks('        p_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pks('        p_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pks('    ) RETURN VARCHAR2;');
        p_append_pks('');
        p_append_pks('    -- 19. Calcular total de páginas para paginación');
        p_append_pks('    FUNCTION f_total_paginas (');
        p_append_pks('        p_json_entrada IN CLOB');
        p_append_pks('    ) RETURN NUMBER;');
        p_append_pks('');
        p_append_pks('    -- 20. Consultar registros paginados retornando JSON');
        p_append_pks('    FUNCTION f_consultar_paginado (');
        p_append_pks('        p_pagina    IN NUMBER,');
        IF v_tiene_tenant THEN
            p_append_pks('        p_registros IN NUMBER,');
            p_append_pks('        p_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pks('        p_registros IN NUMBER');
        END IF;
        p_append_pks('    ) RETURN CLOB;');
        p_append_pks('');
        p_append_pks('END ' || v_pkg_name || ';');

        -- =====================================================================
        -- CONSTRUCCIÓN DEL CUERPO (.PKB)
        -- =====================================================================
        v_sql_pkb := NULL;
        p_append_pkb('CREATE OR REPLACE PACKAGE BODY ' || v_pkg_name);
        p_append_pkb('AS');
        p_append_pkb('    -- 1. Insertar registro completo');
        p_append_pkb('    PROCEDURE p_insertar (');
        p_append_pkb('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE');
        p_append_pkb('    ) IS');
        p_append_pkb('        vro_' || v_tab_low || ' ' || v_tab_low || '%ROWTYPE := pro_' || v_tab_low || ';');
        p_append_pkb('    BEGIN');
        IF v_tiene_tenant THEN
            p_append_pkb('        IF vro_' || v_tab_low || '.id_tenant IS NULL THEN');
            p_append_pkb('            vro_' || v_tab_low || '.id_tenant := TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT''));');
            p_append_pkb('        END IF;');
        END IF;
        p_append_pkb('        INSERT INTO ' || v_tab_low || ' VALUES vro_' || v_tab_low || ';');
        p_append_pkb('    END p_insertar;');
        p_append_pkb('');
        p_append_pkb('    -- 2. Traer registro por PK');
        p_append_pkb('    FUNCTION f_traer (');
        IF v_tiene_tenant THEN
            p_append_pkb('        pty_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pkb('        pty_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pkb('        pty_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pkb('    ) RETURN ' || v_tab_low || '%ROWTYPE IS');
        p_append_pkb('        vro_' || v_tab_low || ' ' || v_tab_low || '%ROWTYPE;');
        p_append_pkb('    BEGIN');
        p_append_pkb('        SELECT *');
        p_append_pkb('          INTO vro_' || v_tab_low);
        p_append_pkb('          FROM ' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('         WHERE id = pty_id;');
        END IF;
        p_append_pkb('        RETURN vro_' || v_tab_low || ';');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN NO_DATA_FOUND THEN');
        p_append_pkb('            RETURN NULL;');
        p_append_pkb('    END f_traer;');
        p_append_pkb('');
        p_append_pkb('    -- 3. Consultar todos los registros');
        p_append_pkb('    PROCEDURE p_consultar_registros (');
        IF v_tiene_tenant THEN
            p_append_pkb('        p_id_tenant    IN  ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL,');
        END IF;
        p_append_pkb('        pta_' || v_tab_low || ' OUT ' || v_pkg_name || '.ta_' || v_tab_low);
        p_append_pkb('    ) IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        SELECT *');
        p_append_pkb('          BULK COLLECT INTO pta_' || v_tab_low);
        p_append_pkb('          FROM ' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('        ;');
        END IF;
        p_append_pkb('    END p_consultar_registros;');
        p_append_pkb('');
        p_append_pkb('    -- 4. Eliminar por ROWID');
        p_append_pkb('    PROCEDURE p_eliminar_rowid (');
        p_append_pkb('        p_rowid IN VARCHAR2');
        p_append_pkb('    ) IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        DELETE FROM ' || v_tab_low);
        p_append_pkb('         WHERE ROWID = p_rowid');
        IF v_tiene_tenant THEN
            p_append_pkb('           AND id_tenant = TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT''));');
        ELSE
            p_append_pkb('        ;');
        END IF;
        p_append_pkb('    END p_eliminar_rowid;');
        p_append_pkb('');
        p_append_pkb('    -- 5. Eliminar por PK');
        p_append_pkb('    PROCEDURE p_eliminar (');
        IF v_tiene_tenant THEN
            p_append_pkb('        pty_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pkb('        pty_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pkb('        pty_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pkb('    ) IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        DELETE FROM ' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('         WHERE id = pty_id;');
        END IF;
        p_append_pkb('    END p_eliminar;');
        p_append_pkb('');
        p_append_pkb('    -- 6. Eliminar todos los registros');
        IF v_tiene_tenant THEN
            p_append_pkb('    PROCEDURE p_eliminar_registros (');
            p_append_pkb('        p_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
            p_append_pkb('    ) IS');
            p_append_pkb('    BEGIN');
            p_append_pkb('        DELETE FROM ' || v_tab_low);
            p_append_pkb('         WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
            p_append_pkb('    END p_eliminar_registros;');
        ELSE
            p_append_pkb('    PROCEDURE p_eliminar_registros IS');
            p_append_pkb('    BEGIN');
            p_append_pkb('        DELETE FROM ' || v_tab_low || ';');
            p_append_pkb('    END p_eliminar_registros;');
        END IF;
        p_append_pkb('');
        p_append_pkb('    -- 7. Verificar existencia por PK');
        p_append_pkb('    FUNCTION f_existe (');
        IF v_tiene_tenant THEN
            p_append_pkb('        pty_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pkb('        pty_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pkb('        pty_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pkb('    ) RETURN BOOLEAN IS');
        p_append_pkb('        v_existe NUMBER(1);');
        p_append_pkb('    BEGIN');
        p_append_pkb('        SELECT 1');
        p_append_pkb('          INTO v_existe');
        p_append_pkb('          FROM ' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('         WHERE id = pty_id;');
        END IF;
        p_append_pkb('        RETURN TRUE;');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN NO_DATA_FOUND THEN');
        p_append_pkb('            RETURN FALSE;');
        p_append_pkb('    END f_existe;');
        p_append_pkb('');
        p_append_pkb('    -- 8. Verificar existencia y retornar registro');
        p_append_pkb('    FUNCTION f_existe (');
        p_append_pkb('        pty_id        IN  ' || v_tab_low || '.id%TYPE,');
        IF v_tiene_tenant THEN
            p_append_pkb('        pty_id_tenant IN  ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL,');
        END IF;
        p_append_pkb('        pro_' || v_tab_low || ' OUT ' || v_tab_low || '%ROWTYPE');
        p_append_pkb('    ) RETURN BOOLEAN IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        SELECT *');
        p_append_pkb('          INTO pro_' || v_tab_low);
        p_append_pkb('          FROM ' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('         WHERE id = pty_id;');
        END IF;
        p_append_pkb('        RETURN TRUE;');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN NO_DATA_FOUND THEN');
        p_append_pkb('            RETURN FALSE;');
        p_append_pkb('    END f_existe;');
        p_append_pkb('');
        p_append_pkb('    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)');
        p_append_pkb('    FUNCTION f_existe (');
        p_append_pkb('        pty_id        IN  ' || v_tab_low || '.id%TYPE,');
        IF v_tiene_tenant THEN
            p_append_pkb('        pty_id_tenant IN  ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL,');
        END IF;
        p_append_pkb('        pro_' || v_tab_low || ' OUT ' || v_tab_low || '%ROWTYPE,');
        p_append_pkb('        p_rowid       OUT VARCHAR2');
        p_append_pkb('    ) RETURN BOOLEAN IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        SELECT ROWID');
        p_append_pkb('          INTO p_rowid');
        p_append_pkb('          FROM ' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('         WHERE id = pty_id;');
        END IF;
        p_append_pkb('');
        p_append_pkb('        SELECT *');
        p_append_pkb('          INTO pro_' || v_tab_low);
        p_append_pkb('          FROM ' || v_tab_low);
        p_append_pkb('         WHERE ROWID = p_rowid;');
        p_append_pkb('');
        p_append_pkb('        RETURN TRUE;');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN NO_DATA_FOUND THEN');
        p_append_pkb('            RETURN FALSE;');
        p_append_pkb('    END f_existe;');
        p_append_pkb('');
        p_append_pkb('    -- 10. Verificar existencia por ROWID');
        p_append_pkb('    FUNCTION f_existe_rowid (');
        p_append_pkb('        p_rowid IN VARCHAR2');
        p_append_pkb('    ) RETURN BOOLEAN IS');
        p_append_pkb('        v_existe NUMBER(1);');
        p_append_pkb('    BEGIN');
        p_append_pkb('        SELECT 1');
        p_append_pkb('          INTO v_existe');
        p_append_pkb('          FROM ' || v_tab_low);
        p_append_pkb('         WHERE ROWID = p_rowid');
        IF v_tiene_tenant THEN
            p_append_pkb('           AND id_tenant = TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT''));');
        ELSE
            p_append_pkb('        ;');
        END IF;
        p_append_pkb('        RETURN TRUE;');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN NO_DATA_FOUND THEN');
        p_append_pkb('            RETURN FALSE;');
        p_append_pkb('    END f_existe_rowid;');
        p_append_pkb('');
        p_append_pkb('    -- 11. Verificar existencia por ROWID y retornar registro');
        p_append_pkb('    FUNCTION f_existe_rowid (');
        p_append_pkb('        p_rowid        IN  VARCHAR2,');
        p_append_pkb('        pro_' || v_tab_low || ' OUT ' || v_tab_low || '%ROWTYPE');
        p_append_pkb('    ) RETURN BOOLEAN IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        SELECT *');
        p_append_pkb('          INTO pro_' || v_tab_low);
        p_append_pkb('          FROM ' || v_tab_low);
        p_append_pkb('         WHERE ROWID = p_rowid');
        IF v_tiene_tenant THEN
            p_append_pkb('           AND id_tenant = TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT''));');
        ELSE
            p_append_pkb('        ;');
        END IF;
        p_append_pkb('        RETURN TRUE;');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN NO_DATA_FOUND THEN');
        p_append_pkb('            RETURN FALSE;');
        p_append_pkb('    END f_existe_rowid;');
        p_append_pkb('');
        p_append_pkb('    -- 12. Actualizar registro completo por PK en ROWTYPE');
        p_append_pkb('    PROCEDURE p_actualizar (');
        p_append_pkb('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE');
        p_append_pkb('    ) IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        UPDATE ' || v_tab_low);
        p_append_pkb('           SET ROW = pro_' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE id = pro_' || v_tab_low || '.id AND id_tenant = NVL(pro_' || v_tab_low || '.id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('         WHERE id = pro_' || v_tab_low || '.id;');
        END IF;
        p_append_pkb('    END p_actualizar;');
        p_append_pkb('');
        p_append_pkb('    -- 13. Actualizar indicando PK explícita');
        p_append_pkb('    PROCEDURE p_actualizar (');
        p_append_pkb('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE,');
        IF v_tiene_tenant THEN
            p_append_pkb('        pty_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pkb('        pty_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pkb('        pty_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pkb('    ) IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        UPDATE ' || v_tab_low);
        p_append_pkb('           SET ROW = pro_' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('         WHERE id = pty_id;');
        END IF;
        p_append_pkb('    END p_actualizar;');
        p_append_pkb('');
        p_append_pkb('    -- 14. Actualizar por ROWID');
        p_append_pkb('    PROCEDURE p_actualizar_rowid (');
        p_append_pkb('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE,');
        p_append_pkb('        p_rowid        IN VARCHAR2');
        p_append_pkb('    ) IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        UPDATE ' || v_tab_low);
        p_append_pkb('           SET ROW = pro_' || v_tab_low);
        p_append_pkb('         WHERE ROWID = p_rowid');
        IF v_tiene_tenant THEN
            p_append_pkb('           AND id_tenant = TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT''));');
        ELSE
            p_append_pkb('        ;');
        END IF;
        p_append_pkb('    END p_actualizar_rowid;');
        p_append_pkb('');
        p_append_pkb('    -- 15. Actualizar todos los registros');
        p_append_pkb('    PROCEDURE p_actualizar_registros (');
        IF v_tiene_tenant THEN
            p_append_pkb('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE,');
            p_append_pkb('        p_id_tenant    IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pkb('        pro_' || v_tab_low || ' IN ' || v_tab_low || '%ROWTYPE');
        END IF;
        p_append_pkb('    ) IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        UPDATE ' || v_tab_low);
        p_append_pkb('           SET ROW = pro_' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('        ;');
        END IF;
        p_append_pkb('    END p_actualizar_registros;');
        p_append_pkb('');
        p_append_pkb('    -- 16. Obtener valores por defecto');
        p_append_pkb('    PROCEDURE p_valores_defecto (');
        p_append_pkb('        pro_' || v_tab_low || ' IN OUT ' || v_tab_low || '%ROWTYPE');
        p_append_pkb('    ) IS');
        p_append_pkb('    BEGIN');
        IF v_tiene_tenant THEN
            p_append_pkb('        pro_' || v_tab_low || '.id_tenant := TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT''));');
        END IF;
        p_append_pkb('        NULL;');
        p_append_pkb('    END p_valores_defecto;');
        p_append_pkb('');
        p_append_pkb('    -- 17. Verificar existencia y retornar JSON CLOB');
        p_append_pkb('    FUNCTION f_existe_json (');
        p_append_pkb('        p_id          IN  ' || v_tab_low || '.id%TYPE,');
        IF v_tiene_tenant THEN
            p_append_pkb('        p_id_tenant   IN  ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL,');
        END IF;
        p_append_pkb('        p_json_' || v_tab_low || ' OUT CLOB');
        p_append_pkb('    ) RETURN NUMBER IS');
        p_append_pkb('    BEGIN');
        p_append_pkb('        SELECT JSON_OBJECT(t.* RETURNING CLOB)');
        p_append_pkb('          INTO p_json_' || v_tab_low);
        p_append_pkb('          FROM ' || v_tab_low || ' t');
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE t.id = p_id AND t.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('         WHERE t.id = p_id;');
        END IF;
        p_append_pkb('        RETURN 1;');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN NO_DATA_FOUND THEN');
        p_append_pkb('            p_json_' || v_tab_low || ' := NULL;');
        p_append_pkb('            RETURN 0;');
        p_append_pkb('    END f_existe_json;');
        p_append_pkb('');
        p_append_pkb('    -- 18. Obtener JSON por PK');
        p_append_pkb('    FUNCTION f_json (');
        IF v_tiene_tenant THEN
            p_append_pkb('        p_id        IN ' || v_tab_low || '.id%TYPE,');
            p_append_pkb('        p_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pkb('        p_id IN ' || v_tab_low || '.id%TYPE');
        END IF;
        p_append_pkb('    ) RETURN VARCHAR2 IS');
        p_append_pkb('        v_json VARCHAR2(4000);');
        p_append_pkb('    BEGIN');
        p_append_pkb('        SELECT JSON_OBJECT(t.*)');
        p_append_pkb('          INTO v_json');
        p_append_pkb('          FROM ' || v_tab_low || ' t');
        IF v_tiene_tenant THEN
            p_append_pkb('         WHERE t.id = p_id AND t.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        ELSE
            p_append_pkb('         WHERE t.id = p_id;');
        END IF;
        p_append_pkb('        RETURN v_json;');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN NO_DATA_FOUND THEN');
        p_append_pkb('            RETURN NULL;');
        p_append_pkb('    END f_json;');
        p_append_pkb('');
        p_append_pkb('    -- 19. Calcular total de páginas');
        p_append_pkb('    FUNCTION f_total_paginas (');
        p_append_pkb('        p_json_entrada IN CLOB');
        p_append_pkb('    ) RETURN NUMBER IS');
        p_append_pkb('        v_registros_por_pagina NUMBER;');
        p_append_pkb('        v_total_registros      NUMBER;');
        IF v_tiene_tenant THEN
            p_append_pkb('        v_id_tenant            NUMBER;');
        END IF;
        p_append_pkb('    BEGIN');
        p_append_pkb('        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, ''$.registros'')), 10);');
        p_append_pkb('        IF v_registros_por_pagina <= 0 THEN');
        p_append_pkb('            v_registros_por_pagina := 10;');
        p_append_pkb('        END IF;');
        p_append_pkb('');
        IF v_tiene_tenant THEN
            p_append_pkb('        v_id_tenant := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, ''$.id_tenant'')), TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
            p_append_pkb('        SELECT COUNT(1)');
            p_append_pkb('          INTO v_total_registros');
            p_append_pkb('          FROM ' || v_tab_low);
            p_append_pkb('         WHERE id_tenant = v_id_tenant;');
        ELSE
            p_append_pkb('        SELECT COUNT(1)');
            p_append_pkb('          INTO v_total_registros');
            p_append_pkb('          FROM ' || v_tab_low || ';');
        END IF;
        p_append_pkb('');
        p_append_pkb('        RETURN CEIL(v_total_registros / v_registros_por_pagina);');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN OTHERS THEN');
        p_append_pkb('            RETURN 0;');
        p_append_pkb('    END f_total_paginas;');
        p_append_pkb('');
        p_append_pkb('    -- 20. Consultar registros paginados retornando JSON');
        p_append_pkb('    FUNCTION f_consultar_paginado (');
        p_append_pkb('        p_pagina    IN NUMBER,');
        IF v_tiene_tenant THEN
            p_append_pkb('        p_registros IN NUMBER,');
            p_append_pkb('        p_id_tenant IN ' || v_tab_low || '.id_tenant%TYPE DEFAULT NULL');
        ELSE
            p_append_pkb('        p_registros IN NUMBER');
        END IF;
        p_append_pkb('    ) RETURN CLOB IS');
        p_append_pkb('        v_offset NUMBER;');
        p_append_pkb('        v_limite NUMBER;');
        p_append_pkb('        v_json   CLOB;');
        IF v_tiene_tenant THEN
            p_append_pkb('        v_tenant NUMBER;');
        END IF;
        p_append_pkb('    BEGIN');
        p_append_pkb('        v_limite := NVL(p_registros, 10);');
        p_append_pkb('        IF v_limite <= 0 THEN');
        p_append_pkb('            v_limite := 10;');
        p_append_pkb('        END IF;');
        p_append_pkb('');
        p_append_pkb('        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;');
        IF v_tiene_tenant THEN
            p_append_pkb('        v_tenant := NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT(''CORE_CTX'', ''ID_TENANT'')));');
        END IF;
        p_append_pkb('');
        p_append_pkb('        SELECT NVL(');
        p_append_pkb('                   JSON_ARRAYAGG(');
        p_append_pkb('                       JSON_OBJECT(t.*)');
        p_append_pkb('                       RETURNING CLOB');
        p_append_pkb('                   ),');
        p_append_pkb('                   TO_CLOB(''[]'')');
        p_append_pkb('               )');
        p_append_pkb('          INTO v_json');
        p_append_pkb('          FROM (');
        p_append_pkb('              SELECT *');
        p_append_pkb('                FROM ' || v_tab_low);
        IF v_tiene_tenant THEN
            p_append_pkb('               WHERE id_tenant = v_tenant');
        END IF;
        p_append_pkb('               ORDER BY id ASC');
        p_append_pkb('              OFFSET v_offset ROWS');
        p_append_pkb('               FETCH NEXT v_limite ROWS ONLY');
        p_append_pkb('          ) t;');
        p_append_pkb('');
        p_append_pkb('        RETURN v_json;');
        p_append_pkb('    EXCEPTION');
        p_append_pkb('        WHEN OTHERS THEN');
        p_append_pkb('            RETURN TO_CLOB(''[]'');');
        p_append_pkb('    END f_consultar_paginado;');
        p_append_pkb('');
        p_append_pkb('END ' || v_pkg_name || ';');

        -- =====================================================================
        -- COMPILACIÓN DINÁMICA DE LA ESPECIFICACIÓN (.PKS)
        -- =====================================================================
        BEGIN
            EXECUTE IMMEDIATE v_sql_pks;
            DBMS_OUTPUT.PUT_LINE('  [OK] Especificación compilada: ' || v_pkg_name);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  [ERROR] Falló compilación de especificación ' || v_pkg_name || ': ' || SQLERRM);
                v_cant_errores := v_cant_errores + 1;
        END;

        -- =====================================================================
        -- COMPILACIÓN DINÁMICA DEL CUERPO (.PKB)
        -- =====================================================================
        BEGIN
            EXECUTE IMMEDIATE v_sql_pkb;
            DBMS_OUTPUT.PUT_LINE('  [OK] Cuerpo compilado: ' || v_pkg_name);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('  [ERROR] Falló compilación de cuerpo ' || v_pkg_name || ': ' || SQLERRM);
                v_cant_errores := v_cant_errores + 1;
        END;

        -- Verificación de errores en USER_ERRORS
        FOR r_err IN (
            SELECT type, line, position, text
              FROM user_errors
             WHERE name = v_pkg_name
             ORDER BY type, sequence
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('    -> ' || r_err.type || ' [' || r_err.line || ':' || r_err.position || ']: ' || r_err.text);
            v_cant_errores := v_cant_errores + 1;
        END LOOP;

        IF v_cant_errores > 0 THEN
            DBMS_OUTPUT.PUT_LINE('  [AVISO] ' || v_pkg_name || ' tiene ' || v_cant_errores || ' advertencias/errores.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('  [EXITO] ' || v_pkg_name || ' compilado y válido.');
        END IF;

    END p_generar_compilar_tabla;

    -- Procedimiento público principal
    PROCEDURE p_crear_dao (
        p_nombre_tabla IN VARCHAR2 DEFAULT NULL
    ) IS
        v_total_procesadas NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('============================================================');
        DBMS_OUTPUT.PUT_LINE('UTI_PAQUETES_PKG: INICIANDO GENERACIÓN DE PAQUETES DAO');
        DBMS_OUTPUT.PUT_LINE('============================================================');

        IF p_nombre_tabla IS NOT NULL THEN
            p_generar_compilar_tabla(p_nombre_tabla);
            v_total_procesadas := 1;
        ELSE
            FOR r_tab IN (
                SELECT table_name
                  FROM user_tables
                 WHERE table_name LIKE 'CORE_%'
                 ORDER BY table_name
            ) LOOP
                p_generar_compilar_tabla(r_tab.table_name);
                v_total_procesadas := v_total_procesadas + 1;
            END LOOP;
        END IF;

        DBMS_OUTPUT.PUT_LINE('============================================================');
        DBMS_OUTPUT.PUT_LINE('TOTAL TABLAS PROCESADAS: ' || v_total_procesadas);
        DBMS_OUTPUT.PUT_LINE('============================================================');

    END p_crear_dao;

END uti_paquetes_pkg;
/
