import { NextRequest, NextResponse } from 'next/server';
import { getOracleConnection } from '@/lib/db';
import { Tenant } from '@/lib/types';

export async function GET() {
  const conn = await getOracleConnection();
  if (!conn) {
    return NextResponse.json(
      { success: false, error: 'No se pudo establecer conexión con Oracle Database. Verifique las credenciales en .env' },
      { status: 500 }
    );
  }

  try {
    const res = await conn.execute(
      `SELECT id, codigo, nombre, id_plan, nit_empresa, contacto_correo, contacto_telefono, pais, estado,
              TO_CHAR(fecha_creacion, 'YYYY-MM-DD HH24:MI:SS') AS fecha_creacion
         FROM core_tenant
        WHERE estado = 1
        ORDER BY id ASC`
    );
    await conn.close();

    const tenants: Tenant[] = (res.rows || []).map((r: any) => ({
      id: r[0],
      codigo: r[1],
      nombre: r[2],
      id_plan: r[3],
      nit_empresa: r[4],
      contacto_correo: r[5],
      contacto_telefono: r[6],
      pais: r[7],
      estado: r[8],
      fecha_creacion: r[9]
    }));

    return NextResponse.json({ success: true, source: 'ORACLE_CLOUD', data: tenants });
  } catch (err: any) {
    try { await conn.close(); } catch {}
    return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { codigo, nombre, id_plan, nit_empresa, contacto_correo, contacto_telefono, pais } = body;

    if (!codigo || !nombre || !contacto_correo) {
      return NextResponse.json({ success: false, error: 'Código, nombre y correo de contacto son obligatorios' }, { status: 400 });
    }

    const conn = await getOracleConnection();
    if (!conn) {
      return NextResponse.json({ success: false, error: 'No se pudo conectar a Oracle Database' }, { status: 500 });
    }

    try {
      const insertSql = `
        INSERT INTO core_tenant (codigo, nombre, id_plan, nit_empresa, contacto_correo, contacto_telefono, pais, estado)
        VALUES (:codigo, :nombre, :id_plan, :nit_empresa, :contacto_correo, :contacto_telefono, :pais, 1)
        RETURNING id INTO :out_id
      `;
      const odb = await import('oracledb');
      const res = await conn.execute(insertSql, {
        codigo: codigo.toUpperCase(),
        nombre,
        id_plan: id_plan || 'STANDARD',
        nit_empresa: nit_empresa || null,
        contacto_correo,
        contacto_telefono: contacto_telefono || null,
        pais: pais || 'CO',
        out_id: { type: odb.default.NUMBER, dir: odb.default.BIND_OUT }
      }, { autoCommit: true });

      const newId = (res.outBinds as any).out_id[0];
      await conn.close();

      return NextResponse.json({
        success: true,
        source: 'ORACLE_CLOUD',
        data: { id: newId, codigo: codigo.toUpperCase(), nombre, id_plan, estado: 1 }
      });
    } catch (err: any) {
      try { await conn.close(); } catch {}
      return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
    }
  } catch (err: any) {
    return NextResponse.json({ success: false, error: err.message }, { status: 500 });
  }
}
