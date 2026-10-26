# Skill: Documentación Funcional de Flujo y Catálogo PL/SQL (`oracle-plsql-documentation`)

Skill oficial para la extracción, creación y actualización de archivos de documentación funcional de flujo (`<nombre_paquete>.md`) y catálogo en `core_documentacion_metodo` para los paquetes orquestadores `pkgln_` del ecosistema CORE.

---

## Estructura del Skill

```text
oracle-plsql-documentation/
├── SKILL.md                                  # Instrucción maestra y estándar de documentación
├── README.md                                 # Guía general de uso y despliegue del skill
└── references/
    ├── flow_markdown_template.md             # Plantilla lista para copiar y rellenar (.md)
    └── visor_parsing_rules.md                # Guía de compatibilidad de sintaxis con visor.html
```

---

## Cuándo Activar este Skill

Activar **SIEMPRE** que:
1. Se cree un nuevo paquete orquestador `pkgln_<dominio>`.
2. Se modifique, agregue o refactorice un procedimiento o función en un paquete `pkgln_`.
3. Se solicite generar o actualizar el archivo de flujo `Documentacion/<nombre_paquete>.md`.
4. Se solicite documentar un flujo para visualizarlo en `Documentacion/visor.html`.
5. Se requiera poblar o sincronizar la tabla de catálogo `core_documentacion_metodo`.

---

## Salidas Principales del Skill

1. **Archivo Markdown (`Documentacion/<nombre_paquete>.md`):**
   - H1: `# Diagrama y Flujo de Información: <PAQUETE>`
   - H2: `## Método: <subprograma>`
   - H3: `### 1. Descripción en Lenguaje Natural`
   - H3: `### 2. Decisiones y Bifurcaciones Lógicas` (delimitadas por `;` para rombos y ramas)
   - H3: `### 3. Mapa de Objetos Invocados y Llamados` (tabla 6 columnas)
   - Bloques `json` de entrada y salida de ejemplo.

2. **Visualización Interactiva Inmediata:**
   - Consumo directo mediante `Documentacion/visor.html` con renderizado de rombos rojos (`isTerminalExit`), cian (`returnsToMain`) y ámbar, badges `SÍ / NO` y mapa relacional.
