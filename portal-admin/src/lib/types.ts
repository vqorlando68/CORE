// ============================================================================
// TIPOS Y MODELOS DE DATOS DE LA PLATAFORMA CORE SAAS
// ============================================================================

export interface Tenant {
  id: number;
  codigo: string;
  nombre: string;
  id_plan: 'STARTER' | 'BUSINESS' | 'ENTERPRISE';
  nit_empresa?: string;
  contacto_correo: string;
  contacto_telefono?: string;
  pais: string;
  estado: number; // 1 = Activo, 0 = Inactivo
  fecha_creacion?: string;
}

export interface Aplicacion {
  id: number;
  codigo: string;
  nombre: string;
  descripcion: string;
  version: string;
  estado: string; // ACTIVA, MANTENIMIENTO, DEPRECADA
  habilitada?: number;
  total_modulos?: number;
}

export interface ModuloApp {
  id: number;
  id_aplicacion: number;
  codigo: string;
  nombre: string;
  descripcion?: string;
  icono?: string;
  ruta?: string;
  orden?: number;
  estado: number;
}

export interface Usuario {
  id: number;
  id_tenant: number;
  id_persona: number;
  nombre_usuario: string;
  correo_electronico: string;
  primer_nombre: string;
  primer_apellido: string;
  tipo_documento?: string;
  numero_documento?: string;
  estado: number; // 1 = Activo, 0 = Inactivo
  bloqueado: number;
  intentos_fallidos: number;
  ultimo_ingreso?: string;
  roles?: string[];
}

export interface Rol {
  id: number;
  id_tenant: number;
  codigo: string;
  nombre: string;
  descripcion?: string;
  alcance: 'G' | 'S' | 'O'; // Global, Sucursal, Operativo
  estado_registro: number;
  total_usuarios?: number;
  permisos?: string[];
}

export interface DocumentacionMetodo {
  id: number;
  id_tenant: number;
  id_aplicacion?: number;
  id_modulo?: number;
  nombre_paquete: string;
  nombre_metodo: string;
  titulo_funcional: string;
  resumen_ejecutivo: string;
  descripcion_negocio: string;
  actor_principal?: string;
  flujo_funcional_pasos?: string;
  reglas_validacion?: string;
  descripcion_entrada_natural: string;
  ejemplo_json_entrada: string;
  descripcion_salida_natural: string;
  ejemplo_json_salida: string;
  excepciones_negocio?: string;
  requiere_autenticacion: number;
  permiso_requerido?: string;
  version_metodo: string;
  estado_publicacion: 'BORRADOR' | 'PUBLICADO' | 'DEPRECADO';
  categoria_visual: 'SEGURIDAD' | 'OPERATIVO' | 'TELEMETRIA' | 'CONFIGURACION' | 'FACTURACION';
  icono_interfaz: string;
  color_distintivo: string;
  etiquetas_busqueda?: string;
  estado_registro: number;
  fecha_creacion?: string;
  fecha_modificacion?: string;
}

export interface TrazaEjecucion {
  id: number;
  id_tenant: number;
  id_config?: number;
  id_objeto?: number;
  id_usuario?: number;
  nombre_paquete: string;
  nombre_metodo: string;
  codigo_traza: string;
  ip_origen?: string;
  id_sesion_oracle?: string;
  fecha_inicio: string;
  fecha_fin?: string;
  duracion_ms?: number;
  estado: 'EN_PROCESO' | 'EXITO' | 'ERROR' | 'TIMEOUT';
  codigo_error?: number;
  mensaje_error?: string;
  json_entrada?: string;
  json_salida?: string;
  total_llamados: number;
}

export interface TrazaLlamado {
  id: number;
  id_tenant: number;
  id_ejecucion: number;
  id_llamado_padre?: number;
  orden_llamado: number;
  nivel_anidamiento: number;
  tipo_llamado: 'ORQUESTADOR_PKGLN' | 'LOGICA_PKGCN' | 'DAO' | 'FUNCION' | 'REST_API' | 'PLSQL_SUBPROGRAM';
  paquete_llamado: string;
  metodo_llamado: string;
  parametros_enviados?: string;
  parametros_recibidos?: string;
  duracion_ms?: number;
  estado: 'EXITO' | 'ERROR' | 'OMITIDO';
  codigo_error?: number;
  mensaje_error?: string;
}

export interface DbHealthStatus {
  conectado: boolean;
  modo: 'ORACLE_CLOUD' | 'SIMULADOR_OFFLINE';
  mensaje: string;
  database?: string;
  servicio?: string;
  hora_servidor?: string;
  wallet_detectado: boolean;
}
