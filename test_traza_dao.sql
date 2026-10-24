-- ============================================================================
-- SISTEMA TKR — PAQUETES DE ACCESO A DATOS DAO (20 MÉTODOS ESTÁNDAR)
-- TOTAL: 11 PAQUETES DAO PARA MOTOR DE PRUEBAS Y TELEMETRÍA (MONO-TENANT)
--
-- Base de Datos: Oracle Database (23ai / 21c / 19c)
-- Estándar     : Plantilla Oficial DAO PL/SQL Oracle
-- Control Transaccional: Sin COMMIT ni ROLLBACK (controlado por capa superior)
-- Solución Puntero    : Consulta por ROWID para compatibilidad %ROWTYPE
-- ============================================================================

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TEST_SUITE_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TEST_SUITE_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TEST_SUITE_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_test_suite
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_test_suite IS TABLE OF tkr_test_suite%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_suite.id%TYPE
    ) RETURN tkr_test_suite%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_suite OUT PKGTKR_TEST_SUITE_DAO.ta_tkr_test_suite
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_suite.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_suite.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_suite.id%TYPE,
        pro_tkr_test_suite OUT tkr_test_suite%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_test_suite.id%TYPE,
        pro_tkr_test_suite OUT tkr_test_suite%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_suite OUT tkr_test_suite%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE,
        pty_id         IN tkr_test_suite.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_suite IN OUT tkr_test_suite%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_suite.id%TYPE,
        p_json_tkr_test_suite OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_suite.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TEST_SUITE_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TEST_SUITE_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TEST_SUITE_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE
    ) IS
        vro_tkr_test_suite tkr_test_suite%ROWTYPE := pro_tkr_test_suite;
    BEGIN
        INSERT INTO tkr_test_suite VALUES vro_tkr_test_suite;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_suite.id%TYPE
    ) RETURN tkr_test_suite%ROWTYPE IS
        vro_tkr_test_suite tkr_test_suite%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_test_suite
          FROM tkr_test_suite
         WHERE id = pty_id;
        RETURN vro_tkr_test_suite;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_suite OUT PKGTKR_TEST_SUITE_DAO.ta_tkr_test_suite
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_test_suite
          FROM tkr_test_suite;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_test_suite
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_suite.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_test_suite
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_test_suite;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_suite.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_test_suite
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_suite.id%TYPE,
        pro_tkr_test_suite OUT tkr_test_suite%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_suite
          FROM tkr_test_suite
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_test_suite.id%TYPE,
        pro_tkr_test_suite OUT tkr_test_suite%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_test_suite
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_test_suite
          FROM tkr_test_suite
         WHERE ROWID = p_rowid;

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
          FROM tkr_test_suite
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_suite OUT tkr_test_suite%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_suite
          FROM tkr_test_suite
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_suite
           SET ROW = pro_tkr_test_suite
         WHERE id = pro_tkr_test_suite.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE,
        pty_id         IN tkr_test_suite.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_test_suite
           SET ROW = pro_tkr_test_suite
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_test_suite
           SET ROW = pro_tkr_test_suite
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_suite IN tkr_test_suite%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_suite
           SET ROW = pro_tkr_test_suite;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_suite IN OUT tkr_test_suite%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_suite.id%TYPE,
        p_json_tkr_test_suite OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_test_suite
          FROM tkr_test_suite t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_test_suite := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_suite.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_test_suite t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_test_suite;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_test_suite
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TEST_SUITE_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TEST_OBJETO_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TEST_OBJETO_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TEST_OBJETO_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_test_objeto
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_test_objeto IS TABLE OF tkr_test_objeto%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_objeto.id%TYPE
    ) RETURN tkr_test_objeto%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_objeto OUT PKGTKR_TEST_OBJETO_DAO.ta_tkr_test_objeto
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_objeto.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_objeto.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_objeto.id%TYPE,
        pro_tkr_test_objeto OUT tkr_test_objeto%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_test_objeto.id%TYPE,
        pro_tkr_test_objeto OUT tkr_test_objeto%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_objeto OUT tkr_test_objeto%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE,
        pty_id         IN tkr_test_objeto.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_objeto IN OUT tkr_test_objeto%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_objeto.id%TYPE,
        p_json_tkr_test_objeto OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_objeto.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TEST_OBJETO_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TEST_OBJETO_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TEST_OBJETO_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE
    ) IS
        vro_tkr_test_objeto tkr_test_objeto%ROWTYPE := pro_tkr_test_objeto;
    BEGIN
        INSERT INTO tkr_test_objeto VALUES vro_tkr_test_objeto;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_objeto.id%TYPE
    ) RETURN tkr_test_objeto%ROWTYPE IS
        vro_tkr_test_objeto tkr_test_objeto%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_test_objeto
          FROM tkr_test_objeto
         WHERE id = pty_id;
        RETURN vro_tkr_test_objeto;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_objeto OUT PKGTKR_TEST_OBJETO_DAO.ta_tkr_test_objeto
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_test_objeto
          FROM tkr_test_objeto;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_test_objeto
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_objeto.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_test_objeto
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_test_objeto;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_objeto.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_test_objeto
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_objeto.id%TYPE,
        pro_tkr_test_objeto OUT tkr_test_objeto%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_objeto
          FROM tkr_test_objeto
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_test_objeto.id%TYPE,
        pro_tkr_test_objeto OUT tkr_test_objeto%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_test_objeto
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_test_objeto
          FROM tkr_test_objeto
         WHERE ROWID = p_rowid;

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
          FROM tkr_test_objeto
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_objeto OUT tkr_test_objeto%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_objeto
          FROM tkr_test_objeto
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_objeto
           SET ROW = pro_tkr_test_objeto
         WHERE id = pro_tkr_test_objeto.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE,
        pty_id         IN tkr_test_objeto.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_test_objeto
           SET ROW = pro_tkr_test_objeto
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_test_objeto
           SET ROW = pro_tkr_test_objeto
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_objeto IN tkr_test_objeto%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_objeto
           SET ROW = pro_tkr_test_objeto;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_objeto IN OUT tkr_test_objeto%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_objeto.id%TYPE,
        p_json_tkr_test_objeto OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_test_objeto
          FROM tkr_test_objeto t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_test_objeto := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_objeto.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_test_objeto t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_test_objeto;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_test_objeto
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TEST_OBJETO_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TEST_CASO_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TEST_CASO_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TEST_CASO_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_test_caso
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_test_caso IS TABLE OF tkr_test_caso%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_caso.id%TYPE
    ) RETURN tkr_test_caso%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_caso OUT PKGTKR_TEST_CASO_DAO.ta_tkr_test_caso
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_caso.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_caso.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_caso.id%TYPE,
        pro_tkr_test_caso OUT tkr_test_caso%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_test_caso.id%TYPE,
        pro_tkr_test_caso OUT tkr_test_caso%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_caso OUT tkr_test_caso%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE,
        pty_id         IN tkr_test_caso.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_caso IN OUT tkr_test_caso%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_caso.id%TYPE,
        p_json_tkr_test_caso OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_caso.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TEST_CASO_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TEST_CASO_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TEST_CASO_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE
    ) IS
        vro_tkr_test_caso tkr_test_caso%ROWTYPE := pro_tkr_test_caso;
    BEGIN
        INSERT INTO tkr_test_caso VALUES vro_tkr_test_caso;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_caso.id%TYPE
    ) RETURN tkr_test_caso%ROWTYPE IS
        vro_tkr_test_caso tkr_test_caso%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_test_caso
          FROM tkr_test_caso
         WHERE id = pty_id;
        RETURN vro_tkr_test_caso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_caso OUT PKGTKR_TEST_CASO_DAO.ta_tkr_test_caso
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_test_caso
          FROM tkr_test_caso;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_test_caso
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_caso.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_test_caso
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_test_caso;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_caso.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_test_caso
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_caso.id%TYPE,
        pro_tkr_test_caso OUT tkr_test_caso%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_caso
          FROM tkr_test_caso
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_test_caso.id%TYPE,
        pro_tkr_test_caso OUT tkr_test_caso%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_test_caso
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_test_caso
          FROM tkr_test_caso
         WHERE ROWID = p_rowid;

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
          FROM tkr_test_caso
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_caso OUT tkr_test_caso%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_caso
          FROM tkr_test_caso
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_caso
           SET ROW = pro_tkr_test_caso
         WHERE id = pro_tkr_test_caso.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE,
        pty_id         IN tkr_test_caso.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_test_caso
           SET ROW = pro_tkr_test_caso
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_test_caso
           SET ROW = pro_tkr_test_caso
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_caso IN tkr_test_caso%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_caso
           SET ROW = pro_tkr_test_caso;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_caso IN OUT tkr_test_caso%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_caso.id%TYPE,
        p_json_tkr_test_caso OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_test_caso
          FROM tkr_test_caso t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_test_caso := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_caso.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_test_caso t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_test_caso;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_test_caso
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TEST_CASO_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TEST_ASERCION_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TEST_ASERCION_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TEST_ASERCION_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_test_asercion
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_test_asercion IS TABLE OF tkr_test_asercion%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_asercion.id%TYPE
    ) RETURN tkr_test_asercion%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_asercion OUT PKGTKR_TEST_ASERCION_DAO.ta_tkr_test_asercion
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_asercion.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_asercion.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_asercion.id%TYPE,
        pro_tkr_test_asercion OUT tkr_test_asercion%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_test_asercion.id%TYPE,
        pro_tkr_test_asercion OUT tkr_test_asercion%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_asercion OUT tkr_test_asercion%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE,
        pty_id         IN tkr_test_asercion.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_asercion IN OUT tkr_test_asercion%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_asercion.id%TYPE,
        p_json_tkr_test_asercion OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_asercion.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TEST_ASERCION_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TEST_ASERCION_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TEST_ASERCION_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE
    ) IS
        vro_tkr_test_asercion tkr_test_asercion%ROWTYPE := pro_tkr_test_asercion;
    BEGIN
        INSERT INTO tkr_test_asercion VALUES vro_tkr_test_asercion;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_asercion.id%TYPE
    ) RETURN tkr_test_asercion%ROWTYPE IS
        vro_tkr_test_asercion tkr_test_asercion%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_test_asercion
          FROM tkr_test_asercion
         WHERE id = pty_id;
        RETURN vro_tkr_test_asercion;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_asercion OUT PKGTKR_TEST_ASERCION_DAO.ta_tkr_test_asercion
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_test_asercion
          FROM tkr_test_asercion;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_test_asercion
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_asercion.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_test_asercion
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_test_asercion;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_asercion.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_test_asercion
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_asercion.id%TYPE,
        pro_tkr_test_asercion OUT tkr_test_asercion%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_asercion
          FROM tkr_test_asercion
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_test_asercion.id%TYPE,
        pro_tkr_test_asercion OUT tkr_test_asercion%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_test_asercion
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_test_asercion
          FROM tkr_test_asercion
         WHERE ROWID = p_rowid;

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
          FROM tkr_test_asercion
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_asercion OUT tkr_test_asercion%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_asercion
          FROM tkr_test_asercion
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_asercion
           SET ROW = pro_tkr_test_asercion
         WHERE id = pro_tkr_test_asercion.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE,
        pty_id         IN tkr_test_asercion.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_test_asercion
           SET ROW = pro_tkr_test_asercion
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_test_asercion
           SET ROW = pro_tkr_test_asercion
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_asercion IN tkr_test_asercion%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_asercion
           SET ROW = pro_tkr_test_asercion;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_asercion IN OUT tkr_test_asercion%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_asercion.id%TYPE,
        p_json_tkr_test_asercion OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_test_asercion
          FROM tkr_test_asercion t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_test_asercion := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_asercion.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_test_asercion t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_test_asercion;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_test_asercion
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TEST_ASERCION_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TEST_MOCK_DATO_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TEST_MOCK_DATO_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TEST_MOCK_DATO_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_test_mock_dato
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_test_mock_dato IS TABLE OF tkr_test_mock_dato%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_mock_dato.id%TYPE
    ) RETURN tkr_test_mock_dato%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_mock_dato OUT PKGTKR_TEST_MOCK_DATO_DAO.ta_tkr_test_mock_dato
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_mock_dato.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_mock_dato.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_mock_dato.id%TYPE,
        pro_tkr_test_mock_dato OUT tkr_test_mock_dato%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_test_mock_dato.id%TYPE,
        pro_tkr_test_mock_dato OUT tkr_test_mock_dato%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_mock_dato OUT tkr_test_mock_dato%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE,
        pty_id         IN tkr_test_mock_dato.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_mock_dato IN OUT tkr_test_mock_dato%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_mock_dato.id%TYPE,
        p_json_tkr_test_mock_dato OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_mock_dato.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TEST_MOCK_DATO_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TEST_MOCK_DATO_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TEST_MOCK_DATO_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE
    ) IS
        vro_tkr_test_mock_dato tkr_test_mock_dato%ROWTYPE := pro_tkr_test_mock_dato;
    BEGIN
        INSERT INTO tkr_test_mock_dato VALUES vro_tkr_test_mock_dato;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_mock_dato.id%TYPE
    ) RETURN tkr_test_mock_dato%ROWTYPE IS
        vro_tkr_test_mock_dato tkr_test_mock_dato%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_test_mock_dato
          FROM tkr_test_mock_dato
         WHERE id = pty_id;
        RETURN vro_tkr_test_mock_dato;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_mock_dato OUT PKGTKR_TEST_MOCK_DATO_DAO.ta_tkr_test_mock_dato
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_test_mock_dato
          FROM tkr_test_mock_dato;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_test_mock_dato
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_mock_dato.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_test_mock_dato
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_test_mock_dato;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_mock_dato.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_test_mock_dato
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_mock_dato.id%TYPE,
        pro_tkr_test_mock_dato OUT tkr_test_mock_dato%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_mock_dato
          FROM tkr_test_mock_dato
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_test_mock_dato.id%TYPE,
        pro_tkr_test_mock_dato OUT tkr_test_mock_dato%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_test_mock_dato
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_test_mock_dato
          FROM tkr_test_mock_dato
         WHERE ROWID = p_rowid;

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
          FROM tkr_test_mock_dato
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_mock_dato OUT tkr_test_mock_dato%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_mock_dato
          FROM tkr_test_mock_dato
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_mock_dato
           SET ROW = pro_tkr_test_mock_dato
         WHERE id = pro_tkr_test_mock_dato.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE,
        pty_id         IN tkr_test_mock_dato.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_test_mock_dato
           SET ROW = pro_tkr_test_mock_dato
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_test_mock_dato
           SET ROW = pro_tkr_test_mock_dato
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_mock_dato IN tkr_test_mock_dato%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_mock_dato
           SET ROW = pro_tkr_test_mock_dato;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_mock_dato IN OUT tkr_test_mock_dato%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_mock_dato.id%TYPE,
        p_json_tkr_test_mock_dato OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_test_mock_dato
          FROM tkr_test_mock_dato t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_test_mock_dato := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_mock_dato.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_test_mock_dato t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_test_mock_dato;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_test_mock_dato
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TEST_MOCK_DATO_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TEST_EJECUCION_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TEST_EJECUCION_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TEST_EJECUCION_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_test_ejecucion
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_test_ejecucion IS TABLE OF tkr_test_ejecucion%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_ejecucion.id%TYPE
    ) RETURN tkr_test_ejecucion%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_ejecucion OUT PKGTKR_TEST_EJECUCION_DAO.ta_tkr_test_ejecucion
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_ejecucion.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_ejecucion.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_ejecucion.id%TYPE,
        pro_tkr_test_ejecucion OUT tkr_test_ejecucion%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_test_ejecucion.id%TYPE,
        pro_tkr_test_ejecucion OUT tkr_test_ejecucion%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_ejecucion OUT tkr_test_ejecucion%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE,
        pty_id         IN tkr_test_ejecucion.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_ejecucion IN OUT tkr_test_ejecucion%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_ejecucion.id%TYPE,
        p_json_tkr_test_ejecucion OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_ejecucion.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TEST_EJECUCION_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TEST_EJECUCION_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TEST_EJECUCION_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE
    ) IS
        vro_tkr_test_ejecucion tkr_test_ejecucion%ROWTYPE := pro_tkr_test_ejecucion;
    BEGIN
        INSERT INTO tkr_test_ejecucion VALUES vro_tkr_test_ejecucion;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_ejecucion.id%TYPE
    ) RETURN tkr_test_ejecucion%ROWTYPE IS
        vro_tkr_test_ejecucion tkr_test_ejecucion%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_test_ejecucion
          FROM tkr_test_ejecucion
         WHERE id = pty_id;
        RETURN vro_tkr_test_ejecucion;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_ejecucion OUT PKGTKR_TEST_EJECUCION_DAO.ta_tkr_test_ejecucion
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_test_ejecucion
          FROM tkr_test_ejecucion;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_test_ejecucion
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_ejecucion.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_test_ejecucion
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_test_ejecucion;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_ejecucion.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_test_ejecucion
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_ejecucion.id%TYPE,
        pro_tkr_test_ejecucion OUT tkr_test_ejecucion%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_ejecucion
          FROM tkr_test_ejecucion
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_test_ejecucion.id%TYPE,
        pro_tkr_test_ejecucion OUT tkr_test_ejecucion%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_test_ejecucion
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_test_ejecucion
          FROM tkr_test_ejecucion
         WHERE ROWID = p_rowid;

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
          FROM tkr_test_ejecucion
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_ejecucion OUT tkr_test_ejecucion%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_ejecucion
          FROM tkr_test_ejecucion
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_ejecucion
           SET ROW = pro_tkr_test_ejecucion
         WHERE id = pro_tkr_test_ejecucion.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE,
        pty_id         IN tkr_test_ejecucion.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_test_ejecucion
           SET ROW = pro_tkr_test_ejecucion
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_test_ejecucion
           SET ROW = pro_tkr_test_ejecucion
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_ejecucion IN tkr_test_ejecucion%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_ejecucion
           SET ROW = pro_tkr_test_ejecucion;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_ejecucion IN OUT tkr_test_ejecucion%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_ejecucion.id%TYPE,
        p_json_tkr_test_ejecucion OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_test_ejecucion
          FROM tkr_test_ejecucion t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_test_ejecucion := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_ejecucion.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_test_ejecucion t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_test_ejecucion;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_test_ejecucion
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TEST_EJECUCION_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TEST_DETALLE_EJECUCION_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TEST_DETALLE_EJECUCION_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TEST_DETALLE_EJECUCION_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_test_detalle_ejecucion
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_test_detalle_ejecucion IS TABLE OF tkr_test_detalle_ejecucion%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_detalle_ejecucion.id%TYPE
    ) RETURN tkr_test_detalle_ejecucion%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_detalle_ejecucion OUT PKGTKR_TEST_DETALLE_EJECUCION_DAO.ta_tkr_test_detalle_ejecucion
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_detalle_ejecucion.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_detalle_ejecucion.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_detalle_ejecucion.id%TYPE,
        pro_tkr_test_detalle_ejecucion OUT tkr_test_detalle_ejecucion%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_test_detalle_ejecucion.id%TYPE,
        pro_tkr_test_detalle_ejecucion OUT tkr_test_detalle_ejecucion%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_detalle_ejecucion OUT tkr_test_detalle_ejecucion%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE,
        pty_id         IN tkr_test_detalle_ejecucion.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_detalle_ejecucion IN OUT tkr_test_detalle_ejecucion%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_detalle_ejecucion.id%TYPE,
        p_json_tkr_test_detalle_ejecucion OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_detalle_ejecucion.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TEST_DETALLE_EJECUCION_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TEST_DETALLE_EJECUCION_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TEST_DETALLE_EJECUCION_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE
    ) IS
        vro_tkr_test_detalle_ejecucion tkr_test_detalle_ejecucion%ROWTYPE := pro_tkr_test_detalle_ejecucion;
    BEGIN
        INSERT INTO tkr_test_detalle_ejecucion VALUES vro_tkr_test_detalle_ejecucion;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_test_detalle_ejecucion.id%TYPE
    ) RETURN tkr_test_detalle_ejecucion%ROWTYPE IS
        vro_tkr_test_detalle_ejecucion tkr_test_detalle_ejecucion%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_test_detalle_ejecucion
          FROM tkr_test_detalle_ejecucion
         WHERE id = pty_id;
        RETURN vro_tkr_test_detalle_ejecucion;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_test_detalle_ejecucion OUT PKGTKR_TEST_DETALLE_EJECUCION_DAO.ta_tkr_test_detalle_ejecucion
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_test_detalle_ejecucion
          FROM tkr_test_detalle_ejecucion;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_test_detalle_ejecucion
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_test_detalle_ejecucion.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_test_detalle_ejecucion
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_test_detalle_ejecucion;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_test_detalle_ejecucion.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_test_detalle_ejecucion
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_test_detalle_ejecucion.id%TYPE,
        pro_tkr_test_detalle_ejecucion OUT tkr_test_detalle_ejecucion%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_detalle_ejecucion
          FROM tkr_test_detalle_ejecucion
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_test_detalle_ejecucion.id%TYPE,
        pro_tkr_test_detalle_ejecucion OUT tkr_test_detalle_ejecucion%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_test_detalle_ejecucion
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_test_detalle_ejecucion
          FROM tkr_test_detalle_ejecucion
         WHERE ROWID = p_rowid;

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
          FROM tkr_test_detalle_ejecucion
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_test_detalle_ejecucion OUT tkr_test_detalle_ejecucion%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_test_detalle_ejecucion
          FROM tkr_test_detalle_ejecucion
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_detalle_ejecucion
           SET ROW = pro_tkr_test_detalle_ejecucion
         WHERE id = pro_tkr_test_detalle_ejecucion.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE,
        pty_id         IN tkr_test_detalle_ejecucion.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_test_detalle_ejecucion
           SET ROW = pro_tkr_test_detalle_ejecucion
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_test_detalle_ejecucion
           SET ROW = pro_tkr_test_detalle_ejecucion
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_test_detalle_ejecucion IN tkr_test_detalle_ejecucion%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_test_detalle_ejecucion
           SET ROW = pro_tkr_test_detalle_ejecucion;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_test_detalle_ejecucion IN OUT tkr_test_detalle_ejecucion%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_test_detalle_ejecucion.id%TYPE,
        p_json_tkr_test_detalle_ejecucion OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_test_detalle_ejecucion
          FROM tkr_test_detalle_ejecucion t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_test_detalle_ejecucion := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_test_detalle_ejecucion.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_test_detalle_ejecucion t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_test_detalle_ejecucion;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_test_detalle_ejecucion
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TEST_DETALLE_EJECUCION_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TRAZA_CONFIG_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TRAZA_CONFIG_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TRAZA_CONFIG_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_traza_config
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_traza_config IS TABLE OF tkr_traza_config%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_traza_config.id%TYPE
    ) RETURN tkr_traza_config%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_traza_config OUT PKGTKR_TRAZA_CONFIG_DAO.ta_tkr_traza_config
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_traza_config.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_traza_config.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_config.id%TYPE,
        pro_tkr_traza_config OUT tkr_traza_config%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_config.id%TYPE,
        pro_tkr_traza_config OUT tkr_traza_config%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_traza_config OUT tkr_traza_config%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE,
        pty_id         IN tkr_traza_config.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_traza_config IN OUT tkr_traza_config%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_traza_config.id%TYPE,
        p_json_tkr_traza_config OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_traza_config.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TRAZA_CONFIG_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TRAZA_CONFIG_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TRAZA_CONFIG_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE
    ) IS
        vro_tkr_traza_config tkr_traza_config%ROWTYPE := pro_tkr_traza_config;
    BEGIN
        INSERT INTO tkr_traza_config VALUES vro_tkr_traza_config;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_traza_config.id%TYPE
    ) RETURN tkr_traza_config%ROWTYPE IS
        vro_tkr_traza_config tkr_traza_config%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_traza_config
          FROM tkr_traza_config
         WHERE id = pty_id;
        RETURN vro_tkr_traza_config;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_traza_config OUT PKGTKR_TRAZA_CONFIG_DAO.ta_tkr_traza_config
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_traza_config
          FROM tkr_traza_config;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_traza_config
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_traza_config.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_traza_config
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_traza_config;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_traza_config.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_traza_config
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_config.id%TYPE,
        pro_tkr_traza_config OUT tkr_traza_config%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_traza_config
          FROM tkr_traza_config
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_config.id%TYPE,
        pro_tkr_traza_config OUT tkr_traza_config%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_traza_config
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_traza_config
          FROM tkr_traza_config
         WHERE ROWID = p_rowid;

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
          FROM tkr_traza_config
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_traza_config OUT tkr_traza_config%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_traza_config
          FROM tkr_traza_config
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_config
           SET ROW = pro_tkr_traza_config
         WHERE id = pro_tkr_traza_config.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE,
        pty_id         IN tkr_traza_config.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_config
           SET ROW = pro_tkr_traza_config
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_traza_config
           SET ROW = pro_tkr_traza_config
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_traza_config IN tkr_traza_config%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_config
           SET ROW = pro_tkr_traza_config;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_traza_config IN OUT tkr_traza_config%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_traza_config.id%TYPE,
        p_json_tkr_traza_config OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_traza_config
          FROM tkr_traza_config t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_traza_config := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_traza_config.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_traza_config t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_traza_config;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_traza_config
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TRAZA_CONFIG_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TRAZA_EJECUCION_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TRAZA_EJECUCION_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TRAZA_EJECUCION_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_traza_ejecucion
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_traza_ejecucion IS TABLE OF tkr_traza_ejecucion%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_traza_ejecucion.id%TYPE
    ) RETURN tkr_traza_ejecucion%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_traza_ejecucion OUT PKGTKR_TRAZA_EJECUCION_DAO.ta_tkr_traza_ejecucion
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_traza_ejecucion.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_traza_ejecucion.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_ejecucion.id%TYPE,
        pro_tkr_traza_ejecucion OUT tkr_traza_ejecucion%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_ejecucion.id%TYPE,
        pro_tkr_traza_ejecucion OUT tkr_traza_ejecucion%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_traza_ejecucion OUT tkr_traza_ejecucion%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE,
        pty_id         IN tkr_traza_ejecucion.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_traza_ejecucion IN OUT tkr_traza_ejecucion%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_traza_ejecucion.id%TYPE,
        p_json_tkr_traza_ejecucion OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_traza_ejecucion.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TRAZA_EJECUCION_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TRAZA_EJECUCION_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TRAZA_EJECUCION_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE
    ) IS
        vro_tkr_traza_ejecucion tkr_traza_ejecucion%ROWTYPE := pro_tkr_traza_ejecucion;
    BEGIN
        INSERT INTO tkr_traza_ejecucion VALUES vro_tkr_traza_ejecucion;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_traza_ejecucion.id%TYPE
    ) RETURN tkr_traza_ejecucion%ROWTYPE IS
        vro_tkr_traza_ejecucion tkr_traza_ejecucion%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_traza_ejecucion
          FROM tkr_traza_ejecucion
         WHERE id = pty_id;
        RETURN vro_tkr_traza_ejecucion;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_traza_ejecucion OUT PKGTKR_TRAZA_EJECUCION_DAO.ta_tkr_traza_ejecucion
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_traza_ejecucion
          FROM tkr_traza_ejecucion;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_traza_ejecucion
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_traza_ejecucion.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_traza_ejecucion
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_traza_ejecucion;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_traza_ejecucion.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_traza_ejecucion
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_ejecucion.id%TYPE,
        pro_tkr_traza_ejecucion OUT tkr_traza_ejecucion%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_traza_ejecucion
          FROM tkr_traza_ejecucion
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_ejecucion.id%TYPE,
        pro_tkr_traza_ejecucion OUT tkr_traza_ejecucion%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_traza_ejecucion
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_traza_ejecucion
          FROM tkr_traza_ejecucion
         WHERE ROWID = p_rowid;

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
          FROM tkr_traza_ejecucion
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_traza_ejecucion OUT tkr_traza_ejecucion%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_traza_ejecucion
          FROM tkr_traza_ejecucion
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_ejecucion
           SET ROW = pro_tkr_traza_ejecucion
         WHERE id = pro_tkr_traza_ejecucion.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE,
        pty_id         IN tkr_traza_ejecucion.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_ejecucion
           SET ROW = pro_tkr_traza_ejecucion
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_traza_ejecucion
           SET ROW = pro_tkr_traza_ejecucion
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_traza_ejecucion IN tkr_traza_ejecucion%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_ejecucion
           SET ROW = pro_tkr_traza_ejecucion;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_traza_ejecucion IN OUT tkr_traza_ejecucion%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_traza_ejecucion.id%TYPE,
        p_json_tkr_traza_ejecucion OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_traza_ejecucion
          FROM tkr_traza_ejecucion t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_traza_ejecucion := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_traza_ejecucion.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_traza_ejecucion t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_traza_ejecucion;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_traza_ejecucion
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TRAZA_EJECUCION_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TRAZA_LLAMADO_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TRAZA_LLAMADO_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TRAZA_LLAMADO_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_traza_llamado
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_traza_llamado IS TABLE OF tkr_traza_llamado%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_traza_llamado.id%TYPE
    ) RETURN tkr_traza_llamado%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_traza_llamado OUT PKGTKR_TRAZA_LLAMADO_DAO.ta_tkr_traza_llamado
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_traza_llamado.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_traza_llamado.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_llamado.id%TYPE,
        pro_tkr_traza_llamado OUT tkr_traza_llamado%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_llamado.id%TYPE,
        pro_tkr_traza_llamado OUT tkr_traza_llamado%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_traza_llamado OUT tkr_traza_llamado%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE,
        pty_id         IN tkr_traza_llamado.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_traza_llamado IN OUT tkr_traza_llamado%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_traza_llamado.id%TYPE,
        p_json_tkr_traza_llamado OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_traza_llamado.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TRAZA_LLAMADO_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TRAZA_LLAMADO_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TRAZA_LLAMADO_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE
    ) IS
        vro_tkr_traza_llamado tkr_traza_llamado%ROWTYPE := pro_tkr_traza_llamado;
    BEGIN
        INSERT INTO tkr_traza_llamado VALUES vro_tkr_traza_llamado;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_traza_llamado.id%TYPE
    ) RETURN tkr_traza_llamado%ROWTYPE IS
        vro_tkr_traza_llamado tkr_traza_llamado%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_traza_llamado
          FROM tkr_traza_llamado
         WHERE id = pty_id;
        RETURN vro_tkr_traza_llamado;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_traza_llamado OUT PKGTKR_TRAZA_LLAMADO_DAO.ta_tkr_traza_llamado
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_traza_llamado
          FROM tkr_traza_llamado;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_traza_llamado
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_traza_llamado.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_traza_llamado
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_traza_llamado;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_traza_llamado.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_traza_llamado
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_llamado.id%TYPE,
        pro_tkr_traza_llamado OUT tkr_traza_llamado%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_traza_llamado
          FROM tkr_traza_llamado
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_llamado.id%TYPE,
        pro_tkr_traza_llamado OUT tkr_traza_llamado%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_traza_llamado
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_traza_llamado
          FROM tkr_traza_llamado
         WHERE ROWID = p_rowid;

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
          FROM tkr_traza_llamado
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_traza_llamado OUT tkr_traza_llamado%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_traza_llamado
          FROM tkr_traza_llamado
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_llamado
           SET ROW = pro_tkr_traza_llamado
         WHERE id = pro_tkr_traza_llamado.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE,
        pty_id         IN tkr_traza_llamado.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_llamado
           SET ROW = pro_tkr_traza_llamado
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_traza_llamado
           SET ROW = pro_tkr_traza_llamado
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_traza_llamado IN tkr_traza_llamado%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_llamado
           SET ROW = pro_tkr_traza_llamado;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_traza_llamado IN OUT tkr_traza_llamado%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_traza_llamado.id%TYPE,
        p_json_tkr_traza_llamado OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_traza_llamado
          FROM tkr_traza_llamado t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_traza_llamado := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_traza_llamado.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_traza_llamado t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_traza_llamado;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_traza_llamado
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TRAZA_LLAMADO_DAO;
/

-- =====================================================================
-- ESPECIFICACIÓN: PKGTKR_TRAZA_ESTADISTICA_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKGTKR_TRAZA_ESTADISTICA_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGTKR_TRAZA_ESTADISTICA_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla tkr_traza_estadistica
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Colección estándar de registros
    TYPE ta_tkr_traza_estadistica IS TABLE OF tkr_traza_estadistica%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_traza_estadistica.id%TYPE
    ) RETURN tkr_traza_estadistica%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_traza_estadistica OUT PKGTKR_TRAZA_ESTADISTICA_DAO.ta_tkr_traza_estadistica
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_traza_estadistica.id%TYPE
    );

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_traza_estadistica.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_estadistica.id%TYPE,
        pro_tkr_traza_estadistica OUT tkr_traza_estadistica%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_estadistica.id%TYPE,
        pro_tkr_traza_estadistica OUT tkr_traza_estadistica%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_traza_estadistica OUT tkr_traza_estadistica%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE,
        pty_id         IN tkr_traza_estadistica.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_traza_estadistica IN OUT tkr_traza_estadistica%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_traza_estadistica.id%TYPE,
        p_json_tkr_traza_estadistica OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_traza_estadistica.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB;

END PKGTKR_TRAZA_ESTADISTICA_DAO;
/

-- =====================================================================
-- CUERPO: PKGTKR_TRAZA_ESTADISTICA_DAO
-- =====================================================================
CREATE OR REPLACE PACKAGE BODY PKGTKR_TRAZA_ESTADISTICA_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE
    ) IS
        vro_tkr_traza_estadistica tkr_traza_estadistica%ROWTYPE := pro_tkr_traza_estadistica;
    BEGIN
        INSERT INTO tkr_traza_estadistica VALUES vro_tkr_traza_estadistica;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_traza_estadistica.id%TYPE
    ) RETURN tkr_traza_estadistica%ROWTYPE IS
        vro_tkr_traza_estadistica tkr_traza_estadistica%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_tkr_traza_estadistica
          FROM tkr_traza_estadistica
         WHERE id = pty_id;
        RETURN vro_tkr_traza_estadistica;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_traza_estadistica OUT PKGTKR_TRAZA_ESTADISTICA_DAO.ta_tkr_traza_estadistica
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_tkr_traza_estadistica
          FROM tkr_traza_estadistica;
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM tkr_traza_estadistica
         WHERE ROWID = p_rowid;
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_traza_estadistica.id%TYPE
    ) IS
    BEGIN
        DELETE FROM tkr_traza_estadistica
         WHERE id = pty_id;
    END p_eliminar;

    -- 6. Eliminar todos los registros
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM tkr_traza_estadistica;
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_traza_estadistica.id%TYPE
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM tkr_traza_estadistica
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_estadistica.id%TYPE,
        pro_tkr_traza_estadistica OUT tkr_traza_estadistica%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_traza_estadistica
          FROM tkr_traza_estadistica
         WHERE id = pty_id;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID (Solución a PLS-00494)
    FUNCTION f_existe (
        pty_id         IN  tkr_traza_estadistica.id%TYPE,
        pro_tkr_traza_estadistica OUT tkr_traza_estadistica%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT ROWID
          INTO p_rowid
          FROM tkr_traza_estadistica
         WHERE id = pty_id;

        SELECT *
          INTO pro_tkr_traza_estadistica
          FROM tkr_traza_estadistica
         WHERE ROWID = p_rowid;

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
          FROM tkr_traza_estadistica
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_tkr_traza_estadistica OUT tkr_traza_estadistica%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_tkr_traza_estadistica
          FROM tkr_traza_estadistica
         WHERE ROWID = p_rowid;
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_estadistica
           SET ROW = pro_tkr_traza_estadistica
         WHERE id = pro_tkr_traza_estadistica.id;
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE,
        pty_id         IN tkr_traza_estadistica.id%TYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_estadistica
           SET ROW = pro_tkr_traza_estadistica
         WHERE id = pty_id;
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE,
        p_rowid        IN VARCHAR2
    ) IS
    BEGIN
        UPDATE tkr_traza_estadistica
           SET ROW = pro_tkr_traza_estadistica
         WHERE ROWID = p_rowid;
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros
    PROCEDURE p_actualizar_registros (
        pro_tkr_traza_estadistica IN tkr_traza_estadistica%ROWTYPE
    ) IS
    BEGIN
        UPDATE tkr_traza_estadistica
           SET ROW = pro_tkr_traza_estadistica;
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_traza_estadistica IN OUT tkr_traza_estadistica%ROWTYPE
    ) IS
    BEGIN
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id          IN  tkr_traza_estadistica.id%TYPE,
        p_json_tkr_traza_estadistica OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_tkr_traza_estadistica
          FROM tkr_traza_estadistica t
         WHERE t.id = p_id;
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_tkr_traza_estadistica := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK
    FUNCTION f_json (
        p_id IN tkr_traza_estadistica.id%TYPE
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM tkr_traza_estadistica t
         WHERE t.id = p_id;
        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Calcular total de páginas
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER IS
        v_registros_por_pagina NUMBER;
        v_total_registros      NUMBER;
    BEGIN
        v_registros_por_pagina := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros')), 10);
        IF v_registros_por_pagina <= 0 THEN
            v_registros_por_pagina := 10;
        END IF;

        SELECT COUNT(1)
          INTO v_total_registros
          FROM tkr_traza_estadistica;

        RETURN CEIL(v_total_registros / v_registros_por_pagina);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END f_total_paginas;

    -- 20. Consultar registros paginados retornando JSON
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER
    ) RETURN CLOB IS
        v_offset NUMBER;
        v_limite NUMBER;
        v_json   CLOB;
    BEGIN
        v_limite := NVL(p_registros, 10);
        IF v_limite <= 0 THEN
            v_limite := 10;
        END IF;

        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * v_limite;

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
                FROM tkr_traza_estadistica
               ORDER BY id ASC
              OFFSET v_offset ROWS
               FETCH NEXT v_limite ROWS ONLY
          ) t;

        RETURN v_json;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN TO_CLOB('[]');
    END f_consultar_paginado;

END PKGTKR_TRAZA_ESTADISTICA_DAO;
/
