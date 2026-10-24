---
name: oracle-plsql-architecture
description: >-
  Estándar arquitectónico obligatorio de PL/SQL para Oracle. Debe activarse SIEMPRE que se solicite crear, modificar, revisar, optimizar, refactorizar o proponer código PL/SQL, paquetes Oracle, procedimientos, funciones, consultas, APIs PL/SQL, generación de JSON o manejo transaccional. Aplica la estricta separación de responsabilidades entre paquetes DAO (pkg<tabla>_dao), pkgca_ (acceso/DML no-PK mono-tabla exclusivo), pkgcn_ (operaciones multi-tabla: DML, consultas relacionales tradicionales y JSON_TABLE), pkgln_ (orquestadores de negocio transaccionales con control atómico y política Cero RAISE_APPLICATION_ERROR retornando p_json_salida estructurado) y uti_ (utilitarios transversales agnósticos al negocio), documentación de flujo en <paquete>.md y core_documentacion_metodo, control atómico de transacciones, logging persistente en core_error con uti_ge_excepciones_pkg.p_grabar_log, SYS_REFCURSOR y JSON nativo.
---

# Estándar Arquitectónico PL/SQL para Oracle

## 1. Misión y Carácter Obligatorio

Este skill define el **estándar arquitectónico oficial e innegociable** para cualquier desarrollo, modificación, refactorización, optimización o revisión de código PL/SQL en Oracle.

> [!IMPORTANT]
> Este documento **no es solo una guía de estilo**, sino una **regla arquitectónica vinculante**.
> Antes de generar cualquier línea de código PL/SQL, se DEBE clasificar la responsabilidad de la operación y ubicarla en la familia de paquete correspondiente. Queda estrictamente prohibido mezclar responsabilidades entre paquetes.

---

## 2. Clasificación Obligatoria de Familias de Paquetes

Todo artefacto PL/SQL pertenece obligatoriamente a una de estas cinco familias:

| Familia | Prefijo / Sufijo | Propósito Principal | DML Directo Tabla | Transacciones (p_do_commit / ROLLBACK) | Manejo de Excepciones |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DAO** | `pkg<tabla>_dao` | Acceso a datos de UNA tabla específica por PK / ROWID (CRUD básico y plantilla oficial de 20 métodos). | Sí (su tabla exclusiva) | **PROHIBIDO** (COMMIT/ROLLBACK arbitrario prohibido, propaga errores) | Propagación hacia capas superiores |
| **pkgca_** | `pkgca_<nombre_tabla>` | **Acceso y DML No-PK sobre UNA SOLA TABLA física** (filtros no-PK, rangos, estados, búsquedas mono-tabla `SYS_REFCURSOR`, updates/deletes batch mono-tabla). **PROHIBIDO INVOLUCRAR MÁS DE UNA TABLA**. | Sí (exclusivamente su tabla asignada) | **PROHIBIDO** salvo proceso batch explícito aislado | Propagación o log si es batch |
| **pkgcn_** | `pkgcn_<negocio>` | **Operaciones y Consultas Multi-Tabla**: Sentencias DML que involucran más de una tabla, consultas complejas con joins (sintaxis tradicional `(+)`) entre múltiples tablas, o procesos para descomponer/extraer valores de un JSON mediante `JSON_TABLE`. | Sí (múltiples tablas del proceso de negocio) | **PROHIBIDO** (Delegado al orquestador `pkgln_`) | Propagación o control puntual |
| **pkgln_** | `pkgln_<dominio>` | **Orquestadores de Negocio Transaccionales** expuestos al Frontend/API (`p_json_entrada` / `p_json_salida`). Verificación previa obligatoria de trazabilidad en `core_traza_config`. Coordinan lógica de dominio, invocan `pkgcn_`, DAOs y utilitarios. Generan archivo de flujo `<nombre_paquete>.md`. | A través de `pkgcn_` / DAOs | **OBLIGATORIO** (Control atómico: `p_do_commit('<paquete>.<metodo>')` al éxito, `ROLLBACK;` al fallo) | Bloque `WHEN OTHERS` con `ROLLBACK;`, log en `core_error` y retorno estructurado en `p_json_salida` (`codigo`/`error`, `mensaje` e `id_error`). **PROHIBIDO RAISE_APPLICATION_ERROR**. |
| **uti_** | `uti_<tema>_pkg` | **Utilitarios Generales y Transversales** agnósticos al negocio (manejo de archivos BLOB/CLOB/SO, validación de tipos de datos, formateo, utilidades del sistema como telemetría `uti_manejo_trazas_pkg` o excepciones `uti_ge_excepciones_pkg`). | No aplica (o tablas técnicas de logging/soporte) | **PROHIBIDO** (Servicios puros o autónomos, sin control transaccional de negocio) | Manejo interno o propagación limpia |

---

## 3. Árbol de Decisión Arquitectónico Obligatorio

Antes de escribir cualquier procedimiento o función, aplicar estrictamente este árbol de decisión:

```text
¿Cuál es la responsabilidad principal de la operación?
│
├── ¿Es una funcionalidad utilitaria general agnóstica al negocio
│   (manejo de archivos, validación genérica de tipos de datos, criptografía, formateo)?
│   │
│   └── SÍ ──────────────────────────────────────────────────────────► Pertenece a: uti_<tema>_pkg
│                                                                     (Utilitarios transversales,
│                                                                      cero lógica de negocio,
│                                                                      sin p_do_commit ni transacciones)
│
├── ¿Es una operación orquestadora de negocio expuesta hacia el Frontend o API Gateway
│   que recibe p_json_entrada, retorna p_json_salida, coordina el flujo y controla la transacción?
│   │
│   └── SÍ ──────────────────────────────────────────────────────────► Pertenece a: pkgln_
│                                                                     (Orquestador transaccional,
│                                                                      firma p_json_entrada/salida,
│                                                                      invoca p_do_commit, genera <paquete>.md)
│
├── ¿Involucra MÁS DE UNA TABLA (consultas con JOINs tradicional (+), DML multi-tabla)
│   o desestructura/procesa un JSON usando JSON_TABLE para devolver valores?
│   │
│   └── SÍ ──────────────────────────────────────────────────────────► Pertenece a: pkgcn_
│                                                                     (Multi-tabla: Joins relacionales,
│                                                                      DML multi-tabla, JSON_TABLE)
│
├── ¿Es una consulta o sentencia DML (filtro por rango/estado, delete batch, búsqueda)
│   que afecta EXCLUSIVAMENTE a UNA SOLA TABLA física sin depender solo de la PK?
│   │
│   └── SÍ ──────────────────────────────────────────────────────────► Pertenece a: pkgca_
│                                                                     (Estrictamente mono-tabla:
│                                                                      pkgca_<nombre_tabla>, jamás multi-tabla)
│
└── ¿Es una operación CRUD directa sobre una única tabla física identificando por PK o ROWID?
    │
    └── SÍ ──────────────────────────────────────────────────────────► Pertenece a: pkg<tabla>_dao
                                                                      (Plantilla estándar oficial de 20 métodos)
```

> [!NOTE]
> Si existe duda entre dos categorías, se debe explicar brevemente la justificación antes de generar el código. Si una petición ubica código en el paquete incorrecto, se debe advertir la infracción y reubicarlo.

---

## 4. Paquetes DAO (`pkg<tabla>_dao`)

### 4.1 Convención de Nomenclatura
El nombre del paquete DAO debe formarse **exactamente** con la fórmula:
$$\text{pkg} + \text{nombre\_tabla} + \text{\_dao}$$

*Ejemplos:*
- Tabla: `core_usuario` $\rightarrow$ Paquete: `PKGCORE_USUARIO_DAO`
- Tabla: `core_rol` $\rightarrow$ Paquete: `PKGCORE_ROL_DAO`
- Tabla: `core_proceso` $\rightarrow$ Paquete: `PKGCORE_PROCESO_DAO`

*(Nunca omitir el prefijo `PKG` inicial; no usar nombres como `CORE_USUARIOS_DAO`).*

> [!IMPORTANT]
> **Regla de Singularidad de Tablas:** Todas las tablas de la plataforma se definen estrictamente en **singular** (ej. `core_usuario`, `core_rol`, `core_permiso`, `core_proceso`, `core_archivo`, `core_notificacion`, `core_error`, `core_sesion_activa`), prohibiéndose el uso de nombres en plural. En consecuencia, su paquete DAO adopta dicha singularidad 1:1: `PKGCORE_USUARIO_DAO`, `PKGCORE_ROL_DAO`, `PKGCORE_PROCESO_DAO`, etc.

### 4.2 Métodos de la Plantilla Oficial DAO
Todo DAO debe implementar los siguientes 20 métodos estándar adaptados a la tabla correspondiente:

```sql
CREATE OR REPLACE PACKAGE PKGCORE_<TABLA>_DAO
AS
    -- Tipo colección para consultas generales
    TYPE ta_core_<tabla> IS TABLE OF core_<tabla>%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE
    );

    -- 2. Traer un registro por PK
    FUNCTION f_traer (
        pty_id      IN core_<tabla>.id%TYPE,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN core_<tabla>%ROWTYPE;

    -- 3. Traer todos los registros
    PROCEDURE p_consultar_registros (
        pta_core_<tabla> OUT PKGCORE_<TABLA>_DAO.ta_core_<tabla>,
        p_id_tenant      IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL
    );

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id      IN core_<tabla>.id%TYPE,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    );

    -- 6. Eliminar todos los registros (Enfoque B: acotado al tenant activo)
    PROCEDURE p_eliminar_registros (
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    );

    -- 7. Existe por PK (Simple)
    FUNCTION f_existe (
        pty_id      IN core_<tabla>.id%TYPE,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    -- 8. Existe por PK retornando %ROWTYPE
    FUNCTION f_existe (
        pty_id           IN  core_<tabla>.id%TYPE,
        pro_core_<tabla> OUT core_<tabla>%ROWTYPE,
        p_id_tenant      IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    -- 9. Existe por PK retornando %ROWTYPE y ROWID
    FUNCTION f_existe (
        pty_id           IN  core_<tabla>.id%TYPE,
        pro_core_<tabla> OUT core_<tabla>%ROWTYPE,
        p_rowid          OUT VARCHAR2,
        p_id_tenant      IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    -- 10. Existe por ROWID (Simple)
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN NUMBER;

    -- 11. Existe por ROWID retornando %ROWTYPE
    FUNCTION f_existe_rowid (
        p_rowid          IN  VARCHAR2,
        pro_core_<tabla> OUT core_<tabla>%ROWTYPE
    ) RETURN NUMBER;

    -- 12. Actualizar registro completo por PK (%ROWTYPE)
    PROCEDURE p_actualizar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        pty_id_tenant    IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    );

    -- 13. Actualizar registro completo por PK explícito
    PROCEDURE p_actualizar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        pty_id           IN core_<tabla>.id%TYPE,
        pty_id_tenant    IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    );

    -- 14. Actualizar registro completo por ROWID
    PROCEDURE p_actualizar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        p_rowid          IN VARCHAR2
    );

    -- 15. Actualizar todos los registros (Enfoque B: acotado al tenant activo)
    PROCEDURE p_actualizar_registros (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        p_id_tenant      IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    );

    -- 16. Asignar valores por defecto (IN OUT %ROWTYPE)
    PROCEDURE p_valores_defecto (
        pro_core_<tabla> IN OUT core_<tabla>%ROWTYPE
    );

    -- 17. Validar existencia y retornar JSON de la fila por PK
    FUNCTION f_existe_json (
        p_id                IN  core_<tabla>.id%TYPE,
        p_id_tenant         IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL,
        p_json_core_<tabla> OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON nativo de la fila por PK
    FUNCTION f_json (
        p_id        IN core_<tabla>.id%TYPE,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN CLOB;

    -- 19. Total de páginas para paginación de la tabla
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consulta paginada (SYS_REFCURSOR)
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN SYS_REFCURSOR;

END PKGCORE_<TABLA>_DAO;
/
```

### 4.3 Implementación Universal del Body DAO (Plantilla Oficial)
```sql
CREATE OR REPLACE PACKAGE BODY PKGCORE_<TABLA>_DAO
AS
    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE
    )
    IS
        vro_registro core_<tabla>%ROWTYPE := pro_core_<tabla>;
    BEGIN
        IF vro_registro.id_tenant IS NULL THEN
            vro_registro.id_tenant := TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        END IF;

        INSERT INTO core_<tabla>
        VALUES vro_registro;
    END p_insertar;

    -- 2. Traer un registro por PK
    FUNCTION f_traer (
        pty_id      IN core_<tabla>.id%TYPE,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN core_<tabla>%ROWTYPE
    IS
        vro_core_<tabla> core_<tabla>%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_core_<tabla>
          FROM core_<tabla>
         WHERE id = pty_id
           AND id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));

        RETURN vro_core_<tabla>;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Traer todos los registros
    PROCEDURE p_consultar_registros (
        pta_core_<tabla> OUT PKGCORE_<TABLA>_DAO.ta_core_<tabla>,
        p_id_tenant      IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL
    )
    IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_core_<tabla>
          FROM core_<tabla>
         WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_consultar_registros;

    -- 4. Eliminar por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    )
    IS
    BEGIN
        DELETE FROM core_<tabla>
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_eliminar_rowid;

    -- 5. Eliminar por PK
    PROCEDURE p_eliminar (
        pty_id      IN core_<tabla>.id%TYPE,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    )
    IS
    BEGIN
        DELETE FROM core_<tabla>
         WHERE id = pty_id
           AND id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_eliminar;

    -- 6. Eliminar todos los registros (Enfoque B: acotado al tenant activo)
    PROCEDURE p_eliminar_registros (
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    )
    IS
    BEGIN
        DELETE FROM core_<tabla>
         WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_eliminar_registros;

    -- 7. Existe por PK (Simple)
    FUNCTION f_existe (
        pty_id      IN core_<tabla>.id%TYPE,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_dummy NUMBER := 0;
    BEGIN
        SELECT 1
          INTO v_dummy
          FROM core_<tabla>
         WHERE id = pty_id
           AND id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));

        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END f_existe;

    -- 8. Existe por PK retornando %ROWTYPE
    FUNCTION f_existe (
        pty_id           IN  core_<tabla>.id%TYPE,
        pro_core_<tabla> OUT core_<tabla>%ROWTYPE,
        p_id_tenant      IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN NUMBER
    IS
    BEGIN
        pro_core_<tabla> := f_traer(pty_id, p_id_tenant);
        IF pro_core_<tabla>.id IS NOT NULL THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    END f_existe;

    -- 9. Existe por PK retornando %ROWTYPE y ROWID (Solución optimizada ORA-03056 / PLS-00494)
    FUNCTION f_existe (
        pty_id           IN  core_<tabla>.id%TYPE,
        pro_core_<tabla> OUT core_<tabla>%ROWTYPE,
        p_rowid          OUT VARCHAR2,
        p_id_tenant      IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN NUMBER
    IS
        v_rowid_interno ROWID;
    BEGIN
        SELECT ROWID
          INTO v_rowid_interno
          FROM core_<tabla>
         WHERE id = pty_id
           AND id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));

        p_rowid := ROWIDTOCHAR(v_rowid_interno);

        SELECT *
          INTO pro_core_<tabla>
          FROM core_<tabla>
         WHERE ROWID = v_rowid_interno;

        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pro_core_<tabla> := NULL;
            p_rowid          := NULL;
            RETURN 0;
    END f_existe;

    -- 10. Existe por ROWID (Simple)
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_dummy NUMBER := 0;
    BEGIN
        SELECT 1
          INTO v_dummy
          FROM core_<tabla>
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));

        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
    END f_existe_rowid;

    -- 11. Existe por ROWID retornando %ROWTYPE
    FUNCTION f_existe_rowid (
        p_rowid          IN  VARCHAR2,
        pro_core_<tabla> OUT core_<tabla>%ROWTYPE
    ) RETURN NUMBER
    IS
    BEGIN
        SELECT *
          INTO pro_core_<tabla>
          FROM core_<tabla>
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));

        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pro_core_<tabla> := NULL;
            RETURN 0;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK (%ROWTYPE)
    PROCEDURE p_actualizar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        pty_id_tenant    IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    )
    IS
    BEGIN
        UPDATE core_<tabla>
           SET ROW = pro_core_<tabla>
         WHERE id = pro_core_<tabla>.id
           AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_actualizar;

    -- 13. Actualizar registro completo por PK explícito
    PROCEDURE p_actualizar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        pty_id           IN core_<tabla>.id%TYPE,
        pty_id_tenant    IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    )
    IS
    BEGIN
        UPDATE core_<tabla>
           SET ROW = pro_core_<tabla>
         WHERE id = pty_id
           AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_actualizar;

    -- 14. Actualizar registro completo por ROWID
    PROCEDURE p_actualizar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        p_rowid          IN VARCHAR2
    )
    IS
    BEGIN
        UPDATE core_<tabla>
           SET ROW = pro_core_<tabla>
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_actualizar;

    -- 15. Actualizar todos los registros (Enfoque B: acotado al tenant activo)
    PROCEDURE p_actualizar_registros (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        p_id_tenant      IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    )
    IS
    BEGIN
        UPDATE core_<tabla>
           SET ROW = pro_core_<tabla>
         WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_actualizar_registros;

    -- 16. Asignar valores por defecto (IN OUT %ROWTYPE)
    PROCEDURE p_valores_defecto (
        pro_core_<tabla> IN OUT core_<tabla>%ROWTYPE
    )
    IS
    BEGIN
        pro_core_<tabla>.id_tenant       := TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        pro_core_<tabla>.estado_registro := NVL(pro_core_<tabla>.estado_registro, 1);
    END p_valores_defecto;

    -- 17. Validar existencia y retornar JSON de la fila por PK
    FUNCTION f_existe_json (
        p_id                IN  core_<tabla>.id%TYPE,
        p_id_tenant         IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL,
        p_json_core_<tabla> OUT CLOB
    ) RETURN NUMBER
    IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_core_<tabla>
          FROM core_<tabla> t
         WHERE t.id = p_id
           AND t.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));

        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_core_<tabla> := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON nativo de la fila por PK
    FUNCTION f_json (
        p_id        IN core_<tabla>.id%TYPE,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN CLOB
    IS
        v_json CLOB;
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO v_json
          FROM core_<tabla> t
         WHERE t.id = p_id
           AND t.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));

        RETURN v_json;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_json;

    -- 19. Total de páginas para paginación de la tabla
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER
    IS
        v_registros_pagina     NUMBER;
        v_total_registros      NUMBER := 0;
        v_id_tenant            NUMBER;
    BEGIN
        v_registros_pagina := TO_NUMBER(JSON_VALUE(p_json_entrada, '$.registros_pagina'));
        v_id_tenant        := NVL(TO_NUMBER(JSON_VALUE(p_json_entrada, '$.id_tenant')), TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));

        IF v_registros_pagina IS NULL OR v_registros_pagina <= 0 THEN
            v_registros_pagina := 10;
        END IF;

        SELECT COUNT(*)
          INTO v_total_registros
          FROM core_<tabla>
         WHERE id_tenant = v_id_tenant;

        RETURN CEIL(v_total_registros / v_registros_pagina);
    END f_total_paginas;

    -- 20. Consulta paginada (SYS_REFCURSOR)
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN SYS_REFCURSOR
    IS
        v_cursor  SYS_REFCURSOR;
        v_offset  NUMBER;
        v_tenant  NUMBER;
    BEGIN
        v_tenant := NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        v_offset := (GREATEST(NVL(p_pagina, 1), 1) - 1) * GREATEST(NVL(p_registros, 10), 1);

        OPEN v_cursor FOR
            SELECT *
              FROM (
                    SELECT t.*,
                           ROW_NUMBER() OVER (ORDER BY t.id) AS rn
                      FROM core_<tabla> t
                     WHERE t.id_tenant = v_tenant
                   )
             WHERE rn > v_offset
               AND rn <= v_offset + GREATEST(NVL(p_registros, 10), 1);

        RETURN v_cursor;
    END f_consultar_paginado;

END PKGCORE_<TABLA>_DAO;
/
```

### 4.4 Reglas Específicas para DAO
1. **Un DAO por tabla física**: No crear DAOs compartidos para múltiples tablas.
2. **Tipado fuerte**: Usar siempre `%ROWTYPE` para registros y `<tabla>.<columna>%TYPE` para parámetros escalares.
3. **Cero Lógica de Negocio**: No incluir validaciones de reglas de dominio ni cálculos empresariales en el DAO.
4. **Cero Orquestación Multi-tabla**: El DAO jamás consulta ni actualiza tablas ajenas a la suya.
5. **Cero COMMIT / ROLLBACK**: El DAO nunca controla la transacción. Los errores deben propagarse limpiamente al nivel superior (`pkgcn_`).
6. **Aislamiento Multi-Tenant (Enfoque B en toda sentencia DML)**: En tablas multi-tenant, el código PL/SQL aplica obligatoriamente defensa en profundidad con `SYS_CONTEXT('CORE_CTX', 'ID_TENANT')`:
   - **SELECT / UPDATE / DELETE**: En toda cláusula WHERE se incluye `AND id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')))`.
   - **INSERT**: En `p_insertar`, si `id_tenant` es NULL, se asigna `TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'))`.
   - **Parámetro Formal**: `p_id_tenant IN <tabla>.id_tenant%TYPE DEFAULT NULL` en todos los métodos pertinentes.
7. **Aplicación Universal del Body**: La plantilla oficial del cuerpo DAO (20 métodos de la Sección 4.3) es vinculante y obligatoria para cualquier tabla de la plataforma.

---

## 5. Paquetes de Acceso y DML No-PK Mono-Tabla (`pkgca_<nombre_tabla>`)

- **Propósito**: Encapsular operaciones de consulta y DML masivo o no-PK que **afectan exclusivamente a una sola tabla física**, tales como filtros dinámicos, búsquedas por rangos o estados, inactivaciones masivas o borrados batch de esa entidad.
- **Nomenclatura**: Debe nombrarse obligatoriamente con el nombre exacto de la tabla física en singular:
  $$\text{pkgca\_} + \text{nombre\_tabla}$$
  *(Ejemplos: `pkgca_core_horario_profesional`, `pkgca_core_ausencia_profesional`, `pkgca_core_usuario`).*

> [!IMPORTANT]
> **Prohibición Total de Multi-Tabla en `pkgca_`**: La capa `pkgca_` solo y exclusivamente realiza operaciones sobre **UNA SOLA TABLA FÍSICA**.
> - Queda **terminantemente prohibido** realizar `JOINs`, relacionar tablas secundarias o tocar más de una tabla dentro de un paquete `pkgca_`.
> - Si una consulta, reporte o proceso DML involucra **MÁS DE UNA TABLA**, **NO PERTENECE A `pkgca_`**, sino que debe ubicarse obligatoriamente en la capa **`pkgcn_<negocio>`**.
> - Por esta regla, nombres genéricos de negocio como `pkgca_horarios_profesional` no deben existir si no representan una tabla física o si integran múltiples tablas (deben llamarse `pkgca_<nombre_tabla>` para la tabla física específica, y la lógica multi-tabla debe residir en `pkgcn_<negocio>`).

- **Retorno de Conjuntos Multi-fila Mono-Tabla**: Si retorna múltiples registros de esa tabla, debe usar `SYS_REFCURSOR`.
- **Enfoque B en Sentencias DML**: En entidades multi-tenant, todos los métodos deben aceptar `p_id_tenant IN <tabla>.id_tenant%TYPE DEFAULT NULL`, filtrando en sus consultas DML con `WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')))`.
- **Transacciones**: PROHIBIDO ejecutar `p_do_commit` o `ROLLBACK`.

*Ejemplo Mono-Tabla:*
```sql
CREATE OR REPLACE PACKAGE pkgca_core_horario_profesional AS
    -- DML mono-tabla sobre core_horario_profesional
    PROCEDURE p_borrar_x_profesional (
        p_id_usuario IN core_horario_profesional.id_usuario%TYPE,
        p_id_tenant  IN core_horario_profesional.id_tenant%TYPE DEFAULT NULL
    );

    PROCEDURE p_inactivar_x_profesional (
        p_id_usuario IN core_horario_profesional.id_usuario%TYPE,
        p_id_tenant  IN core_horario_profesional.id_tenant%TYPE DEFAULT NULL
    );

    FUNCTION f_consultar_x_profesional (
        p_id_usuario IN core_horario_profesional.id_usuario%TYPE,
        p_id_tenant  IN core_horario_profesional.id_tenant%TYPE DEFAULT NULL
    ) RETURN SYS_REFCURSOR;
END pkgca_core_horario_profesional;
/
```

---

## 6. Paquetes Multi-Tabla: DML, Consultas Relacionales y Procesamiento JSON (`pkgcn_<negocio>`)

- **Propósito**: Encapsular todas las operaciones que involucran **MÁS DE UNA TABLA**:
  1. **Consultas Relacionales Multi-Tabla**: Vistas de negocio, reportes, búsquedas consolidadas que requieren combinar dos o más tablas mediante JOINs.
  2. **Sentencias DML Multi-Tabla**: Inserciones, actualizaciones o eliminaciones que coordinan cambios atómicos sobre múltiples tablas del proceso.
  3. **Procesamiento y Parsing JSON (`JSON_TABLE`)**: Desestructurar arreglos o registros JSON en filas relacionales e interactuar con múltiples tablas.
- **Nomenclatura**: Debe nombrarse por el caso de negocio o dominio funcional:
  $$\text{pkgcn\_} + \text{caso\_o\_negocio}$$
  *(Ejemplos: `pkgcn_horarios`, `pkgcn_citas`, `pkgcn_usuarios`, `pkgcn_facturacion`).*
- **Regla Transaccional**: **No ejecuta `p_do_commit` ni `ROLLBACK` directo**. La responsabilidad transaccional y el commit final recaen exclusivamente sobre el orquestador `pkgln_`.

### 6.1 Regla Obligatoria de Sintaxis SQL: Prohibición de la Nomenclatura JOIN (Sintaxis Tradicional Oracle)
> [!IMPORTANT]
> **Prohibición de ANSI JOIN en toda sentencia SELECT:** Queda terminantemente prohibido el uso de la sintaxis ANSI JOIN (`INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL JOIN`, `CROSS JOIN`) en todas las consultas y cursores de la plataforma.
> 
> **Sintaxis Tradicional Obligatoria:**
> 1. Todas las tablas se declaran en el `FROM` separadas por coma con alias claros (ej. `FROM core_usuario u, core_persona p`).
> 2. Las condiciones de enlace se especifican en el `WHERE` con igualdad (ej. `WHERE p.id = u.id_persona`).
> 3. Para uniones externas (Outer Joins), es obligatorio usar el operador nativo de Oracle **`(+)`** al lado de la columna de la tabla externa/opcional (ej. `WHERE p.id(+) = u.id_persona`).
> 4. Los filtros de negocio y de tenant se encadenan con `AND` en el mismo `WHERE`.

*Ejemplo Tradicional Multi-Tabla:*
```sql
OPEN p_cursor FOR
    SELECT u.id,
           u.nombre_usuario,
           u.correo_electronico,
           p.primer_nombre,
           p.primer_apellido
      FROM core_usuario u,
           core_persona p
     WHERE p.id(+) = u.id_persona
       AND u.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')))
       AND u.estado_registro = 1;
```

### 6.2 Uso de `JSON_TABLE` en `pkgcn_`
Se debe emplear `JSON_TABLE` para desestructurar arreglos o registros JSON en filas relacionales y realizar inserciones, actualizaciones o uniones entre múltiples tablas del dominio:

```sql
PROCEDURE p_insertar_orden_con_detalles (
    p_id_tenant    IN NUMBER,
    p_json_entrada IN CLOB
)
IS
BEGIN
    -- DML multi-tabla utilizando JSON_TABLE para desestructurar el payload
    INSERT INTO core_orden_detalle (id_tenant, id, id_orden, id_producto, cantidad, precio)
    SELECT p_id_tenant,
           core_orden_detalle_seq.NEXTVAL,
           jt.id_orden,
           jt.id_producto,
           jt.cantidad,
           jt.precio
      FROM JSON_TABLE(p_json_entrada, '$.items[*]'
               COLUMNS (
                   id_orden    NUMBER(12)    PATH '$.id_orden',
                   id_producto NUMBER(12)    PATH '$.id_producto',
                   cantidad    NUMBER(10,2)  PATH '$.cantidad',
                   precio      NUMBER(15,2)  PATH '$.precio'
               )
           ) jt;
END p_insertar_orden_con_detalles;
```

---

## 7. Paquetes Orquestadores de Negocio Transaccionales (`pkgln_`)

- **Propósito**: Son los **orquestadores de negocio principales** del sistema. Reciben las peticiones expuestas hacia el Frontend o API Gateway, coordinan la lógica funcional invocando paquetes `pkgcn_`, DAOs (`pkg<tabla>_dao`), `pkgca_` y utilitarios, y **gobiernan la transacción atómica completa**.
- **Nomenclatura**: `pkgln_<dominio>` (ej. `pkgln_usuarios`, `pkgln_citas`, `pkgln_ordenes`, `pkgln_autenticacion`).
- **Firma Obligatoria Frontend**: Todo procedimiento en `pkgln_` expuesto al front debe implementar obligatoriamente:
  ```sql
  PROCEDURE p_nombre_operacion (
      p_json_entrada IN  CLOB,
      p_json_salida  OUT CLOB
  );
  ```
- **Arquitectura de Invocación**:
  $$\text{Frontend / API} \longrightarrow \text{pkgln\_ (Orquestador)} \longrightarrow \text{pkgcn\_ (Multi-Tabla / JSON\_TABLE)} \longrightarrow \text{DAO / pkgca\_} \longrightarrow \text{p\_do\_commit en pkgln\_}$$

### 7.1 Control Transaccional en `pkgln_`
1. Validar el payload de entrada recibido en `p_json_entrada`.
2. Invocar los paquetes `pkgcn_` para operaciones DML complejas/multi-tabla o DAOs para operaciones unitarias.
3. Ejecutar obligatoriamente **`p_do_commit('<paquete>.<subprograma>');`** únicamente en la capa orquestadora `pkgln_` al completar con éxito todas las operaciones.
4. En caso de excepción en el bloque `WHEN OTHERS`, ejecutar inmediatamente `ROLLBACK;` antes de persistir el error en `core_error`.

### 7.2 Procedimiento de Confirmación Controlada (`p_do_commit`)
> [!CAUTION]
> **Queda terminantemente prohibido ejecutar `COMMIT;` directo en cualquier paquete.**
> Toda confirmación de cambios debe realizarse exclusivamente desde los orquestadores `pkgln_` invocando el procedimiento centralizado `p_do_commit`, suministrando en el parámetro `p_contexto` el nombre del objeto orquestador (`'pkgln_<dominio>.<subprograma>'`).

```sql
CREATE OR REPLACE PROCEDURE p_do_commit (
    p_contexto IN VARCHAR2 DEFAULT 'General'
) AS
BEGIN
    -- Lógica de control, auditoría o telemetría previa al commit
    DBMS_OUTPUT.PUT_LINE('Ejecutando COMMIT controlado para: ' || p_contexto);
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al ejecutar COMMIT en ' || p_contexto || ': ' || SQLERRM);
        RAISE;
END p_do_commit;
/
```

*Ejemplos de Invocación Obligatoria en `pkgln_`:*
```sql
-- Dentro del orquestador pkgln_citas.p_crear_cita:
p_do_commit('pkgln_citas.p_crear_cita');

-- Dentro del orquestador pkgln_usuarios.p_procesar_usuario:
p_do_commit('pkgln_usuarios.p_procesar_usuario');
```

### 7.3 Paquete Centralizado de Telemetría: `uti_manejo_trazas_pkg`
> [!IMPORTANT]
> **Regla Innegociable para todo paquete `pkgln_`:**
> Todo método y regla para el manejo de la traza se centraliza exclusivamente en el paquete institucional **`uti_manejo_trazas_pkg`**.
> Este paquete encapsula todas las reglas de evaluación, apertura, sub-llamados y cierre de telemetría, y se comporta como un paquete de la capa **`pkgln_`** (expone endpoints API CLOB con control transaccional) a la vez que provee procedimientos autónomos para el consumo de los orquestadores de negocio.
> 
> Todo orquestador `pkgln_` **DEBE como primera acción verificar si el objeto tiene habilitada la trazabilidad** invocando `uti_manejo_trazas_pkg.f_debe_trazar(...)` e iniciarla con `uti_manejo_trazas_pkg.p_iniciar_traza(...)`.

#### Métodos Provistos por `uti_manejo_trazas_pkg`:
1. **`f_debe_trazar(...)` (FUNCTION BOOLEAN):**
   Consulta de forma segura en `core_traza_config` si el inquilino (`p_id_tenant`), paquete (`p_nombre_paquete`), subprograma (`p_nombre_metodo`), usuario y ventana temporal tienen `es_activo = 1`. Retorna `TRUE` o `FALSE`, devolviendo además el `p_id_config_out`, `p_nivel_out` y `p_grabar_pay_out`.
2. **`p_iniciar_traza(...)` (PROCEDURE AUTÓNOMO):**
   Inserta de forma atómica y autónoma (`PRAGMA AUTONOMOUS_TRANSACTION`) el registro de cabecera en `core_traza_ejecucion` con estado `'EN_PROCESO'`, capturando IP, SID de Oracle, `codigo_traza` (Correlation ID / UUID) y el `p_json_entrada` (si `grabar_payload = 1`), retornando el `p_id_ejecucion_out`.
3. **`p_finalizar_traza(...)` (PROCEDURE AUTÓNOMO):**
   Calcula con precisión de microsegundos la duración transcurrida (`duracion_ms`) y actualiza `core_traza_ejecucion` con estado `'EXITO'`, `fecha_fin` y `json_salida`.
4. **`p_finalizar_traza_error(...)` (PROCEDURE AUTÓNOMO):**
   Calcula la duración transcurrida y actualiza de forma autónoma `core_traza_ejecucion` con estado `'ERROR'`, `codigo_error` (SQLCODE) y `mensaje_error` (SQLERRM), garantizando que la evidencia del fallo persista aún después del `ROLLBACK` de la transacción de negocio.
5. **`p_registrar_llamado(...)` (PROCEDURE AUTÓNOMO):**
   Registra el call-stack detallado y sub-llamados a DAOs, `pkgcn_` u otros paquetes en `core_traza_llamado`.
6. **Endpoints API Frontend (`p_json_entrada IN CLOB, p_json_salida OUT CLOB`):**
   - `uti_manejo_trazas_pkg.p_iniciar_traza`
   - `uti_manejo_trazas_pkg.p_finalizar_traza`
   - `uti_manejo_trazas_pkg.p_configurar_regla`
   - `uti_manejo_trazas_pkg.p_consultar_trazas`

### 7.4 Regla Obligatoria: Archivo de Documentación Funcional de Flujo (`<nombre_paquete>.md`)
> [!IMPORTANT]
> **Documentación de Flujo para Visualizador Gráfico de Información:**
> Cada vez que se cree o modifique un método en un paquete `pkgln_`, es **estrictamente obligatorio** crear o actualizar un archivo con el nombre exacto del paquete: **`<nombre_paquete>.md`** (ej: `pkgln_citas.md`, `pkgln_usuarios.md`).
> 
> En este archivo, cada método de `pkgln_` debe documentarse en **lenguaje natural** estructurado en tres bloques:
> 1. **Descripción Funcional en Lenguaje Natural**: Explicación clara, amigable y comprensible para negocio y usuarios de qué hace el método.
> 2. **Decisiones (Bifurcaciones Lógicas)**: Relación explícita de todas las condiciones (`IF / ELSE`), reglas de negocio evaluadas y caminos resultantes.
> 3. **Llamados Realizados y Objetos Invocados**: Registro detallado de cada invocación almacenando el **nombre exacto del objeto que llama** (ej: `uti_manejo_trazas_pkg.f_debe_trazar`, `pkgca_core_usuario.f_consultar_x_filtro`, `pkgcn_citas.p_insertar_con_detalle`, `PKGCORE_CITA_DAO.p_insertar`, `p_do_commit`, `uti_ge_excepciones_pkg.p_grabar_log`), su tipo y la condición bajo la cual se ejecuta.
> 
> **Propósito:** Este archivo es la fuente de verdad que consume la aplicación encargada de graficar interactivamente el flujo de la información, el árbol de decisiones y las dependencias entre componentes.

---

## 8. Paquetes Utilitarios Transversales (`uti_`)

Los paquetes que inician con el prefijo **`uti_`** (generalmente con sufijo `_pkg`, ej: `uti_archivos_pkg`, `uti_validaciones_pkg`) encapsulan componentes y rutinas técnicas auxiliares **estrictamente agnósticas al negocio**:

### 8.1 Responsabilidades de la Capa Utilitaria
- **Manejo de Archivos**: Lectura, escritura, parsing de archivos planos, manipulación de `BLOB` y `CLOB`, conversión Base64, interacción con almacenamiento u Object Storage (ej: `uti_archivos_pkg`).
- **Validaciones de Tipos de Datos y Formatos**: Comprobación genérica de tipos de datos, fechas válidas, sintaxis de correos electrónicos, expresiones regulares, dígitos de verificación y estructuras numéricas (ej: `uti_validaciones_pkg`).
- **Herramientas de Criptografía y Transformación**: Funciones de hash (SHA-256), formateo de cadenas, saneamiento de entradas, cálculos matemáticos auxiliares y conversiones de charsets.
- **Servicios Transversales del Ecosistema Core**:
  - `uti_manejo_trazas_pkg`: Telemetría centralizada, auditoría y tracing distribuido.
  - `uti_ge_excepciones_pkg`: Registro forense autónomo de errores no controlados en `core_error`.

### 8.2 Restricciones Innegociables para Paquetes `uti_`
1. **Cero Lógica de Negocio**: No deben incluir reglas de dominio, tarifas, flujos comerciales ni validaciones atadas a procesos de negocio.
2. **Cero Control Transaccional**: Queda **terminantemente prohibido** ejecutar `COMMIT;`, `ROLLBACK;` o `p_do_commit` dentro de un paquete `uti_`. Son utilidades puras y en su mayoría stateless (a excepción de procedimientos autónomos de telemetría y logging que usan `PRAGMA AUTONOMOUS_TRANSACTION`).
3. **Reutilización y Consumo Transversal**: Pueden ser invocados libremente por cualquiera de las capas superiores o inferiores (`pkgln_`, `pkgcn_`, `pkgca_`, o DAOs si se requiere una función escalar pura).

---

## 9. Estándar Obligatorio de Manejo de Excepciones y Logging (Cero RAISE_APPLICATION_ERROR)

### 9.1 Errores de Negocio Conocidos
- En orquestadores `pkgln_`, los errores de negocio controlados **NO DEBEN lanzar `RAISE_APPLICATION_ERROR`**.
- Deben ejecutar `ROLLBACK;`, armar la respuesta JSON de salida estructurada con código de negocio negativo (entre `-20001` y `-20999`), mensaje descriptivo, y finalizar con `RETURN;`.

```sql
IF v_stock < p_cantidad THEN
    ROLLBACK;
    p_json_salida := JSON_OBJECT(
        'codigo'  VALUE -20001,
        'error'   VALUE -20001,
        'mensaje' VALUE 'No existe inventario suficiente para completar la operación solicitada.',
        'datos'   VALUE NULL
        RETURNING CLOB
    );
    RETURN;
END IF;
```

### 9.2 Errores Inesperados (`WHEN OTHERS`) y Ciclo de Vida Transaccional
En todo orquestador transaccional `pkgln_`, la orquestación, verificación de telemetría con `uti_manejo_trazas_pkg`, registro forense en `core_error` y retorno estructurado en JSON debe implementarse bajo este esquema estándar integral (sin `RAISE_APPLICATION_ERROR`):

```sql
CREATE OR REPLACE PACKAGE BODY pkgln_modulo
AS
    vro_error core_error%ROWTYPE;

    PROCEDURE p_operacion (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    )
    IS
        -- Variables de Negocio y Control
        v_obj_in                JSON_OBJECT_T;
        v_id                    NUMBER(12);
        v_id_tenant             NUMBER(12);
        v_id_usuario            NUMBER(12);
        v_codigo_traza          VARCHAR2(100);
        v_ip_origen             VARCHAR2(50);
        
        -- Variables de Telemetría (uti_manejo_trazas_pkg)
        v_traza_activa          BOOLEAN := FALSE;
        v_id_config_traza       NUMBER(12) := NULL;
        v_id_traza_ejecucion    NUMBER(12) := NULL;
        v_nivel_detalle_traza   VARCHAR2(30) := 'COMPLETO';
        v_grabar_payloads_traza NUMBER(1) := 1;
        v_fecha_inicio_traza    TIMESTAMP := SYSTIMESTAMP;
    BEGIN
        -- 1. Parseo inicial del payload de entrada y extracción de metadatos
        v_obj_in    := JSON_OBJECT_T.parse(p_json_entrada);
        v_id_tenant := v_obj_in.get_number('id_tenant');
        v_id        := v_obj_in.get_number('id');
        
        IF v_obj_in.has('id_usuario') THEN
            v_id_usuario := v_obj_in.get_number('id_usuario');
        END IF;

        IF v_obj_in.has('codigo_traza') THEN
            v_codigo_traza := v_obj_in.get_string('codigo_traza');
        ELSIF v_obj_in.has('id_traza') THEN
            v_codigo_traza := v_obj_in.get_string('id_traza');
        ELSE
            v_codigo_traza := RAWTOHEX(SYS_GUID());
        END IF;

        IF v_obj_in.has('ip_origen') THEN
            v_ip_origen := v_obj_in.get_string('ip_origen');
        ELSE
            v_ip_origen := SYS_CONTEXT('USERENV', 'IP_ADDRESS');
        END IF;

        -- =====================================================================
        -- PASO 1: VERIFICACIÓN OBLIGATORIA DE TRAZABILIDAD (uti_manejo_trazas_pkg)
        -- =====================================================================
        v_traza_activa := uti_manejo_trazas_pkg.f_debe_trazar(
            p_id_tenant      => v_id_tenant,
            p_nombre_paquete => 'pkgln_modulo',
            p_nombre_metodo  => 'p_operacion',
            p_id_usuario     => v_id_usuario,
            p_id_config_out  => v_id_config_traza,
            p_nivel_out      => v_nivel_detalle_traza,
            p_grabar_pay_out => v_grabar_payloads_traza
        );

        -- =====================================================================
        -- PASO 2: APERTURA DE LA TRAZA SI ESTÁ HABILITADA
        -- =====================================================================
        IF v_traza_activa THEN
            uti_manejo_trazas_pkg.p_iniciar_traza(
                p_id_tenant        => v_id_tenant,
                p_nombre_paquete   => 'pkgln_modulo',
                p_nombre_metodo    => 'p_operacion',
                p_id_config        => v_id_config_traza,
                p_id_usuario       => v_id_usuario,
                p_codigo_traza     => v_codigo_traza,
                p_ip_origen        => v_ip_origen,
                p_json_entrada     => p_json_entrada,
                p_grabar_payload   => v_grabar_payloads_traza,
                p_id_ejecucion_out => v_id_traza_ejecucion
            );
        END IF;

        -- =====================================================================
        -- PASO 3: LÓGICA DE NEGOCIO COORDINADA (pkgcn_, pkgca_ y DAOs)
        -- =====================================================================
        -- pkgcn_modulo.p_procesar_multi_tabla(v_id_tenant, v_id, p_json_entrada);

        -- =====================================================================
        -- PASO 4: CONFIRMACIÓN CONTROLADA DE TRANSACCIÓN (p_do_commit)
        -- =====================================================================
        p_do_commit('pkgln_modulo.p_operacion');

        -- Construcción del payload de salida exitoso
        SELECT JSON_OBJECT(
                   'codigo'  VALUE 0,
                   'mensaje' VALUE 'Operación completada exitosamente',
                   'datos'   VALUE JSON_OBJECT(
                                      'id'           VALUE v_id,
                                      'codigo_traza' VALUE v_codigo_traza
                                   )
                   RETURNING CLOB
               )
          INTO p_json_salida
          FROM DUAL;

        -- =====================================================================
        -- PASO 5: CIERRE EXITOSO DE LA TRAZA CON uti_manejo_trazas_pkg
        -- =====================================================================
        IF v_traza_activa AND v_id_traza_ejecucion IS NOT NULL THEN
            uti_manejo_trazas_pkg.p_finalizar_traza(
                p_id_tenant      => v_id_tenant,
                p_id_ejecucion   => v_id_traza_ejecucion,
                p_fecha_inicio   => v_fecha_inicio_traza,
                p_json_salida    => p_json_salida,
                p_grabar_payload => v_grabar_payloads_traza
            );
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- 1. Rollback inmediato de la transacción de negocio
            ROLLBACK;

            -- 2. Cierre autónomo de la traza de ejecución en estado ERROR
            IF v_traza_activa AND v_id_traza_ejecucion IS NOT NULL THEN
                uti_manejo_trazas_pkg.p_finalizar_traza_error(
                    p_id_tenant     => v_id_tenant,
                    p_id_ejecucion  => v_id_traza_ejecucion,
                    p_fecha_inicio  => v_fecha_inicio_traza,
                    p_codigo_error  => SQLCODE,
                    p_mensaje_error => SQLERRM
                );
            END IF;

            -- 3. Registro forense autónomo en core_error
            vro_error.id_tenant          := v_id_tenant;
            vro_error.id_usuario         := v_id_usuario;
            vro_error.id_traza_ejecucion := v_id_traza_ejecucion;
            vro_error.codigo_traza       := v_codigo_traza;
            vro_error.nombre_programa    := 'pkgln_modulo';
            vro_error.nombre_metodo      := 'p_operacion';
            vro_error.objeto_error       := 'pkgln_modulo.p_operacion';
            vro_error.codigo_error       := SQLCODE;
            vro_error.mensaje_error      := SUBSTR(SQLERRM, 1, 4000);
            vro_error.traza_error        := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            vro_error.pila_llamadas      := DBMS_UTILITY.FORMAT_CALL_STACK;
            vro_error.payload_entrada    := p_json_entrada;
            vro_error.id_sesion_oracle   := SYS_CONTEXT('USERENV', 'SID');
            vro_error.direccion_ip       := v_ip_origen;
            vro_error.severidad          := 'ERROR';
            vro_error.resuelto           := 0;
            vro_error.estado_registro    := 1;

            vro_error.parametros :=
                   'p_json_entrada: '
                || CASE 
                       WHEN DBMS_LOB.GETLENGTH(p_json_entrada) > 3000 
                       THEN SUBSTR(p_json_entrada, 1, 3000) || '... [TRUNCADO]'
                       ELSE p_json_entrada
                   END;

            uti_ge_excepciones_pkg.p_grabar_log(vro_error);

            -- 4. Retorno estructurado del error en p_json_salida (PROHIBIDO RAISE_APPLICATION_ERROR)
            SELECT JSON_OBJECT(
                       'codigo'   VALUE -20000,
                       'error'    VALUE -20000,
                       'mensaje'  VALUE 'Se presento un error comunicarse con soporte. Número error: '
                                        || vro_error.id,
                       'id_error' VALUE vro_error.id,
                       'datos'    VALUE NULL
                       RETURNING CLOB
                   )
              INTO p_json_salida
              FROM DUAL;
    END p_operacion;
END pkgln_modulo;
```

### 9.3 Prohibiciones Estrictas de Manejo de Errores
> [!CAUTION]
> 1. **Prohibido:** `WHEN OTHERS THEN NULL;` (Nunca silenciar ni ocultar excepciones).
> 2. **Prohibido:** El uso de `RAISE_APPLICATION_ERROR` en cualquier orquestador o interfaz expuesta hacia el API/Frontend. Todo error (de negocio o imprevisto) DEBE devolverse obligatoriamente serializado en el JSON de salida (`p_json_salida`) con los atributos `codigo`/`error` y `mensaje`.
> 3. **Prohibido:** Retornar errores al cliente sin haber ejecutado `uti_ge_excepciones_pkg.p_grabar_log(vro_error);` ante fallos no controlados.
> 4. **Prohibido:** Inserciones manuales directas como `INSERT INTO core_error...`.
> 5. **Prohibido:** Nombres genéricos en `vro_error.nombre_programa` (e.g. `'PACKAGE'`, `'PROCESO'`).

---

## 10. Estándar Universal e Innegociable de Manejo de Fechas (YYYY-MM-DD)

### 10.1 Regla General
Cualquier método, procedimiento, función, cursor o JSON que reciba o retorne una fecha DEBE utilizar de manera estricta y obligatoria el formato ISO **`YYYY-MM-DD`** (ejemplo: `'2026-10-21'`). Queda prohibido el uso de formatos dependientes del NLS de sesión, formatos locales (ej. `dd/mm/yyyy`) o timestamps con hora no solicitados en campos puramente de fecha.

### 10.2 Fechas de Entrada (`p_json_entrada` o parámetros VARCHAR2)
1. **Validación Estricta:** Al extraer fechas de un JSON o recibirlas como cadenas, deben convertirse exclusivamente utilizando:
   ```sql
   v_fecha := TO_DATE(TRIM(v_fecha_str), 'YYYY-MM-DD');
   ```
2. **Control de Errores de Entrada:** Si la fecha viene nula (y es obligatoria) o su formato no corresponde a `YYYY-MM-DD`, **no se debe lanzar RAISE_APPLICATION_ERROR**. En su lugar, se debe construir la respuesta en `p_json_salida` y salir inmediatamente:
   ```sql
   BEGIN
       v_fecha := TO_DATE(TRIM(v_fecha_str), 'YYYY-MM-DD');
   EXCEPTION
       WHEN OTHERS THEN
           p_json_salida := JSON_OBJECT(
               'codigo'  VALUE -20005,
               'error'   VALUE -20005,
               'mensaje' VALUE 'Formato de fecha inválido (' || v_fecha_str || '). Se espera YYYY-MM-DD.',
               'datos'   VALUE NULL
               RETURNING CLOB
           );
           RETURN;
   END;
   ```

### 10.3 Fechas de Salida (`p_json_salida`, DAOs y `SYS_REFCURSOR`)
1. **En Generación de JSON (`JSON_OBJECT`, `JSON_ARRAYAGG`):** Toda columna de tipo `DATE` debe proyectarse explícitamente formateada con `TO_CHAR`:
   ```sql
   JSON_OBJECT(
       'id'            VALUE t.id,
       'fecha_inicial' VALUE TO_CHAR(t.fecha_inicial, 'YYYY-MM-DD'),
       'fecha_final'   VALUE TO_CHAR(t.fecha_final, 'YYYY-MM-DD')
   )
   ```
2. **En Consultas de Cursores (`SYS_REFCURSOR` en `pkgca_`, `pkgcn_` o DAOs):** Formatear las columnas de fecha con `TO_CHAR(columna, 'YYYY-MM-DD') AS columna` para garantizar coherencia independiente de la configuración del cliente.

---

## 11. Retorno Multi-Fila y Generación de JSON en Oracle

### 11.1 Consultas Multi-Fila: `SYS_REFCURSOR`
Cualquier procedimiento o función de consulta multi-registro debe retornar un `SYS_REFCURSOR`:
```sql
FUNCTION f_buscar_citas (
    p_id_profesional IN NUMBER,
    p_fecha          IN DATE,
    p_id_tenant      IN NUMBER DEFAULT NULL
) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
        SELECT id, id_paciente, fecha_hora, estado
          FROM core_cita
         WHERE id_profesional = p_id_profesional
           AND TRUNC(fecha_hora) = TRUNC(p_fecha)
           AND id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    RETURN v_cursor;
END f_buscar_citas;
```

### 11.2 Generación Nativa de JSON (APIs / Frontends / APEX / Node)
Cuando el consumidor requiera JSON, se debe generar **directamente en el motor Oracle** con funciones SQL/JSON nativas y cláusula `RETURNING CLOB`.
> [!WARNING]
> Queda **terminantemente prohibida** la concatenación manual de cadenas para formar JSON (e.g. `'{ "id": ' || id || '}'`).

```sql
-- Objeto individual
SELECT JSON_OBJECT(
           'id'     VALUE id,
           'nombre' VALUE nombre_usuario,
           'estado' VALUE estado_registro
           RETURNING CLOB
       )
  INTO p_json_clob
  FROM core_usuario
 WHERE id = p_id
   AND id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));

-- Colección de objetos (Array)
SELECT JSON_ARRAYAGG(
           JSON_OBJECT(
               'id'     VALUE u.id,
               'nombre' VALUE u.nombre_usuario,
               'correo' VALUE u.correo_electronico
               RETURNING CLOB
           )
           RETURNING CLOB
       )
  INTO p_json_clob
  FROM core_usuario u
 WHERE u.estado_registro = 1
   AND u.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
```

---

## 12. Nomenclatura de Subprogramas, Parámetros y Variables

### 12.1 Subprogramas (Procedimientos y Funciones)
> [!IMPORTANT]
> **Regla Innegociable de Prefijos de Subprogramas:**
> * **TODO PROCEDIMIENTO NUEVO** debe empezar obligatoriamente con el prefijo **`p_`** (tanto en paquetes DAO como en `pkgca_`, `pkgcn_`, `pkgln_` y `uti_`).
> * **TODA FUNCIÓN NUEVA** debe empezar obligatoriamente con el prefijo **`f_`** (tanto en paquetes DAO como en `pkgca_`, `pkgcn_`, `pkgln_` y `uti_`).
> * Queda terminantemente prohibido el uso de prefijos alternativos como `pr_`, `fn_`, `sp_`, `func_` o subprogramas sin prefijo tipado.

| Tipo de Subprograma | Prefijo Obligatorio | Ejemplos Permitidos | Prohibido |
| :--- | :--- | :--- | :--- |
| **Procedimientos** | **`p_`** | `p_insertar`, `p_actualizar`, `p_eliminar`, `p_confirmar_orden`, `p_crear_usuario`, `p_actualizar_estado` | `pr_confirmar`, `sp_crear`, `crear_usuario` |
| **Funciones** | **`f_`** | `f_traer`, `f_existe`, `f_json`, `f_buscar_citas`, `f_calcular_total`, `f_validar_token` | `fn_buscar`, `fun_calcular`, `calcular_total` |

### 12.2 Convención Estricta de Variables y Parámetros
Queda terminantemente prohibido el uso de nombres de variables o parámetros sin prefijo tipado. Todo objeto PL/SQL debe respetar obligatoriamente la siguiente tabla:

| Categoría de Dato | Variable Local (Declaración interna) | Parámetro Formal (Firma de Subprograma) | Ejemplos |
| :--- | :--- | :--- | :--- |
| **Escalares / Simples** (`NUMBER`, `VARCHAR2`, `DATE`, `BOOLEAN`, etc.) | **`v_`** | **`p_`** | Local: `v_id`, `v_contador`, `v_nombre`, `v_estado`<br>Parámetro: `p_id`, `p_codigo`, `p_fecha`, `p_tipo` |
| **Registros** (`%ROWTYPE`, `RECORD`) | **`vro_`** | **`pro_`** | Local: `vro_usuario`, `vro_error`, `vro_core_tenant`<br>Parámetro: `pro_usuario`, `pro_core_tenant` |
| **Tablas PL / Colecciones** (`TABLE OF ... INDEX BY`) | **`vta_`** | **`pta_`** | Local: `vta_usuarios`, `vta_detalles`<br>Parámetro: `pta_usuarios`, `pta_core_tenant` |
| **Endpoints Frontend / APIs (CLOB JSON)** | N/A | **`p_json_entrada`** (IN CLOB)<br>**`p_json_salida`** (OUT CLOB) | Parámetros obligatorios de firma en orquestadores `pkgln_` |

---

## 13. Regla de Parámetros CLOB para Procesos Invocados desde Frontend / APIs

Todo procedimiento expuesto para ser invocado desde el front-end, API Gateway, microservicios o Node.js pertenece a la familia de orquestadores **`pkgln_`** y **debe tener obligatoriamente y sin excepción** la siguiente firma fija de dos parámetros CLOB:

```sql
PROCEDURE p_nombre_operacion (
    p_json_entrada IN  CLOB,
    p_json_salida  OUT CLOB
);
```

* **`p_json_entrada` (IN CLOB):** Recibe el payload JSON. Se debe parsear con `JSON_OBJECT_T.parse(p_json_entrada)`.
* **`p_json_salida` (OUT CLOB):** Retorna la respuesta en JSON. Se genera nativamente en Oracle mediante `JSON_OBJECT(...) RETURNING CLOB` o `JSON_ARRAYAGG(...) RETURNING CLOB`.
* Queda **prohibido** renombrar estos parámetros (e.g. `p_json_in`, `p_datos`, `p_resultado` no están permitidos).

---

## 14. Documentación Obligatoria, Archivo de Flujo Gráfico (`<nombre_paquete>.md`) y Control de Cambios en `.pks`

### 14.1 Estructura del Bloque de Documentación en `.pks`
En la especificación de todo paquete (`.pks`), **antes de cada objeto (procedimiento o función)**, debe ubicarse un bloque de documentación estructurado.
Es requisito obligatorio **documentar en detalle la estructura (schema) y un ejemplo completo del JSON de entrada (`p_json_entrada`) como del JSON de salida (`p_json_salida`)**. Asimismo, cuando se realice cualquier modificación o ajuste de funcionalidad, **debe agregarse un registro por fecha en el historial de cambios**.

```sql
    /**
     * =========================================================================
     * Objeto      : p_nombre_operacion
     * Propósito   : Descripción clara y detallada de la funcionalidad del objeto.
     * 
     * Parámetros  :
     *   @param p_json_entrada (IN CLOB)  : Payload JSON con los datos de entrada.
     *   @param p_json_salida  (OUT CLOB) : Payload JSON con el resultado o código de error.
     * 
     * Estructura JSON Entrada (Schema):
     *   {
     *     "id_tenant": NUMBER (Obligatorio) - Identificador del inquilino,
     *     "id_usuario_ejecutor": NUMBER (Opcional) - ID del usuario que invoca la acción,
     *     "id_traza": VARCHAR2 (Opcional) - Identificador único de correlación / tracing distribuido,
     *     "datos": {
     *       "campo_1": VARCHAR2(100) (Obligatorio) - Descripción del campo,
     *       "campo_2": NUMBER (Opcional) - Valor numérico adicional
     *     }
     *   }
     * 
     * Ejemplo JSON Entrada:
     *   {
     *     "id_tenant": 1,
     *     "id_usuario_ejecutor": 105,
     *     "id_traza": "TRZ-20261007-0091",
     *     "datos": {
     *       "campo_1": "Valor de prueba",
     *       "campo_2": 42
     *     }
     *   }
     * 
     * Estructura JSON Salida (Schema):
     *   {
     *     "codigo": NUMBER - 0 si es exitoso, diferente de 0 si hay error de negocio,
     *     "mensaje": VARCHAR2 - Mensaje descriptivo de la operación,
     *     "datos": OBJECT / ARRAY - Contenedor con la entidad creada o respuesta
     *   }
     * 
     * Ejemplo JSON Salida:
     *   -- Éxito:
     *   {
     *     "codigo": 0,
     *     "mensaje": "Operación completada exitosamente",
     *     "datos": {
     *       "id": 1250,
     *       "estado": "ACTIVO"
     *     }
     *   }
     *   -- Error de Negocio Controlado:
     *   {
     *     "codigo": -20001,
     *     "mensaje": "El registro ya existe en el sistema",
     *     "datos": null
     *   }
     * 
     * Retorno (si aplica):
     *   @return <Tipo y descripción del retorno si es función>
     * 
     * Excepciones :
     *   -20000 : Error inesperado del sistema (registrado en log autónomo core_error).
     *   -20001 : Error de negocio controlado (e.g. validación de campos, regla de dominio).
     * 
     * Historial de Modificaciones:
     *   -----------------------------------------------------------------------
     *   FECHA       | AUTOR                  | DESCRIPCIÓN DEL CAMBIO
     *   -----------------------------------------------------------------------
     *   2026-10-07  | Orlando Valverde       | Creación inicial de la funcionalidad.
     *   2026-10-08  | Equipo Core            | Adición de validación de tokens federados.
     * =========================================================================
     */
    PROCEDURE p_nombre_operacion (
        p_json_entrada IN  CLOB,
        p_json_salida  OUT CLOB
    );
```

---

### 14.2 Catálogo y Documentación en Lenguaje Natural (`core_documentacion_metodo`)
Para alimentar visualizadores gráficos interactivos, portales de documentación funcional y catálogos de APIs para analistas e integradores, todo método orquestador de `pkgln_` debe contar con su correspondiente registro en la tabla **`core_documentacion_metodo`**:
* **Enfoque de Lenguaje Natural:** La documentación almacenada no es meramente técnica, sino redactada para ser entendida por analistas de negocio, usuarios operativos y líderes de producto.
* **Metadatos Registrados:**
  - `nombre_paquete` y `nombre_metodo` (Identificadores del servicio).
  - `titulo_funcional` y `resumen_ejecutivo` (Para tarjetas e índices del catálogo).
  - `descripcion_negocio` y `actor_principal` (Propósito de negocio y rol que lo invoca).
  - `flujo_funcional_pasos` (Secuencia paso a paso explicada didácticamente).
  - `reglas_validacion` (Reglas y condiciones requeridas para la ejecución).
  - `descripcion_entrada_natural` y `ejemplo_json_entrada` (Explicación y JSON real de `p_json_entrada`).
  - `descripcion_salida_natural` y `ejemplo_json_salida` (Explicación y JSON real de `p_json_salida`).
  - `excepciones_negocio` (Códigos de error de negocio y acciones de resolución).
  - `categoria_visual`, `icono_interfaz` y `color_distintivo` (Tokens de renderizado para UI gráfica).

---

### 14.3 Regla Obligatoria: Archivo de Flujo Gráfico por Paquete (`<nombre_paquete>.md`)
> [!IMPORTANT]
> **REGLA VINCULANTE PARA TODO MÉTODO EN `pkgln_`:**
> Cada vez que se cree o modifique un procedimiento o función dentro de un paquete orquestador `pkgln_<dominio>`, **se debe crear o actualizar obligatoriamente un archivo Markdown con el nombre del paquete: `<nombre_paquete>.md`** (ej: `pkgln_citas.md`, `pkgln_usuarios.md`).
>
> **Finalidad:** Servir de insumo directo y fuente de datos para una aplicación o módulo visual que procesa estos archivos y genera diagramas de flujo interactivos, árboles de decisión y grafos de dependencia entre objetos de base de datos.

#### Plantilla Estándar Obligatoria para `<nombre_paquete>.md`:

```markdown
# Diagrama y Flujo de Información: <NOMBRE_PAQUETE>

## Método: <nombre_metodo> (ej: p_agendar_cita)

### 1. Descripción en Lenguaje Natural
Explicación comprensible para negocio y usuarios del flujo completo que ejecuta el método:
- Qué necesidad de negocio resuelve.
- Qué rol o sistema externo lo dispara.
- Cuál es el resultado esperado en caso exitoso y en caso de error.

### 2. Decisiones y Bifurcaciones Lógicas
Relación detallada de todas las condiciones evaluadas y sus caminos resultantes:
- **Decisión 1 [Validación de Entrada]**: Si los campos obligatorios vienen incompletos en el JSON, se retorna de inmediato con código `-20001` sin afectar la base de datos.
- **Decisión 2 [Evaluación de Regla de Negocio]**: Se consulta si existe disponibilidad para la fecha/hora seleccionada. Si no hay disponibilidad, se interrumpe el flujo y se notifica al usuario.
- **Decisión 3 [Trazabilidad Activa]**: Si `uti_manejo_trazas_pkg.f_debe_trazar` retorna `TRUE`, se registra la apertura y cierre de la traza de ejecución; de lo contrario, se omite.

### 3. Mapa de Objetos Invocados y Llamados
Tabla estructurada que almacena el **nombre exacto del objeto que llama**, su capa, propósito y momento de llamada:

| Orden | Nombre Exacto del Objeto Invocado | Capa / Familia | Tipo | Propósito de la Invocación | Condición / Momento |
| :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | `uti_manejo_trazas_pkg.f_debe_trazar` | `uti_` | Función | Determinar si el método tiene telemetría activa | Al iniciar el subprograma |
| 2 | `uti_manejo_trazas_pkg.p_iniciar_traza` | `uti_` | Procedimiento | Registrar cabecera en core_traza_ejecucion | Si f_debe_trazar = TRUE |
| 3 | `pkgca_core_usuario.f_consultar_x_filtro` | `pkgca_` | Función | Comprobar que el usuario no esté suspendido | Siempre |
| 4 | `PKGCORE_CITA_DAO.f_existe` | `DAO` | Función | Verificar si ya existe cita para el horario | Previo a la inserción |
| 5 | `pkgcn_citas.p_insertar_con_detalle` | `pkgcn_` | Procedimiento | Insertar cabecera y desglose desestructurando JSON | Si no existe cita previa |
| 6 | `p_do_commit` | `Transaccional` | Procedimiento | Confirmar cambios en la base de datos | Éxito sin excepciones |
| 7 | `uti_manejo_trazas_pkg.p_finalizar_traza` | `uti_` | Procedimiento | Registrar fin exitoso de telemetría | Éxito antes de salir |
| 8 | `uti_ge_excepciones_pkg.p_grabar_log` | `uti_` | Procedimiento | Registro forense autónomo en core_error | Bloque WHEN OTHERS |
```

---

## 15. Lista de Chequeo Arquitectónica Obligatoria (Pre-entrega)

Antes de entregar cualquier código, el agente debe auto-verificar:
- [ ] **Clasificación**: ¿El código está en el paquete correcto (`_DAO`, `pkgca_`, `pkgcn_`, `pkgln_`, `uti_`) según su responsabilidad?
- [ ] **Nombre DAO**: ¿Cumple con la sintaxis exacta `PKGCORE_<TABLA>_DAO` en singular?
- [ ] **Plantilla DAO**: ¿Mantiene los nombres y firmas de los 20 métodos oficiales con soporte multi-tenant (Enfoque B)?
- [ ] **Mono-Tabla estricto en `pkgca_`**: ¿El paquete `pkgca_<nombre_tabla>` afecta exclusivamente a una sola tabla física sin JOINs ni tablas secundarias?
- [ ] **Multi-Tabla en `pkgcn_`**: ¿Toda consulta con JOIN tradicional `(+)` o DML coordinado reside en `pkgcn_<negocio>`?
- [ ] **Sintaxis Tradicional Oracle**: ¿Se eliminó cualquier indicio de ANSI JOIN (`JOIN`, `INNER`, `LEFT`) usando comas en el `FROM` y `(+)` en el `WHERE`?
- [ ] **Utilitarios Transversales (`uti_`)**: ¿El paquete `uti_` carece de lógica de negocio y se abstiene de hacer `p_do_commit` o transacciones?
- [ ] **Prefijos de Subprogramas**: ¿Todo procedimiento empieza por `p_` y toda función empieza por `f_` (incluyendo `uti_`)?
- [ ] **Nomenclatura Variables Locales**: ¿Toda variable local escalar empieza por `v_`?
- [ ] **Nomenclatura Parámetros**: ¿Todo parámetro formal escalar empieza por `p_`?
- [ ] **Registros Locales y Parámetros**: ¿Los registros usan `vro_` (locales) y `pro_` (parámetros)?
- [ ] **Tablas PL Locales y Parámetros**: ¿Las tablas PL usan `vta_` (locales) y `pta_` (parámetros)?
- [ ] **Procesos Frontend CLOB**: ¿Los endpoints del frontend residen en `pkgln_` con `p_json_entrada` (IN) y `p_json_salida` (OUT)?
- [ ] **Validación de Trazabilidad**: ¿El objeto `pkgln_` valida si tiene seguimiento habilitado en `core_traza_config` e interactúa con `uti_manejo_trazas_pkg`?
- [ ] **Cero RAISE_APPLICATION_ERROR en `pkgln_`**: ¿Se eliminaron todos los `RAISE_APPLICATION_ERROR` en el orquestador, retornando el error estructurado en `p_json_salida` (`codigo`/`error` y `mensaje`)?
- [ ] **Trazabilidad de Errores**: ¿Se asignaron `nombre_programa`, `nombre_metodo` y `parametros` en `vro_error`?
- [ ] **Log Autónomo**: ¿Se usó `uti_ge_excepciones_pkg.p_grabar_log(vro_error)`?
- [ ] **Manejo de Fechas YYYY-MM-DD**: ¿Todas las fechas entrantes y salientes usan estrictamente `YYYY-MM-DD`?
- [ ] **Archivo de Flujo Gráfico (`<nombre_paquete>.md`)**: ¿Se creó o actualizó el archivo `.md` del paquete con lenguaje natural, bifurcaciones y tabla de objetos llamados?
- [ ] **Documentación en Lenguaje Natural (`core_documentacion_metodo`)**: ¿Está documentado el orquestador con su narrativa de negocio, pasos funcionales, validaciones y ejemplos para el catálogo visual?
- [ ] **Documentación de Esquemas y Ejemplos JSON en `.pks`**: ¿El bloque en `.pks` documenta el schema y ejemplos reales tanto del JSON de entrada como del JSON de salida?
- [ ] **Documentación y Control de Cambios**: ¿Existe el bloque de documentación antes de cada objeto con fecha, autor y descripción de cambios?
- [ ] **Transaccionalidad en Orquestador**: ¿Se invocó `p_do_commit('<paquete>.<subprograma>')` únicamente en `pkgln_` y nunca en `pkgcn_`, `pkgca_`, `uti_` ni DAO?
- [ ] **Sin COMMITs espurios**: ¿Los DAOs y subprogramas de bajo nivel se abstienen de hacer COMMIT o p_do_commit?
- [ ] **Multi-fila**: ¿Se utilizó `SYS_REFCURSOR`?
- [ ] **JSON Nativo**: ¿Se utilizó `JSON_OBJECT` / `JSON_ARRAYAGG` con `RETURNING CLOB` sin concatenaciones manuales?

---

## 16. Formato Estándar de Respuesta al Usuario

Al responder solicitudes de desarrollo PL/SQL, estructurar la salida en este orden:
1. **Clasificación arquitectónica:** (e.g. `pkgln_citas` para orquestador, `pkgcn_citas_pacientes` para DML multi-tabla, `pkgca_core_horario_profesional` para mono-tabla, o `uti_archivos_pkg` para utilitarios)
2. **Justificación breve:** Explicación técnica de por qué pertenece a esa categoría.
3. **Package Specification:** Código `.pks` (con encabezados de documentación y tabla de control de cambios por fecha).
4. **Package Body:** Código `.pkb` (con prefijos `v_`, `p_`, `vro_`, `pro_`, `vta_`, `pta_`).
5. **Consideraciones técnicas y transaccionales:** Detalle de commit/rollback, telemetría y excepciones (sin `RAISE_APPLICATION_ERROR`).
6. **Validación contra el estándar arquitectónico:** Verificación cruzada con la lista de chequeo pre-entrega.
7. **Archivo de Documentación de Flujo (`<nombre_paquete>.md`):** Si se creó o modificó un método en `pkgln_`, proveer el contenido del archivo con la narrativa en lenguaje natural, decisiones y la tabla de objetos llamados para el visualizador gráfico.
