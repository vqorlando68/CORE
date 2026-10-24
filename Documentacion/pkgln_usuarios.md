# Diagrama y Flujo de Información: PKGLN_USUARIOS

## Método: p_procesar_usuario
### 1. Descripción en Lenguaje Natural
Gestiona la creación o actualización atómica de usuarios de la plataforma garantizando consistencia relacional y auditoría:
- Resuelve el enrolamiento de colaboradores validando previamente existencia de persona y roles asignados.
- Disparado por el API Gateway o Portal Administrativo mediante token institucional.
- Retorna código 0 con ID y código de traza si es exitoso, o código negativo estructurado en caso de fallo.

### 2. Decisiones y Bifurcaciones Lógicas
- **Decisión 1 [Validación de Entrada]**: Si el payload viene nulo o no contiene correo electrónico, se retorna de inmediato con código -20001; Salida inmediata con error de validación
- **Decisión 2 [Evaluación de Trazabilidad]**: Si uti_manejo_trazas_pkg.f_debe_trazar retorna TRUE; Registra inicio de traza en core_traza_ejecucion
- **Decisión 3 [Existencia de Persona]**: Si PKGCORE_PERSONA_DAO.f_existe retorna 0; Se inserta nueva persona mediante PKGCORE_PERSONA_DAO.p_insertar
- **Decisión 4 [Validación de Usuario Duplicado]**: Si PKGCORE_USUARIO_DAO.f_existe retorna 1; Se interrumpe el flujo y retorna código -20002
- **Decisión 5 [Asignación de Roles]**: Si el array roles viene poblado; Se invocan inserciones multi-tabla con pkgcn_usuarios.p_asignar_roles
- **Decisión 6 [Transacción Exitosa]**: Confirma cambios de manera controlada invocando p_do_commit; Notifica éxito y finaliza telemetría

### 3. Mapa de Objetos Invocados y Llamados
| Orden | Nombre Exacto del Objeto Invocado | Capa / Familia | Tipo | Propósito de la Invocación | Condición / Momento |
| :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | `uti_manejo_trazas_pkg.f_debe_trazar` | `uti_` | Función | Determinar si el método tiene telemetría activa | Al inicio del proceso |
| 2 | `uti_manejo_trazas_pkg.p_iniciar_traza` | `uti_` | Procedimiento | Registrar cabecera en core_traza_ejecucion | Si f_debe_trazar = TRUE |
| 3 | `PKGCORE_PERSONA_DAO.f_existe` | `DAO` | Función | Comprobar si la persona ya está registrada | Previo a insertar persona |
| 4 | `PKGCORE_PERSONA_DAO.p_insertar` | `DAO` | Procedimiento | Insertar datos básicos de la persona | Si no existe persona previa |
| 5 | `PKGCORE_USUARIO_DAO.f_existe` | `DAO` | Función | Verificar duplicidad de nombre de usuario | Previo a insertar usuario |
| 6 | `PKGCORE_USUARIO_DAO.p_insertar` | `DAO` | Procedimiento | Persistir credenciales y usuario | Si usuario es nuevo |
| 7 | `pkgcn_usuarios.p_asignar_roles` | `pkgcn_` | Procedimiento | Desglosar array JSON_TABLE e insertar roles | Si incluye roles en el payload |
| 8 | `p_do_commit` | `Transaccional` | Procedimiento | Confirmar cambios de forma controlada | Éxito sin excepciones |
| 9 | `uti_manejo_trazas_pkg.p_finalizar_traza` | `uti_` | Procedimiento | Registrar cierre de telemetría exitosa | Éxito antes de responder |
| 10 | `uti_ge_excepciones_pkg.p_grabar_log` | `uti_` | Procedimiento | Registro forense autónomo en core_error | Bloque WHEN OTHERS |

```json
{
  "id_tenant": 1,
  "id_usuario_ejecutor": 105,
  "datos": {
    "nombre_usuario": "jdoe_core",
    "correo_electronico": "jdoe@empresa.com",
    "primer_nombre": "John",
    "primer_apellido": "Doe"
  }
}
```

```json
{
  "codigo": 0,
  "mensaje": "Usuario procesado exitosamente",
  "datos": {
    "id": 1289,
    "codigo_traza": "TRZ-20261024-9981"
  }
}
```
