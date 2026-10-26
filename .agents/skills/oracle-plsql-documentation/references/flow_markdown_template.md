# Plantilla Oficial de Archivo de Documentación Funcional de Flujo

Use esta plantilla para generar el archivo `Documentacion/<nombre_paquete>.md` correspondiente a cualquier paquete `pkgln_<dominio>`.

---

```markdown
# Diagrama y Flujo de Información: <NOMBRE_PAQUETE_EN_MAYUSCULAS>

## Método: <nombre_procedimiento>
### 1. Descripción en Lenguaje Natural
<Explicación funcional completa del subprograma: qué necesidad de negocio cubre, quién o qué componente lo invoca, qué validaciones principales ejecuta de forma global y qué resultado retorna ante el éxito o el fallo>.

### 2. Decisiones y Bifurcaciones Lógicas
- **Decisión 1 [Validación de Entrada]** [Línea 35]: Si el payload viene nulo o ausente de campos obligatorios; Salida inmediata con código -20001 por datos obligatorios ausentes
- **Decisión 2 [Evaluación de Telemetría]** [Línea 48]: Si `uti_manejo_trazas_pkg.f_debe_trazar` retorna TRUE; Registra inicio de traza en core_traza_ejecucion
- **Paso 03 [Apertura de Telemetría]** [Línea 54]: Invoca `uti_manejo_trazas_pkg.p_iniciar_traza` para auditoría y seguimiento
- **Decisión 4 [Existencia de Entidad Previa]** [Línea 65]: Si `PKGCORE_<ENTIDAD>_DAO.f_existe` retorna 0; Se inserta nueva entidad con `PKGCORE_<ENTIDAD>_DAO.p_insertar` y vuelve al flujo principal
- **Decisión 5 [Validación Bloqueante de Negocio]** [Línea 82]: Si <condicion_bloqueante>; Se interrumpe el flujo y retorna código -20002 por <motivo_rechazo>
- **Paso 06 [Persistencia Principal]** [Línea 98]: Persiste la entidad cabecera mediante `PKGCORE_<TABLA>_DAO.p_insertar`
- **Decisión 7 [Operación Opcional o Multi-Tabla]** [Línea 115]: Si el payload contiene datos secundarios; Invoca inserciones coordinadas con `pkgcn_<dominio>.<subprograma>` y reintegra al flujo
- **Paso 08 [Confirmación Atómica]** [Línea 130]: Confirma cambios de manera controlada invocando `p_do_commit`
- **Paso 09 [Cierre de Telemetría]** [Línea 136]: Finaliza el ciclo de vida de la traza invocando `uti_manejo_trazas_pkg.p_finalizar_traza`

### 3. Mapa de Objetos Invocados y Llamados
| Orden | Nombre Exacto del Objeto Invocado | Capa / Familia | Tipo | Propósito de la Invocación | Condición / Momento |
| :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | `uti_manejo_trazas_pkg.f_debe_trazar` | `uti_` | Función | Determinar si el método tiene telemetría activa | Al inicio del proceso |
| 2 | `uti_manejo_trazas_pkg.p_iniciar_traza` | `uti_` | Procedimiento | Registrar cabecera en core_traza_ejecucion | Si f_debe_trazar = TRUE |
| 3 | `PKGCORE_<TABLA>_DAO.f_existe` | `DAO` | Función | Comprobar existencia del registro en BD | Previo a ejecutar cambios |
| 4 | `PKGCORE_<TABLA>_DAO.p_insertar` | `DAO` | Procedimiento | Persistir registro unitario en BD | Si la entidad es nueva |
| 5 | `pkgcn_<dominio>.<subprograma>` | `pkgcn_` | Procedimiento | Desglosar arrays JSON_TABLE y coordinar DML multi-tabla | Si incluye colecciones |
| 6 | `p_do_commit` | `Transaccional` | Procedimiento | Confirmar cambios de forma controlada | Éxito sin excepciones |
| 7 | `uti_manejo_trazas_pkg.p_finalizar_traza` | `uti_` | Procedimiento | Registrar cierre de telemetría exitosa | Éxito antes de responder |
| 8 | `uti_manejo_trazas_pkg.p_finalizar_traza_error` | `uti_` | Procedimiento | Cerrar traza registrando código SQLCODE y error | Bloque WHEN OTHERS tras ROLLBACK |
| 9 | `uti_ge_excepciones_pkg.p_grabar_log` | `uti_` | Procedimiento | Registro forense autónomo en core_error | Bloque WHEN OTHERS |

```json
{
  "id_tenant": 1,
  "id_usuario_ejecutor": 105,
  "datos": {
    "campo_1": "Valor de prueba",
    "campo_2": 100
  }
}
```

```json
{
  "codigo": 0,
  "mensaje": "Operación completada exitosamente",
  "datos": {
    "id": 1289,
    "codigo_traza": "TRZ-20261025-001"
  }
}
```
```
