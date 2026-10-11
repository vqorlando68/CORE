# Árbol de Decisión y Matriz de Responsabilidades

Antes de crear, modificar o proponer un subprograma o paquete PL/SQL en Oracle, se debe seguir rigurosamente este flujo:

```
                          ¿Requiere acceso a datos (tablas relacionales)?
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
                 NO                                               SÍ
                  │                                               │
      ┌───────────────────────┐                    ┌──────────────────────────────┐
      │        pkgln_         │                    │ ¿Es operación directa CRUD   │
      │   Lógica funcional    │                    │ sobre una tabla por PK/ROWID?│
      │   Cálculos puros      │                    └──────────────┬───────────────┘
      │   Algoritmos dominio  │                                   │
      └───────────────────────┘                   ┌───────────────┴───────────────┐
                                                  ▼                               ▼
                                                 SÍ                               NO
                                                  │                               │
                                      ┌───────────────────────┐     ┌───────────────────────────┐
                                      │    pkg<tabla>_dao     │     │ ¿Es consulta/DML masivo o │
                                      │   Plantilla oficial   │     │ por filtros sin PK única? │
                                      │   Un DAO por tabla    │     └─────────────┬─────────────┘
                                      └───────────────────────┘                   │
                                                                  ┌───────────────┴───────────────┐
                                                                  ▼                               ▼
                                                                 SÍ                               NO
                                                                  │                               │
                                                      ┌───────────────────────┐     ┌───────────────────────────┐
                                                      │        pkgca_         │     │ ¿Es un proceso de negocio │
                                                      │ Consultas multi-fila  │     │ multi-tabla o atómico?    │
                                                      │ (SYS_REFCURSOR), DML  │     └─────────────┬─────────────┘
                                                      │ masivo sin PK         │                   │
                                                      └───────────────────────┘                   ▼
                                                                                                 SÍ
                                                                                    ┌───────────────────────────┐
                                                                                    │          pkgcn_           │
                                                                                    │ Orquestador de negocio    │
                                                                                    │ Control de transacción    │
                                                                                    │ (COMMIT / ROLLBACK / Log) │
                                                                                    └───────────────────────────┘
```

## Matriz Comparativa

| Pregunta Clave | DAO | pkgca_ | pkgcn_ | pkgln_ |
|---|---|---|---|---|
| ¿Accede directamente a una tabla por su PK/ROWID? | **SÍ (Exclusivo)** | NO | NO (Vía DAO/pkgca) | NO |
| ¿Realiza búsquedas con filtros, fechas o estados? | NO | **SÍ** | NO (Vía pkgca) | NO |
| ¿Retorna `SYS_REFCURSOR`? | Raro (Usa tipos DAO) | **SÍ (Estándar)** | Sí (si delega API) | NO |
| ¿Puede ejecutar `COMMIT` o `ROLLBACK`? | **NUNCA** | **NUNCA** | **OBLIGATORIO** | **NUNCA** |
| ¿Valida reglas complejas de negocio entre entidades? | **NUNCA** | **NUNCA** | **SÍ** | NO |
| ¿Genera algoritmos matemáticos o de fechas sin SQL? | NO | NO | NO (Vía pkgln) | **SÍ** |
| ¿Usa `uti_ge_excepciones_pkg.p_grabar_log`? | Solo si captura | Solo si es batch | **SÍ (Siempre)** | **SÍ (Siempre)** |
