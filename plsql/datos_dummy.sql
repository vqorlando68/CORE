-- ============================================================================
-- PLATAFORMA SAAS MULTI-APLICACIONES — DATOS DUMMY PARA PRUEBAS (SEMILLA)
-- ARCHIVO: datos_dummy.sql
-- REQUISITOS CUMPLIDOS:
-- 1. Mínimo 2 Tenants (ACME Corp y Globex Enterprise)
-- 2. 3 Roles de negocio por Tenant (ADMIN, SUPERVISOR, OPERADOR)
-- 3. 4 Usuarios por cada Rol (12 usuarios por tenant = 24 usuarios totales)
-- 4. Notificaciones y plantillas para CADA TIPO (EMAIL, SMS, WHATSAPP, PUSH_NOTIFICATION)
-- 5. Catálogo de Procesos, asociación a plantillas, destinatarios y variables
-- 6. Parámetros, aplicaciones, contextos y reglas de telemetría
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
WHENEVER SQLERROR CONTINUE;

PROMPT ============================================================================
PROMPT INSERTANDO DATOS DUMMY DE PRUEBA EN LA BASE DE DATOS CORE...
PROMPT ============================================================================

-- ----------------------------------------------------------------------------
-- 1. TENANTS MAESTROS (2 TENANTS)
-- ----------------------------------------------------------------------------
PROMPT 1. Registrando Tenants...

INSERT INTO core_tenant (
    id, codigo, nombre, id_plan, nit_empresa, contacto_correo, contacto_telefono, pais, estado
) VALUES (
    1, 'ACME', 'Acme Global SaaS Corp', 'ENTERPRISE', '900123456-1', 'admin@acme.com', '+57 3001234567', 'CO', 1
);

INSERT INTO core_tenant (
    id, codigo, nombre, id_plan, nit_empresa, contacto_correo, contacto_telefono, pais, estado
) VALUES (
    2, 'GLOBEX', 'Globex Cloud Solutions', 'BUSINESS', '900987654-2', 'contacto@globex.com', '+57 3109876543', 'CO', 1
);

-- ----------------------------------------------------------------------------
-- 2. APLICACIONES Y SUSCRIPCIONES
-- ----------------------------------------------------------------------------
PROMPT 2. Registrando Aplicaciones y Suscripciones...

INSERT INTO core_aplicacion (
    id, codigo, nombre, descripcion, version, estado
) VALUES (
    1, 'CORE_ADMIN', 'Portal Administrativo Core', 'Panel de control de usuarios, seguridad y parametrización', '1.0.0', 'ACTIVA'
);

INSERT INTO core_aplicacion (
    id, codigo, nombre, descripcion, version, estado
) VALUES (
    2, 'SAAS_CRM', 'CRM Omnicanal', 'Gestión de clientes, oportunidades y comunicación', '2.1.0', 'ACTIVA'
);

INSERT INTO core_app_tenant (id, id_tenant, id_aplicacion, habilitada) VALUES (1, 1, 1, 1);
INSERT INTO core_app_tenant (id, id_tenant, id_aplicacion, habilitada) VALUES (2, 1, 2, 1);
INSERT INTO core_app_tenant (id, id_tenant, id_aplicacion, habilitada) VALUES (3, 2, 1, 1);
INSERT INTO core_app_tenant (id, id_tenant, id_aplicacion, habilitada) VALUES (4, 2, 2, 1);

-- ----------------------------------------------------------------------------
-- 3. CONTEXTOS / SUCURSALES POR TENANT
-- ----------------------------------------------------------------------------
PROMPT 3. Registrando Contextos Organizacionales...

INSERT INTO core_contexto (id, id_tenant, tipo, nombre, descripcion, habilitado)
VALUES (1, 1, 'SEDE_PRINCIPAL', 'Sede Principal Bogotá', 'Oficina central ACME', 1);

INSERT INTO core_contexto (id, id_tenant, tipo, nombre, descripcion, habilitado)
VALUES (2, 1, 'SUCURSAL', 'Sucursal Medellín', 'Operaciones Antioquia ACME', 1);

INSERT INTO core_contexto (id, id_tenant, tipo, nombre, descripcion, habilitado)
VALUES (3, 2, 'SEDE_PRINCIPAL', 'Sede Central Cali', 'Oficina central Globex', 1);

INSERT INTO core_contexto (id, id_tenant, tipo, nombre, descripcion, habilitado)
VALUES (4, 2, 'SUCURSAL', 'Sucursal Barranquilla', 'Operaciones Caribe Globex', 1);

-- ----------------------------------------------------------------------------
-- 4. ROLES DE NEGOCIO (3 ROLES POR TENANT)
-- ----------------------------------------------------------------------------
PROMPT 4. Registrando Roles de Seguridad...

-- Roles para Tenant 1 (ACME)
INSERT INTO core_rol (id, id_tenant, codigo, nombre, descripcion, alcance, estado_registro)
VALUES (1, 1, 'ROL_ADMIN', 'Administrador General', 'Control total de configuración, roles y seguridad', 'G', 1);

INSERT INTO core_rol (id, id_tenant, codigo, nombre, descripcion, alcance, estado_registro)
VALUES (2, 1, 'ROL_SUPERVISOR', 'Supervisor Operativo', 'Supervisión de operaciones, auditoría y reportes', 'G', 1);

INSERT INTO core_rol (id, id_tenant, codigo, nombre, descripcion, alcance, estado_registro)
VALUES (3, 1, 'ROL_OPERADOR', 'Operador de Servicios', 'Atención directa y ejecución de transacciones', 'G', 1);

-- Roles para Tenant 2 (GLOBEX)
INSERT INTO core_rol (id, id_tenant, codigo, nombre, descripcion, alcance, estado_registro)
VALUES (4, 2, 'ROL_ADMIN', 'Administrador General', 'Control total de configuración, roles y seguridad', 'G', 1);

INSERT INTO core_rol (id, id_tenant, codigo, nombre, descripcion, alcance, estado_registro)
VALUES (5, 2, 'ROL_SUPERVISOR', 'Supervisor Operativo', 'Supervisión de operaciones, auditoría y reportes', 'G', 1);

INSERT INTO core_rol (id, id_tenant, codigo, nombre, descripcion, alcance, estado_registro)
VALUES (6, 2, 'ROL_OPERADOR', 'Operador de Servicios', 'Atención directa y ejecución de transacciones', 'G', 1);

-- ----------------------------------------------------------------------------
-- 5. PERSONAS Y USUARIOS (4 USUARIOS POR CADA ROL)
-- Total: 12 usuarios para Tenant 1 + 12 usuarios para Tenant 2 = 24 Usuarios
-- ----------------------------------------------------------------------------
PROMPT 5. Registrando Personas, Usuarios y Membresías...

-- ==================== TENANT 1 (ACME) ====================
-- ROL_ADMIN (Usuarios 1 a 4)
INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (1, 1, 'N', '101001', 'Carlos Méndez', 'carlos.mendez@acme.com', '+573001000001');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (1, 1, 1, 'admin1_acme', 'carlos.mendez@acme.com', 1);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (1, 1, 1, 1, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (2, 1, 'N', '101002', 'Laura Gómez', 'laura.gomez@acme.com', '+573001000002');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (2, 1, 2, 'admin2_acme', 'laura.gomez@acme.com', 1);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (2, 1, 2, 1, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (3, 1, 'N', '101003', 'Andrés Silva', 'andres.silva@acme.com', '+573001000003');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (3, 1, 3, 'admin3_acme', 'andres.silva@acme.com', 1);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (3, 1, 3, 1, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (4, 1, 'N', '101004', 'Diana Torres', 'diana.torres@acme.com', '+573001000004');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (4, 1, 4, 'admin4_acme', 'diana.torres@acme.com', 1);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (4, 1, 4, 1, DATE '2026-01-01', 1);

-- ROL_SUPERVISOR (Usuarios 5 a 8)
INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (5, 1, 'N', '101005', 'Fernando Ruiz', 'fernando.ruiz@acme.com', '+573001000005');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (5, 1, 5, 'sup1_acme', 'fernando.ruiz@acme.com', 1);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (5, 1, 5, 2, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (6, 1, 'N', '101006', 'Marcela Castro', 'marcela.castro@acme.com', '+573001000006');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (6, 1, 6, 'sup2_acme', 'marcela.castro@acme.com', 1);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (6, 1, 6, 2, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (7, 1, 'N', '101007', 'Camilo Vargas', 'camilo.vargas@acme.com', '+573001000007');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (7, 1, 7, 'sup3_acme', 'camilo.vargas@acme.com', 2);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (7, 1, 7, 2, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (8, 1, 'N', '101008', 'Patricia Herrera', 'patricia.herrera@acme.com', '+573001000008');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (8, 1, 8, 'sup4_acme', 'patricia.herrera@acme.com', 2);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (8, 1, 8, 2, DATE '2026-01-01', 1);

-- ROL_OPERADOR (Usuarios 9 a 12)
INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (9, 1, 'N', '101009', 'Santiago Morales', 'santiago.morales@acme.com', '+573001000009');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (9, 1, 9, 'op1_acme', 'santiago.morales@acme.com', 1);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (9, 1, 9, 3, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (10, 1, 'N', '101010', 'Valentina Ríos', 'valentina.rios@acme.com', '+573001000010');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (10, 1, 1, 'op2_acme', 'valentina.rios@acme.com', 1);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (10, 1, 10, 3, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (11, 1, 'N', '101011', 'Jorge Martínez', 'jorge.martinez@acme.com', '+573001000011');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (11, 1, 11, 'op3_acme', 'jorge.martinez@acme.com', 2);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (11, 1, 11, 3, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (12, 1, 'N', '101012', 'Natalia Pardo', 'natalia.pardo@acme.com', '+573001000012');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (12, 1, 12, 'op4_acme', 'natalia.pardo@acme.com', 2);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (12, 1, 12, 3, DATE '2026-01-01', 1);

-- ==================== TENANT 2 (GLOBEX) ====================
-- ROL_ADMIN (Usuarios 13 a 16)
INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (13, 2, 'N', '202001', 'Esteban Peña', 'esteban.pena@globex.com', '+573102000001');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (13, 2, 13, 'admin1_globex', 'esteban.pena@globex.com', 3);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (13, 2, 13, 4, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (14, 2, 'N', '202002', 'Claudia Ortiz', 'claudia.ortiz@globex.com', '+573102000002');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (14, 2, 14, 'admin2_globex', 'claudia.ortiz@globex.com', 3);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (14, 2, 14, 4, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (15, 2, 'N', '202003', 'Ricardo Cano', 'ricardo.cano@globex.com', '+573102000003');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (15, 2, 15, 'admin3_globex', 'ricardo.cano@globex.com', 3);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (15, 2, 15, 4, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (16, 2, 'N', '202004', 'Andrea Lozano', 'andrea.lozano@globex.com', '+573102000004');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (16, 2, 16, 'admin4_globex', 'andrea.lozano@globex.com', 3);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (16, 2, 16, 4, DATE '2026-01-01', 1);

-- ROL_SUPERVISOR (Usuarios 17 a 20)
INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (17, 2, 'N', '202005', 'Gabriel Vega', 'gabriel.vega@globex.com', '+573102000005');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (17, 2, 17, 'sup1_globex', 'gabriel.vega@globex.com', 3);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (17, 2, 17, 5, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (18, 2, 'N', '202006', 'Mónica Delgado', 'monica.delgado@globex.com', '+573102000006');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (18, 2, 18, 'sup2_globex', 'monica.delgado@globex.com', 3);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (18, 2, 18, 5, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (19, 2, 'N', '202007', 'Daniel Cárdenas', 'daniel.cardenas@globex.com', '+573102000007');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (19, 2, 19, 'sup3_globex', 'daniel.cardenas@globex.com', 4);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (19, 2, 19, 5, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (20, 2, 'N', '202008', 'Vanessa Gutiérrez', 'vanessa.gutierrez@globex.com', '+573102000008');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (20, 2, 20, 'sup4_globex', 'vanessa.gutierrez@globex.com', 4);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (20, 2, 20, 5, DATE '2026-01-01', 1);

-- ROL_OPERADOR (Usuarios 21 a 24)
INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (21, 2, 'N', '202009', 'Héctor Benítez', 'hector.benitez@globex.com', '+573102000009');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (21, 2, 21, 'op1_globex', 'hector.benitez@globex.com', 3);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (21, 2, 21, 6, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (22, 2, 'N', '202010', 'Daniela Rojas', 'daniela.rojas@globex.com', '+573102000010');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (22, 2, 22, 'op2_globex', 'daniela.rojas@globex.com', 3);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (22, 2, 22, 6, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (23, 2, 'N', '202011', 'Óscar Fuentes', 'oscar.fuentes@globex.com', '+573102000011');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (23, 2, 23, 'op3_globex', 'oscar.fuentes@globex.com', 4);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (23, 2, 23, 6, DATE '2026-01-01', 1);

INSERT INTO core_persona (id, id_tenant, tipo, identificacion, nombre_completo, correo_principal, telefono_principal)
VALUES (24, 2, 'N', '202012', 'Paola Salazar', 'paola.salazar@globex.com', '+573102000012');
INSERT INTO core_usuario (id, id_tenant, id_persona, nombre_usuario, correo_electronico, id_contexto_actual)
VALUES (24, 2, 24, 'op4_globex', 'paola.salazar@globex.com', 4);
INSERT INTO core_usuario_rol (id, id_tenant, id_usuario, id_rol, fecha_inicio, habilitado)
VALUES (24, 2, 24, 6, DATE '2026-01-01', 1);

-- ----------------------------------------------------------------------------
-- 6. PLANTILLAS DE NOTIFICACIÓN PARA CADA TIPO (EMAIL, SMS, WHATSAPP, PUSH)
-- ----------------------------------------------------------------------------
PROMPT 6. Registrando Plantillas de Notificación por Canal...

-- 6.1 Layout Maestro (EMAIL)
INSERT INTO core_plantilla_notificacion (
    id, id_tenant, id_aplicacion, es_layout, etiqueta_incrustacion,
    estilo_css, nombre, asunto, contenido, canal, activa
) VALUES (
    1, 1, 1, 1, '{{cuerpo_mensaje}}',
    'body { font-family: sans-serif; background-color: #f4f4f7; } .card { background: #ffffff; padding: 24px; border-radius: 8px; }',
    'Layout Maestro Corporativo ACME', NULL,
    '<html><body><div class="card"><h2>{{nombre_tenant}}</h2><hr/>{{cuerpo_mensaje}}<hr/><small>&copy; 2026 {{nombre_tenant}} - Todos los derechos reservados.</small></div></body></html>',
    'EMAIL', 1
);

-- 6.2 Tipo 1: EMAIL (Bienvenida)
INSERT INTO core_plantilla_notificacion (
    id, id_tenant, id_aplicacion, id_plantilla_padre, es_layout,
    tipo_evento, nombre, asunto, contenido, canal, activa
) VALUES (
    2, 1, 1, 1, 0,
    'CREACION_USUARIO', 'Bienvenida a Nuevo Usuario (EMAIL)',
    '¡Bienvenido a {{nombre_tenant}}, {{nombre_persona}}!',
    '<p>Estimado/a <strong>{{nombre_persona}}</strong>,</p><p>Tu cuenta con usuario <code>{{nombre_usuario}}</code> ha sido creada exitosamente.</p><p><a href="{{enlace_activacion}}">Haz clic aquí para ingresar</a></p>',
    'EMAIL', 1
);

-- 6.3 Tipo 2: SMS (Token de Seguridad OTP)
INSERT INTO core_plantilla_notificacion (
    id, id_tenant, id_aplicacion, es_layout,
    tipo_evento, nombre, asunto, contenido, canal, activa
) VALUES (
    3, 1, 1, 0,
    'AUTENTICACION_OTP', 'Código de Verificación OTP (SMS)',
    NULL,
    '{{nombre_tenant}}: Tu código de seguridad OTP es {{codigo_otp}}. Válido por 5 minutos. No lo compartas con nadie.',
    'SMS', 1
);

-- 6.4 Tipo 3: WHATSAPP (Alerta de Seguridad)
INSERT INTO core_plantilla_notificacion (
    id, id_tenant, id_aplicacion, es_layout,
    tipo_evento, nombre, asunto, contenido, canal, activa
) VALUES (
    4, 1, 1, 0,
    'ALERTA_ACCESO', 'Alerta de Inicio de Sesión (WHATSAPP)',
    NULL,
    '🔒 *Alerta de Seguridad {{nombre_tenant}}*' || CHR(10) ||
    'Hola {{nombre_persona}}, detectamos un nuevo inicio de sesión en tu cuenta.' || CHR(10) ||
    '📍 Dirección IP: {{direccion_ip}}' || CHR(10) ||
    '🕒 Fecha: {{fecha_evento}}' || CHR(10) ||
    'Si no fuiste tú, comunícate de inmediato con soporte.',
    'WHATSAPP', 1
);

-- 6.5 Tipo 4: PUSH_NOTIFICATION (Recordatorio de Tarea)
INSERT INTO core_plantilla_notificacion (
    id, id_tenant, id_aplicacion, es_layout,
    tipo_evento, nombre, asunto, contenido, canal, activa
) VALUES (
    5, 1, 1, 0,
    'ASIGNACION_TAREA', 'Recordatorio de Tarea Asignada (PUSH)',
    'Nueva tarea asignada',
    'Tienes una tarea pendiente #{{numero_tarea}}: {{titulo_tarea}} en el módulo {{nombre_modulo}}.',
    'PUSH_NOTIFICATION', 1
);

-- ----------------------------------------------------------------------------
-- 7. VARIABLES DINÁMICAS POR PLANTILLA (VALIDACIÓN PREVIA)
-- ----------------------------------------------------------------------------
PROMPT 7. Registrando Variables Dinámicas de Plantillas...

-- Variables para Plantilla 2 (EMAIL)
INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (1, 1, 2, 'nombre_tenant', '{{nombre_tenant}}', 'Nombre de la empresa inquilina', 'STRING', 1, 'Acme Corp', 'Acme Global SaaS Corp');

INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (2, 1, 2, 'nombre_persona', '{{nombre_persona}}', 'Nombre completo del destinatario', 'STRING', 1, NULL, 'Carlos Méndez');

INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (3, 1, 2, 'nombre_usuario', '{{nombre_usuario}}', 'Username asignado en el sistema', 'STRING', 1, NULL, 'admin1_acme');

INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (4, 1, 2, 'enlace_activacion', '{{enlace_activacion}}', 'URL de acceso directo o confirmación', 'URL', 1, 'https://app.acme.com', 'https://app.acme.com/login');

-- Variables para Plantilla 3 (SMS)
INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (5, 1, 3, 'nombre_tenant', '{{nombre_tenant}}', 'Nombre mnemotécnico del inquilino', 'STRING', 1, 'ACME', 'ACME');

INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (6, 1, 3, 'codigo_otp', '{{codigo_otp}}', 'Código numérico de 6 dígitos', 'NUMBER', 1, NULL, '482910');

-- Variables para Plantilla 4 (WHATSAPP)
INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (7, 1, 4, 'nombre_tenant', '{{nombre_tenant}}', 'Nombre del tenant emisor', 'STRING', 1, 'ACME', 'ACME');

INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (8, 1, 4, 'nombre_persona', '{{nombre_persona}}', 'Nombre del usuario receptor', 'STRING', 1, NULL, 'Carlos Méndez');

INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (9, 1, 4, 'direccion_ip', '{{direccion_ip}}', 'Dirección IP detectada en el inicio de sesión', 'STRING', 1, '127.0.0.1', '190.25.100.42');

INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (10, 1, 4, 'fecha_evento', '{{fecha_evento}}', 'Fecha y hora del evento de seguridad', 'STRING', 1, NULL, '2026-10-10 19:30:00');

-- Variables para Plantilla 5 (PUSH_NOTIFICATION)
INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (11, 1, 5, 'numero_tarea', '{{numero_tarea}}', 'Identificador único de la tarea', 'NUMBER', 1, NULL, '1054');

INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (12, 1, 5, 'titulo_tarea', '{{titulo_tarea}}', 'Título o asunto de la tarea asignada', 'STRING', 1, NULL, 'Revisión mensual de auditoría');

INSERT INTO core_plantilla_variable (id, id_tenant, id_plantilla, nombre_variable, etiqueta_variable, descripcion, tipo_dato, es_obligatoria, valor_defecto, ejemplo_valor)
VALUES (13, 1, 5, 'nombre_modulo', '{{nombre_modulo}}', 'Módulo funcional de la tarea', 'STRING', 0, 'General', 'Seguridad y Cumplimiento');

-- ----------------------------------------------------------------------------
-- 8. PROCESOS FUNCIONALES, ASOCIACIÓN A PLANTILLAS Y REGLAS DE DESTINATARIOS
-- ----------------------------------------------------------------------------
PROMPT 8. Registrando Procesos Funcionales y Enlace de Despacho...

-- 8.1 Catálogo de Procesos
INSERT INTO core_proceso (id, id_tenant, id_aplicacion, codigo, nombre, objeto_bd, descripcion, activo)
VALUES (1, 1, 1, 'CREACION_USUARIO', 'Alta de Usuario', 'pkgln_usuarios.p_crear_usuario', 'Orquesta la creación de persona, usuario y notificación de bienvenida', 1);

INSERT INTO core_proceso (id, id_tenant, id_aplicacion, codigo, nombre, objeto_bd, descripcion, activo)
VALUES (2, 1, 1, 'AUTENTICACION_MFA', 'Generación de Código OTP', 'pkgln_seguridad.p_generar_otp', 'Genera código numérico seguro y despacha SMS', 1);

INSERT INTO core_proceso (id, id_tenant, id_aplicacion, codigo, nombre, objeto_bd, descripcion, activo)
VALUES (3, 1, 1, 'ALERTA_ACCESO', 'Notificación de Acceso Sospechoso', 'pkgln_seguridad.p_notificar_acceso', 'Emite alerta por WhatsApp al detectarse IP nueva', 1);

INSERT INTO core_proceso (id, id_tenant, id_aplicacion, codigo, nombre, objeto_bd, descripcion, activo)
VALUES (4, 1, 1, 'ASIGNACION_TAREA', 'Asignación de Actividad', 'pkgln_tareas.p_asignar_tarea', 'Notifica al operador vía Push sobre una nueva actividad', 1);

-- 8.2 Asociación Proceso -> Plantilla
INSERT INTO core_proceso_plantilla (id, id_tenant, id_proceso, id_plantilla, es_obligatoria, orden_despacho, activo)
VALUES (1, 1, 1, 2, 1, 1, 1); -- Creación de usuario dispara EMAIL

INSERT INTO core_proceso_plantilla (id, id_tenant, id_proceso, id_plantilla, es_obligatoria, orden_despacho, activo)
VALUES (2, 1, 2, 3, 1, 1, 1); -- MFA dispara SMS

INSERT INTO core_proceso_plantilla (id, id_tenant, id_proceso, id_plantilla, es_obligatoria, orden_despacho, activo)
VALUES (3, 1, 3, 4, 1, 1, 1); -- Acceso dispara WHATSAPP

INSERT INTO core_proceso_plantilla (id, id_tenant, id_proceso, id_plantilla, es_obligatoria, orden_despacho, activo)
VALUES (4, 1, 4, 5, 0, 1, 1); -- Tarea dispara PUSH_NOTIFICATION

-- 8.3 Destinatarios por Proceso-Plantilla
INSERT INTO core_proceso_destinatario (id, id_tenant, id_proceso_plantilla, tipo_destinatario, activo)
VALUES (1, 1, 1, 'TITULAR_PROCESO', 1); -- EMAIL va al nuevo usuario

INSERT INTO core_proceso_destinatario (id, id_tenant, id_proceso_plantilla, tipo_destinatario, activo)
VALUES (2, 1, 2, 'TITULAR_PROCESO', 1); -- SMS va al titular autenticado

INSERT INTO core_proceso_destinatario (id, id_tenant, id_proceso_plantilla, tipo_destinatario, id_rol, activo)
VALUES (3, 1, 3, 'ROL', 2, 1); -- Copia de alerta WhatsApp va también a Supervisores (Rol 2)

INSERT INTO core_proceso_destinatario (id, id_tenant, id_proceso_plantilla, tipo_destinatario, id_usuario, activo)
VALUES (4, 1, 4, 'USUARIO', 9, 1); -- Push dirigido puntualmente a Operador 9

-- ----------------------------------------------------------------------------
-- 9. NOTIFICACIONES DISPACHADAS Y PENDIENTES (UNA PARA CADA TIPO/CANAL)
-- ----------------------------------------------------------------------------
PROMPT 9. Registrando Notificaciones Transaccionales (EMAIL, SMS, WHATSAPP, PUSH)...

-- 9.1 Notificación Tipo EMAIL (Enviada)
INSERT INTO core_notificacion (
    id, id_tenant, id_usuario, id_plantilla, destinatario, asunto,
    contenido_final,
    variables_json, canal, estado, tiene_auditoria
) VALUES (
    1, 1, 1, 2, 'carlos.mendez@acme.com', '¡Bienvenido a Acme Global SaaS Corp, Carlos Méndez!',
    '<html><body><div class="card"><h2>Acme Global SaaS Corp</h2><hr/><p>Estimado/a <strong>Carlos Méndez</strong>,</p><p>Tu cuenta con usuario <code>admin1_acme</code> ha sido creada exitosamente.</p><p><a href="https://app.acme.com/login">Haz clic aquí para ingresar</a></p><hr/><small>&copy; 2026 Acme Global SaaS Corp</small></div></body></html>',
    '{"nombre_tenant":"Acme Global SaaS Corp","nombre_persona":"Carlos Méndez","nombre_usuario":"admin1_acme","enlace_activacion":"https://app.acme.com/login"}',
    'EMAIL', 'ENVIADO', 1
);

-- 9.2 Notificación Tipo SMS (Entregada)
INSERT INTO core_notificacion (
    id, id_tenant, id_usuario, id_plantilla, destinatario, asunto,
    contenido_final,
    variables_json, canal, estado, tiene_auditoria
) VALUES (
    2, 1, 1, 3, '+573001000001', NULL,
    'ACME: Tu código de seguridad OTP es 482910. Válido por 5 minutos. No lo compartas con nadie.',
    '{"nombre_tenant":"ACME","codigo_otp":482910}',
    'SMS', 'ENTREGADO', 1
);

-- 9.3 Notificación Tipo WHATSAPP (Leída)
INSERT INTO core_notificacion (
    id, id_tenant, id_usuario, id_plantilla, destinatario, asunto,
    contenido_final,
    variables_json, canal, estado, tiene_auditoria
) VALUES (
    3, 1, 1, 4, '+573001000001', NULL,
    '🔒 *Alerta de Seguridad ACME*' || CHR(10) ||
    'Hola Carlos Méndez, detectamos un nuevo inicio de sesión en tu cuenta.' || CHR(10) ||
    '📍 Dirección IP: 190.25.100.42' || CHR(10) ||
    '🕒 Fecha: 2026-10-10 19:30:00' || CHR(10) ||
    'Si no fuiste tú, comunícate de inmediato con soporte.',
    '{"nombre_tenant":"ACME","nombre_persona":"Carlos Méndez","direccion_ip":"190.25.100.42","fecha_evento":"2026-10-10 19:30:00"}',
    'WHATSAPP', 'LEIDO', 1
);

-- 9.4 Notificación Tipo PUSH_NOTIFICATION (Pendiente)
INSERT INTO core_notificacion (
    id, id_tenant, id_usuario, id_plantilla, destinatario, asunto,
    contenido_final,
    variables_json, canal, estado, tiene_auditoria
) VALUES (
    4, 1, 9, 5, 'fcm_token_device_op1_acme_498172', 'Nueva tarea asignada',
    'Tienes una tarea pendiente #1054: Revisión mensual de auditoría en el módulo Seguridad y Cumplimiento.',
    '{"numero_tarea":1054,"titulo_tarea":"Revisión mensual de auditoría","nombre_modulo":"Seguridad y Cumplimiento"}',
    'PUSH_NOTIFICATION', 'PENDIENTE', 1
);

-- ----------------------------------------------------------------------------
-- 10. PREFERENCIAS DE NOTIFICACIÓN DE USUARIOS
-- ----------------------------------------------------------------------------
PROMPT 10. Registrando Preferencias de Notificación...

INSERT INTO core_preferencia_notificacion (id, id_tenant, id_usuario, canal, habilitado, horario_inicio, horario_fin, consentimiento_gdpr)
VALUES (1, 1, 1, 'EMAIL', 1, '08:00', '20:00', 1);

INSERT INTO core_preferencia_notificacion (id, id_tenant, id_usuario, canal, habilitado, horario_inicio, horario_fin, consentimiento_gdpr)
VALUES (2, 1, 1, 'SMS', 1, '08:00', '22:00', 1);

INSERT INTO core_preferencia_notificacion (id, id_tenant, id_usuario, canal, habilitado, horario_inicio, horario_fin, consentimiento_gdpr)
VALUES (3, 1, 1, 'WHATSAPP', 1, '08:00', '20:00', 1);

INSERT INTO core_preferencia_notificacion (id, id_tenant, id_usuario, canal, habilitado, horario_inicio, horario_fin, consentimiento_gdpr)
VALUES (4, 1, 9, 'PUSH_NOTIFICATION', 1, '07:00', '19:00', 1);

-- ----------------------------------------------------------------------------
-- 11. REGLAS DE TELEMETRÍA Y OBSERVABILIDAD (uti_manejo_trazas_pkg)
-- ----------------------------------------------------------------------------
PROMPT 11. Registrando Reglas de Trazabilidad...

INSERT INTO core_traza_config (
    id, id_tenant, nombre_paquete, nombre_metodo, es_activo, nivel_detalle, grabar_payloads
) VALUES (
    1, 1, 'pkgln_usuarios', '%', 1, 'COMPLETO', 1
);

INSERT INTO core_traza_config (
    id, id_tenant, nombre_paquete, nombre_metodo, es_activo, nivel_detalle, grabar_payloads
) VALUES (
    2, 1, 'uti_manejo_trazas_pkg', '%', 1, 'COMPLETO', 1
);

INSERT INTO core_traza_config (
    id, id_tenant, nombre_paquete, nombre_metodo, es_activo, nivel_detalle, grabar_payloads
) VALUES (
    3, 1, 'pkgln_seguridad', '%', 1, 'COMPLETO', 1
);

-- ----------------------------------------------------------------------------
-- 12. PARÁMETROS DEL SISTEMA
-- ----------------------------------------------------------------------------
PROMPT 12. Registrando Parámetros del Sistema...

INSERT INTO core_parametro (
    id, id_tenant, id_aplicacion, categoria, clave, valor_texto, valor_numero, tipo_valor, descripcion, editable_por_usuario
) VALUES (
    1, 1, 1, 'SEGURIDAD', 'MAX_INTENTOS_LOGIN', NULL, 5, 'NUMBER', 'Intentos máximos permitidos antes de bloqueo de cuenta', 1
);

INSERT INTO core_parametro (
    id, id_tenant, id_aplicacion, categoria, clave, valor_texto, valor_numero, tipo_valor, descripcion, editable_por_usuario
) VALUES (
    2, 1, 1, 'NOTIFICACIONES', 'REMITENTE_CORREO_DEFAULT', 'notificaciones@acme.com', NULL, 'STRING', 'Dirección From para correos del tenant', 1
);

INSERT INTO core_parametro (
    id, id_tenant, id_aplicacion, categoria, clave, valor_texto, valor_numero, tipo_valor, descripcion, editable_por_usuario
) VALUES (
    3, 2, 1, 'SEGURIDAD', 'MAX_INTENTOS_LOGIN', NULL, 3, 'NUMBER', 'Intentos máximos permitidos antes de bloqueo de cuenta', 1
);

-- ----------------------------------------------------------------------------
-- 13. TOKEN DE API MACHINE-TO-MACHINE (M2M)
-- ----------------------------------------------------------------------------
PROMPT 13. Registrando Token de API M2M...

INSERT INTO core_api_token (
    id, id_tenant, id_usuario, id_aplicacion, nombre, prefijo_clave,
    hash_token, alcances_json, tipo_token, limite_peticiones_min
) VALUES (
    1, 1, 1, 1, 'Integración API Gateway Webhooks', 'ak_acme_live',
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    '["notificaciones:enviar", "usuarios:consultar", "trazas:registrar"]',
    'API_KEY', 120
);

-- ----------------------------------------------------------------------------
-- CONFIRMACIÓN DE LA TRANSACCIÓN
-- ----------------------------------------------------------------------------
COMMIT;

PROMPT ============================================================================
PROMPT CARGA DE DATOS DUMMY COMPLETADA EXITOSAMENTE.
PROMPT Tenants creados: 2
PROMPT Roles creados: 6 (3 por tenant)
PROMPT Usuarios creados: 24 (4 por cada rol)
PROMPT Tipos de notificación probados: EMAIL, SMS, WHATSAPP, PUSH_NOTIFICATION
PROMPT ============================================================================
