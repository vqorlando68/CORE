import { NextRequest, NextResponse } from 'next/server';
import { getOracleConnection } from '@/lib/db';
import { TrazaEjecucion, TrazaLlamado } from '@/lib/types';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const tenantId = searchParams.get('tenantId') || '1';
  const executionId = searchParams.get('executionId');

  const conn = await getOracleConnection();
  if (!conn) {
    return NextResponse.json(
      { success: false, error: 'No se pudo conectar a Oracle Database. Verifique las credenciales en .env' },
      { status: 500 }
    );
  }

  // Si se solicita el detalle de una ejecución en particular (call stack / spans)
  if (executionId) {
    try {
      const queryLlamados = `
        SELECT id, id_tenant, id_ejecucion, id_llamado_padre, orden_llamado,
               nivel_anidamiento, tipo_llamado, paquete_llamado, metodo_llamado,
               duracion_ms, estado, codigo_error, mensaje_error
          FROM core_traza_llamado
         WHERE id_ejecucion = :executionId
         ORDER BY orden_llamado ASC
      `;
      const resLl = await conn.execute(queryLlamados, { executionId: Number(executionId) });
      await conn.close();

      const llamados: TrazaLlamado[] = (resLl.rows || []).map((r: any) => ({
        id: r[0],
        id_tenant: r[1],
        id_ejecucion: r[2],
        id_llamado_padre: r[3],
        orden_llamado: r[4],
        nivel_anidamiento: r[5],
        tipo_llamado: r[6],
        paquete_llamado: r[7],
        metodo_llamado: r[8],
        duracion_ms: r[9],
        estado: r[10],
        codigo_error: r[11],
        mensaje_error: r[12]
      }));

      return NextResponse.json({ success: true, source: 'ORACLE_CLOUD', data: llamados });
    } catch (err: any) {
      try { await conn.close(); } catch {}
      return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
    }
  }

  // Lista de ejecuciones generales
  try {
    const queryTrazas = `
      SELECT id, id_tenant, id_config, id_objeto, id_usuario,
             nombre_paquete, nombre_metodo, codigo_traza, ip_origen, id_sesion_oracle,
             TO_CHAR(fecha_inicio, 'YYYY-MM-DD HH24:MI:SS') AS fecha_inicio,
             TO_CHAR(fecha_fin, 'YYYY-MM-DD HH24:MI:SS') AS fecha_fin,
             duracion_ms, estado, codigo_error, mensaje_error,
             json_entrada, json_salida, total_llamados
        FROM core_traza_ejecucion
       WHERE id_tenant = :tenantId
       ORDER BY fecha_inicio DESC
       FETCH FIRST 50 ROWS ONLY
    `;

    const res = await conn.execute(queryTrazas, { tenantId: Number(tenantId) });
    await conn.close();

    const trazas: TrazaEjecucion[] = (res.rows || []).map((r: any) => ({
      id: r[0],
      id_tenant: r[1],
      id_config: r[2],
      id_objeto: r[3],
      id_usuario: r[4],
      nombre_paquete: r[5],
      nombre_metodo: r[6],
      codigo_traza: r[7],
      ip_origen: r[8],
      id_sesion_oracle: r[9],
      fecha_inicio: r[10],
      fecha_fin: r[11],
      duracion_ms: r[12],
      estado: r[13],
      codigo_error: r[14],
      mensaje_error: r[15],
      json_entrada: r[16],
      json_salida: r[17],
      total_llamados: r[18]
    }));

    return NextResponse.json({ success: true, source: 'ORACLE_CLOUD', data: trazas });
  } catch (err: any) {
    try { await conn.close(); } catch {}
    return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
  }
}
