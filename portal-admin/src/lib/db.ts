// ============================================================================
// CONEXIÓN A ORACLE DATABASE 23ai / 26ai CON SOPORTE PARA WALLET EN VERCEL
// ============================================================================
import fs from 'fs';
import path from 'path';
import AdmZip from 'adm-zip';
import { DbHealthStatus } from './types';

// Variable global de caché para el pool o inicialización
let walletExtractPath: string | null = null;
let oracledb: any = null;

/**
 * Inicializa y extrae el Wallet_CORE.zip si está presente
 */
export function ensureWalletExtracted(): string | null {
  if (walletExtractPath && fs.existsSync(/*turbopackIgnore: true*/ walletExtractPath)) {
    return walletExtractPath;
  }

  // Rutas donde puede estar el zip
  const possibleZipPaths = [
    path.join(process.cwd(), 'Wallet_CORE.zip'),
    path.join(process.cwd(), '..', 'Wallet_CORE.zip'),
    path.join(process.cwd(), 'wallet', 'Wallet_CORE.zip')
  ];

  const zipPath = possibleZipPaths.find(p => fs.existsSync(/*turbopackIgnore: true*/ p));

  // Destino de extracción
  const isVercel = process.env.VERCEL === '1';
  const targetDir = isVercel 
    ? path.join('/tmp', 'oracle_wallet') 
    : path.join(process.cwd(), '.wallet_cache');

  if (zipPath) {
    try {
      if (!fs.existsSync(/*turbopackIgnore: true*/ targetDir)) {
        fs.mkdirSync(targetDir, { recursive: true });
      }
      const zip = new AdmZip(zipPath);
      zip.extractAllTo(targetDir, true);
      walletExtractPath = targetDir;
      return targetDir;
    } catch (err) {
      console.warn('Advertencia: No se pudo descomprimir Wallet_CORE.zip:', err);
    }
  }

  return null;
}

/**
 * Intenta cargar dinámicamente node-oracledb
 */
async function getOracledb() {
  if (!oracledb) {
    try {
      const mod = await import('oracledb');
      oracledb = mod.default || mod;
      
      // Modo Thin nativo (sin necesidad de binarios Instant Client en Vercel)
      if (oracledb) {
        oracledb.fetchAsString = [ oracledb.CLOB ];
      }
    } catch (err) {
      console.warn('node-oracledb no pudo ser cargado en este entorno:', err);
      return null;
    }
  }
  return oracledb;
}

/**
 * Obtiene una conexión a Oracle si las credenciales están configuradas
 */
export async function getOracleConnection() {
  const odb = await getOracledb();
  if (!odb) return null;

  const user = process.env.ORACLE_USER || process.env.DB_USER;
  const password = process.env.ORACLE_PASSWORD || process.env.DB_PASSWORD;
  const connectString = process.env.ORACLE_CONNECT_STRING || process.env.DB_CONNECT_STRING || 'core_high';

  if (!user || !password) {
    return null; // Modo autónomo / Mock
  }

  const walletDir = ensureWalletExtracted();

  try {
    const connConfig: any = {
      user,
      password,
      connectString
    };

    if (walletDir) {
      connConfig.configDir = walletDir;
      connConfig.walletLocation = walletDir;
      if (process.env.WALLET_PASSWORD) {
        connConfig.walletPassword = process.env.WALLET_PASSWORD;
      }
    }

    const connection = await odb.getConnection(connConfig);
    return connection;
  } catch (err) {
    console.error('Error al conectar a Oracle Database con Wallet:', err);
    return null;
  }
}

/**
 * Verifica el estado y salud de la conexión a Oracle
 */
export async function checkDatabaseHealth(): Promise<DbHealthStatus> {
  const walletDir = ensureWalletExtracted();
  const user = process.env.ORACLE_USER || process.env.DB_USER;
  const connectString = process.env.ORACLE_CONNECT_STRING || process.env.DB_CONNECT_STRING || 'core_high';

  if (!user) {
    return {
      conectado: false,
      modo: 'SIMULADOR_OFFLINE',
      mensaje: 'Modo Autónomo Local (Semilla CORE activa). Para conectar a Oracle Cloud, defina ORACLE_USER y ORACLE_PASSWORD en variables de entorno.',
      servicio: connectString,
      wallet_detectado: !!walletDir
    };
  }

  const conn = await getOracleConnection();
  if (conn) {
    try {
      const result = await conn.execute(
        `SELECT TO_CHAR(CAST(SYSTIMESTAMP AT TIME ZONE 'America/Bogota' AS DATE), 'YYYY-MM-DD HH24:MI:SS') AS hora_bogota,
                SYS_CONTEXT('USERENV', 'DB_NAME') AS db_name
           FROM DUAL`
      );
      await conn.close();

      const row = (result.rows && result.rows[0]) as any;
      return {
        conectado: true,
        modo: 'ORACLE_CLOUD',
        mensaje: 'Conectado exitosamente a Oracle Cloud Autonomous Database con Wallet TLS.',
        database: row ? row[1] : 'CORE',
        hora_servidor: row ? row[0] : new Date().toISOString(),
        servicio: connectString,
        wallet_detectado: true
      };
    } catch (err: any) {
      try { await conn.close(); } catch {}
      return {
        conectado: false,
        modo: 'SIMULADOR_OFFLINE',
        mensaje: `Error al consultar Oracle: ${err.message}. Operando en modo de respaldo.`,
        servicio: connectString,
        wallet_detectado: !!walletDir
      };
    }
  }

  return {
    conectado: false,
    modo: 'SIMULADOR_OFFLINE',
    mensaje: 'No fue posible abrir conexión con el Wallet provisto. Operando con catálogo simulado.',
    servicio: connectString,
    wallet_detectado: !!walletDir
  };
}
