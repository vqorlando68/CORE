# Reglas y Estándares del Proyecto CORE

Este repositorio define el Core Transversal multi-inquilino para la construcción de aplicaciones SaaS sobre Oracle Database 23ai / 26ai.

---

## 1. Skill Activa Obligatoria
* **Skill:** `oracle-plsql-architecture`
* **Ubicación en el proyecto:** [.agents/skills/oracle-plsql-architecture/SKILL.md](file:///c:/Repositorios/CORE/.agents/skills/oracle-plsql-architecture/SKILL.md)
* **Carácter:** Vinculante e innegociable para cualquier desarrollo, modificación, revisión o propuesta de código PL/SQL.

---

## 2. Convenciones de Base de Datos
1. **Prefijo de Tablas y Secuencias:** Todas las tablas de este proyecto llevan el prefijo `core_` (ej. `core_tenant`, `core_usuario`, `core_test_objeto`) y sus secuencias `core_*_seq`.
2. **Nomenclatura Estricta en Singular para Tablas:**
   * **Regla de Singularidad Innegociable:** Todo nombre de tabla debe definirse obligatoriamente en **singular estricto** en idioma español (ej. `core_usuario`, `core_rol`, `core_permiso`, `core_proceso`, `core_archivo`, `core_notificacion`, `core_error`, `core_sesion_activa`, `core_plantilla_variable`, `core_proceso_plantilla`, `core_proceso_destinatario`).
   * **Prohibición del Plural:** Queda **terminantemente prohibido el uso de nombres de tablas en plural** (ej. `core_usuarios`, `core_roles`, `core_permisos`, `core_archivos`, `core_notificaciones`, `core_errores`, `core_procesos`).
   * **Consistencia Relacional y PL/SQL:**
     1. Cada fila o tupla en la base de datos representa conceptualmente una **instancia individual** de la entidad.
     2. Mantiene correspondencia natural 1:1 con las columnas de clave foránea (`id_<entidad>` apuntando a `core_<entidad>(id)`, ej. `id_usuario` -> `core_usuario`, `id_proceso` -> `core_proceso`, `id_plantilla` -> `core_plantilla_notificacion`).
     3. Garantiza coherencia directa en variables de registro (`vro_core_<entidad> core_<entidad>%ROWTYPE`) y en la nomenclatura DAO (`PKGCORE_<ENTIDAD>_DAO`).
3. **Clave Primaria y Multi-Tenancy:** Toda tabla debe tener como primer campo y llave primaria exclusiva el campo `id` de tipo `NUMBER` (`NUMBER(12)`). En las tablas específicas de tenant, la columna `id_tenant` se ubica como segundo campo con su clave foránea `fk_..._tenant` referenciando a `core_tenant(id)`.
4. **Claves Foráneas con Prefijo `id_`:** Toda columna que haga referencia al `id` de otra tabla debe comenzar obligatoriamente con el prefijo **`id_`** seguido del nombre de la entidad referenciada en singular (ej. `id_persona` referenciando a `core_persona`, `id_usuario` a `core_usuario`, `id_aplicacion` a `core_aplicacion`, `id_rol` a `core_rol`, `id_proceso` a `core_proceso`, `id_objeto` a `core_test_objeto`, etc.).
5. **Documentación Obligatoria en Diccionario de Datos:** Todo script DDL debe contener obligatoriamente la documentación técnica mediante sentencias Oracle `COMMENT ON TABLE` para la descripción de la entidad y `COMMENT ON COLUMN` para **cada una de las columnas** de la tabla.
6. **Nomenclatura y Estructura DAO Oficial:**
   * La fórmula exacta es: `PKG` + `<nombre_tabla>` + `_DAO` (ej. `PKGCORE_USUARIO_DAO`, `PKGCORE_ERROR_DAO`, `PKGCORE_TEST_OBJETO_DAO`).
   * Debe implementar obligatoriamente la plantilla oficial de 20 métodos estándar (`p_insertar`, `f_traer`, `p_consultar_registros`, `p_eliminar_rowid`, `p_eliminar`, `p_eliminar_registros`, `f_existe` [3 sobrecargas], `f_existe_rowid` [2 sobrecargas], `p_actualizar` [3 sobrecargas], `p_actualizar_registros`, `p_valores_defecto`, `f_existe_json`, `f_json`, `f_total_paginas`, `f_consultar_paginado`).
   * **Implementación Universal del Body:** La codificación del `BODY` para los 20 métodos definida en la skill `oracle-plsql-architecture` debe aplicarse siempre y sin excepción para todas las tablas de la base de datos.
   * En tablas multi-tenant, todos los métodos que manejen `id_tenant` deben permitirlo como parámetro opcional (`DEFAULT NULL`) y aplicar Enfoque B con `SYS_CONTEXT('CORE_CTX', 'ID_TENANT')`.
   * Prohibido ejecutar `COMMIT` o `ROLLBACK` dentro de paquetes DAO.
7. **Campos Booleanos o Banderas (0 o 1):** Todo campo que represente valores lógicos, activos o booleanos (0 o 1) debe definirse obligatoriamente como tipo numérico **`NUMBER(1)`** con valores por defecto `1` o `0` y su correspondiente restricción `CHECK (<columna> IN (0, 1))`. Queda prohibido el uso de `CHAR(1)` o caracteres de texto para valores booleanos.
8. **Nomenclatura de Columnas en Español:** Todos los nombres de las columnas deben estar redactados en idioma español (ej. `nombre_usuario`, `correo_electronico`, `primer_ingreso`, `ultimo_ingreso`, `estado_registro`, `direccion_ip`, `agente_usuario`, `id_sesion_oracle`, `id_traza`, `hash_token`, `tipo_mime`, etc.), conservando preferiblemente los términos técnicos institucionales **`tenant`** (ej. `id_tenant`, `core_tenant`) y **`oidc`** (ej. `oidc_sub`, `oidc_provider`).
9. **Triggers Before-Insert para Autonumeración (`TRG_BI_<TABLA>`):** Toda tabla con clave primaria numérica basada en secuencia debe implementar su trigger `BEFORE INSERT` con la nomenclatura oficial **`TRG_BI_<NOMBRE_TABLA>`** (ej. `TRG_BI_CORE_USUARIO`). El trigger debe asegurar la asignación del ID si viene nulo:
   ```sql
   IF :new.id IS NULL THEN
       :new.id := core_<tabla>_seq.NEXTVAL;
   END IF;
   ```
10. **Application Context y Aislamiento Automático Multi-Tenant (Enfoque B - DML Blindado):**
   * Es regla institucional obligatoria aplicar el **Enfoque B** mediante el Application Context **`SYS_CONTEXT('CORE_CTX', 'ID_TENANT')`** en **toda sentencia DML** de tablas multi-tenant, haciendo físicamente imposible consultar, modificar o insertar datos ajenos al inquilino activo:
     1. **En Consultas (`SELECT`) y Operaciones por PK (`UPDATE`, `DELETE`):**
        * Los métodos de los paquetes `_DAO` (`PKG<TABLA>_DAO`) y `PKGCA_` deben recibir `p_id_tenant IN <tabla>.id_tenant%TYPE DEFAULT NULL`.
        * Toda cláusula WHERE debe filtrar por el inquilino resolviendo:
          ```sql
          WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')))
          ```
     2. **En Inserciones (`INSERT`):**
        * En el procedimiento `p_insertar` del DAO y en orquestadores, se debe asegurar el tenant antes del insert:
          ```sql
          IF vro_registro.id_tenant IS NULL THEN
              vro_registro.id_tenant := TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT'));
          END IF;
          ```
        * Adicionalmente, el trigger `TRG_BI_<TABLA>` actúa como red de seguridad final asegurando `:new.id_tenant := NVL(:new.id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')));`.
     3. **En Consultas Masivas y Paginadas (`PKGCA_`, `f_consultar_paginado`, `f_total_paginas`):**
        * Siempre aplican el filtro `WHERE id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')))`.
11. **Prohibición Estricta de la Nomenclatura ANSI JOIN en Sentencias SELECT (Sintaxis Tradicional Oracle):**
   * En toda sentencia `SELECT` y consulta SQL de la plataforma queda **terminantemente prohibido el uso de la nomenclatura ANSI JOIN** (`INNER JOIN`, `LEFT JOIN`, `RIGHT JOIN`, `FULL JOIN`, `CROSS JOIN`).
   * **Sintaxis Tradicional Obligatoria:** Todas las consultas multitabla deben estructurarse exclusivamente con la sintaxis tradicional de Oracle:
     1. Las tablas involucradas se declaran separadas por coma en la cláusula **`FROM`** con sus respectivos alias (ej. `FROM core_usuario u, core_persona p`).
     2. Las condiciones de enlace relacional entre entidades se ubican obligatoriamente dentro de la cláusula **`WHERE`** mediante operadores de igualdad (ej. `WHERE p.id = u.id_persona`).
     3. Para uniones externas (Outer Joins equivalentes a `LEFT JOIN` o `RIGHT JOIN`), es mandatorio utilizar el operador tradicional de Oracle **`(+)`** del lado de la tabla que aporta filas opcionales o nulas (ej. `WHERE p.id(+) = u.id_persona`).
     4. Los filtros de negocio y de tenant se combinan secuencialmente con `AND` en el mismo `WHERE` (ej. `AND u.id_tenant = NVL(p_id_tenant, TO_NUMBER(SYS_CONTEXT('CORE_CTX', 'ID_TENANT')))`).

---

## 3. Nomenclatura de Subprogramas (Procedimientos y Funciones)
* **Procedimientos:** Todo procedimiento nuevo debe empezar obligatoriamente por el prefijo **`p_`** (tanto en paquetes DAO como en `pkgca_`, `pkgcn_`, `pkgln_` y `uti_`, ej. `p_insertar`, `p_actualizar`, `p_eliminar`, `p_procesar_usuario`, `p_iniciar_sesion`).
* **Funciones:** Toda función nueva debe empezar obligatoriamente por el prefijo **`f_`** (tanto en paquetes DAO como en `pkgca_`, `pkgcn_`, `pkgln_` y `uti_`, ej. `f_traer`, `f_existe`, `f_json`, `f_buscar_citas`, `f_calcular_total`).
* **Prohibido:** Queda terminantemente prohibido usar prefijos como `pr_`, `fn_`, `sp_`, `func_` o subprogramas sin prefijo tipado.

---

## 4. Nomenclatura Estricta de Variables y Parámetros
Queda terminantemente prohibido el uso de nombres de variables o parámetros sin prefijo tipado. Todo objeto PL/SQL debe respetar obligatoriamente la siguiente convención:

| Ámbito / Tipo de Dato | Variable Local (Declaración interna) | Parámetro Formal (Firma de Subprograma) | Ejemplos |
| :--- | :--- | :--- | :--- |
| **Escalares / Simples** (`NUMBER`, `VARCHAR2`, `DATE`, `BOOLEAN`, etc.) | **`v_`** | **`p_`** | Local: `v_id`, `v_contador`, `v_nombre`<br>Parámetro: `p_id`, `p_codigo`, `p_fecha` |
| **Registros** (`%ROWTYPE`, `RECORD`) | **`vro_`** | **`pro_`** | Local: `vro_usuario`, `vro_error`, `vro_core_tenant`<br>Parámetro: `pro_usuario`, `pro_core_tenant` |
| **Tablas PL / Colecciones** (`TABLE OF ... INDEX BY`) | **`vta_`** | **`pta_`** | Local: `vta_usuarios`, `vta_detalles`<br>Parámetro: `pta_usuarios`, `pta_core_tenant` |
| **Endpoints Frontend / APIs (CLOB JSON)** | N/A | **`p_json_entrada`** (IN CLOB)<br>**`p_json_salida`** (OUT CLOB) | Parámetros obligatorios de firma en orquestadores `pkgln_` |

---

## 5. Regla de Invocación desde el Frontend y Política 'Cero RAISE_APPLICATION_ERROR' (`pkgln_`)
Todo objeto/procedimiento PL/SQL expuesto para ser llamado desde el front-end o API Gateway pertenece obligatoriamente a la capa orquestadora **`pkgln_`** y debe implementar la siguiente firma estándar de 2 parámetros CLOB:

```sql
PROCEDURE p_nombre_operacion (
    p_json_entrada IN  CLOB,
    p_json_salida  OUT CLOB
);
```

* **Nombres Fijos Obligatorios:** Los parámetros deben llamarse exactamente `p_json_entrada` (IN CLOB) y `p_json_salida` (OUT CLOB).
* **Parseo y Generación:** Usar `JSON_OBJECT_T.parse(p_json_entrada)` para lectura y funciones SQL/JSON nativas (`JSON_OBJECT`, `JSON_ARRAYAGG`) con `RETURNING CLOB` para la salida. Queda prohibida la concatenación manual de cadenas para armar JSON.
* **Política de 'Cero RAISE_APPLICATION_ERROR' en `pkgln_`:**
  - Queda **terminantemente prohibido ejecutar `RAISE_APPLICATION_ERROR`** en cualquier procedimiento de la capa orquestadora `pkgln_` o expuesto al frontend.
  - **Errores de Negocio:** Se ejecuta `ROLLBACK;`, se construye el objeto JSON de salida en `p_json_salida` (`codigo` negativo ej. `-20001`, `error: -20001`, `mensaje: '...'`, `datos: null`) y se finaliza con `RETURN;`.
  - **Errores Inesperados (`WHEN OTHERS`):** Tras ejecutar `ROLLBACK;`, registrar el fallo forense en `core_error` con `uti_ge_excepciones_pkg.p_grabar_log(vro_error);` y finalizar la traza con `uti_manejo_trazas_pkg.p_finalizar_traza_error(...)`, se construye en `p_json_salida` un JSON estructurado con `codigo: -20000`, `error: -20000`, `mensaje: 'Se presento un error comunicarse con soporte. Número error: ' || vro_error.id`, `id_error: vro_error.id` y `datos: null`.
* **Validación y Registro Obligatorio de Trazabilidad con `uti_manejo_trazas_pkg`:** Todo subprograma en `pkgln_` debe delegar obligatoriamente la gestión de telemetría en el paquete transversal **`uti_manejo_trazas_pkg`**:
  1. Verificar al inicio mediante `uti_manejo_trazas_pkg.f_debe_trazar(...)` si el objeto tiene profilado activo en `core_traza_config`.
  2. Si está activo, invocar de inmediato `uti_manejo_trazas_pkg.p_iniciar_traza(...)` para registrar la cabecera en `core_traza_ejecucion`.
  3. Al finalizar con éxito la lógica de negocio y posterior a `p_do_commit(...)`, invocar `uti_manejo_trazas_pkg.p_finalizar_traza(...)` para actualizar `core_traza_ejecucion`.
  4. En caso de error inesperado en `WHEN OTHERS`, tras ejecutar `ROLLBACK;`, invocar inmediatamente `uti_manejo_trazas_pkg.p_finalizar_traza_error(...)` antes de persistir el fallo en `core_error`.
* **Control Transaccional Controlado:** Queda **terminantemente prohibido ejecutar `COMMIT;` directo**. Toda confirmación de transacción debe ejecutarse exclusivamente en el orquestador invocando `p_do_commit('<paquete>.<subprograma>');` al completar con éxito todas las operaciones.

---

## 6. Paquetes de Acceso y DML No-PK Mono-Tabla (`pkgca_<nombre_tabla>`)
Los paquetes con prefijo **`pkgca_`** tienen la responsabilidad exclusiva de operaciones sobre **UNA SOLA TABLA FÍSICA**:
* **Nomenclatura Estricta:** `pkgca_<nombre_tabla>` en singular (ej. `pkgca_core_horario_profesional`, `pkgca_core_usuario`).
* **Prohibición Total de Multi-Tabla y JOINs:** Queda **terminantemente prohibido realizar `JOINs`**, vincular tablas secundarias o tocar más de una tabla dentro de un paquete `pkgca_`. Si una consulta o proceso involucra más de una tabla, pertenece obligatoriamente a `pkgcn_<negocio>`.
* **Retorno Multi-fila:** Retorna conjuntos de registros de esa entidad mediante `SYS_REFCURSOR`.
* **Prohibición Transaccional:** Prohibido ejecutar `p_do_commit` o `ROLLBACK`.

---

## 7. Paquetes Multi-Tabla: DML, Consultas Relacionales y Procesamiento JSON (`pkgcn_<negocio>`)
Los paquetes con prefijo **`pkgcn_`** tienen como responsabilidad exclusiva:
1. **Consultas Relacionales Multi-Tabla:** Vistas de negocio, reportes y búsquedas relacionales que requieren combinar dos o más tablas tradicionales con `(+)` en el WHERE.
2. **Sentencias DML Multi-Tabla:** Inserciones, actualizaciones o eliminaciones que coordinan cambios atómicos sobre múltiples tablas del proceso.
3. **Procesamiento y Parsing JSON (`JSON_TABLE`):** Desestructurar arreglos o registros JSON en filas relacionales e interactuar con múltiples tablas.
4. **Prohibición de Commit:** Los paquetes `pkgcn_` no ejecutan `p_do_commit` ni controlan la transacción final; son invocados por los orquestadores `pkgln_`.

---

## 8. Paquetes Utilitarios Transversales (`uti_`)
Los paquetes con prefijo **`uti_`** (generalmente con sufijo `_pkg`, ej. `uti_archivos_pkg`, `uti_validaciones_pkg`, `uti_manejo_trazas_pkg`, `uti_ge_excepciones_pkg`, `uti_paquetes_pkg`) encapsulan rutinas técnicas auxiliares **estrictamente agnósticas al negocio**:
1. **Cero Lógica de Negocio:** No deben contener reglas de dominio, comerciales ni flujos de negocio.
2. **Cero Control Transaccional:** Queda **terminantemente prohibido ejecutar `COMMIT;`, `ROLLBACK;` o `p_do_commit`** dentro de un paquete `uti_` (salvo transacciones autónomas técnicas con `PRAGMA AUTONOMOUS_TRANSACTION`).
3. **Reutilización Transversal:** Pueden ser consumidos libremente por cualquier capa (`pkgln_`, `pkgcn_`, `pkgca_` o DAOs).

---

## 9. Procedimiento Centralizado de Commit Controlado (`p_do_commit`)
Todo commit en la plataforma debe ejecutarse a través de este procedimiento estándar:

```sql
CREATE OR REPLACE PROCEDURE p_do_commit (
    p_contexto IN VARCHAR2 DEFAULT 'General'
) AS
BEGIN
    -- Lógica de control, auditoría o telemetría previa
    DBMS_OUTPUT.PUT_LINE('Ejecutando COMMIT controlado para: ' || p_contexto);
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al ejecutar COMMIT en ' || p_contexto || ': ' || SQLERRM);
        RAISE;
END p_do_commit;
/
```

---

## 10. Estándar Universal e Innegociable de Manejo de Fechas (YYYY-MM-DD)
* Toda fecha que ingrese (`p_json_entrada` o parámetros) o egrese (`p_json_salida`, DAOs, cursores) debe utilizar obligatoriamente el formato ISO **`YYYY-MM-DD`** (ej. `'2026-10-24'`).
* **Entradas:** Convertir con `v_fecha := TO_DATE(TRIM(v_fecha_str), 'YYYY-MM-DD');`. En caso de formato inválido, no lanzar excepción sino devolver error en `p_json_salida` con código `-20005` y finalizar con `RETURN;`.
* **Salidas:** En JSON nativo y `SYS_REFCURSOR`, proyectar explícitamente formateando con `TO_CHAR(columna, 'YYYY-MM-DD')`.

---

## 11. Documentación Obligatoria, Archivo de Flujo Gráfico (`<nombre_paquete>.md`) y Control de Cambios en `.pks`
En la especificación de todo paquete (`.pks`), **antes de cada objeto (procedimiento o función)**, debe ubicarse obligatoriamente un bloque de documentación estructurado.
Es requisito obligatorio **documentar en detalle la estructura (schema) y un ejemplo completo del JSON de entrada (`p_json_entrada`) como del JSON de salida (`p_json_salida`)**. Asimismo, cuando se realice cualquier modificación o ajuste de funcionalidad, **debe agregarse un registro por fecha en el historial de modificaciones**.

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

### Regla Obligatoria: Archivo de Flujo Gráfico por Paquete (`<nombre_paquete>.md`)
Cada vez que se cree o modifique un procedimiento o función dentro de un paquete orquestador `pkgln_<dominio>`, **se debe crear o actualizar obligatoriamente un archivo Markdown con el nombre del paquete: `<nombre_paquete>.md`** (ej: `pkgln_citas.md`, `pkgln_usuarios.md`) que sirve de insumo para graficar interactivamente el árbol de decisiones, flujo funcional en lenguaje natural y la tabla de objetos llamados.

---

## 12. Motor de Pruebas de Objetos (`core_test_*`)
Las pruebas automatizadas de los objetos construidos se registran y auditan en las 7 tablas del motor de pruebas:
* `core_test_objeto`: Catálogo de endpoints PL/SQL y schemas JSON.
* `core_test_suite`: Baterías y suites de pruebas (Smoke, Regresión).
* `core_test_caso`: Escenarios de prueba con payloads `json_entrada` (CLOB) y `json_esperado`.
* `core_test_asercion`: Reglas de aserción sobre `p_json_salida` mediante JSON Path.
* `core_test_ejecucion`: Cabecera histórica de ejecuciones (Test Runs).
* `core_test_detalle_ejecucion`: Registro individual de ejecuciones (CLOB entrada, CLOB salida, tiempos y diffs).
* `core_test_mock_dato`: Scripts SQL de pre-condición y post-limpieza.

---

## 13. Telemetría, APM y Seguimiento de Llamados (`core_traza_*` y `uti_manejo_trazas_pkg`)
El seguimiento y call-stack jerárquico se audita en 4 tablas de observabilidad y se gestiona mediante el paquete transversal **`uti_manejo_trazas_pkg`** (que opera como un paquete de la capa `pkgln_` y provee servicios autónomos a todos los orquestadores):
* `core_traza_config`: Reglas condicionales de activación en caliente (por usuario, rango de tiempo u objeto).
* `core_traza_ejecucion`: Cabecera de invocación raíz (tiempos inicio/fin, duracion_ms, `json_entrada`, `json_salida`, estado).
* `core_traza_llamado`: Detalle secuencial ordenado (`orden_llamado`, `id_llamado_padre` reflexivo, parámetros enviados y recibidos en JSON).
* `core_traza_estadistica`: Consolidado periódico para análisis de latencias y SLAs (percentil P95).
* **`uti_manejo_trazas_pkg`**: Paquete oficial con `f_debe_trazar`, `p_iniciar_traza`, `p_finalizar_traza`, `p_finalizar_traza_error` y endpoints CLOB para el API Gateway.

---

## 14. Seguridad M2M, Sesiones, Gestión Documental y Excepciones Forenses
* `core_sesion_activa`: Control de sesiones activas concurrentes, JWT/token hashing (`hash_token_sesion`), agente de usuario (`agente_usuario`), IP de origen y revocación en tiempo real.
* `core_api_token`: Credenciales de integración Machine-to-Machine con hash seguro (`hash_token` SHA-256/512), límite de peticiones (`limite_peticiones_min`), alcances JSON (`alcances_json`) y revocación.
* `core_archivo`: Repositorio centralizado de metadatos de documentos, adjuntos, reportes e imágenes con hash SHA-256, URL pública/pre-firmada (`url_archivo`) e integración a Object Storage / S3.
* `core_error`: Repositorio institucional y autónomo de fallos e incidentes (reemplazo oficial de `TKR_ERRORES`), registrando `codigo_error`, `mensaje_error`, `traza_error` (`DBMS_UTILITY.FORMAT_ERROR_BACKTRACE`), `pila_llamadas` (`DBMS_UTILITY.FORMAT_CALL_STACK`), `payload_entrada` e `id_traza`, persistido mediante `uti_ge_excepciones_pkg.p_grabar_log`.

---

## 15. Estándares de Frontend y Diseño UI (Tokens y Archivo Único de Tema)
* **Archivo Único de Tema:** Toda definición del estilo visual de la interfaz de usuario (tipografía, fuentes Google Fonts / locales, paleta de colores, gradientes, escalas de espaciado, radios de bordes, sombras y variantes para modo claro y oscuro) **debe quedar almacenada obligatoriamente en un solo archivo con el nombre del tema** (ej. `tema-core.css`, `theme.css`, `tema-default.css` o equivalente según el stack).
* **Consumo Exclusivo por Variables / Tokens:** Queda terminantemente prohibido quemar estilos directos, valores hexadecimales o tipografías dispersas en archivos HTML, plantillas o componentes individuales. Toda regla visual debe consumir las variables CSS (Custom Properties) o tokens semánticos provistos por dicho archivo de tema (ej. `var(--color-fondo)`, `var(--color-primario)`, `var(--fuente-principal)`).
* **Intercambiabilidad e Identidad Multi-Tenant:** La arquitectura visual debe garantizar que el cambio completo de imagen, branding o soporte de temas personalizados por inquilino (`id_tenant`) se realice únicamente sustituyendo o alternando dicho archivo de tema, sin requerir modificaciones en la estructura de marcado ni en la lógica funcional.

---

## 16. Catálogo y Documentación en Lenguaje Natural de Orquestadores (`core_documentacion_metodo`)
Para permitir que herramientas gráficas, frontends administrativos, portales para desarrolladores y analistas de negocio puedan visualizar de manera interactiva la documentación de los métodos de los orquestadores (`pkgln_`), la plataforma dispone de la tabla centralizada **`core_documentacion_metodo`**:
* **Propósito:** Almacenar de forma estructurada y en **lenguaje natural no técnico** la descripción funcional completa de cada procedimiento expuesto en los paquetes `pkgln_`.
* **Contenido Obligatorio por Método:**
  1. **Encabezado y Metadatos:** `nombre_paquete`, `nombre_metodo`, `titulo_funcional`, `resumen_ejecutivo`, `actor_principal` (rol que lo dispara), `version_metodo`.
  2. **Narrativa de Negocio:** `descripcion_negocio` (explicación en lenguaje natural del proceso), `flujo_funcional_pasos` (pasos secuenciales ordenados), `reglas_validacion` (condiciones y validaciones del dominio).
  3. **Especificación de Payloads en Lenguaje Natural:**
     * `descripcion_entrada_natural`: Explicación didáctica de los campos requeridos en `p_json_entrada`.
     * `ejemplo_json_entrada`: Payload de entrada de ejemplo listo para pruebas (con constraint JSON lax).
     * `descripcion_salida_natural`: Explicación de los datos que retorna `p_json_salida`.
     * `ejemplo_json_salida`: Respuesta devuelta de ejemplo (con constraint JSON lax).
     * `excepciones_negocio`: Posibles errores controlados y cómo corregirlos.
  4. **Metadatos Visuales para el Frontend:** `categoria_visual` (SEGURIDAD, OPERATIVO, FACTURACION, etc.), `icono_interfaz` (token de icono Lucide/FontAwesome), `color_distintivo` (color hex para tarjetas), `etiquetas_busqueda` (palabras clave para filtrado rápido).
* **Consistencia:** Toda modificación en la firma o comportamiento de un orquestador `pkgln_` debe reflejarse en su registro correspondiente en `core_documentacion_metodo`.

---

## 17. Generador Automático de Paquetes DAO (`uti_paquetes_pkg`)
Para garantizar la estandarización absoluta y evitar discrepancias manuales de firmas o sintaxis en los 20 métodos oficiales de acceso a datos, se dispone del paquete utilitario **`uti_paquetes_pkg`**:
* **Procedimiento:** `p_crear_dao(p_nombre_tabla IN VARCHAR2 DEFAULT NULL)`
* **Comportamiento:**
  1. Si recibe `p_nombre_tabla`: Genera y compila dinámicamente la especificación (`PKG<TABLA>_DAO.pks`) y el cuerpo (`PKG<TABLA>_DAO.pkb`) de la tabla indicada.
  2. Si `p_nombre_tabla IS NULL`: Itera sobre todas las tablas del esquema (`user_tables WHERE table_name LIKE 'CORE_%'`) y compila automáticamente todos sus paquetes DAO.
  3. Detecta automáticamente si la tabla posee soporte multi-tenant (`id_tenant`) para incorporar el Enfoque B mediante `SYS_CONTEXT('CORE_CTX', 'ID_TENANT')`.
  4. Resuelve la obtención simultánea de `%ROWTYPE` y `ROWID` (evitando los errores `PLS-00494` y `ORA-03056`) mediante consulta optimizada por puntero interno.
