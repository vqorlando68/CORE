# Estándar de Manejo de Excepciones y Logging Centralizado

## 1. Clasificación de Excepciones

### A. Excepciones de Negocio Conocidas
- Se producen por violaciones a reglas de dominio (saldo insuficiente, cita fuera de horario, usuario inactivo).
- **Rango de Código**: `-20001` a `-20999`.
- **Mensaje**: Explicativo para el usuario o sistema llamador, en español claro.
- **Acción**: Lanzar inmediatamente con `RAISE_APPLICATION_ERROR`. No requieren registrarse como fallos del sistema a menos que la auditoría funcional lo exija explícitamente.

### B. Errores Inesperados del Sistema (`WHEN OTHERS`)
- Excepciones técnicas (fallos de conexión, desbordamiento numérico, violación inesperada de restricciones, nulos imprevistos).
- **Tratamiento**:
  1. `ROLLBACK;` (inmediato para deshacer cambios pendientes en `pkgcn_`).
  2. Poblar metadatos en `vro_error tkr_errores%ROWTYPE;`.
  3. Invocar `uti_ge_excepciones_pkg.p_grabar_log(vro_error);`.
  4. Lanzar `RAISE_APPLICATION_ERROR(-20000, 'Se presento un error comunicarse con soporte. Número error: ' || vro_error.id || ' - ' || SQLERRM);`.

## 2. Estructura de `TKR_ERRORES` y Registro Autónomo

El procedimiento `uti_ge_excepciones_pkg.p_grabar_log` utiliza internamente `PRAGMA AUTONOMOUS_TRANSACTION`. Esto garantiza que:
- El registro de la tabla `TKR_ERRORES` se persiste con su propio `COMMIT` independiente.
- El `ROLLBACK` de la transacción principal en `pkgcn_` no afecta la persistencia del log de error.
- El campo `vro_error.id` queda poblado con el identificador único de error generado para ser retornado al cliente.

## 3. Llenado de Campos en `vro_error`

| Campo | Requisito | Ejemplo |
|---|---|---|
| `nombre_programa` | Nombre literal del paquete PL/SQL. Prohibido usar comodines genéricos. | `'pkgcn_citas'` |
| `nombre_metodo` | Nombre literal del procedimiento o función que falló. | `'pr_confirmar_cita'` |
| `parametros` | Parámetros de entrada formateados y legibles con `CHR(10)`. En CLOBs grandes, proteger contra desbordamientos con `SUBSTR`. | `'p_id_cita: ' \|\| p_id_cita \|\| CHR(10) \|\| 'p_json: ' \|\| ...` |

## 4. Antipatrones Prohibidos
1. `WHEN OTHERS THEN NULL;` $\rightarrow$ Destruye la trazabilidad.
2. `WHEN OTHERS THEN ROLLBACK; RAISE;` sin invocar `uti_ge_excepciones_pkg.p_grabar_log`.
3. `INSERT INTO TKR_ERRORES ...` manual $\rightarrow$ Rompe el estándar de auditoría y la secuencia de IDs.
4. Ocultar el error o alterar el texto de `SQLERRM` en el log interno.
