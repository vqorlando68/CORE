CREATE OR REPLACE PACKAGE PKGCORE_ERROR_DAO
AS
    /*
    || =========================================================================
    || Paquete   : PKGCORE_ERROR_DAO
    || Propósito : Capa de acceso a datos exclusiva para la tabla core_error
    || Estándar  : Plantilla oficial DAO PL/SQL Oracle (20 Métodos Estándar)
    || Seguridad : Aislamiento Multi-Tenant (Enfoque B en toda sentencia DML)
    ||             Resuelve con SYS_CONTEXT('CORE_CTX', 'ID_TENANT')
    || Reglas    : Prohibido ejecutar COMMIT o ROLLBACK dentro de este paquete.
    ||             Consultas relacionales con sintaxis tradicional Oracle.
    || =========================================================================
    */

    -- Tipo de colección estándar para registros de la tabla
    TYPE ta_core_error IS TABLE OF core_error%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_core_error IN core_error%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id        IN core_error.id%TYPE,
        pty_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    ) RETURN core_error%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        p_id_tenant   IN  core_error.id_tenant%TYPE DEFAULT NULL,
        pta_core_error OUT pkgcore_error_dao.ta_core_error
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id        IN core_error.id%TYPE,
        pty_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    );

    -- 6. Eliminar todos los registros (Uso restringido al tenant)
    PROCEDURE p_eliminar_registros (
        p_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    );

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id        IN core_error.id%TYPE,
        pty_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id         IN  core_error.id%TYPE,
        pty_id_tenant  IN  core_error.id_tenant%TYPE DEFAULT NULL,
        pro_core_error OUT core_error%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id         IN  core_error.id%TYPE,
        pty_id_tenant  IN  core_error.id_tenant%TYPE DEFAULT NULL,
        pro_core_error OUT core_error%ROWTYPE,
        p_rowid        OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid        IN  VARCHAR2,
        pro_core_error OUT core_error%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_core_error IN core_error%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_core_error IN core_error%ROWTYPE,
        pty_id         IN core_error.id%TYPE,
        pty_id_tenant  IN core_error.id_tenant%TYPE DEFAULT NULL
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_core_error IN core_error%ROWTYPE,
        p_rowid        IN VARCHAR2
    );

    -- 15. Actualizar todos los registros (Uso restringido al tenant)
    PROCEDURE p_actualizar_registros (
        pro_core_error IN core_error%ROWTYPE,
        p_id_tenant    IN core_error.id_tenant%TYPE DEFAULT NULL
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_core_error IN OUT core_error%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id              IN  core_error.id%TYPE,
        p_id_tenant       IN  core_error.id_tenant%TYPE DEFAULT NULL,
        p_json_core_error OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK (VARCHAR2 o CLOB según tamaño)
    FUNCTION f_json (
        p_id        IN core_error.id%TYPE,
        p_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación recibiendo JSON con campo "registros"
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON con información correspondiente
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER,
        p_id_tenant IN core_error.id_tenant%TYPE DEFAULT NULL
    ) RETURN CLOB;

END PKGCORE_ERROR_DAO;
/
