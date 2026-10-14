'use client';

import React, { useState, useMemo } from 'react';
import { 
  ZoomIn, 
  ZoomOut, 
  RotateCcw, 
  ListOrdered, 
  GitBranch, 
  Sparkles, 
  Code2, 
  Database, 
  Check, 
  Copy,
  Layers,
  ArrowRight,
  ShieldCheck,
  CheckCircle2,
  AlertTriangle
} from 'lucide-react';

export type DiagramStyle = 'modern' | 'timeline';

interface FlowchartDiagramProps {
  pasosTexto: string;
  tituloMetodo?: string;
  defaultStyle?: DiagramStyle;
}

interface FlowNode {
  id: string;
  stepNumber?: number;
  type: 'start' | 'process' | 'decision' | 'end';
  label: string;
  invokedMethod?: string;
  methodType?: 'dao' | 'service' | 'utility' | 'table' | 'transaction';
  yesLabel?: string;
  yesAction?: string;
  yesMethod?: string;
  noLabel?: string;
}

// Extractor heurístico inteligente de métodos PL/SQL y tablas
function extractInvokedMethod(text: string): { cleanText: string; method?: string; type?: FlowNode['methodType'] } {
  // 1. Detección explícita mediante corchetes o flecha: [metodo: ...] o -> metodo o (Invoca: ...)
  const explicitMatch = text.match(/(?:\[(?:metodo|invoca|llama):\s*([^\]]+)\])|(?:->\s*([a-zA-Z0-9_\.]+))|(?:\((?:Invoca|Llama):\s*([^\)]+)\))/i);
  if (explicitMatch) {
    const rawMethod = (explicitMatch[1] || explicitMatch[2] || explicitMatch[3]).trim();
    const cleanText = text.replace(explicitMatch[0], '').trim();
    return { cleanText, method: rawMethod, type: determineMethodType(rawMethod) };
  }

  // 2. Detección de patrones explícitos de paquetes en el texto: uti_*_pkg.*, pkg*.*, etc.
  const packageMatch = text.match(/\b(uti_[a-zA-Z0-9_]+_pkg\.[a-zA-Z0-9_]+|pkgcore_[a-zA-Z0-9_]+_dao\.[a-zA-Z0-9_]+|pkgln_[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+|pkgcn_[a-zA-Z0-9_]+\.[a-zA-Z0-9_]+|p_do_commit(?:\(\))?)\b/i);
  if (packageMatch) {
    const rawMethod = packageMatch[0];
    return { cleanText: text, method: rawMethod, type: determineMethodType(rawMethod) };
  }

  // 3. Detección semántica contextual basada en estándares de AGENTS.md
  const lower = text.toLowerCase();
  
  if (lower.includes('dao de persona') || (lower.includes('persona') && (lower.includes('registra') || lower.includes('dao')))) {
    return { cleanText: text, method: 'PKGCORE_PERSONA_DAO.p_insertar', type: 'dao' };
  }
  if (lower.includes('dao de usuario') || (lower.includes('usuario') && lower.includes('cuenta'))) {
    return { cleanText: text, method: 'PKGCORE_USUARIO_DAO.p_insertar', type: 'dao' };
  }
  if (lower.includes('core_traza_ejecucion') || (lower.includes('telemetría') && lower.includes('inicia'))) {
    return { cleanText: text, method: 'uti_manejo_trazas_pkg.p_iniciar_traza', type: 'utility' };
  }
  if (lower.includes('core_traza_config') || lower.includes('regla exige seguimiento') || lower.includes('configuración activa para el tenant')) {
    return { cleanText: text, method: 'uti_manejo_trazas_pkg.f_debe_trazar', type: 'utility' };
  }
  if (lower.includes('trace id') || lower.includes('código de traza')) {
    return { cleanText: text, method: 'uti_manejo_trazas_pkg.p_iniciar_traza', type: 'utility' };
  }
  if (lower.includes('core_error') || lower.includes('graba log') || lower.includes('excepción')) {
    return { cleanText: text, method: 'uti_ge_excepciones_pkg.p_grabar_log', type: 'utility' };
  }
  if (lower.includes('commit') || lower.includes('confirma') || lower.includes('transacción controlada')) {
    return { cleanText: text, method: 'p_do_commit()', type: 'transaction' };
  }
  if (lower.includes('asigna los roles') || lower.includes('rol')) {
    return { cleanText: text, method: 'PKGCORE_USUARIO_ROL_DAO.p_insertar', type: 'dao' };
  }

  // 4. Detección de tablas core_*
  const tableMatch = text.match(/\b(core_[a-zA-Z0-9_]+)\b/i);
  if (tableMatch) {
    return { cleanText: text, method: tableMatch[1], type: 'table' };
  }

  return { cleanText: text };
}

function determineMethodType(method: string): FlowNode['methodType'] {
  const m = method.toLowerCase();
  if (m.includes('_dao') || m.startsWith('pkgcore_')) return 'dao';
  if (m.includes('uti_') || m.includes('excepcion') || m.includes('traza')) return 'utility';
  if (m.includes('commit') || m.includes('rollback')) return 'transaction';
  if (m.startsWith('core_')) return 'table';
  return 'service';
}

export const FlowchartDiagram: React.FC<FlowchartDiagramProps> = ({ 
  pasosTexto, 
  tituloMetodo,
  defaultStyle = 'modern'
}) => {
  const [zoom, setZoom] = useState<number>(1);
  const [diagramStyle, setDiagramStyle] = useState<DiagramStyle>(defaultStyle);
  const [copiedMethod, setCopiedMethod] = useState<string | null>(null);

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedMethod(text);
    setTimeout(() => setCopiedMethod(null), 2000);
  };

  // Parser inteligente de los pasos para generar la estructura del diagrama
  const nodes = useMemo<FlowNode[]>(() => {
    if (!pasosTexto) return [];

    const lines = pasosTexto
      .split('\n')
      .map((l) => l.trim())
      .filter((l) => l.length > 0);

    const parsed: FlowNode[] = [];

    // Nodo 1: INICIO
    parsed.push({
      id: 'node-start',
      type: 'start',
      label: 'INICIO'
    });

    let stepCounter = 1;

    // Procesar cada línea de paso
    lines.forEach((line, index) => {
      // Limpiar prefijo numérico como "1. ", "2) "
      const cleanLine = line.replace(/^\d+[\.\)]\s*/, '').trim();
      const lower = cleanLine.toLowerCase();

      // Detectar si el paso representa una decisión / validación condicional
      const isDecision =
        lower.includes('si ') ||
        lower.includes('consulta si') ||
        lower.includes('valida si') ||
        lower.includes('existe ') ||
        lower.includes('¿') ||
        lower.includes('compara ');

      if (isDecision) {
        let condicion = cleanLine;
        let accionSi = 'Continuar flujo / Rechazar';

        if (cleanLine.includes(';')) {
          const partes = cleanLine.split(';');
          condicion = partes[0].trim();
          accionSi = partes[1].trim();
        } else if (cleanLine.includes(',')) {
          const partes = cleanLine.split(',');
          if (partes[0].toLowerCase().includes('si ') || partes[0].toLowerCase().includes('existe') || partes[0].toLowerCase().includes('consulta si')) {
            condicion = partes[0].trim();
            accionSi = partes.slice(1).join(',').trim();
          }
        }

        const condExtracted = extractInvokedMethod(condicion);
        const yesExtracted = extractInvokedMethod(accionSi);

        parsed.push({
          id: `node-decision-${index}`,
          stepNumber: stepCounter++,
          type: 'decision',
          label: condExtracted.cleanText,
          invokedMethod: condExtracted.method,
          methodType: condExtracted.type,
          yesLabel: 'SÍ',
          yesAction: yesExtracted.cleanText,
          yesMethod: yesExtracted.method,
          noLabel: 'NO'
        });
      } else {
        const extracted = extractInvokedMethod(cleanLine);
        parsed.push({
          id: `node-process-${index}`,
          stepNumber: stepCounter++,
          type: 'process',
          label: extracted.cleanText,
          invokedMethod: extracted.method,
          methodType: extracted.type
        });
      }
    });

    // Nodo Final: FIN
    parsed.push({
      id: 'node-end',
      type: 'end',
      label: 'FIN'
    });

    return parsed;
  }, [pasosTexto]);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '14px', width: '100%' }}>
      {/* Barra Superior de Controles: Selector de Estilos y Controles de Zoom */}
      <div 
        style={{ 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center', 
          flexWrap: 'wrap', 
          gap: '10px',
          padding: '8px 12px',
          background: 'var(--bg-surface)',
          borderRadius: 'var(--radius-md)',
          border: '1px solid var(--border-subtle)'
        }}
      >
        {/* Selector de Estilo del Diagrama */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          <span style={{ fontSize: '11.5px', fontWeight: 700, color: 'var(--text-muted)', textTransform: 'uppercase', marginRight: '4px' }}>
            Estilo Visual:
          </span>

          <button
            type="button"
            onClick={() => setDiagramStyle('modern')}
            className={`btn btn-sm ${diagramStyle === 'modern' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px' }}
          >
            <Sparkles size={13} />
            <span>Modern Glass (Enterprise)</span>
          </button>

          <button
            type="button"
            onClick={() => setDiagramStyle('timeline')}
            className={`btn btn-sm ${diagramStyle === 'timeline' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px' }}
          >
            <ListOrdered size={13} />
            <span>Línea de Tiempo</span>
          </button>
        </div>

        {/* Herramientas de Zoom */}
        {diagramStyle !== 'timeline' && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '11px', color: 'var(--text-muted)' }}>Zoom: {Math.round(zoom * 100)}%</span>
            <button
              type="button"
              onClick={() => setZoom((z) => Math.max(0.6, z - 0.1))}
              className="btn btn-secondary btn-sm"
              title="Reducir zoom"
              style={{ padding: '4px 8px' }}
            >
              <ZoomOut size={13} />
            </button>
            <button
              type="button"
              onClick={() => setZoom(1)}
              className="btn btn-secondary btn-sm"
              title="Restablecer zoom"
              style={{ padding: '4px 8px' }}
            >
              <RotateCcw size={13} />
            </button>
            <button
              type="button"
              onClick={() => setZoom((z) => Math.min(1.5, z + 0.1))}
              className="btn btn-secondary btn-sm"
              title="Aumentar zoom"
              style={{ padding: '4px 8px' }}
            >
              <ZoomIn size={13} />
            </button>
          </div>
        )}
      </div>

      {/* =========================================================================
          ESTILO 1: MODERN GLASS (ENTERPRISE WORKFLOW - ESTILO LINEAR / VERCEL)
          ========================================================================= */}
      {diagramStyle === 'modern' && (
        <div
          style={{
            background: 'radial-gradient(ellipse at 50% 0%, rgba(37, 99, 235, 0.06), transparent 75%), var(--bg-surface-elevated)',
            border: '1px solid var(--border-subtle)',
            borderRadius: 'var(--radius-lg)',
            padding: '48px 24px',
            overflowX: 'auto',
            overflowY: 'hidden',
            display: 'flex',
            justifyContent: 'center',
            minHeight: '520px',
            boxShadow: '0 8px 30px rgba(0, 0, 0, 0.08)'
          }}
        >
          <div
            style={{
              transform: `scale(${zoom})`,
              transformOrigin: 'top center',
              transition: 'transform 0.15s ease',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              width: '100%',
              maxWidth: '720px',
              position: 'relative'
            }}
          >
            {nodes.map((node) => {
              if (node.type === 'start') {
                return (
                  <React.Fragment key={node.id}>
                    {/* NODO TERMINAL MODERNO: INICIO */}
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        background: 'linear-gradient(135deg, rgba(37, 99, 235, 0.15), rgba(16, 185, 129, 0.15))',
                        border: '1.5px solid var(--color-primary)',
                        borderRadius: '9999px',
                        padding: '10px 32px',
                        fontWeight: 800,
                        fontSize: '15px',
                        letterSpacing: '1.5px',
                        color: 'var(--text-main)',
                        boxShadow: '0 4px 16px rgba(37, 99, 235, 0.2)',
                        backdropFilter: 'blur(8px)'
                      }}
                    >
                      <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#10b981', display: 'inline-block', boxShadow: '0 0 8px #10b981' }} />
                      <span>{node.label}</span>
                    </div>
                    <ModernArrowConnector />
                  </React.Fragment>
                );
              }

              if (node.type === 'process') {
                return (
                  <React.Fragment key={node.id}>
                    {/* TARJETA MODERNA DE PROCESO / ACCIÓN */}
                    <div
                      style={{
                        background: 'var(--bg-surface)',
                        border: '1px solid var(--border-subtle)',
                        borderRadius: '12px',
                        padding: '18px 22px',
                        width: '100%',
                        maxWidth: '480px',
                        boxShadow: '0 4px 20px rgba(0, 0, 0, 0.05)',
                        display: 'flex',
                        flexDirection: 'column',
                        gap: '10px',
                        transition: 'all 0.2s ease',
                        position: 'relative'
                      }}
                    >
                      {/* Cabecera del Paso */}
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{ fontSize: '11px', fontWeight: 800, color: 'var(--color-primary)', letterSpacing: '0.8px', textTransform: 'uppercase' }}>
                          Paso {node.stepNumber ? String(node.stepNumber).padStart(2, '0') : ''}
                        </span>
                        <span style={{ fontSize: '10.5px', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <Layers size={12} />
                          Acción de Negocio
                        </span>
                      </div>

                      {/* Descripción del Paso */}
                      <div style={{ fontSize: '13.5px', fontWeight: 600, color: 'var(--text-main)', lineHeight: '1.5' }}>
                        {node.label}
                      </div>

                      {/* Chip Destacado del Método Invocado */}
                      {node.invokedMethod && (
                        <MethodHighlightChip 
                          method={node.invokedMethod} 
                          type={node.methodType}
                          onCopy={() => copyToClipboard(node.invokedMethod!)}
                          isCopied={copiedMethod === node.invokedMethod}
                        />
                      )}
                    </div>
                    <ModernArrowConnector />
                  </React.Fragment>
                );
              }

              if (node.type === 'decision') {
                return (
                  <React.Fragment key={node.id}>
                    {/* TARJETA MODERNA DE DECISIÓN CON RAMIFICACIÓN */}
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        width: '100%',
                        position: 'relative',
                        margin: '6px 0'
                      }}
                    >
                      {/* Tarjeta Central de Validación / Decisión */}
                      <div
                        style={{
                          background: 'linear-gradient(180deg, rgba(245, 158, 11, 0.06), rgba(245, 158, 11, 0.02)), var(--bg-surface)',
                          border: '1.5px solid rgba(245, 158, 11, 0.4)',
                          borderRadius: '12px',
                          padding: '18px 22px',
                          width: '100%',
                          maxWidth: '440px',
                          boxShadow: '0 4px 20px rgba(245, 158, 11, 0.08)',
                          display: 'flex',
                          flexDirection: 'column',
                          gap: '10px',
                          zIndex: 2
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={{ fontSize: '11px', fontWeight: 800, color: '#f59e0b', letterSpacing: '0.8px', textTransform: 'uppercase', display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <AlertTriangle size={12} />
                            Validación Condicional
                          </span>
                          <span style={{ fontSize: '10.5px', color: 'var(--text-muted)' }}>
                            Paso {node.stepNumber ? String(node.stepNumber).padStart(2, '0') : ''}
                          </span>
                        </div>

                        <div style={{ fontSize: '13.5px', fontWeight: 700, color: 'var(--text-main)', lineHeight: '1.45' }}>
                          {node.label}
                        </div>

                        {node.invokedMethod && (
                          <MethodHighlightChip 
                            method={node.invokedMethod} 
                            type={node.methodType}
                            onCopy={() => copyToClipboard(node.invokedMethod!)}
                            isCopied={copiedMethod === node.invokedMethod}
                          />
                        )}
                      </div>

                      {/* Rama Lateral: SÍ */}
                      <div
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '8px',
                          marginLeft: '16px',
                          zIndex: 2
                        }}
                      >
                        {/* Conector SÍ con flecha */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <span 
                            style={{ 
                              fontSize: '11px', 
                              fontWeight: 800, 
                              color: '#10b981', 
                              background: 'rgba(16, 185, 129, 0.12)',
                              padding: '2px 8px',
                              borderRadius: '4px',
                              border: '1px solid rgba(16, 185, 129, 0.3)'
                            }}
                          >
                            {node.yesLabel || 'SÍ'}
                          </span>
                          <svg width="24" height="16">
                            <line x1="0" y1="8" x2="16" y2="8" stroke="#10b981" strokeWidth="2" />
                            <polygon points="14,4 22,8 14,12" fill="#10b981" />
                          </svg>
                        </div>

                        {/* Tarjeta del Camino Alterno SÍ */}
                        <div
                          style={{
                            background: 'var(--bg-surface)',
                            border: '1px dashed #10b981',
                            borderRadius: '8px',
                            padding: '12px 16px',
                            minWidth: '200px',
                            maxWidth: '240px',
                            boxShadow: '0 4px 12px rgba(0,0,0,0.04)',
                            display: 'flex',
                            flexDirection: 'column',
                            gap: '6px'
                          }}
                        >
                          <div style={{ fontSize: '12.5px', fontWeight: 600, color: 'var(--text-main)', lineHeight: '1.4' }}>
                            {node.yesAction}
                          </div>
                          {node.yesMethod && (
                            <MethodHighlightChip 
                              method={node.yesMethod} 
                              type="service"
                              compact
                              onCopy={() => copyToClipboard(node.yesMethod!)}
                              isCopied={copiedMethod === node.yesMethod}
                            />
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Conector Vertical NO */}
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', margin: '4px 0' }}>
                      <span 
                        style={{ 
                          fontSize: '11px', 
                          fontWeight: 800, 
                          color: 'var(--text-muted)',
                          background: 'var(--bg-surface)',
                          padding: '2px 8px',
                          borderRadius: '4px',
                          border: '1px solid var(--border-subtle)',
                          marginBottom: '-2px',
                          zIndex: 3
                        }}
                      >
                        {node.noLabel || 'NO'}
                      </span>
                      <ModernArrowConnector />
                    </div>
                  </React.Fragment>
                );
              }

              if (node.type === 'end') {
                return (
                  <React.Fragment key={node.id}>
                    {/* NODO TERMINAL MODERNO: FIN */}
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '8px',
                        background: 'linear-gradient(135deg, rgba(239, 68, 68, 0.12), rgba(245, 158, 11, 0.12))',
                        border: '1.5px solid var(--color-danger)',
                        borderRadius: '9999px',
                        padding: '10px 38px',
                        fontWeight: 800,
                        fontSize: '15px',
                        letterSpacing: '1.5px',
                        color: 'var(--text-main)',
                        boxShadow: '0 4px 16px rgba(239, 68, 68, 0.2)',
                        backdropFilter: 'blur(8px)'
                      }}
                    >
                      <span style={{ width: '8px', height: '8px', borderRadius: '50%', background: 'var(--color-danger)', display: 'inline-block' }} />
                      <span>{node.label}</span>
                    </div>
                  </React.Fragment>
                );
              }

              return null;
            })}
          </div>
        </div>
      )}

      {/* =========================================================================
          ESTILO 2: LÍNEA DE TIEMPO / TIMELINE PASO A PASO
          ========================================================================= */}
      {diagramStyle === 'timeline' && (
        <div
          style={{
            padding: '24px',
            background: 'var(--bg-surface-elevated)',
            borderRadius: 'var(--radius-lg)',
            border: '1px solid var(--border-subtle)',
            display: 'flex',
            flexDirection: 'column',
            gap: '16px'
          }}
        >
          {nodes
            .filter((n) => n.type === 'process' || n.type === 'decision')
            .map((node, idx) => (
              <div 
                key={node.id}
                style={{
                  display: 'flex',
                  gap: '16px',
                  alignItems: 'flex-start',
                  position: 'relative'
                }}
              >
                {/* Indicador de Paso */}
                <div
                  style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    background: node.type === 'decision' ? 'rgba(245, 158, 11, 0.15)' : 'rgba(37, 99, 235, 0.15)',
                    border: `1.5px solid ${node.type === 'decision' ? '#f59e0b' : 'var(--color-primary)'}`,
                    color: node.type === 'decision' ? '#f59e0b' : 'var(--color-primary)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontWeight: 800,
                    fontSize: '12.5px',
                    flexShrink: 0
                  }}
                >
                  {node.stepNumber || idx + 1}
                </div>

                {/* Contenido del Paso */}
                <div
                  style={{
                    background: 'var(--bg-surface)',
                    border: '1px solid var(--border-subtle)',
                    borderRadius: '8px',
                    padding: '14px 18px',
                    flex: 1,
                    display: 'flex',
                    flexDirection: 'column',
                    gap: '8px'
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '11px', fontWeight: 800, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
                      {node.type === 'decision' ? 'Paso de Validación' : 'Paso de Ejecución'}
                    </span>
                  </div>

                  <div style={{ fontSize: '13.5px', fontWeight: 600, color: 'var(--text-main)', lineHeight: '1.45' }}>
                    {node.label}
                  </div>

                  {node.invokedMethod && (
                    <MethodHighlightChip 
                      method={node.invokedMethod} 
                      type={node.methodType}
                      onCopy={() => copyToClipboard(node.invokedMethod!)}
                      isCopied={copiedMethod === node.invokedMethod}
                    />
                  )}

                  {node.type === 'decision' && node.yesAction && (
                    <div style={{ marginTop: '4px', padding: '8px 12px', background: 'rgba(16, 185, 129, 0.08)', borderRadius: '6px', border: '1px solid rgba(16, 185, 129, 0.2)' }}>
                      <span style={{ fontSize: '11px', fontWeight: 800, color: '#10b981', marginRight: '6px' }}>RAMA SÍ:</span>
                      <span style={{ fontSize: '12.5px', color: 'var(--text-main)' }}>{node.yesAction}</span>
                      {node.yesMethod && (
                        <div style={{ marginTop: '6px' }}>
                          <MethodHighlightChip 
                            method={node.yesMethod} 
                            type="service"
                            compact
                            onCopy={() => copyToClipboard(node.yesMethod!)}
                            isCopied={copiedMethod === node.yesMethod}
                          />
                        </div>
                      )}
                    </div>
                  )}
                </div>
              </div>
            ))}
        </div>
      )}
    </div>
  );
};

// Componente Píldora / Chip para Resaltar Métodos y Objetos PL/SQL
const MethodHighlightChip: React.FC<{
  method: string;
  type?: FlowNode['methodType'];
  compact?: boolean;
  onCopy?: () => void;
  isCopied?: boolean;
}> = ({ method, type = 'service', compact, onCopy, isCopied }) => {
  const badgeColors = {
    dao: { bg: 'rgba(59, 130, 246, 0.1)', border: 'rgba(59, 130, 246, 0.3)', text: '#3b82f6', label: 'DAO' },
    utility: { bg: 'rgba(168, 85, 247, 0.1)', border: 'rgba(168, 85, 247, 0.3)', text: '#a855f7', label: 'UTI' },
    transaction: { bg: 'rgba(239, 68, 68, 0.1)', border: 'rgba(239, 68, 68, 0.3)', text: '#ef4444', label: 'TX' },
    table: { bg: 'rgba(16, 185, 129, 0.1)', border: 'rgba(16, 185, 129, 0.3)', text: '#10b981', label: 'TABLA' },
    service: { bg: 'rgba(14, 165, 233, 0.1)', border: 'rgba(14, 165, 233, 0.3)', text: '#0ea5e9', label: 'MÉTODO' },
  }[type];

  return (
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '6px',
        padding: compact ? '2px 8px' : '4px 10px',
        background: badgeColors.bg,
        border: `1px solid ${badgeColors.border}`,
        borderRadius: '6px',
        fontSize: compact ? '11px' : '11.5px',
        fontFamily: 'Consolas, Monaco, monospace',
        color: badgeColors.text,
        fontWeight: 600,
        maxWidth: '100%',
        boxSizing: 'border-box'
      }}
    >
      <Code2 size={compact ? 12 : 13} color={badgeColors.text} />
      <span style={{ fontSize: '9.5px', fontWeight: 800, opacity: 0.85, textTransform: 'uppercase' }}>
        [{badgeColors.label}]
      </span>
      <span style={{ wordBreak: 'break-all' }}>{method}</span>

      {onCopy && (
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            onCopy();
          }}
          title="Copiar método"
          style={{
            background: 'none',
            border: 'none',
            padding: '2px',
            cursor: 'pointer',
            color: 'inherit',
            display: 'flex',
            alignItems: 'center',
            marginLeft: '4px'
          }}
        >
          {isCopied ? <Check size={12} color="#10b981" /> : <Copy size={12} opacity={0.7} />}
        </button>
      )}
    </div>
  );
};

// Flechas conectoras modernas con animación de pulso sutil y vector SVG
const ModernArrowConnector: React.FC = () => (
  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', margin: '4px 0', userSelect: 'none' }}>
    <svg width="24" height="34" viewBox="0 0 24 34">
      <line x1="12" y1="0" x2="12" y2="24" stroke="var(--color-primary)" strokeWidth="2" strokeDasharray="3 3" />
      <polygon points="6,22 12,32 18,22" fill="var(--color-primary)" />
    </svg>
  </div>
);
