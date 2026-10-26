# Diagrama y Flujo de Información: PKGLN_ATENCION_MEDICA

## Método: p_registrar_atencion
### 1. Descripción en Lenguaje Natural
Coordina el registro integral, clínico y administrativo de una atención médica en el sistema de salud SaaS multi-inquilino:
- Valida la integridad estructural del payload, la vigencia del token de sesión y la concurrencia de la agenda profesional.
- Disparado desde el Portal Médico o API Gateway de Admisiones tras la recepción del paciente en consultorio.
- Orquesta la creación o enlace de la persona, generación del episodio clínico, desglose de diagnósticos (CIE-10) y prescripciones farmacológicas en una única transacción atómica gobernada por `p_do_commit`.
- Retorna código 0 con los identificadores del episodio clínico y código de traza APM, o código negativo estructurado en caso de validación fallida o excepción forense.

### 2. Decisiones y Bifurcaciones Lógicas
- **Decisión 1 [Validación de Entrada]** [Línea 42]: Si el payload viene nulo o no contiene id_paciente ni fecha_atencion; Salida inmediata con código -20001 por datos obligatorios ausentes
- **Decisión 2 [Evaluación de Telemetría APM]** [Línea 58]: Si `uti_manejo_trazas_pkg.f_debe_trazar` retorna TRUE; Registra inicio de traza en core_traza_ejecucion
- **Paso 03 [Inicio de Traza Activa]** [Línea 64]: Invoca `uti_manejo_trazas_pkg.p_iniciar_traza` para registrar la cabecera de ejecución y telemetría
- **Decisión 4 [Comprobación de Persona / Paciente]** [Línea 75]: Si `PKGCORE_PERSONA_DAO.f_existe` retorna 0; Se inserta nueva persona mediante `PKGCORE_PERSONA_DAO.p_insertar` y vuelve al flujo principal
- **Decisión 5 [Disponibilidad de Turno Profesional]** [Línea 92]: Si `pkgca_core_horario_profesional.f_consultar_disponibilidad` retorna 0; Se interrumpe el flujo y retorna código -20002 por turno no disponible o bloqueado
- **Paso 06 [Creación de Atención Principal]** [Línea 110]: Persiste la cabecera de la atención médica invocando el DAO unitario `PKGCORE_ATENCION_MEDICA_DAO.p_insertar`
- **Decisión 7 [Registro de Diagnósticos Secundarios]** [Línea 128]: Si el array diagnosticos viene poblado en el payload; Invoca procesamiento relacional multi-tabla con `pkgcn_atencion_medica.p_procesar_diagnosticos` y reintegra al flujo
- **Decisión 8 [Emisión de Receta Farmacológica]** [Línea 145]: Si el array medicamentos contiene prescripciones activas; Coordina inserción atómica de recetas con `pkgcn_atencion_medica.p_emitir_receta` y vuelve al flujo principal
- **Decisión 9 [Comprobación de Cobertura Aseguradora]** [Línea 162]: Si requiere validación con aseguradora externa; Evalúa convenios institucionales con `pkgca_core_convenio_aseguradora.f_validar_cobertura`
- **Paso 10 [Confirmación Atómica Transaccional]** [Línea 178]: Confirma todos los cambios en la base de datos de manera controlada invocando `p_do_commit`
- **Paso 11 [Cierre Exitoso de Telemetría]** [Línea 184]: Finaliza el ciclo de vida de la traza invocando `uti_manejo_trazas_pkg.p_finalizar_traza` antes de retornar respuesta exitosa

### 3. Mapa de Objetos Invocados y Llamados
| Orden | Nombre Exacto del Objeto Invocado | Capa / Familia | Tipo | Propósito de la Invocación | Condición / Momento |
| :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | `uti_manejo_trazas_pkg.f_debe_trazar` | `uti_` | Función | Comprobar si el método y tenant tienen perfilado activo en core_traza_config | Al inicio del procedimiento |
| 2 | `uti_manejo_trazas_pkg.p_iniciar_traza` | `uti_` | Procedimiento | Registrar cabecera en core_traza_ejecucion con payload inicial | Si f_debe_trazar = TRUE |
| 3 | `PKGCORE_PERSONA_DAO.f_existe` | `DAO` | Función | Verificar existencia previa de la persona en el tenant actual | Previo a validar paciente |
| 4 | `PKGCORE_PERSONA_DAO.p_insertar` | `DAO` | Procedimiento | Insertar datos demográficos y básicos de la nueva persona | Si f_existe = 0 (Persona nueva) |
| 5 | `pkgca_core_horario_profesional.f_consultar_disponibilidad` | `pkgca_` | Función | Validar mono-tabla si el horario y consultorio del profesional están libres | Antes de crear la cita/atención |
| 6 | `PKGCORE_ATENCION_MEDICA_DAO.p_insertar` | `DAO` | Procedimiento | Persistir registro principal en core_atencion_medica | Superadas las validaciones previas |
| 7 | `pkgcn_atencion_medica.p_procesar_diagnosticos` | `pkgcn_` | Procedimiento | Desestructurar array JSON_TABLE e insertar diagnósticos vinculados CIE-10 | Si array diagnosticos tiene elementos |
| 8 | `pkgcn_atencion_medica.p_emitir_receta` | `pkgcn_` | Procedimiento | Coordinar inserción de cabecera y detalle farmacológico multi-tabla | Si incluye medicamentos prescritos |
| 9 | `pkgca_core_convenio_aseguradora.f_validar_cobertura` | `pkgca_` | Función | Consultar mono-tabla reglas arancelarias de la aseguradora | Si la atención tiene cobertura médica |
| 10 | `p_do_commit` | `Transaccional` | Procedimiento | Confirmar de forma atómica y centralizada todas las operaciones DML | Finalización exitosa sin fallos |
| 11 | `uti_manejo_trazas_pkg.p_finalizar_traza` | `uti_` | Procedimiento | Registrar hora de finalización, duración en ms y payload de salida | Posterior al commit exitoso |
| 12 | `uti_manejo_trazas_pkg.p_finalizar_traza_error` | `uti_` | Procedimiento | Actualizar traza con estado ERROR, SQLCODE y SQLERRM | Bloque WHEN OTHERS tras ROLLBACK |
| 13 | `uti_ge_excepciones_pkg.p_grabar_log` | `uti_` | Procedimiento | Registro forense autónomo en core_error con backtrace y call-stack | Bloque WHEN OTHERS |

```json
{
  "id_tenant": 1,
  "id_usuario_ejecutor": 105,
  "codigo_traza": "TRZ-ATN-20261026-0042",
  "datos": {
    "id_paciente": 4520,
    "id_profesional": 810,
    "id_especialidad": 12,
    "fecha_atencion": "2026-10-26",
    "hora_inicio": "09:30",
    "motivo_consulta": "Control periódico post-operatorio y evaluación de tensión arterial.",
    "diagnosticos": [
      {
        "codigo_cie10": "I10",
        "descripcion": "Hipertensión esencial (primaria)",
        "tipo_diagnostico": "PRINCIPAL"
      },
      {
        "codigo_cie10": "E11.9",
        "descripcion": "Diabetes mellitus tipo 2 sin mención de complicación",
        "tipo_diagnostico": "SECUNDARIO"
      }
    ],
    "medicamentos": [
      {
        "id_medicamento": 302,
        "dosis": "1 tableta cada 24 horas",
        "duracion_dias": 30
      }
    ]
  }
}
```

```json
{
  "codigo": 0,
  "mensaje": "Atención médica registrada exitosamente",
  "datos": {
    "id_atencion": 78912,
    "id_paciente": 4520,
    "numero_folio": "FOL-2026-00918",
    "codigo_traza": "TRZ-ATN-20261026-0042",
    "fecha_registro": "2026-10-26"
  }
}
```

---

## Método: p_anular_atencion
### 1. Descripción en Lenguaje Natural
Permite la anulación administrativa o médica justificada de un episodio de atención previamente registrado:
- Comprueba que la atención exista en el tenant activo y pertenezca al usuario auditor o profesional facultado.
- Disparado por la Jefatura de Enfermería o Auditoría Médica desde el Portal de Gestión.
- Realiza el bloqueo transaccional de la fila (`SELECT FOR UPDATE`), revoca recetas asociadas y audita el motivo obligatorio de anulación.
- Finaliza ejecutando `p_do_commit` o retorna código de negocio negativo si la atención ya fue facturada o cerrada.

### 2. Decisiones y Bifurcaciones Lógicas
- **Decisión 1 [Validación de Entrada y Motivo]** [Línea 215]: Si el payload no contiene id_atencion o el motivo_anulacion tiene menos de 10 caracteres; Salida inmediata con código -20001 por datos o justificación ausente
- **Decisión 2 [Evaluación de Trazabilidad]** [Línea 228]: Si `uti_manejo_trazas_pkg.f_debe_trazar` retorna TRUE; Registra inicio de traza en core_traza_ejecucion
- **Paso 03 [Apertura de Traza]** [Línea 234]: Invoca `uti_manejo_trazas_pkg.p_iniciar_traza` para auditoría y seguimiento
- **Decisión 4 [Existencia de la Atención]** [Línea 245]: Si `PKGCORE_ATENCION_MEDICA_DAO.f_existe` retorna 0; Se interrumpe el flujo y retorna código -20003 por atención no encontrada
- **Decisión 5 [Estado de Facturación]** [Línea 260]: Si la atención ya posee liquidación o factura emitida; Salida inmediata con código -20004 por impedimento de anulación en atención liquidada
- **Paso 06 [Actualización de Estado a Anulado]** [Línea 276]: Actualiza estado a ANULADO invocando el DAO unitario `PKGCORE_ATENCION_MEDICA_DAO.p_actualizar`
- **Decisión 7 [Revocación de Recetas Asociadas]** [Línea 290]: Si existen recetas emitidas asociadas a la atención; Invoca revocación coordinada mediante `pkgcn_atencion_medica.p_revocar_recetas` y vuelve al flujo principal
- **Paso 08 [Confirmación Transaccional]** [Línea 305]: Ejecuta confirmación atómica invocando `p_do_commit`
- **Paso 09 [Finalización de Traza]** [Línea 312]: Cierra la traza exitosa mediante `uti_manejo_trazas_pkg.p_finalizar_traza`

### 3. Mapa de Objetos Invocados y Llamados
| Orden | Nombre Exacto del Objeto Invocado | Capa / Familia | Tipo | Propósito de la Invocación | Condición / Momento |
| :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | `uti_manejo_trazas_pkg.f_debe_trazar` | `uti_` | Función | Evaluar si la anulación requiere seguimiento en telemetría | Al inicio del procedimiento |
| 2 | `uti_manejo_trazas_pkg.p_iniciar_traza` | `uti_` | Procedimiento | Registrar cabecera de auditoría en core_traza_ejecucion | Si f_debe_trazar = TRUE |
| 3 | `PKGCORE_ATENCION_MEDICA_DAO.f_existe` | `DAO` | Función | Verificar existencia de la atención en el tenant | Previo a evaluar bloqueo |
| 4 | `PKGCORE_ATENCION_MEDICA_DAO.f_traer` | `DAO` | Función | Obtener estado actual y datos de facturación de la atención | Antes de anular |
| 5 | `PKGCORE_ATENCION_MEDICA_DAO.p_actualizar` | `DAO` | Procedimiento | Modificar estado_registro a ANULADO y registrar auditoría | Si pasa validaciones de facturación |
| 6 | `pkgcn_atencion_medica.p_revocar_recetas` | `pkgcn_` | Procedimiento | Actualizar masivamente estados de prescripciones a REVOCADO | Si la atención generó recetas previas |
| 7 | `p_do_commit` | `Transaccional` | Procedimiento | Confirmar la anulación de manera atómica | Operación completada sin excepciones |
| 8 | `uti_manejo_trazas_pkg.p_finalizar_traza` | `uti_` | Procedimiento | Registrar cierre de telemetría exitosa | Éxito antes de emitir respuesta |
| 9 | `uti_manejo_trazas_pkg.p_finalizar_traza_error` | `uti_` | Procedimiento | Actualizar traza con estado ERROR y SQLCODE | Bloque WHEN OTHERS tras ROLLBACK |
| 10 | `uti_ge_excepciones_pkg.p_grabar_log` | `uti_` | Procedimiento | Registro forense autónomo del incidente en core_error | Bloque WHEN OTHERS |

```json
{
  "id_tenant": 1,
  "id_usuario_ejecutor": 88,
  "codigo_traza": "TRZ-ANUL-20261026-9901",
  "datos": {
    "id_atencion": 78912,
    "motivo_anulacion": "Registro duplicado por error involuntario del personal de admisión en ventanilla."
  }
}
```

```json
{
  "codigo": 0,
  "mensaje": "Atención médica anulada exitosamente",
  "datos": {
    "id_atencion": 78912,
    "estado": "ANULADO",
    "codigo_traza": "TRZ-ANUL-20261026-9901",
    "fecha_anulacion": "2026-10-26"
  }
}
```
