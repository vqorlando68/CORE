import { NextRequest, NextResponse } from 'next/server';
import { getOracleConnection } from '@/lib/db';
import { DocumentacionMetodo } from '@/lib/types';

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const tenantId = searchParams.get('tenantId') || '1';
  const categoria = searchParams.get('categoria');
  const busqueda = searchParams.get('q');

  const conn = await getOracleConnection();
  if (!conn) {
    return NextResponse.json(
      { success: false, error: 'No se pudo conectar a Oracle Database. Verifique las credenciales en .env' },
      { status: 500 }
    );
  }

  try {
    let query = `
      SELECT id, id_tenant, id_aplicacion, id_modulo, nombre_paquete, nombre_metodo,
             titulo_funcional, resumen_ejecutivo, descripcion_negocio, actor_principal,
             flujo_funcional_pasos, reglas_validacion,
             descripcion_entrada_natural, ejemplo_json_entrada,
             descripcion_salida_natural, ejemplo_json_salida,
             excepciones_negocio, requiere_autenticacion, permiso_requerido,
             version_metodo, estado_publicacion, categoria_visual, icono_interfaz,
             color_distintivo, etiquetas_busqueda, estado_registro,
             TO_CHAR(fecha_creacion, 'YYYY-MM-DD HH24:MI:SS') AS fecha_creacion
        FROM core_documentacion_metodo
       WHERE id_tenant = :tenantId
         AND estado_registro = 1
    `;

    const binds: any = { tenantId: Number(tenantId) };

    if (categoria && categoria !== 'ALL') {
      query += ` AND categoria_visual = :categoria`;
      binds.categoria = categoria;
    }

    if (busqueda) {
      query += ` AND (LOWER(titulo_funcional) LIKE :busqueda 
                   OR LOWER(nombre_paquete) LIKE :busqueda 
                   OR LOWER(nombre_metodo) LIKE :busqueda 
                   OR LOWER(etiquetas_busqueda) LIKE :busqueda)`;
      binds.busqueda = `%${busqueda.toLowerCase()}%`;
    }

    query += ` ORDER BY categoria_visual, nombre_paquete, nombre_metodo`;

    const res = await conn.execute(query, binds);
    await conn.close();

    const docs: DocumentacionMetodo[] = (res.rows || []).map((r: any) => ({
      id: r[0],
      id_tenant: r[1],
      id_aplicacion: r[2],
      id_modulo: r[3],
      nombre_paquete: r[4],
      nombre_metodo: r[5],
      titulo_funcional: r[6],
      resumen_ejecutivo: r[7],
      descripcion_negocio: r[8],
      actor_principal: r[9],
      flujo_funcional_pasos: r[10],
      reglas_validacion: r[11],
      descripcion_entrada_natural: r[12],
      ejemplo_json_entrada: r[13],
      descripcion_salida_natural: r[14],
      ejemplo_json_salida: r[15],
      excepciones_negocio: r[16],
      requiere_autenticacion: r[17],
      permiso_requerido: r[18],
      version_metodo: r[19],
      estado_publicacion: r[20],
      categoria_visual: r[21],
      icono_interfaz: r[22] || 'lucide-cpu',
      color_distintivo: r[23] || '#3b82f6',
      etiquetas_busqueda: r[24],
      estado_registro: r[25],
      fecha_creacion: r[26]
    }));

    return NextResponse.json({ success: true, source: 'ORACLE_CLOUD', data: docs });
  } catch (err: any) {
    try { await conn.close(); } catch {}
    return NextResponse.json({ success: false, error: `Error Oracle: ${err.message}` }, { status: 500 });
  }
}
