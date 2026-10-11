import { NextRequest, NextResponse } from 'next/server';
import { getOracleConnection } from '@/lib/db';
import { Usuario } from '@/lib/types';

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
    // Regla Institucional CORE: Sintaxis tradicional Oracle (NO ANSI JOIN)
    const query = `
      SELECT u.id, u.id_tenant, u.id_persona, u.nombre_usuario, u.correo_electronico,
             NVL(p.nombre_completo, u.nombre_usuario) AS nombre_completo,
             NVL(p.tipo, 'CC') AS tipo_documento,
             NVL(p.identificacion, '-') AS numero_documento,
             u.estado_registro AS estado,
             u.bloqueado,
             u.intentos_fallidos,
             TO_CHAR(u.ultimo_ingreso, 'YYYY-MM-DD HH24:MI:SS') AS ultimo_ingreso
        FROM core_usuario u,
             core_persona p
       WHERE p.id(+) = u.id_persona
         AND u.id_tenant = :tenantId
       ORDER BY u.id ASC
    `;

    const res = await conn.execute(query, { tenantId: Number(tenantId) });
    await conn.close();

    const users: Usuario[] = (res.rows || []).map((r: any) => {
      const nombreCompleto = r[5] || '';
      const partes = nombreCompleto.split(' ');
      return {
        id: r[0],
        id_tenant: r[1],
        id_persona: r[2],
        nombre_usuario: r[3],
        correo_electronico: r[4],
        primer_nombre: partes[0] || r[3],
        primer_apellido: partes.slice(1).join(' ') || '',
        tipo_documento: r[6],
        numero_documento: r[7],
        estado: r[8],
        bloqueado: r[9],
        intentos_fallidos: r[10],
        ultimo_ingreso: r[11] || '-',
        roles: ['ROL_OPERADOR']
      };
    });

    return NextResponse.json({ success: true, source: 'ORACLE_CLOUD', data: users });
  } catch (err: any) {
    try { await conn.close(); } catch {}
    return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { id_tenant, nombre_usuario, correo_electronico, primer_nombre, primer_apellido, tipo_documento, numero_documento } = body;

    if (!nombre_usuario || !correo_electronico) {
      return NextResponse.json({ success: false, error: 'Nombre de usuario y correo son obligatorios' }, { status: 400 });
    }

    const tenant = Number(id_tenant) || 1;

    const conn = await getOracleConnection();
    if (!conn) {
      return NextResponse.json({ success: false, error: 'No se pudo conectar a Oracle Database' }, { status: 500 });
    }

    try {
      const odb = await import('oracledb');
      const nombreCompleto = `${primer_nombre || ''} ${primer_apellido || ''}`.trim() || nombre_usuario;

      // Inserción coordinada: 1. Persona, 2. Usuario
      const insertPersonaSql = `
        INSERT INTO core_persona (id_tenant, tipo, identificacion, nombre_completo, correo_principal, es_activo, estado_registro)
        VALUES (:id_tenant, :tipo, :identificacion, :nombre_completo, :correo, 1, 1)
        RETURNING id INTO :out_id
      `;
      const resP = await conn.execute(insertPersonaSql, {
        id_tenant: tenant,
        tipo: tipo_documento || 'CC',
        identificacion: numero_documento || '0',
        nombre_completo: nombreCompleto,
        correo: correo_electronico,
        out_id: { type: odb.default.NUMBER, dir: odb.default.BIND_OUT }
      });
      const idPersona = (resP.outBinds as any).out_id[0];

      const insertUserSql = `
        INSERT INTO core_usuario (id_tenant, id_persona, nombre_usuario, correo_electronico, bloqueado, intentos_fallidos, estado_registro)
        VALUES (:id_tenant, :id_persona, :nombre_usuario, :correo_electronico, 0, 0, 1)
        RETURNING id INTO :out_id
      `;
      const resU = await conn.execute(insertUserSql, {
        id_tenant: tenant,
        id_persona: idPersona,
        nombre_usuario,
        correo_electronico,
        out_id: { type: odb.default.NUMBER, dir: odb.default.BIND_OUT }
      }, { autoCommit: true });

      const idUsuario = (resU.outBinds as any).out_id[0];
      await conn.close();

      return NextResponse.json({
        success: true,
        source: 'ORACLE_CLOUD',
        data: {
          id: idUsuario,
          id_tenant: tenant,
          id_persona: idPersona,
          nombre_usuario,
          correo_electronico,
          primer_nombre,
          primer_apellido,
          estado: 1
        }
      });
    } catch (err: any) {
      try { await conn.close(); } catch {}
      return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
    }
  } catch (err: any) {
    return NextResponse.json({ success: false, error: err.message }, { status: 500 });
  }
}
