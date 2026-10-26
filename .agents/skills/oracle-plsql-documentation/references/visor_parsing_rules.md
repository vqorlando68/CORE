# Reglas de Compatibilidad y Parsing con `Documentacion/visor.html`

El visualizador gráfico `visor.html` utiliza un parser heurístico que interpreta la estructura de los archivos `.md`. Para que los diagramas se rendericen con máxima fidelidad visual (rombos, ramas y badges automáticos), se deben cumplir las siguientes reglas:

---

## 1. Delimitación Estricta de Decisiones con Punto y Coma (`;`)

El parser de `visor.html` divide cada línea de decisión mediante el carácter `;`:

```text
- **Decisión N [Etiqueta]**: <Condición (dentro del rombo)>; <Acción Rama SÍ (tarjeta lateral)>
```

* **Lado Izquierdo (antes de `;`):** Es el texto que se introduce en el SVG del rombo y en el tooltip. Debe ser conciso (máximo 2 líneas visibles, el resto se trunca con puntos suspensivos y se expande en tooltip / popover).
* **Lado Derecho (después de `;`):** Es la acción que ocurre si la condición es verdadera (camino `SÍ`).
* **Camino `NO`:** El visor asume automáticamente que si la condición es falsa, el flujo continúa por defecto hacia el nodo inferior.

---

## 2. Palabras Clave para Tipos de Rombo

El visor asigna automáticamente colores y geometrías a los rombos según las palabras clave en la acción de la rama SÍ (lado derecho del `;`):

| Tipo de Rombo | Color y Estilo | Propósito Funcional | Palabras Clave en la Acción (después de `;`) |
| :--- | :--- | :--- | :--- |
| **Salida Terminal / Error** (`isTerminalExit`) | **Rojo** (`#f43f5e`) con badge `SÍ (FALLO)` | Validaciones fallidas o condiciones bloqueantes que cortan el proceso con `ROLLBACK` y código negativo. | `salida inmediata`, `interrumpe`, `rechaza`, `aborta`, `código -`, `retorna -`, `bloqueada`, `error` |
| **Bifurcación que Reintegra** (`returnsToMain`) | **Cian** (`#00f0ff`) con badge `SÍ (RAMA)` | Acciones complementarias u opcionales que, tras ejecutarse, retornan al tronco principal del proceso. | `vuelve al flujo principal`, `retorna al flujo`, `reintegra`, `reincorpora` |
| **Punto de Decisión Estándar** | **Ámbar** (`#f59e0b`) con badge `SÍ` | Evaluaciones de opciones o configuración general. | Cualquier otra acción sin palabras terminales ni de retorno. |

---

## 3. Reconocimiento de Objetos Invocados

El visor detecta automáticamente los objetos invocados si cumplen cualquiera de estos dos formatos:
1. **Entre comillas invertidas:** `` `PKGCORE_USUARIO_DAO.f_existe` `` o `` `uti_manejo_trazas_pkg.f_debe_trazar` ``.
2. **Nombres canónicos con prefijos conocidos:**
   - `PKGCORE_*_DAO.*` $\rightarrow$ Etiqueta `[DAO]`
   - `uti_*_pkg.*` $\rightarrow$ Etiqueta `[UTI]`
   - `pkgcn_*.*` $\rightarrow$ Etiqueta `[CN]`
   - `pkgca_*.*` $\rightarrow$ Etiqueta `[CA]`
   - `p_do_commit` $\rightarrow$ Etiqueta `[TX]`

---

## 4. Tabla de Objetos

La tabla debe tener exactamente 6 columnas y no omitir los delimitadores `|`.
El encabezado debe ser:
```markdown
| Orden | Nombre Exacto del Objeto Invocado | Capa / Familia | Tipo | Propósito de la Invocación | Condición / Momento |
| :---: | :--- | :--- | :--- | :--- | :--- |
```

---

## 5. Payloads JSON

Deben ubicarse como bloques de código cercados con triple comilla invertida y lenguaje `json`.
- El primer bloque `json` se interpretará como el JSON de entrada (`p_json_entrada`).
- El segundo bloque `json` (o aquel que contenga `"codigo":`) se interpretará como el JSON de salida (`p_json_salida`).

---

## 6. Badge de Número de Línea en Código Fuente (`[Línea XXX]`)

El parser de `visor.html` reconoce patrones de número de línea en cada ítem de paso o decisión:
- Formatos soportados: `[Línea 842]`, `[Linea 842]`, `[L: 842]`, `[L:842]`, `[L-842]`, `(Línea 842)`.
- El visor extrae automáticamente el número y limpia el texto del título/etiqueta para no sobrecargarlo.
- Se proyecta un badge estilizado `L:842` en el encabezado del rombo, en la tarjeta de paso de proceso, en el tooltip inteligente, en el popover modal y en el timeline lateral.

