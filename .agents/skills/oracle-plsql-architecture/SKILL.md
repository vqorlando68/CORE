---
name: oracle-plsql-architecture
description: >-
  Estándar arquitectónico obligatorio de PL/SQL para Oracle. Debe activarse SIEMPRE que se solicite crear, modificar, revisar, optimizar, refactorizar o proponer código PL/SQL, paquetes Oracle, procedimientos, funciones, consultas, APIs PL/SQL, generación de JSON o manejo transaccional. Aplica la estricta separación de responsabilidades entre paquetes DAO (pkg<tabla>_dao), pkgca_ (acceso/DML sin PK, filtros y búsquedas), pkgcn_ (lógica de negocio transaccional con COMMIT/ROLLBACK) y pkgln_ (lógica funcional/algoritmos de dominio puros), control atómico de transacciones, logging persistente en core_error con uti_ge_excepciones_pkg.p_grabar_log, SYS_REFCURSOR y JSON nativo.
---

# Estándar Arquitectónico PL/SQL para Oracle

## 1. Misión y Carácter Obligatorio

Este skill define el **estándar arquitectónico oficial e innegociable** para cualquier desarrollo, modificación, refactorización, optimización o revisión de código PL/SQL en Oracle.

> [!IMPORTANT]
> Este documento **no es solo una guía de estilo**, sino una **regla arquitectónica vinculante**.
> Antes de generar cualquier línea de código PL/SQL, se DEBE clasificar la responsabilidad de la operación y ubicarla en la familia de paquete correspondiente. Queda estrictamente prohibido mezclar responsabilidades entre paquetes.

---

## 2. Clasificación Obligatoria de Familias de Paquetes

Todo artefacto PL/SQL pertenece obligatoriamente a una de estas cuatro familias:

| Familia | Prefijo / Sufijo | Propósito Principal | DML Directo Tabla | Transacciones (p_do_commit / ROLLBACK) | Manejo de Excepciones |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **DAO** | `pkg<tabla>_dao` | Acceso a datos de UNA tabla específica por PK / ROWID (CRUD básico y plantilla oficial de 20 métodos). | Sí (su tabla exclusiva) | **PROHIBIDO** (COMMIT/ROLLBACK arbitrario prohibido, propaga errores) | Propagación hacia capas superiores |
| **pkgca_** | `pkgca_<entidad>` | Consultas y DML multi-registro o sin PK (filtros, rangos, estados, búsquedas `SYS_REFCURSOR`, updates batch). | Sí (tablas de la entidad) | **PROHIBIDO** salvo proceso batch explícito aislado | Propagación o log si es batch |
| **pkgcn_** | `pkgcn_<caso_negocio>` | Sentencias DML que involucran más de una tabla o procesos para descomponer/extraer valores de un JSON mediante `JSON_TABLE`. | Sí (múltiples tablas del proceso) | **PROHIBIDO** (Delegado al orquestador `pkgln_`) | Propagación o control puntual |
| **pkgln_** | `pkgln_<dominio>` | **Orquestadores de Negocio Transaccionales** expuestos al Frontend/API (`p_json_entrada` / `p_json_salida`). Verificación previa obligatoria de trazabilidad en `core_traza_config`. Coordinan lógica de dominio, invocan `pkgcn_`, DAOs y utilitarios. | A través de `pkgcn_` / DAOs | **OBLIGATORIO** (Control atómico: `p_do_commit('<paquete>.<metodo>')` al éxito, `ROLLBACK;` al fallo) | Bloque `WHEN OTHERS` con `ROLLBACK;`, cierre de traza en `core_traza_ejecucion`, log en `core_error` y `-20000` |

---

## 3. Árbol de Decisión Arquitectónico Obligatorio

Antes de escribir cualquier procedimiento o función, aplicar estrictamente este árbol de decisión:

```text
¿Cuál es la responsabilidad principal de la operación?
│
├── ¿Es una operación orquestadora de negocio expuesta hacia el Frontend o API Gateway
│   que recibe p_json_entrada, retorna p_json_salida, coordina el flujo y controla la transacción?
│   │
│   └── SÍ ──────────────────────────────────────────────────────────► Pertenece a: pkgln_
│                                                                     (Orquestador transaccional,
│                                                                      firma p_json_entrada/salida,
│                                                                      invoca p_do_commit)
│
├── ¿Es una sentencia DML que afecta a más de una tabla o un proceso
│   que desestructura/procesa un JSON usando JSON_TABLE para devolver valores?
│   │
│   └── SÍ ──────────────────────────────────────────────────────────► Pertenece a: pkgcn_
│                                                                     (DML multi-tabla, parsing
│                                                                      avanzado JSON / JSON_TABLE)
│
├── ¿Es una consulta/búsqueda multi-registro (SYS_REFCURSOR), filtro por rango/estado,
│   o DML masivo sobre una entidad sin depender exclusivamente de una PK?
│   │
│   └── SÍ ──────────────────────────────────────────────────────────► Pertenece a: pkgca_
│                                                                     (Búsquedas SYS_REFCURSOR,
│                                                                      filtros por estado/fecha)
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
- Tabla: `TKR_USUARIOS` $\rightarrow$ Paquete: `PKGTKR_USUARIOS_DAO`
- Tabla: `TKR_CITAS` $\rightarrow$ Paquete: `PKGTKR_CITAS_DAO`
- Tabla: `TKR_CONSULTAS` $\rightarrow$ Paquete: `PKGTKR_CONSULTAS_DAO`

*(Nunca omitir el prefijo `PKG` inicial; no usar nombres como `TKR_USUARIOS_DAO`).*

> [!IMPORTANT]
> **Regla de Singularidad de Tablas:** Todas las tablas de la plataforma se definen estrictamente en **singular** (ej. `core_usuario`, `core_rol`, `core_permiso`, `core_proceso`, `core_archivo`, `core_notificacion`, `core_error`, `core_sesion_activa`), prohibiéndose el uso de nombres en plural. En consecuencia, su paquete DAO adopta dicha singularidad 1:1: `PKGCORE_USUARIO_DAO`, `PKGCORE_ROL_DAO`, `PKGCORE_PROCESO_DAO`, etc.

### 4.2 Métodos de la Plantilla Oficial DAO
Todo DAO debe implementar los siguientes 20 métodos estándar adaptados a la tabla correspondiente:

```sql
CREATE OR REPLACE PACKAGE PKGTKR_TABLA_DAO
AS
    -- Tipo colección para consultas generales
    TYPE ta_tkr_tabla IS TABLE OF tkr_tabla%ROWTYPE INDEX BY BINARY_INTEGER;

    -- 1. Insertar registro completo
    PROCEDURE p_insertar (
        pro_tkr_tabla IN tkr_tabla%ROWTYPE
    );

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id IN tkr_tabla.id%TYPE
    ) RETURN tkr_tabla%ROWTYPE;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        pta_tkr_tabla OUT pkgtkr_tabla_dao.ta_tkr_tabla
    );

    -- 4. Eliminar registro por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    );

    -- 5. Eliminar registro por PK
    PROCEDURE p_eliminar (
        pty_id IN tkr_tabla.id%TYPE
    );

    -- 6. Eliminar todos los registros (Uso restringido)
    PROCEDURE p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id IN tkr_tabla.id%TYPE
    ) RETURN BOOLEAN;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id IN tkr_tabla.id%TYPE,
        pro_tkr_tabla OUT tkr_tabla%ROWTYPE
    ) RETURN BOOLEAN;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id IN tkr_tabla.id%TYPE,
        pro_tkr_tabla OUT tkr_tabla%ROWTYPE,
        p_rowid OUT VARCHAR2
    ) RETURN BOOLEAN;

    -- 10. Verificar existencia por ROWID
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2
    ) RETURN BOOLEAN;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid IN VARCHAR2,
        pro_tkr_tabla OUT tkr_tabla%ROWTYPE
    ) RETURN BOOLEAN;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_tkr_tabla IN tkr_tabla%ROWTYPE
    );

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_tkr_tabla IN tkr_tabla%ROWTYPE,
        pty_id IN tkr_tabla.id%TYPE
    );

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_tkr_tabla IN tkr_tabla%ROWTYPE,
        p_rowid IN VARCHAR2
    );

    -- 15. Actualizar todos los registros (Uso restringido)
    PROCEDURE p_actualizar_registros (
        pro_tkr_tabla IN tkr_tabla%ROWTYPE
    );

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_tkr_tabla IN OUT tkr_tabla%ROWTYPE
    );

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id IN tkr_tabla.id%TYPE,
        p_json_tkr_tabla OUT CLOB
    ) RETURN NUMBER;

    -- 18. Obtener JSON por PK (VARCHAR2 o CLOB según tamaño)
    FUNCTION f_json (
        p_id IN tkr_tabla.id%TYPE
    ) RETURN VARCHAR2;

    -- 19. Calcular total de páginas para paginación recibiendo JSON con campo "registros"
    FUNCTION f_total_paginas (
        p_json_entrada IN CLOB
    ) RETURN NUMBER;

    -- 20. Consultar registros paginados retornando JSON con información correspondiente
    FUNCTION f_consultar_paginado (
        p_pagina    IN NUMBER,
        p_registros IN NUMBER,
        p_id_tenant IN tkr_tabla.id_tenant%TYPE DEFAULT NULL
    ) RETURN CLOB;

END PKGTKR_TABLA_DAO;
/
```

### 4.3 Plantilla Oficial Obligatoria del Body para DAO (20 Métodos Estándar)
> [!IMPORTANT]
> **Regla Institucional Innegociable:** La siguiente estructura y codificación del **BODY** para los paquetes `_DAO` (`PKGCORE_<TABLA>_DAO`) **debe aplicarse obligatoriamente y sin excepción para todas las tablas de la base de datos**.

```sql
/**
 * =============================================================================
 * CUERPO DEL PAQUETE DAO: PKGCORE_<TABLA>_DAO
 * =============================================================================
 * Implementación oficial de los 20 métodos estándar para la tabla core_<tabla>.
 * =============================================================================
 */
CREATE OR REPLACE PACKAGE BODY PKGCORE_<TABLA>_DAO
AS
    -- 1. Insertar registro completo (Enfoque B: asegura tenant antes de insertar)
    PROCEDURE p_insertar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE
    ) IS
        vro_core_<tabla> core_<tabla>%ROWTYPE := pro_core_<tabla>;
    BEGIN
        IF vro_core_<tabla>.id_tenant IS NULL THEN
            vro_core_<tabla>.id_tenant := TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        END IF;
        INSERT INTO core_<tabla> VALUES vro_core_<tabla>;
    END p_insertar;

    -- 2. Traer registro por PK
    FUNCTION f_traer (
        pty_id        IN core_<tabla>.id%TYPE,
        pty_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN core_<tabla>%ROWTYPE IS
        vro_core_<tabla> core_<tabla>%ROWTYPE;
    BEGIN
        SELECT *
          INTO vro_core_<tabla>
          FROM core_<tabla>
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN vro_core_<tabla>;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END f_traer;

    -- 3. Consultar todos los registros
    PROCEDURE p_consultar_registros (
        p_id_tenant      IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL,
        pta_core_<tabla> OUT PKGCORE_<TABLA>_DAO.ta_core_<tabla>
    ) IS
    BEGIN
        SELECT *
          BULK COLLECT INTO pta_core_<tabla>
          FROM core_<tabla>
         WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_consultar_registros;

    -- 4. Eliminar registro por ROWID
    PROCEDURE p_eliminar_rowid (
        p_rowid IN VARCHAR2
    ) IS
    BEGIN
        DELETE FROM core_<tabla>
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_eliminar_rowid;

    -- 5. Eliminar registro por PK
    PROCEDURE p_eliminar (
        pty_id        IN core_<tabla>.id%TYPE,
        pty_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) IS
    BEGIN
        DELETE FROM core_<tabla>
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_eliminar;

    -- 6. Eliminar todos los registros (Enfoque B: acotado al tenant activo)
    PROCEDURE p_eliminar_registros IS
    BEGIN
        DELETE FROM core_<tabla>
         WHERE id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_eliminar_registros;

    -- 7. Verificar existencia por PK
    FUNCTION f_existe (
        pty_id        IN core_<tabla>.id%TYPE,
        pty_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN BOOLEAN IS
        v_existe NUMBER(1);
    BEGIN
        SELECT 1
          INTO v_existe
          FROM core_<tabla>
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 8. Verificar existencia y retornar registro
    FUNCTION f_existe (
        pty_id           IN  core_<tabla>.id%TYPE,
        pty_id_tenant    IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL,
        pro_core_<tabla> OUT core_<tabla>%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_core_<tabla>
          FROM core_<tabla>
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe;

    -- 9. Verificar existencia, retornar registro y ROWID
    FUNCTION f_existe (
        pty_id           IN  core_<tabla>.id%TYPE,
        pty_id_tenant    IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL,
        pro_core_<tabla> OUT core_<tabla>%ROWTYPE,
        p_rowid          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT t.*, t.ROWID
          INTO pro_core_<tabla>, p_rowid
          FROM core_<tabla> t
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
          FROM core_<tabla>
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 11. Verificar existencia por ROWID y retornar registro
    FUNCTION f_existe_rowid (
        p_rowid          IN  VARCHAR2,
        pro_core_<tabla> OUT core_<tabla>%ROWTYPE
    ) RETURN BOOLEAN IS
    BEGIN
        SELECT *
          INTO pro_core_<tabla>
          FROM core_<tabla>
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        RETURN TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END f_existe_rowid;

    -- 12. Actualizar registro completo por PK en ROWTYPE
    PROCEDURE p_actualizar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE
    ) IS
    BEGIN
        UPDATE core_<tabla>
           SET ROW = pro_core_<tabla>
         WHERE id = pro_core_<tabla>.id AND id_tenant = NVL(pro_core_<tabla>.id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_actualizar;

    -- 13. Actualizar indicando PK explícita
    PROCEDURE p_actualizar (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        pty_id           IN core_<tabla>.id%TYPE,
        pty_id_tenant    IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) IS
    BEGIN
        UPDATE core_<tabla>
           SET ROW = pro_core_<tabla>
         WHERE id = pty_id AND id_tenant = NVL(pty_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
    END p_actualizar;

    -- 14. Actualizar por ROWID
    PROCEDURE p_actualizar_rowid (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE,
        p_rowid          IN VARCHAR2
    ) IS
    BEGIN
        UPDATE core_<tabla>
           SET ROW = pro_core_<tabla>
         WHERE ROWID = p_rowid
           AND id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_actualizar_rowid;

    -- 15. Actualizar todos los registros (Enfoque B: acotado al tenant activo)
    PROCEDURE p_actualizar_registros (
        pro_core_<tabla> IN core_<tabla>%ROWTYPE
    ) IS
    BEGIN
        UPDATE core_<tabla>
           SET ROW = pro_core_<tabla>
         WHERE id_tenant = TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
    END p_actualizar_registros;

    -- 16. Obtener valores por defecto
    PROCEDURE p_valores_defecto (
        pro_core_<tabla> IN OUT core_<tabla>%ROWTYPE
    ) IS
    BEGIN
        pro_core_<tabla>.id_tenant := TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
        -- Valores por defecto específicos de la entidad si aplican
        NULL;
    END p_valores_defecto;

    -- 17. Verificar existencia y retornar JSON CLOB
    FUNCTION f_existe_json (
        p_id                IN  core_<tabla>.id%TYPE,
        p_id_tenant         IN  core_<tabla>.id_tenant%TYPE DEFAULT NULL,
        p_json_core_<tabla> OUT CLOB
    ) RETURN NUMBER IS
    BEGIN
        SELECT JSON_OBJECT(t.* RETURNING CLOB)
          INTO p_json_core_<tabla>
          FROM core_<tabla> t
         WHERE t.id = p_id AND t.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_json_core_<tabla> := NULL;
            RETURN 0;
    END f_existe_json;

    -- 18. Obtener JSON por PK (VARCHAR2 o CLOB según tamaño)
    FUNCTION f_json (
        p_id        IN core_<tabla>.id%TYPE,
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        v_json VARCHAR2(4000);
    BEGIN
        SELECT JSON_OBJECT(t.*)
          INTO v_json
          FROM core_<tabla> t
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
          FROM core_<tabla>
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
        p_id_tenant IN core_<tabla>.id_tenant%TYPE DEFAULT NULL
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
                FROM core_<tabla>
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


## 5. Paquetes de Consulta y Acceso No-PK (`pkgca_`)

- **Propósito**: Encapsular consultas complejas, filtros dinámicos, búsquedas, rangos de fechas, operaciones por estado y DML masivo que no dependen exclusivamente de una clave primaria.
- **Nomenclatura**: `pkgca_<entidad>` (ej. `pkgca_usuarios`, `pkgca_citas`, `pkgca_horarios`).
- **Retorno de Conjuntos Multi-fila**: Debe usar `SYS_REFCURSOR`.
- **Enfoque B en Sentencias DML**: En entidades multi-tenant, todos los métodos deben aceptar `p_id_tenant IN NUMBER DEFAULT NULL`, filtrando en sus consultas DML con `WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')))`.
- **Límites**: No debe coordinar procesos transaccionales de negocio complejos ni reemplazar a `pkgcn_`.

*Ejemplo:*
```sql
FUNCTION f_buscar_usuarios (
    p_nombre    IN VARCHAR2,
    p_estado    IN NUMBER,
    p_id_tenant IN NUMBER DEFAULT NULL
) RETURN SYS_REFCURSOR;

PROCEDURE p_actualizar_estado_citas (
    p_fecha_desde IN DATE,
    p_fecha_hasta IN DATE,
    p_estado      IN NUMBER,
    p_id_tenant   IN NUMBER DEFAULT NULL
);
```

### 5.1 Regla Obligatoria de Sintaxis SQL: Prohibición de la Nomenclatura JOIN (Sintaxis Tradicional Oracle)
> [!IMPORTANT]
> **Prohibición de ANSI JOIN en toda sentencia SELECT:** Queda terminantemente prohibido el uso de la sintaxis ANSI JOIN (`INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL JOIN`, `CROSS JOIN`) en todas las consultas y cursores de la plataforma.
> 
> **Sintaxis Tradicional Obligatoria:**
> 1. Todas las tablas se declaran en el `FROM` separadas por coma con alias claros (ej. `FROM core_usuarios u, core_personas p`).
> 2. Las condiciones de enlace se especifican en el `WHERE` con igualdad (ej. `WHERE p.id = u.id_persona`).
> 3. Para uniones externas (Outer Joins), es obligatorio usar el operador nativo de Oracle **`(+)`** al lado de la columna de la tabla externa/opcional (ej. `WHERE p.id(+) = u.id_persona`).
> 4. Los filtros de negocio y de tenant se encadenan con `AND` en el mismo `WHERE`.

*Ejemplo Tradicional Obligatorio:*
```sql
OPEN p_cursor FOR
    SELECT u.id,
           u.nombre_usuario,
           u.correo_electronico,
           p.primer_nombre,
           p.primer_apellido
      FROM core_usuarios u,
           core_personas p
     WHERE p.id(+) = u.id_persona
       AND u.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')))
       AND u.estado_registro = 1;
```

---

## 6. Paquetes DML Multi-Tabla y Procesamiento JSON (`pkgcn_`)

- **Propósito**: Encapsular sentencias DML que involucran más de una tabla o procesos especializados en devolver valores y transformar datos a partir de un JSON, utilizando sentencias SQL nativas avanzadas como `JSON_TABLE`.
- **Nomenclatura**: `pkgcn_<caso_o_entidad>` (ej. `pkgcn_citas_pacientes`, `pkgcn_ordenes_detalles`, `pkgcn_usuarios_roles`).
- **Regla Transaccional**: **No ejecuta `p_do_commit` ni `ROLLBACK` directo**. La responsabilidad transaccional y el commit final recaen exclusivamente sobre el orquestador `pkgln_`.
- **Uso de `JSON_TABLE`**: Se debe emplear `JSON_TABLE` para desestructurar arreglos o registros JSON en filas relacionales y realizar inserciones, actualizaciones o uniones entre múltiples tablas del dominio:

```sql
PROCEDURE p_insertar_orden_con_detalles (
    p_id_tenant    IN NUMBER,
    p_json_entrada IN CLOB
)
IS
BEGIN
    -- DML multi-tabla utilizando JSON_TABLE para desestructurar el payload
    INSERT INTO core_orden_detalles (id_tenant, id, orden_id, producto_id, cantidad, precio)
    SELECT p_id_tenant,
           core_orden_detalles_seq.NEXTVAL,
           jt.orden_id,
           jt.producto_id,
           jt.cantidad,
           jt.precio
      FROM JSON_TABLE(p_json_entrada, '$.items[*]'
               COLUMNS (
                   orden_id    NUMBER(12)    PATH '$.orden_id',
                   producto_id NUMBER(12)    PATH '$.producto_id',
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
  $$\text{Frontend / API} \longrightarrow \text{pkgln\_ (Orquestador)} \longrightarrow \text{pkgcn\_ (DML Multi-Tabla / JSON\_TABLE)} \longrightarrow \text{DAO / pkgca\_} \longrightarrow \text{p\_do\_commit en pkgln\_}$$

### 7.1 Control Transaccional en `pkgln_`
1. Validar el payload de entrada recibido en `p_json_entrada`.
2. Invocar los paquetes `pkgcn_` para operaciones DML complejas o DAOs para operaciones unitarias.
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

---

## 8. Estándar Obligatorio de Manejo de Excepciones y Logging

### 8.1 Errores de Negocio Conocidos
- Deben dispararse explícitamente con códigos entre `-20001` y `-20999` y mensajes claros.
- No deben confundirse con errores inesperados del sistema.

```sql
IF v_stock < p_cantidad THEN
    RAISE_APPLICATION_ERROR(
        -20001,
        'No existe inventario suficiente para completar la operación solicitada.'
    );
END IF;
```

### 8.2 Errores Inesperados (`WHEN OTHERS`) y Ciclo de Vida Transaccional
En todo orquestador transaccional `pkgln_`, la orquestación, verificación de telemetría con `uti_manejo_trazas_pkg` y manejo forense de excepciones debe implementarse bajo este esquema estándar integral:

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
        -- PASO 3: LÓGICA DE NEGOCIO COORDINADA (pkgcn_ y DAOs)
        -- =====================================================================
        -- pkgcn_modulo.p_procesar_multi_tabla(v_id_tenant, v_id, p_json_entrada);

        -- =====================================================================
        -- PASO 4: CONFIRMACIÓN CONTROLADA DE TRANSACCIÓN (p_do_commit)
        -- =====================================================================
        p_do_commit('pkgln_modulo.p_operacion');

        -- Construcción del payload de salida
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

            -- 4. Propagación al consumidor reportando el incidente forense
            RAISE_APPLICATION_ERROR(
                -20000,
                'Se presento un error comunicarse con soporte. Número error: '
                || vro_error.id
                || ' - '
                || SQLERRM
            );
    END p_operacion;
END pkgln_modulo;
```

### 8.3 Prohibiciones Estrictas de Manejo de Errores
> [!CAUTION]
> 1. **Prohibido:** `WHEN OTHERS THEN NULL;` (Nunca silenciar ni ocultar excepciones).
> 2. **Prohibido:** `WHEN OTHERS THEN RAISE_APPLICATION_ERROR(...)` sin haber ejecutado `uti_ge_excepciones_pkg.p_grabar_log(vro_error);`.
> 3. **Prohibido:** Inserciones manuales directas como `INSERT INTO core_error...`.
> 4. **Prohibido:** Nombres genéricos en `vro_error.nombre_programa` (e.g. `'PACKAGE'`, `'PROCESO'`).

---

## 9. Retorno Multi-Fila y Generación de JSON en Oracle

### 9.1 Consultas Multi-Fila: `SYS_REFCURSOR`
Cualquier procedimiento o función de consulta multi-registro debe retornar un `SYS_REFCURSOR`:
```sql
FUNCTION f_buscar_citas (
    p_id_profesional IN NUMBER,
    p_fecha          IN DATE
) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
        SELECT id_cita, id_paciente, fecha_hora, estado
          FROM tkr_citas
         WHERE id_profesional = p_id_profesional
           AND TRUNC(fecha_hora) = TRUNC(p_fecha);
    RETURN v_cursor;
END f_buscar_citas;
```

### 9.2 Generación Nativa de JSON (APIs / Frontends / APEX / Node)
Cuando el consumidor requiera JSON, se debe generar **directamente en el motor Oracle** con funciones SQL/JSON nativas y cláusula `RETURNING CLOB`.
> [!WARNING]
> Queda **terminantemente prohibida** la concatenación manual de cadenas para formar JSON (e.g. `'{ "id": ' || id || '}'`).

```sql
-- Objeto individual
SELECT JSON_OBJECT(
           'id' VALUE id,
           'nombre' VALUE nombre,
           'estado' VALUE estado
           RETURNING CLOB
       )
  INTO p_json_clob
  FROM tkr_usuarios
 WHERE id = p_id;

-- Colección de objetos (Array)
SELECT JSON_ARRAYAGG(
           JSON_OBJECT(
               'id' VALUE u.id,
               'nombre' VALUE u.nombre,
               'correo' VALUE u.correo
               RETURNING CLOB
           )
           RETURNING CLOB
       )
  INTO p_json_clob
  FROM tkr_usuarios u
 WHERE u.estado = 1;
```

---

## 10. Nomenclatura de Subprogramas, Parámetros y Variables

### 10.1 Subprogramas (Procedimientos y Funciones)
> [!IMPORTANT]
> **Regla Innegociable de Prefijos de Subprogramas:**
> * **TODO PROCEDIMIENTO NUEVO** debe empezar obligatoriamente con el prefijo **`p_`** (tanto en paquetes DAO como en `pkgca_`, `pkgcn_` y `pkgln_`).
> * **TODA FUNCIÓN NUEVA** debe empezar obligatoriamente con el prefijo **`f_`** (tanto en paquetes DAO como en `pkgca_`, `pkgcn_` y `pkgln_`).
> * Queda terminantemente prohibido el uso de prefijos alternativos como `pr_`, `fn_`, `sp_`, `func_` o subprogramas sin prefijo tipado.

| Tipo de Subprograma | Prefijo Obligatorio | Ejemplos Permitidos | Prohibido |
| :--- | :--- | :--- | :--- |
| **Procedimientos** | **`p_`** | `p_insertar`, `p_actualizar`, `p_eliminar`, `p_confirmar_orden`, `p_crear_usuario`, `p_actualizar_estado` | `pr_confirmar`, `sp_crear`, `crear_usuario` |
| **Funciones** | **`f_`** | `f_traer`, `f_existe`, `f_json`, `f_buscar_citas`, `f_calcular_total`, `f_validar_token` | `fn_buscar`, `fun_calcular`, `calcular_total` |

### 10.2 Convención Estricta de Variables y Parámetros
Queda terminantemente prohibido el uso de nombres de variables o parámetros sin prefijo tipado. Todo objeto PL/SQL debe respetar obligatoriamente la siguiente tabla:

| Categoría de Dato | Variable Local (Declaración interna) | Parámetro Formal (Firma de Subprograma) | Ejemplos |
| :--- | :--- | :--- | :--- |
| **Escalares / Simples** (`NUMBER`, `VARCHAR2`, `DATE`, `BOOLEAN`, etc.) | **`v_`** | **`p_`** | Local: `v_id`, `v_contador`, `v_nombre`, `v_estado`<br>Parámetro: `p_id`, `p_codigo`, `p_fecha`, `p_tipo` |
| **Registros** (`%ROWTYPE`, `RECORD`) | **`vro_`** | **`pro_`** | Local: `vro_usuario`, `vro_error`, `vro_core_tenants`<br>Parámetro: `pro_usuario`, `pro_core_tenants` |
| **Tablas PL / Colecciones** (`TABLE OF ... INDEX BY`) | **`vta_`** | **`pta_`** | Local: `vta_usuarios`, `vta_detalles`<br>Parámetro: `pta_usuarios`, `pta_core_tenants` |
| **Endpoints Frontend / APIs (CLOB JSON)** | N/A | **`p_json_entrada`** (IN CLOB)<br>**`p_json_salida`** (OUT CLOB) | Parámetros obligatorios de firma en orquestadores `pkgln_` |

---

## 11. Regla de Parámetros CLOB para Procesos Invocados desde Frontend / APIs

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

## 12. Documentación Obligatoria y Registro de Control de Cambios en `.pks`

En la especificación de todo paquete (`.pks`), **antes de cada objeto (procedimiento o función)**, debe ubicarse un bloque de documentación estructurado.
Es requisito obligatorio **documentar en detalle la estructura (schema) y un ejemplo completo del JSON de entrada (`p_json_entrada`) como del JSON de salida (`p_json_salida`)**. Asimismo, cuando se realice cualquier modificación o ajuste de funcionalidad, **debe agregarse un registro por fecha en el historial de cambios**.

### Estructura del Bloque de Documentación en `.pks`:
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

## 13. Lista de Chequeo Arquitectónica Obligatoria (Pre-entrega)

Antes de entregar cualquier código, el agente debe auto-verificar:
- [ ] **Clasificación**: ¿El código está en el paquete correcto (`_DAO`, `pkgca_`, `pkgcn_`, `pkgln_`) según su responsabilidad?
- [ ] **Nombre DAO**: ¿Cumple con la sintaxis exacta `PKG<TABLA>_DAO`?
- [ ] **Plantilla DAO**: ¿Mantiene los nombres y firmas de los 18 métodos oficiales sin inventar variaciones?
- [ ] **Prefijos de Subprogramas**: ¿Todo procedimiento empieza por `p_` y toda función empieza por `f_` (prohibido `pr_`, `fn_`)?
- [ ] **Nomenclatura Variables Locales**: ¿Toda variable local escalar empieza por `v_`?
- [ ] **Nomenclatura Parámetros**: ¿Todo parámetro formal escalar empieza por `p_`?
- [ ] **Registros Locales y Parámetros**: ¿Los registros usan `vro_` (locales) y `pro_` (parámetros)?
- [ ] **Tablas PL Locales y Parámetros**: ¿Las tablas PL usan `vta_` (locales) y `pta_` (parámetros)?
- [ ] **Procesos Frontend CLOB**: ¿Los endpoints del frontend residen en `pkgln_` con `p_json_entrada` (IN) y `p_json_salida` (OUT)?
- [ ] **Validación de Trazabilidad**: ¿El objeto `pkgln_` valida si tiene seguimiento habilitado en `core_trazas_config` y realiza su registro en `core_trazas_ejecucion`?
- [ ] **Documentación de Esquemas y Ejemplos JSON en `.pks`**: ¿El bloque en `.pks` documenta el schema y ejemplos reales tanto del JSON de entrada como del JSON de salida?
- [ ] **Documentación y Control de Cambios**: ¿Existe el bloque de documentación antes de cada objeto con fecha, autor y descripción de cambios?
- [ ] **Transaccionalidad en Orquestador**: ¿Se invocó `p_do_commit('<paquete>.<subprograma>')` únicamente en `pkgln_` y nunca en `pkgcn_` ni DAO?
- [ ] **Sin COMMITs espurios**: ¿Los DAOs y subprogramas de bajo nivel se abstienen de hacer COMMIT o p_do_commit?
- [ ] **Trazabilidad de Errores**: ¿Se asignaron `nombre_programa`, `nombre_metodo` y `parametros` en `vro_error`?
- [ ] **Log Autónomo**: ¿Se usó `uti_ge_excepciones_pkg.p_grabar_log(vro_error)`?
- [ ] **Error al Cliente**: ¿Se utilizó `RAISE_APPLICATION_ERROR(-20000, '... Número error: ' || vro_error.id || ' - ' || SQLERRM);`?
- [ ] **Multi-fila**: ¿Se utilizó `SYS_REFCURSOR`?
- [ ] **JSON Nativo**: ¿Se utilizó `JSON_OBJECT` / `JSON_ARRAYAGG` con `RETURNING CLOB` sin concatenaciones manuales?

---

## 14. Formato Estándar de Respuesta al Usuario

Al responder solicitudes de desarrollo PL/SQL, estructurar la salida en este orden:
1. **Clasificación arquitectónica:** (e.g. `pkgln_citas` para orquestador o `pkgcn_citas_pacientes` para DML multi-tabla)
2. **Justificación breve:** Explicación técnica de por qué pertenece a esa categoría.
3. **Package Specification:** Código `.pks` (con encabezados de documentación y tabla de control de cambios por fecha).
4. **Package Body:** Código `.pkb` (con prefijos `v_`, `p_`, `vro_`, `pro_`, `vta_`, `pta_`).
5. **Consideraciones técnicas y transaccionales**
6. **Validación contra el estándar arquitectónico**

