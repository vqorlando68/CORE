import { NextRequest, NextResponse } from 'next/server';
import { getOracleConnection } from '@/lib/db';
import { Aplicacion } from '@/lib/types';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const tenantId = searchParams.get('tenantId');

  const conn = await getOracleConnection();
  if (!conn) {
    return NextResponse.json(
      { success: false, error: 'No se pudo conectar a Oracle Database. Verifique las credenciales en .env' },
      { status: 500 }
    );
  }

  try {
    let query = `
      SELECT a.id, a.codigo, a.nombre, a.descripcion, a.version, a.estado
        FROM core_aplicacion a
       ORDER BY a.id ASC
    `;

    if (tenantId) {
      query = `
        SELECT a.id, a.codigo, a.nombre, a.descripcion, a.version, a.estado,
               NVL(at.habilitada, 0) AS habilitada
          FROM core_aplicacion a,
               core_app_tenant at
         WHERE a.id = at.id_aplicacion(+)
           AND at.id_tenant(+) = :tenantId
         ORDER BY a.id ASC
      `;
    }

    const res = await conn.execute(query, tenantId ? { tenantId: Number(tenantId) } : {});
    await conn.close();

    const apps: Aplicacion[] = (res.rows || []).map((r: any) => ({
      id: r[0],
      codigo: r[1],
      nombre: r[2],
      descripcion: r[3],
      version: r[4],
      estado: r[5],
      habilitada: tenantId ? r[6] : 1,
      total_modulos: 3
    }));

    return NextResponse.json({ success: true, source: 'ORACLE_CLOUD', data: apps });
  } catch (err: any) {
    try { await conn.close(); } catch {}
    return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { codigo, nombre, descripcion, version, estado } = body;

    if (!codigo || !nombre) {
      return NextResponse.json({ success: false, error: 'Código y nombre de aplicación son requeridos' }, { status: 400 });
    }

    const conn = await getOracleConnection();
    if (!conn) {
      return NextResponse.json({ success: false, error: 'No se pudo conectar a Oracle Database' }, { status: 500 });
    }

    try {
      const insertSql = `
        INSERT INTO core_aplicacion (codigo, nombre, descripcion, version, estado)
        VALUES (:codigo, :nombre, :descripcion, :version, :estado)
        RETURNING id INTO :out_id
      `;
      const odb = await import('oracledb');
      const res = await conn.execute(insertSql, {
        codigo: codigo.toUpperCase(),
        nombre,
        descripcion: descripcion || '',
        version: version || '1.0.0',
        estado: estado || 'ACTIVA',
        out_id: { type: odb.default.NUMBER, dir: odb.default.BIND_OUT }
      }, { autoCommit: true });

      const newId = (res.outBinds as any).out_id[0];
      await conn.close();

      return NextResponse.json({
        success: true,
        source: 'ORACLE_CLOUD',
        data: { id: newId, codigo: codigo.toUpperCase(), nombre, version: version || '1.0.0', estado: 'ACTIVA' }
      });
    } catch (err: any) {
      try { await conn.close(); } catch {}
      return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
    }
  } catch (err: any) {
    return NextResponse.json({ success: false, error: err.message }, { status: 500 });
  }
}
