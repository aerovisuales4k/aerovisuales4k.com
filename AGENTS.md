# AGENTS.md — Aerovisuales 4K

> Lee este archivo COMPLETO antes de tocar código.
> Sitio: `https://www.aerovisuales4k.com` · Hosting: GitHub Pages
> Owner: Julio César Cornejo · WhatsApp: `+51 927 929 541`

---

## 1. Qué es

Sistema de captación de leads de producción aérea profesional en Lima, Perú. No es solo landing: incluye cotizador en tiempo real, captura en BD, automatización 24/7 y dashboard administrativo.

## 2. Decisiones de arquitectura (NO revertir)

1. **Cero dependencias.** HTML5 + CSS3 + JS vanilla ES2020+. Sin frameworks, bundlers, ni preprocesadores. Razón: PageSpeed máximo + SEO óptimo + cero costo de mantenimiento.
2. **Fonts self-hosted** en `/fonts/` como `.woff2`. NUNCA agregar `<link>` a Google Fonts.
3. **Sin backend propio.** Todo distribuido entre Supabase + n8n/Railway + SendGrid + Telegram (~$5/mes total). Si necesitas lógica de servidor, agrégala como workflow de n8n.
4. **Clave anon de Supabase expuesta en HTML es INTENCIONAL.** Las políticas RLS solo permiten INSERT. Nadie puede leer datos con esa clave. NO la "ocultes" en variables de entorno.
5. **Sin build step.** Lo que ves en el repo es lo que el navegador ejecuta. No introducir pipelines de build.

## 3. Stack

| Capa | Servicio | URL/Identificador |
|---|---|---|
| Frontend | GitHub Pages | `aerovisuales4k.com` |
| BD + Auth | Supabase Free | proyecto `zfekvffhpqsduwemqdxj` |
| Automatización | n8n en Railway Hobby | `main-production-51c0.up.railway.app` |
| Email | SendGrid Free | sender `aerovisuales4k@gmail.com` |
| Notificaciones | Telegram Bot API | `@aerovisuales4k_leads_bot` (Chat ID `1893739649`) |
| Analítica | Google Analytics 4 | `G-ER6HD62CR3` |

## 4. Estructura

```
/
├── index.html              # CORE: landing + cotizador
├── dashboard.html          # Admin (auth requerida, bloqueada en robots.txt)
├── 404.html
├── robots.txt · sitemap.xml
├── fonts/                  # DM Serif Display, Manrope, DM Mono
├── img/                    # WebP preferido, sin JPG >200KB
├── articles/               # Artículos GEO para SEO
└── AGENTS.md
```

## 5. Comandos

```bash
# Servir local
python3 -m http.server 8080

# Deploy (automático al push)
git add . && git commit -m "mensaje" && git push origin main
```

Antes de push: abrir `index.html`, completar cotizador, verificar lead en Supabase, correr Lighthouse (Performance/SEO/A11y >90).

## 6. Datos críticos

### Tabla `leads_captacion`

```sql
CREATE TABLE leads_captacion (
  id          uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  timestamptz   DEFAULT now(),
  nombre      text,
  email       text,
  ruc_dni     text,
  distrito    text,
  paquete     text,
  total       numeric,
  mensaje_wa  text,
  estado      text          DEFAULT 'nuevo'
);
-- estado: nuevo | notificado | contactado | cerrado | perdido
-- RLS: INSERT permitido a 'anon', SELECT solo a 'authenticated'
```

⚠️ NO hacer migraciones destructivas (DROP COLUMN, ALTER TYPE) sin verificar dependencias en workflows de n8n.

### Workflow activo de n8n — "Leads Nuevos → Telegram"

```
Schedule (cada 5 min) → Supabase SELECT estado='nuevo' →
SendGrid email a Julio → Supabase UPDATE 'notificado' → Telegram
```

NO modificar sin coordinar con Julio. Es el corazón del sistema.

## 7. Convenciones

**HTML:** indentación 2 espacios, semántico siempre (`<button>` no `<div onclick>`), IDs y clases en `kebab-case`.
**CSS:** custom properties para tema, mobile-first con `min-width`, sin `!important` injustificado.
**JS:** `const` por defecto · `async/await` sobre `.then()` · funciones nombradas · sin `console.log` en producción.
**Naming:** archivos `kebab-case.html`, variables `camelCase`, constantes `SCREAMING_SNAKE_CASE`.

## 8. Brand identity

```css
--carbon:       #1A1A18    /* fondo oscuro principal */
--carbon-light: #242420    /* fondo secundario */
--sand:         #E1E1DC    /* texto sobre carbon */
--mid:          #8C8C88    /* texto secundario */
--blue:         #2D5FA0    /* CTAs */
--accent-green: #9FE1CB    /* validaciones */
```

**Fonts:** DM Serif Display (headlines), Manrope (body), DM Mono (captions con `letter-spacing: 0.08em`).
**Principio:** espacio en blanco generoso, fondos oscuros para premium, bordes sutiles `#D5D5D0` en claro.

## 9. NUNCA hacer

1. Instalar paquetes npm "para hacer X más fácil"
2. Migrar a framework (React/Vue) sin discusión explícita
3. Usar CDNs externos (Google Fonts, Bootstrap, jQuery)
4. "Ocultar" la clave anon de Supabase en `.env`
5. Modificar RLS policies sin entender que son la única protección
6. Renombrar tablas/columnas sin coordinar con n8n
7. Desactivar el workflow de n8n por más de 10 min sin avisar
8. Subir imágenes pesadas (>200KB) sin optimizar a WebP
9. Agregar tracking de terceros (FB Pixel, TikTok Pixel) sin coordinar
10. Cambiar branding visual sin consultar brand manual v3.0
11. Commit de credenciales reales (SendGrid API key, Railway tokens, etc.)

## 10. SIEMPRE hacer

1. Ejecutar `init.sh` antes de empezar a hacer cualquier cambio. Si falla, no continuar, pedir ayuda.
2. Leer este archivo completo antes del primer cambio
3. Verificar cotizador end-to-end después de tocar `index.html`
4. Probar en móvil (mayoría del tráfico es mobile)
5. Comentar el "por qué" de decisiones no obvias (el "qué" se lee solo)
6. Mantener JSON-LD schema actualizado si cambia contenido principal
7. Preguntar antes de borrar archivos no entendidos (pueden ser de las 36 cajitas HTML internas)

## 11. Cajitas pendientes (no tocar áreas relacionadas sin coordinar)

- **#8** Email de proforma automática vía Telegram bot (en planeación)
- **#9** Seguimiento automático de leads no convertidos
- **#10** Google Business Profile
- **#11** Página pública del marketplace de aliados
- **#12** Automatización completa del marketplace
- **#13** Health-check de Railway con alertas

## 12. Escalation

Si un cambio genera duda sobre si está alineado con el proyecto: **frenar y preguntar a Julio**. Es mejor consultar que romper algo que funciona.

Si actualizas estructura del proyecto (nueva tabla, workflow, sección): **actualizar AGENTS.md en el mismo commit**. Un AGENTS.md desactualizado es peor que ninguno.

---

*v1.0 · Mayo 2026 · Mantenido por Julio César Cornejo + agentes con permiso explícito*
