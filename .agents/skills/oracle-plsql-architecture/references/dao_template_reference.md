# Referencia de Plantilla Oficial DAO

Los paquetes DAO (`pkg<tabla>_dao`) constituyen la capa de acceso y persistencia dedicada a una tabla física específica. Cada tabla del modelo relacional debe contar con su correspondiente paquete DAO.

## Convención de Nomenclatura

```text
pkg + <nombre_tabla> + _dao
```

- Tabla: `TKR_USUARIOS` $\rightarrow$ Paquete: `PKGTKR_USUARIOS_DAO`
- Tabla: `TKR_CITAS` $\rightarrow$ Paquete: `PKGTKR_CITAS_DAO`
- Tabla: `TKR_HISTORIAS` $\rightarrow$ Paquete: `PKGTKR_HISTORIAS_DAO`

## Resumen de los 18 Métodos Oficiales

| # | Subprograma | Firma | Propósito |
|---|---|---|---|
| 1 | `p_insertar` | `(pro_tkr_tabla IN tkr_tabla%ROWTYPE)` | Inserta un registro completo mediante `%ROWTYPE`. |
| 2 | `f_traer` | `(pty_id IN tkr_tabla.id%TYPE) RETURN tkr_tabla%ROWTYPE` | Recupera el registro identificado por su Primary Key. |
| 3 | `p_consultar_registros` | `(pta_tkr_tabla OUT pkgtkr_tabla_dao.ta_tkr_tabla)` | Retorna todos los registros en colección asociativa. |
| 4 | `p_eliminar_rowid` | `(p_rowid IN VARCHAR2)` | Elimina el registro referenciado por `ROWID`. |
| 5 | `p_eliminar` | `(pty_id IN tkr_tabla.id%TYPE)` | Elimina el registro por Primary Key. |
| 6 | `p_eliminar_registros`| `()` | Elimina todos los registros de la tabla (Cuidado). |
| 7 | `f_existe` | `(pty_id IN tkr_tabla.id%TYPE) RETURN BOOLEAN` | Verifica si existe registro con la PK. |
| 8 | `f_existe` (Sobrecarga 1) | `(pty_id IN tkr_tabla.id%TYPE, pro_tkr_tabla OUT tkr_tabla%ROWTYPE) RETURN BOOLEAN` | Verifica y devuelve el registro por parámetro `OUT`. |
| 9 | `f_existe` (Sobrecarga 2) | `(pty_id IN tkr_tabla.id%TYPE, pro_tkr_tabla OUT tkr_tabla%ROWTYPE, p_rowid OUT VARCHAR2) RETURN BOOLEAN` | Verifica y devuelve el registro y su `ROWID`. |
| 10| `f_existe_rowid` | `(p_rowid IN VARCHAR2) RETURN BOOLEAN` | Verifica existencia buscando por `ROWID`. |
| 11| `f_existe_rowid` (Sobrecarga) | `(p_rowid IN VARCHAR2, pro_tkr_tabla OUT tkr_tabla%ROWTYPE) RETURN BOOLEAN` | Verifica por `ROWID` y retorna el registro. |
| 12| `p_actualizar` | `(pro_tkr_tabla IN tkr_tabla%ROWTYPE)` | Actualiza usando la PK contenida en el `%ROWTYPE`. |
| 13| `p_actualizar` (Sobrecarga) | `(pro_tkr_tabla IN tkr_tabla%ROWTYPE, pty_id IN tkr_tabla.id%TYPE)` | Actualiza asignando datos y PK explícita. |
| 14| `p_actualizar_rowid` | `(pro_tkr_tabla IN tkr_tabla%ROWTYPE, p_rowid IN VARCHAR2)` | Actualiza el registro ubicado por `ROWID`. |
| 15| `p_actualizar_registros` | `(pro_tkr_tabla IN tkr_tabla%ROWTYPE)` | Actualización masiva de registros. |
| 16| `p_valores_defecto` | `(pro_tkr_tabla IN OUT tkr_tabla%ROWTYPE)` | Completa valores por defecto de la tabla. |
| 17| `f_existe_json` | `(p_id IN tkr_tabla.id%TYPE, p_json_tkr_tabla OUT CLOB) RETURN NUMBER` | Determina si existe (1 o 0) y retorna JSON CLOB. |
| 18| `f_json` | `(p_id IN tkr_tabla.id%TYPE) RETURN VARCHAR2` | Retorna representación JSON por PK (`RETURNING CLOB` si excede). |

## Reglas Innegociables
- **Sin Transacciones**: No colocar `COMMIT` ni `ROLLBACK` en ningún método DAO.
- **Sin Lógica de Negocio**: No validar reglas funcionales ni coordinar múltiples tablas.
- **Propagación de Excepciones**: Los errores de BD (`DUP_VAL_ON_INDEX`, `NO_DATA_FOUND`, etc.) deben fluir naturalmente hacia el orquestador (`pkgcn_`).
