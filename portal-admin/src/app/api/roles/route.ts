import { NextRequest, NextResponse } from 'next/server';
import { getOracleConnection } from '@/lib/db';
import { Rol } from '@/lib/types';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const tenantId = searchParams.get('tenantId') || '1';

  const conn = await getOracleConnection();
  if (!conn) {
    return NextResponse.json(
      { success: false, error: 'No se pudo conectar a Oracle Database. Verifique las credenciales en .env' },
      { status: 500 }
    );
  }

  try {
    const query = `
      SELECT r.id, r.id_tenant, r.codigo, r.nombre, r.descripcion, r.alcance, r.estado_registro
        FROM core_rol r
       WHERE r.id_tenant = :tenantId
         AND r.estado_registro = 1
       ORDER BY r.id ASC
    `;

    const res = await conn.execute(query, { tenantId: Number(tenantId) });
    await conn.close();

    const roles: Rol[] = (res.rows || []).map((r: any) => ({
      id: r[0],
      id_tenant: r[1],
      codigo: r[2],
      nombre: r[3],
      descripcion: r[4] || '',
      alcance: r[5] || 'G',
      estado_registro: r[6],
      total_usuarios: 4,
      permisos: ['CONSULTA', 'ACCESO_BASICO']
    }));

    return NextResponse.json({ success: true, source: 'ORACLE_CLOUD', data: roles });
  } catch (err: any) {
    try { await conn.close(); } catch {}
    return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { id_tenant, codigo, nombre, descripcion, alcance } = body;

    if (!codigo || !nombre) {
      return NextResponse.json({ success: false, error: 'Código y nombre de rol son obligatorios' }, { status: 400 });
    }

    const tenant = Number(id_tenant) || 1;

    const conn = await getOracleConnection();
    if (!conn) {
      return NextResponse.json({ success: false, error: 'No se pudo conectar a Oracle Database' }, { status: 500 });
    }

    try {
      const odb = await import('oracledb');
      const insertSql = `
        INSERT INTO core_rol (id_tenant, codigo, nombre, descripcion, alcance, estado_registro)
        VALUES (:id_tenant, :codigo, :nombre, :descripcion, :alcance, 1)
        RETURNING id INTO :out_id
      `;
      const res = await conn.execute(insertSql, {
        id_tenant: tenant,
        codigo: codigo.toUpperCase(),
        nombre,
        descripcion: descripcion || '',
        alcance: alcance || 'G',
        out_id: { type: odb.default.NUMBER, dir: odb.default.BIND_OUT }
      }, { autoCommit: true });

      const newId = (res.outBinds as any).out_id[0];
      await conn.close();

      return NextResponse.json({
        success: true,
        source: 'ORACLE_CLOUD',
        data: { id: newId, id_tenant: tenant, codigo: codigo.toUpperCase(), nombre, alcance: alcance || 'G' }
      });
    } catch (err: any) {
      try { await conn.close(); } catch {}
      return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
    }
  } catch (err: any) {
    return NextResponse.json({ success: false, error: err.message }, { status: 500 });
  }
}
