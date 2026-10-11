'use client';

import React, { useState, useMemo } from 'react';
import { ZoomIn, ZoomOut, RotateCcw, ListOrdered, GitBranch, ArrowDown, ArrowRight } from 'lucide-react';

interface FlowchartDiagramProps {
  pasosTexto: string;
  tituloMetodo?: string;
}

interface FlowNode {
  id: string;
  type: 'start' | 'process' | 'decision' | 'end';
  label: string;
  yesLabel?: string;
  yesAction?: string;
  noLabel?: string;
}

export const FlowchartDiagram: React.FC<FlowchartDiagramProps> = ({ pasosTexto, tituloMetodo }) => {
  const [zoom, setZoom] = useState<number>(1);
  const [viewMode, setViewMode] = useState<'flowchart' | 'list'>('flowchart');

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

    // Procesar cada línea de paso
    lines.forEach((line, index) => {
      // Limpiar prefijo numérico como "1. ", "2) "
      const cleanText = line.replace(/^\d+[\.\)]\s*/, '').trim();
      const lower = cleanText.toLowerCase();

      // Detectar si el paso representa una decisión / validación condicional
      const isDecision =
        lower.includes('si ') ||
        lower.includes('consulta si') ||
        lower.includes('valida si') ||
        lower.includes('existe ') ||
        lower.includes('¿') ||
        lower.includes('compara ');

      if (isDecision) {
        // Extraer condición y rama alterna si está presente en el mismo texto
        let condicion = cleanText;
        let accionSi = 'Pedir a otra sucursal / Rechazar';

        if (cleanText.includes(';')) {
          const partes = cleanText.split(';');
          condicion = partes[0].trim();
          accionSi = partes[1].trim();
        } else if (cleanText.includes(',')) {
          const partes = cleanText.split(',');
          if (partes[0].toLowerCase().includes('si ') || partes[0].toLowerCase().includes('existe')) {
            condicion = partes[0].trim();
            accionSi = partes.slice(1).join(',').trim();
          }
        }

        parsed.push({
          id: `node-decision-${index}`,
          type: 'decision',
          label: condicion,
          yesLabel: 'SI',
          yesAction: accionSi,
          noLabel: 'NO'
        });
      } else {
        parsed.push({
          id: `node-process-${index}`,
          type: 'process',
          label: cleanText
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
    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
      {/* Barra de Controles de Vista y Zoom */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '8px' }}>
        <div style={{ display: 'flex', gap: '6px' }}>
          <button
            type="button"
            onClick={() => setViewMode('flowchart')}
            className={`btn btn-sm ${viewMode === 'flowchart' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <GitBranch size={13} />
            <span>Diagrama de Flujo</span>
          </button>
          <button
            type="button"
            onClick={() => setViewMode('list')}
            className={`btn btn-sm ${viewMode === 'list' ? 'btn-primary' : 'btn-secondary'}`}
            style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <ListOrdered size={13} />
            <span>Lista Paso a Paso</span>
          </button>
        </div>

        {viewMode === 'flowchart' && (
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

      {/* VISTA 1: DIAGRAMA DE FLUJO GRÁFICO (Estilo similar a la muestra de imagen) */}
      {viewMode === 'flowchart' ? (
        <div
          style={{
            background: 'var(--bg-surface-elevated)',
            border: '1px solid var(--border-subtle)',
            borderRadius: 'var(--radius-lg)',
            padding: '40px 20px',
            overflowX: 'auto',
            overflowY: 'hidden',
            display: 'flex',
            justifyContent: 'center',
            minHeight: '480px',
            boxShadow: 'inset 0 2px 6px rgba(0,0,0,0.05)'
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
              maxWidth: '680px',
              position: 'relative'
            }}
          >
            {nodes.map((node, i) => {
              if (node.type === 'start') {
                return (
                  <React.Fragment key={node.id}>
                    {/* INICIO: Oval / Elipse con borde punteado anaranjado/terracota */}
                    <div
                      style={{
                        border: '2.5px dashed #d97736',
                        borderRadius: '50px',
                        padding: '12px 60px',
                        fontWeight: 900,
                        fontSize: '22px',
                        letterSpacing: '2px',
                        color: 'var(--text-main)',
                        background: 'var(--bg-surface)',
                        boxShadow: '0 4px 12px rgba(217, 119, 54, 0.12)',
                        textAlign: 'center'
                      }}
                    >
                      {node.label}
                    </div>
                    {/* Flecha hacia abajo */}
                    <ArrowConnector />
                  </React.Fragment>
                );
              }

              if (node.type === 'process') {
                return (
                  <React.Fragment key={node.id}>
                    {/* PROCESO: Rectángulo con borde punteado */}
                    <div
                      style={{
                        border: '2px dashed #d97736',
                        borderRadius: '4px',
                        padding: '16px 28px',
                        minWidth: '280px',
                        maxWidth: '380px',
                        textAlign: 'center',
                        fontSize: '13.5px',
                        fontWeight: 600,
                        color: 'var(--text-main)',
                        background: 'var(--bg-surface)',
                        boxShadow: '0 2px 8px rgba(0,0,0,0.04)',
                        lineHeight: 1.4
                      }}
                    >
                      {node.label}
                    </div>
                    {/* Flecha hacia abajo solo si no es el último antes del fin */}
                    <ArrowConnector />
                  </React.Fragment>
                );
              }

              if (node.type === 'decision') {
                return (
                  <React.Fragment key={node.id}>
                    {/* DECISIÓN: Rombo central + Rama lateral SI + Rama vertical NO */}
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        position: 'relative',
                        width: '100%',
                        margin: '10px 0'
                      }}
                    >
                      {/* Rombo / Diamante Central */}
                      <div
                        style={{
                          width: '170px',
                          height: '170px',
                          border: '2px dashed #d97736',
                          transform: 'rotate(45deg)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          background: 'var(--bg-surface)',
                          boxShadow: '0 4px 12px rgba(217, 119, 54, 0.08)',
                          position: 'relative'
                        }}
                      >
                        {/* Contenido dentro del rombo (contra-rotado -45deg para leer derecho) */}
                        <div
                          style={{
                            transform: 'rotate(-45deg)',
                            textAlign: 'center',
                            fontSize: '13px',
                            fontWeight: 700,
                            color: 'var(--text-main)',
                            maxWidth: '125px',
                            lineHeight: 1.3
                          }}
                        >
                          {node.label}
                        </div>
                      </div>

                      {/* RAMA LATERAL DERECHA (SI) */}
                      <div
                        style={{
                          position: 'absolute',
                          left: 'calc(50% + 85px)',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '6px'
                        }}
                      >
                        {/* Etiqueta SI y flecha derecha */}
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <span style={{ fontSize: '12px', fontWeight: 800, color: '#d97736' }}>SI</span>
                          <svg width="34" height="20" style={{ overflow: 'visible' }}>
                            <line x1="0" y1="10" x2="26" y2="10" stroke="#d97736" strokeWidth="2.5" />
                            <polygon points="24,5 34,10 24,15" fill="#d97736" />
                          </svg>
                        </div>

                        {/* Caja del camino alterno */}
                        <div
                          style={{
                            border: '2px dashed #d97736',
                            borderRadius: '4px',
                            padding: '14px 20px',
                            minWidth: '180px',
                            maxWidth: '220px',
                            textAlign: 'center',
                            fontSize: '13px',
                            fontWeight: 700,
                            color: 'var(--text-main)',
                            background: 'var(--bg-surface)',
                            boxShadow: '0 2px 8px rgba(0,0,0,0.05)',
                            position: 'relative'
                          }}
                        >
                          {node.yesAction}

                          {/* Línea punteada que baja hacia el FIN */}
                          <div
                            style={{
                              position: 'absolute',
                              right: '-16px',
                              top: '50%',
                              width: '16px',
                              height: '320px',
                              borderRight: '2px dashed #d97736',
                              borderBottom: '2px dashed #d97736',
                              borderRadius: '0 0 12px 0',
                              pointerEvents: 'none'
                            }}
                          />
                        </div>
                      </div>
                    </div>

                    {/* Conector vertical hacia abajo con etiqueta NO */}
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', margin: '4px 0' }}>
                      <span style={{ fontSize: '12px', fontWeight: 800, color: '#d97736', marginBottom: '-2px' }}>
                        NO
                      </span>
                      <ArrowConnector noMargin />
                    </div>
                  </React.Fragment>
                );
              }

              if (node.type === 'end') {
                return (
                  <React.Fragment key={node.id}>
                    {/* FIN: Oval / Elipse con borde punteado anaranjado/terracota */}
                    <div
                      style={{
                        border: '2.5px dashed #d97736',
                        borderRadius: '50px',
                        padding: '12px 70px',
                        fontWeight: 900,
                        fontSize: '22px',
                        letterSpacing: '2px',
                        color: 'var(--text-main)',
                        background: 'var(--bg-surface)',
                        boxShadow: '0 4px 12px rgba(217, 119, 54, 0.12)',
                        textAlign: 'center',
                        position: 'relative'
                      }}
                    >
                      {node.label}
                    </div>
                  </React.Fragment>
                );
              }

              return null;
            })}
          </div>
        </div>
      ) : (
        /* VISTA 2: LISTA DE TEXTO ORIGINAL */
        <div
          style={{
            padding: '20px',
            background: 'var(--bg-surface-elevated)',
            borderRadius: 'var(--radius-md)',
            border: '1px solid var(--border-subtle)'
          }}
        >
          <pre
            style={{
              whiteSpace: 'pre-wrap',
              fontFamily: 'inherit',
              fontSize: '13.5px',
              lineHeight: '1.7',
              color: 'var(--text-main)',
              margin: 0
            }}
          >
            {pasosTexto}
          </pre>
        </div>
      )}
    </div>
  );
};

// Componente utilitario para flechas descendentes estilo diagrama
const ArrowConnector: React.FC<{ noMargin?: boolean }> = ({ noMargin }) => (
  <div
    style={{
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      margin: noMargin ? '0' : '8px 0',
      userSelect: 'none'
    }}
  >
    <svg width="24" height="38" viewBox="0 0 24 38">
      <line x1="12" y1="0" x2="12" y2="28" stroke="#d97736" strokeWidth="2.5" />
      <polygon points="6,26 12,38 18,26" fill="#d97736" />
    </svg>
  </div>
);
