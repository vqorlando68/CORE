// ============================================================================
// DATOS SEMILLA / MOCK ENRIQUECIDOS (COINCIDEN 1:1 CON DATOS_DUMMY.SQL)
// ============================================================================
import { Tenant, Aplicacion, Usuario, Rol, DocumentacionMetodo, TrazaEjecucion, TrazaLlamado } from './types';

export let mockTenants: Tenant[] = [
  {
    id: 1,
    codigo: 'ACME',
    nombre: 'Acme Global SaaS Corp',
    id_plan: 'ENTERPRISE',
    nit_empresa: '900123456-1',
    contacto_correo: 'admin@acme.com',
    contacto_telefono: '+57 3001234567',
    pais: 'CO',
    estado: 1,
    fecha_creacion: '2026-10-01 08:30:00'
  },
  {
    id: 2,
    codigo: 'GLOBEX',
    nombre: 'Globex Cloud Solutions',
    id_plan: 'BUSINESS',
    nit_empresa: '900987654-2',
    contacto_correo: 'contacto@globex.com',
    contacto_telefono: '+57 3109876543',
    pais: 'CO',
    estado: 1,
    fecha_creacion: '2026-10-02 09:15:00'
  }
];

export let mockAplicaciones: Aplicacion[] = [
  {
    id: 1,
    codigo: 'CORE_ADMIN',
    nombre: 'Portal Administrativo Core',
    descripcion: 'Panel centralizado de control de usuarios, seguridad, auditoría y parametrización multi-inquilino.',
    version: '1.0.0',
    estado: 'ACTIVA',
    habilitada: 1,
    total_modulos: 6
  },
  {
    id: 2,
    codigo: 'SAAS_CRM',
    nombre: 'CRM Omnicanal',
    descripcion: 'Gestión inteligente de clientes, oportunidades, embudo comercial y comunicación masiva.',
    version: '2.1.0',
    estado: 'ACTIVA',
    habilitada: 1,
    total_modulos: 4
  },
  {
    id: 3,
    codigo: 'SAAS_FACTURACION',
    nombre: 'Facturación Electrónica DIAN',
    descripcion: 'Generación, firma digital y radicación de facturas y notas crédito ante la autoridad tributaria.',
    version: '1.5.0',
    estado: 'ACTIVA',
    habilitada: 1,
    total_modulos: 3
  }
];

export let mockRoles: Rol[] = [
  {
    id: 1,
    id_tenant: 1,
    codigo: 'ROL_ADMIN',
    nombre: 'Administrador General',
    descripcion: 'Control y configuración global de tenants, usuarios, roles, aplicaciones y parámetros.',
    alcance: 'G',
    estado_registro: 1,
    total_usuarios: 4,
    permisos: ['TENANTS_GESTION', 'USUARIOS_CREAR', 'ROLES_ASIGNAR', 'TRAZAS_VER', 'METODOS_ADMIN']
  },
  {
    id: 2,
    id_tenant: 1,
    codigo: 'ROL_SUPERVISOR',
    nombre: 'Supervisor Operativo',
    descripcion: 'Supervisión de operaciones del inquilino, consulta de telemetría y auditoría de eventos.',
    alcance: 'G',
    estado_registro: 1,
    total_usuarios: 4,
    permisos: ['USUARIOS_VER', 'AUDITORIA_CONSULTAR', 'TRAZAS_VER']
  },
  {
    id: 3,
    id_tenant: 1,
    codigo: 'ROL_OPERADOR',
    nombre: 'Operador de Servicios',
    descripcion: 'Atención directa de procesos operativos y transacciones diarias del tenant.',
    alcance: 'O',
    estado_registro: 1,
    total_usuarios: 4,
    permisos: ['OPERACION_EJECUTAR', 'CONSULTA_GENERAL']
  },
  {
    id: 4,
    id_tenant: 2,
    codigo: 'ROL_ADMIN',
    nombre: 'Administrador General Globex',
    descripcion: 'Administración total del espacio de trabajo Globex.',
    alcance: 'G',
    estado_registro: 1,
    total_usuarios: 4,
    permisos: ['TENANTS_GESTION', 'USUARIOS_CREAR', 'ROLES_ASIGNAR']
  }
];

export let mockUsuarios: Usuario[] = [
  {
    id: 1,
    id_tenant: 1,
    id_persona: 101,
    nombre_usuario: 'admin.acme',
    correo_electronico: 'admin@acme.com',
    primer_nombre: 'Orlando',
    primer_apellido: 'Valverde',
    tipo_documento: 'CC',
    numero_documento: '1098765432',
    estado: 1,
    bloqueado: 0,
    intentos_fallidos: 0,
    ultimo_ingreso: '2026-10-10 20:15:22',
    roles: ['ROL_ADMIN']
  },
  {
    id: 2,
    id_tenant: 1,
    id_persona: 102,
    nombre_usuario: 'supervisor1.acme',
    correo_electronico: 'supervisor1@acme.com',
    primer_nombre: 'Mariana',
    primer_apellido: 'Restrepo',
    tipo_documento: 'CC',
    numero_documento: '1032456789',
    estado: 1,
    bloqueado: 0,
    intentos_fallidos: 0,
    ultimo_ingreso: '2026-10-10 18:40:00',
    roles: ['ROL_SUPERVISOR']
  },
  {
    id: 3,
    id_tenant: 1,
    id_persona: 103,
    nombre_usuario: 'operador1.acme',
    correo_electronico: 'operador1@acme.com',
    primer_nombre: 'Andrés',
    primer_apellido: 'Morales',
    tipo_documento: 'CC',
    numero_documento: '1045678901',
    estado: 1,
    bloqueado: 0,
    intentos_fallidos: 0,
    ultimo_ingreso: '2026-10-10 16:10:05',
    roles: ['ROL_OPERADOR']
  },
  {
    id: 4,
    id_tenant: 2,
    id_persona: 104,
    nombre_usuario: 'admin.globex',
    correo_electronico: 'admin@globex.com',
    primer_nombre: 'Beatriz',
    primer_apellido: 'Jiménez',
    tipo_documento: 'CC',
    numero_documento: '1076543210',
    estado: 1,
    bloqueado: 0,
    intentos_fallidos: 0,
    ultimo_ingreso: '2026-10-10 19:00:15',
    roles: ['ROL_ADMIN']
  }
];

export let mockDocumentacion: DocumentacionMetodo[] = [
  {
    id: 1,
    id_tenant: 1,
    id_aplicacion: 1,
    nombre_paquete: 'pkgln_usuarios',
    nombre_metodo: 'p_crear_usuario',
    titulo_funcional: 'Creación y Alta Integral de Nuevo Usuario',
    resumen_ejecutivo: 'Registra a una persona, genera su cuenta de usuario y asigna sus credenciales y roles iniciales en el tenant.',
    descripcion_negocio: 'Este servicio orquestador coordina todo el proceso de onboarding de un colaborador o usuario final en la plataforma. Verifica primero que no existan duplicados de identificación o correo electrónico, crea el registro físico en la entidad de personas, genera el perfil de usuario con sus banderas de seguridad, y deja listo el envío de la notificación de bienvenida.',
    actor_principal: 'Administrador de Seguridad o Gestor de Talento Humano',
    flujo_funcional_pasos: '1. Valida el formato y obligatoriedad de los datos recibidos en el payload.\n2. Consulta si la persona ya existe mediante su documento de identidad.\n3. Si no existe, invoca el DAO de persona para registrar sus datos biográficos.\n4. Invoca el DAO de usuario para crear la cuenta vinculada al tenant activo.\n5. Asigna los roles especificados y dispara el evento de auditoría.',
    reglas_validacion: '- El correo electrónico debe tener formato válido y no estar registrado previamente en el tenant.\n- El tipo de documento y número de identificación son estrictamente obligatorios.\n- Debe suministrarse al menos un rol activo para el usuario.',
    descripcion_entrada_natural: 'Se debe enviar un objeto JSON con el tenant objetivo, el usuario que ejecuta la acción y el bloque "datos" con nombre, apellido, correo, documento de identidad y código del rol.',
    ejemplo_json_entrada: JSON.stringify({
      id_tenant: 1,
      id_usuario_ejecutor: 1,
      datos: {
        primer_nombre: 'Carlos',
        primer_apellido: 'Gómez',
        correo_electronico: 'carlos.gomez@acme.com',
        tipo_documento: 'CC',
        numero_documento: '1020304050',
        nombre_usuario: 'cgomez',
        codigo_rol: 'ROL_OPERADOR'
      }
    }, null, 2),
    descripcion_salida_natural: 'Retorna un JSON estándar con el código de respuesta (0 para éxito), mensaje descriptivo y un objeto "datos" con el ID del usuario generado y su estado.',
    ejemplo_json_salida: JSON.stringify({
      codigo: 0,
      mensaje: 'Usuario creado exitosamente en el sistema',
      datos: {
        id_persona: 105,
        id_usuario: 25,
        nombre_usuario: 'cgomez',
        estado: 'ACTIVO'
      }
    }, null, 2),
    excepciones_negocio: '- Código -20001: El correo electrónico ya se encuentra registrado por otro usuario activo.\n- Código -20002: El rol solicitado no existe o no se encuentra habilitado para este inquilino.',
    requiere_autenticacion: 1,
    permiso_requerido: 'USUARIOS_CREAR',
    version_metodo: '1.0.0',
    estado_publicacion: 'PUBLICADO',
    categoria_visual: 'SEGURIDAD',
    icono_interfaz: 'lucide-user-plus',
    color_distintivo: '#2563eb',
    etiquetas_busqueda: 'usuario, alta, onboarding, personas, seguridad, crear',
    estado_registro: 1,
    fecha_creacion: '2026-10-07 10:00:00'
  },
  {
    id: 2,
    id_tenant: 1,
    id_aplicacion: 1,
    nombre_paquete: 'uti_manejo_trazas_pkg',
    nombre_metodo: 'p_iniciar_traza',
    titulo_funcional: 'Inicio de Telemetría y Rastreo de Ejecución (APM)',
    resumen_ejecutivo: 'Verifica si el subprograma tiene activo el seguimiento y registra la cabecera en core_traza_ejecucion.',
    descripcion_negocio: 'Servicio transversal de observabilidad que inicia una transacción de rastreo jerárquico. Evalúa las reglas dinámicas en caliente configuradas en core_traza_config para el paquete y subprograma en cuestión. Si está habilitado, genera un UUID de traza y registra el timestamp de inicio con nivel de detalle.',
    actor_principal: 'Orquestador PL/SQL (pkgln_) o API Gateway',
    flujo_funcional_pasos: '1. Lee la configuración activa para el tenant y nombre del paquete.\n2. Si la regla exige seguimiento, genera o asocia el código de traza (trace ID).\n3. Inserta el registro inicial en core_traza_ejecucion con estado EN_PROCESO.',
    reglas_validacion: '- Debe suministrarse el nombre del paquete y método que inician la ejecución.\n- Si se suministra payload, debe ser un JSON válido.',
    descripcion_entrada_natural: 'Requiere el nombre del paquete, nombre del método, el payload JSON recibido por el endpoint y opcionalmente el usuario ejecutor.',
    ejemplo_json_entrada: JSON.stringify({
      id_tenant: 1,
      nombre_paquete: 'pkgln_usuarios',
      nombre_metodo: 'p_crear_usuario',
      codigo_traza: 'tr-7f9a2b1c-9921',
      payload_entrada: {
        nombre_usuario: 'cgomez'
      }
    }, null, 2),
    descripcion_salida_natural: 'Devuelve el identificador único de la traza iniciada y la bandera de si la traza debe continuar grabando los llamados hijos.',
    ejemplo_json_salida: JSON.stringify({
      codigo: 0,
      mensaje: 'Traza inicializada correctamente',
      datos: {
        id_traza: 4501,
        debe_trazar_detalle: 1,
        codigo_traza: 'tr-7f9a2b1c-9921'
      }
    }, null, 2),
    excepciones_negocio: '- Código -20050: Error al persistir cabecera de traza en almacenamiento autónomo.',
    requiere_autenticacion: 0,
    version_metodo: '1.0.0',
    estado_publicacion: 'PUBLICADO',
    categoria_visual: 'TELEMETRIA',
    icono_interfaz: 'lucide-activity',
    color_distintivo: '#10b981',
    etiquetas_busqueda: 'telemetria, trazas, apm, observabilidad, profiling',
    estado_registro: 1,
    fecha_creacion: '2026-10-08 14:20:00'
  },
  {
    id: 3,
    id_tenant: 1,
    id_aplicacion: 1,
    nombre_paquete: 'pkgln_seguridad',
    nombre_metodo: 'p_iniciar_sesion',
    titulo_funcional: 'Autenticación y Apertura de Sesión Activa',
    resumen_ejecutivo: 'Valida credenciales de usuario, verifica restricciones de acceso y emite los datos de contexto de la sesión.',
    descripcion_negocio: 'Flujo principal de inicio de sesión en el sistema. Realiza la comprobación de contraseña contra el hash almacenado, verifica que la cuenta no esté bloqueada ni expirada, registra la sesión en core_sesion_activa y recopila los roles y permisos concedidos.',
    actor_principal: 'Usuario Final / Frontend de Login',
    flujo_funcional_pasos: '1. Busca al usuario por nombre de usuario o correo dentro del tenant.\n2. Valida intentos fallidos previos; si supera el límite, bloquea la cuenta.\n3. Compara el hash de la contraseña.\n4. Genera la sesión en core_sesion_activa y actualiza el timestamp de último ingreso.\n5. Compila los permisos y perfiles para devolverlos a la interfaz.',
    reglas_validacion: '- El nombre de usuario y la contraseña no pueden estar vacíos.\n- El tenant debe encontrarse activo y en estado regular.',
    descripcion_entrada_natural: 'Recibe las credenciales del usuario junto con metadatos del cliente (IP y user-agent).',
    ejemplo_json_entrada: JSON.stringify({
      id_tenant: 1,
      nombre_usuario: 'admin.acme',
      clave: 'Secreta123*',
      ip_origen: '190.145.20.10',
      agente_usuario: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
    }, null, 2),
    descripcion_salida_natural: 'Devuelve el token de sesión generado, datos básicos del perfil autenticado y la lista de aplicaciones y permisos autorizados.',
    ejemplo_json_salida: JSON.stringify({
      codigo: 0,
      mensaje: 'Autenticación exitosa',
      datos: {
        id_usuario: 1,
        id_sesion: 890,
        token_sesion: 'eyJhbGciOiJIUzI1NiIsIn...',
        expira_en_minutos: 480,
        roles: ['ROL_ADMIN']
      }
    }, null, 2),
    excepciones_negocio: '- Código -20010: Credenciales inválidas (usuario o contraseña incorrectos).\n- Código -20011: Cuenta bloqueada por exceso de intentos fallidos.',
    requiere_autenticacion: 0,
    version_metodo: '1.0.0',
    estado_publicacion: 'PUBLICADO',
    categoria_visual: 'SEGURIDAD',
    icono_interfaz: 'lucide-key-round',
    color_distintivo: '#f59e0b',
    etiquetas_busqueda: 'login, autenticacion, seguridad, sesion, token',
    estado_registro: 1,
    fecha_creacion: '2026-10-09 09:30:00'
  }
];

export let mockTrazas: TrazaEjecucion[] = [
  {
    id: 101,
    id_tenant: 1,
    id_usuario: 1,
    nombre_paquete: 'pkgln_usuarios',
    nombre_metodo: 'p_crear_usuario',
    codigo_traza: 'TRZ-20261010-8841',
    ip_origen: '190.145.20.10',
    id_sesion_oracle: 'SID: 142 (Audsid: 89912)',
    fecha_inicio: '2026-10-10 20:25:10',
    fecha_fin: '2026-10-10 20:25:10',
    duracion_ms: 42.15,
    estado: 'EXITO',
    total_llamados: 4,
    json_entrada: JSON.stringify({
      id_tenant: 1,
      datos: { nombre_usuario: 'cgomez', correo: 'carlos.gomez@acme.com' }
    }, null, 2),
    json_salida: JSON.stringify({
      codigo: 0,
      mensaje: 'Usuario creado exitosamente',
      datos: { id_usuario: 25, estado: 'ACTIVO' }
    }, null, 2)
  },
  {
    id: 102,
    id_tenant: 1,
    id_usuario: 1,
    nombre_paquete: 'pkgln_seguridad',
    nombre_metodo: 'p_iniciar_sesion',
    codigo_traza: 'TRZ-20261010-8840',
    ip_origen: '190.145.20.10',
    id_sesion_oracle: 'SID: 98 (Audsid: 89901)',
    fecha_inicio: '2026-10-10 20:20:00',
    fecha_fin: '2026-10-10 20:20:00',
    duracion_ms: 18.40,
    estado: 'EXITO',
    total_llamados: 2,
    json_entrada: JSON.stringify({
      nombre_usuario: 'admin.acme',
      ip_origen: '190.145.20.10'
    }, null, 2),
    json_salida: JSON.stringify({
      codigo: 0,
      mensaje: 'Autenticación exitosa',
      datos: { id_sesion: 890, roles: ['ROL_ADMIN'] }
    }, null, 2)
  },
  {
    id: 103,
    id_tenant: 1,
    id_usuario: 2,
    nombre_paquete: 'pkgln_usuarios',
    nombre_metodo: 'p_crear_usuario',
    codigo_traza: 'TRZ-20261010-8835',
    ip_origen: '186.155.80.4',
    id_sesion_oracle: 'SID: 110 (Audsid: 89845)',
    fecha_inicio: '2026-10-10 19:55:12',
    fecha_fin: '2026-10-10 19:55:12',
    duracion_ms: 12.80,
    estado: 'ERROR',
    codigo_error: -20001,
    mensaje_error: 'ORA-20001: El correo electrónico ya se encuentra registrado por otro usuario activo.',
    total_llamados: 2,
    json_entrada: JSON.stringify({
      id_tenant: 1,
      datos: { nombre_usuario: 'duplicado', correo: 'admin@acme.com' }
    }, null, 2),
    json_salida: JSON.stringify({
      codigo: -20001,
      mensaje: 'El correo electrónico ya se encuentra registrado por otro usuario activo.'
    }, null, 2)
  }
];

export let mockLlamados: TrazaLlamado[] = [
  {
    id: 1001,
    id_tenant: 1,
    id_ejecucion: 101,
    orden_llamado: 1,
    nivel_anidamiento: 1,
    tipo_llamado: 'ORQUESTADOR_PKGLN',
    paquete_llamado: 'pkgln_usuarios',
    metodo_llamado: 'p_crear_usuario',
    duracion_ms: 42.15,
    estado: 'EXITO'
  },
  {
    id: 1002,
    id_tenant: 1,
    id_ejecucion: 101,
    id_llamado_padre: 1001,
    orden_llamado: 2,
    nivel_anidamiento: 2,
    tipo_llamado: 'DAO',
    paquete_llamado: 'pkgcore_persona_dao',
    metodo_llamado: 'f_existe',
    duracion_ms: 4.20,
    estado: 'EXITO'
  },
  {
    id: 1003,
    id_tenant: 1,
    id_ejecucion: 101,
    id_llamado_padre: 1001,
    orden_llamado: 3,
    nivel_anidamiento: 2,
    tipo_llamado: 'DAO',
    paquete_llamado: 'pkgcore_persona_dao',
    metodo_llamado: 'p_insertar',
    duracion_ms: 12.50,
    estado: 'EXITO'
  },
  {
    id: 1004,
    id_tenant: 1,
    id_ejecucion: 101,
    id_llamado_padre: 1001,
    orden_llamado: 4,
    nivel_anidamiento: 2,
    tipo_llamado: 'DAO',
    paquete_llamado: 'pkgcore_usuario_dao',
    metodo_llamado: 'p_insertar',
    duracion_ms: 15.30,
    estado: 'EXITO'
  }
];
