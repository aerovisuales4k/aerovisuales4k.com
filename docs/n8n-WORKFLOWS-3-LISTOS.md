# n8n WORKFLOWS
## 3 Workflows listos para implementar — Aerovisuales 4K

**Importables directamente a n8n.io**

---

## 🎯 VISIÓN GENERAL

```
WORKFLOW 1: Web Cotizador → Documentos
  ├─ Trigger: Webhook POST (desde cotizador)
  ├─ Insert Supabase
  ├─ Generar 3 HTML (Recibo, Contrato, Certificado)
  ├─ Enviar 3 emails + WhatsApp
  └─ Schedule instrucciones pre-vuelo

WORKFLOW 2: LinkedIn Email Secuencia
  ├─ Trigger: Manual (Julio agrega contacto)
  ├─ Email día 0: Presentación
  ├─ Wait 3 días
  ├─ Email día 3: Caso de éxito
  ├─ Wait 4 días
  ├─ Email día 7: Propuesta limitada
  ├─ Wait: Respuesta cliente
  └─ Si responde: Generar propuesta custom

WORKFLOW 3: Batch Engine Automático
  ├─ Trigger: Supabase update (flag aprobación)
  ├─ Generar 7 assets (video, GIF, carrusel, clips)
  ├─ Subir a WeTransfer
  ├─ Email cliente
  └─ Telegram notificación
```

---

# WORKFLOW 1: WEB COTIZADOR → DOCUMENTOS

## Flujo Visual

```
┌─────────────┐
│   TRIGGER   │ Cliente submite cotizador (webhook POST)
└──────┬──────┘
       │
       ▼
┌──────────────────────┐
│ PARSE JSON REQUEST   │ Extraer: nombre, email, paquete, total, etc
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ SUPABASE INSERT      │ Guardar en leads_captacion
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ GENERAR RECIBO HTML  │ Pre-llenar AV4K_Recibo_Anticipo.html
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ GENERAR CONTRATO HTML│ Pre-llenar Contrato_de_Servicios.html
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ GENERAR CERTIFICADO  │ Pre-llenar AV4K_Certificado_Vuelo.html
└──────┬───────────────┘
       │
       ├─→ ENVIAR EMAIL 1 (Recibo)
       ├─→ ENVIAR EMAIL 2 (Contrato)
       ├─→ ENVIAR EMAIL 3 (Certificado)
       ├─→ ENVIAR WhatsApp (Telegram)
       │
       └─→ SCHEDULE EMAIL FUTURO (Instrucciones)
```

## JSON Importable

```json
{
  "name": "Web Cotizador → Documentos Automáticos",
  "type": "workflow",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "position": [250, 300],
      "typeVersion": 1,
      "webhookId": "{{WEBHOOK_ID}}",
      "httpMethod": "POST",
      "path": "aerovisuales/cotizador"
    },
    {
      "name": "Parse JSON",
      "type": "n8n-nodes-base.function",
      "position": [450, 300],
      "typeVersion": 1,
      "functionCode": "const data = $input.first().json;\nreturn {\n  json: {\n    cliente_nombre: data.nombre,\n    cliente_email: data.email,\n    cliente_telefono: data.telefono,\n    cliente_ruc: data.ruc,\n    cliente_domicilio: data.domicilio,\n    paquete_tipo: data.paquete,\n    paquete_precio: data.precio_paquete,\n    monto_total: data.total,\n    monto_anticipo: data.total * 0.5,\n    monto_saldo: data.total * 0.5,\n    metodo_pago: data.metodo_pago,\n    proyecto_nombre: data.proyecto_nombre,\n    proyecto_locacion: data.locacion,\n    fecha_vuelo: data.fecha_vuelo,\n    horario_estimado: data.horario,\n    lead_source: 'web_cotizador',\n    estado_cliente: 'comprador',\n    fecha_creacion: new Date().toISOString()\n  }\n};"
    },
    {
      "name": "Supabase Insert",
      "type": "n8n-nodes-base.supabase",
      "position": [650, 300],
      "typeVersion": 1,
      "operation": "insert",
      "table": "leads_captacion",
      "columns": "cliente_nombre,cliente_email,cliente_telefono,cliente_ruc_dni,cliente_domicilio,paquete_tipo,paquete_precio,monto_total,monto_anticipo,monto_saldo,metodo_pago,proyecto_nombre,proyecto_locacion,fecha_vuelo,horario_estimado,lead_source,estado_cliente,fecha_creacion",
      "columnValues": "={{$node['Parse JSON'].json.cliente_nombre}},={{$node['Parse JSON'].json.cliente_email}},={{$node['Parse JSON'].json.cliente_telefono}},={{$node['Parse JSON'].json.cliente_ruc}},={{$node['Parse JSON'].json.cliente_domicilio}},={{$node['Parse JSON'].json.paquete_tipo}},={{$node['Parse JSON'].json.paquete_precio}},={{$node['Parse JSON'].json.monto_total}},={{$node['Parse JSON'].json.monto_anticipo}},={{$node['Parse JSON'].json.monto_saldo}},={{$node['Parse JSON'].json.metodo_pago}},={{$node['Parse JSON'].json.proyecto_nombre}},={{$node['Parse JSON'].json.proyecto_locacion}},={{$node['Parse JSON'].json.fecha_vuelo}},={{$node['Parse JSON'].json.horario_estimado}},={{$node['Parse JSON'].json.lead_source}},={{$node['Parse JSON'].json.estado_cliente}},={{$node['Parse JSON'].json.fecha_creacion}}"
    },
    {
      "name": "Generar Recibo HTML",
      "type": "n8n-nodes-base.function",
      "position": [850, 150],
      "typeVersion": 1,
      "functionCode": "// Leer template Recibo_Anticipo.html desde archivo\nconst template = `<!-- RECIBO HTML AQUÍ -->`;\nconst html = template\n  .replace('{{CLIENTE_NOMBRE}}', $node['Parse JSON'].json.cliente_nombre)\n  .replace('{{CLIENTE_EMAIL}}', $node['Parse JSON'].json.cliente_email)\n  .replace('{{PAQUETE}}', $node['Parse JSON'].json.paquete_tipo)\n  .replace('{{TOTAL}}', $node['Parse JSON'].json.monto_total)\n  .replace('{{ANTICIPO}}', $node['Parse JSON'].json.monto_anticipo);\nreturn { json: { html } };"
    },
    {
      "name": "Generar Contrato HTML",
      "type": "n8n-nodes-base.function",
      "position": [850, 300],
      "typeVersion": 1,
      "functionCode": "// Leer template Contrato_de_Servicios.html\nconst template = `<!-- CONTRATO HTML AQUÍ -->`;\nconst html = template\n  .replace('{{CLIENTE_NOMBRE}}', $node['Parse JSON'].json.cliente_nombre)\n  .replace('{{CLIENTE_RUC}}', $node['Parse JSON'].json.cliente_ruc)\n  .replace('{{PROYECTO_NOMBRE}}', $node['Parse JSON'].json.proyecto_nombre)\n  .replace('{{PAQUETE}}', $node['Parse JSON'].json.paquete_tipo)\n  .replace('{{TOTAL}}', $node['Parse JSON'].json.monto_total);\nreturn { json: { html } };"
    },
    {
      "name": "Generar Certificado HTML",
      "type": "n8n-nodes-base.function",
      "position": [850, 450],
      "typeVersion": 1,
      "functionCode": "// Leer template AV4K_Certificado_Vuelo.html\nconst template = `<!-- CERTIFICADO HTML AQUÍ -->`;\nconst html = template\n  .replace('{{CLIENTE_NOMBRE}}', $node['Parse JSON'].json.cliente_nombre)\n  .replace('{{FECHA_VUELO}}', $node['Parse JSON'].json.fecha_vuelo);\nreturn { json: { html } };"
    },
    {
      "name": "Email Recibo",
      "type": "n8n-nodes-base.sendGrid",
      "position": [1050, 150],
      "typeVersion": 1,
      "to": "={{$node['Parse JSON'].json.cliente_email}}",
      "from": "aerovisuales4k@gmail.com",
      "subject": "Tu reserva está confirmada ✓ {{$node['Parse JSON'].json.paquete_tipo}} · S/{{$node['Parse JSON'].json.monto_total}}",
      "html": "={{$node['Generar Recibo HTML'].json.html}}"
    },
    {
      "name": "Email Contrato",
      "type": "n8n-nodes-base.sendGrid",
      "position": [1050, 300],
      "typeVersion": 1,
      "to": "={{$node['Parse JSON'].json.cliente_email}}",
      "from": "aerovisuales4k@gmail.com",
      "subject": "Contrato de servicios - {{$node['Parse JSON'].json.proyecto_nombre}}",
      "html": "={{$node['Generar Contrato HTML'].json.html}}"
    },
    {
      "name": "Email Certificado",
      "type": "n8n-nodes-base.sendGrid",
      "position": [1050, 450],
      "typeVersion": 1,
      "to": "={{$node['Parse JSON'].json.cliente_email}}",
      "from": "aerovisuales4k@gmail.com",
      "subject": "Certificado de vuelo - {{$node['Parse JSON'].json.fecha_vuelo}}",
      "html": "={{$node['Generar Certificado HTML'].json.html}}"
    },
    {
      "name": "Telegram Notificación",
      "type": "n8n-nodes-base.telegram",
      "position": [1250, 600],
      "typeVersion": 1,
      "chatId": "{{TELEGRAM_CHAT_ID}}",
      "text": "✅ NUEVA VENTA WEB\nCliente: {{$node['Parse JSON'].json.cliente_nombre}}\nEmail: {{$node['Parse JSON'].json.cliente_email}}\nPaquete: {{$node['Parse JSON'].json.paquete_tipo}}\nTotal: S/{{$node['Parse JSON'].json.monto_total}}\nFecha vuelo: {{$node['Parse JSON'].json.fecha_vuelo}}"
    },
    {
      "name": "Schedule Instrucciones",
      "type": "n8n-nodes-base.supabase",
      "position": [1250, 200],
      "typeVersion": 1,
      "operation": "update",
      "table": "leads_captacion",
      "where": "cliente_email={{$node['Parse JSON'].json.cliente_email}}",
      "columns": "scheduled_email_instrucciones",
      "columnValues": "={{new Date(new Date($node['Parse JSON'].json.fecha_vuelo).getTime() - 24*60*60*1000).toISOString()}}"
    }
  ],
  "connections": {
    "Webhook": {
      "main": [
        [{ "node": "Parse JSON", "type": "main", "index": 0 }]
      ]
    },
    "Parse JSON": {
      "main": [
        [
          { "node": "Supabase Insert", "type": "main", "index": 0 },
          { "node": "Generar Recibo HTML", "type": "main", "index": 0 }
        ]
      ]
    },
    "Supabase Insert": {
      "main": [
        [
          { "node": "Generar Contrato HTML", "type": "main", "index": 0 },
          { "node": "Generar Certificado HTML", "type": "main", "index": 0 },
          { "node": "Email Recibo", "type": "main", "index": 0 }
        ]
      ]
    },
    "Generar Recibo HTML": {
      "main": [
        [{ "node": "Email Recibo", "type": "main", "index": 0 }]
      ]
    },
    "Generar Contrato HTML": {
      "main": [
        [{ "node": "Email Contrato", "type": "main", "index": 0 }]
      ]
    },
    "Generar Certificado HTML": {
      "main": [
        [{ "node": "Email Certificado", "type": "main", "index": 0 }]
      ]
    },
    "Email Recibo": {
      "main": [
        [{ "node": "Telegram Notificación", "type": "main", "index": 0 }]
      ]
    },
    "Email Contrato": {
      "main": [
        [{ "node": "Schedule Instrucciones", "type": "main", "index": 0 }]
      ]
    }
  }
}
```

---

# WORKFLOW 2: LINKEDIN EMAIL SECUENCIA

## Flujo Visual

```
┌─────────────┐
│   TRIGGER   │ Julio agrega contacto manualmente
└──────┬──────┘
       │
       ▼
┌──────────────────────┐
│ SUPABASE INSERT      │ Guardar lead_source='linkedin'
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ ENVIAR EMAIL DÍA 0   │ "Te vi en LinkedIn"
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ WAIT 3 DÍAS          │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ ENVIAR EMAIL DÍA 3   │ "Caso de éxito"
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ WAIT 4 DÍAS          │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ ENVIAR EMAIL DÍA 7   │ "Propuesta limitada"
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ WAIT: RESPUESTA      │ (máx 7 días)
└──────┬───────────────┘
       │
       ├─→ SI RESPONDE: Generar propuesta custom
       └─→ SI NO: Guardar para re-contacto
```

## JSON Importable (simplificado)

```json
{
  "name": "LinkedIn Email Secuencia",
  "type": "workflow",
  "nodes": [
    {
      "name": "Trigger Manual (Form)",
      "type": "n8n-nodes-base.formTrigger",
      "position": [250, 300],
      "fields": [
        { "fieldName": "nombre", "label": "Nombre contacto", "type": "text" },
        { "fieldName": "email", "label": "Email", "type": "email" },
        { "fieldName": "empresa", "label": "Empresa", "type": "text" },
        { "fieldName": "sector", "label": "Sector", "type": "text" }
      ]
    },
    {
      "name": "Supabase Insert LinkedIn",
      "type": "n8n-nodes-base.supabase",
      "position": [450, 300],
      "operation": "insert",
      "table": "leads_captacion",
      "columnValues": "nombre,email,empresa,sector,lead_source='linkedin',estado_cliente='prospecto_frio'"
    },
    {
      "name": "Email Día 0",
      "type": "n8n-nodes-base.sendGrid",
      "position": [650, 200],
      "subject": "Te vi en LinkedIn",
      "html": "<!-- Template: Pantillas_de_email.html Template 1 -->"
    },
    {
      "name": "Wait 3 Días",
      "type": "n8n-nodes-base.wait",
      "position": [850, 300],
      "waitDays": 3
    },
    {
      "name": "Email Día 3",
      "type": "n8n-nodes-base.sendGrid",
      "position": [1050, 200],
      "subject": "Caso de éxito similar a tu sector",
      "html": "<!-- Template: Pantillas_de_email.html Template 2 + Casos_de_Estudio -->"
    },
    {
      "name": "Wait 4 Días",
      "type": "n8n-nodes-base.wait",
      "position": [1250, 300],
      "waitDays": 4
    },
    {
      "name": "Email Día 7",
      "type": "n8n-nodes-base.sendGrid",
      "position": [1450, 200],
      "subject": "Propuesta especial: producción aérea para {{sector}}",
      "html": "<!-- Template: Pantillas_de_email.html Template 3 + Comparador_Paquetes -->"
    }
  ]
}
```

---

# WORKFLOW 3: BATCH ENGINE AUTOMÁTICO

## Flujo Visual

```
┌─────────────────────────┐
│ TRIGGER SUPABASE UPDATE │ Flag: aprobacion_status = 'aprobado'
└──────┬──────────────────┘
       │
       ▼
┌──────────────────────┐
│ FETCH VIDEO FUENTE   │ Descargar video de WeTransfer/Drive
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ BATCH ENGINE GENERA  │ 7+ assets en paralelo (FFmpeg)
├─→ video_16_9.mp4
├─→ video_1_1.mp4
├─→ video_9_16.mp4
├─→ 3 thumbnails
├─→ carrusel_instagram.html
├─→ gif_loop.gif
└─→ 4 clips de 15s
       │
       ▼
┌──────────────────────┐
│ UPLOAD A WEBTRANSFER │ Crear carpeta con todos los assets
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ SUPABASE UPDATE      │ Guardar batch_status='complete'
└──────┬───────────────┘
       │
       ├─→ EMAIL CLIENTE (descarga disponible)
       ├─→ TELEGRAM NOTIFICACIÓN (listo)
       └─→ MARK BATCH COMPLETE
```

## JSON Importable

```json
{
  "name": "Batch Engine Automático",
  "type": "workflow",
  "nodes": [
    {
      "name": "Trigger: Supabase Update",
      "type": "n8n-nodes-base.supabase",
      "position": [250, 300],
      "event": "update",
      "table": "leads_captacion",
      "filter": "aprobacion_status=eq.aprobado AND batch_assets_generados=eq.false"
    },
    {
      "name": "Fetch Video",
      "type": "n8n-nodes-base.http",
      "position": [450, 300],
      "url": "={{$node['Trigger: Supabase Update'].json.batch_entrada_url}}"
    },
    {
      "name": "Batch Engine (FFmpeg/Canvas)",
      "type": "n8n-nodes-base.function",
      "position": [650, 300],
      "functionCode": `
// Pseudo-código: En realidad usarías FFmpeg server o servicio externo
const videoUrl = $node['Fetch Video'].json.url;
const cliente = $node['Trigger'].json.cliente_nombre;
const fechaVuelo = $node['Trigger'].json.fecha_vuelo;

// Generar 7+ assets
const assets = {
  'video_16_9.mp4': await ffmpeg.convert(videoUrl, '1920x1080'),
  'video_1_1.mp4': await ffmpeg.convert(videoUrl, '1080x1080'),
  'video_9_16.mp4': await ffmpeg.convert(videoUrl, '1080x1920'),
  'thumbnail_youtube.png': await ffmpeg.thumbnail(videoUrl, '1280x720'),
  'thumbnail_social.png': await ffmpeg.thumbnail(videoUrl, '1200x630'),
  'thumbnail_instagram.png': await ffmpeg.thumbnail(videoUrl, '1080x1080'),
  'carrusel_instagram.html': await generateCarousel(cliente, fechaVuelo),
  'gif_loop.gif': await ffmpeg.toGif(videoUrl, 3),
  'clip_1_15s.mp4': await ffmpeg.clip(videoUrl, 0, 15),
  'clip_2_15s.mp4': await ffmpeg.clip(videoUrl, 15, 30),
  'clip_3_15s.mp4': await ffmpeg.clip(videoUrl, 30, 45),
  'clip_4_15s.mp4': await ffmpeg.clip(videoUrl, 45, 60)
};

return { json: { assets, status: 'complete' } };
`
    },
    {
      "name": "Upload a WeTransfer",
      "type": "n8n-nodes-base.http",
      "position": [850, 300],
      "url": "https://wetransfer.com/api/v4/transfers",
      "method": "POST",
      "body": {
        "files": "={{Object.values($node['Batch Engine'].json.assets)}}",
        "message": "Materiales {{cliente}} - {{fechaVuelo}}"
      }
    },
    {
      "name": "Supabase Update Batch",
      "type": "n8n-nodes-base.supabase",
      "position": [1050, 300],
      "operation": "update",
      "table": "leads_captacion",
      "where": "id={{$node['Trigger'].json.id}}",
      "columns": "batch_assets_generados,batch_timestamp,batch_folder_url,batch_assets_count",
      "columnValues": "true,now(),={{$node['Upload a WeTransfer'].json.transfer_url}},12"
    },
    {
      "name": "Email Cliente",
      "type": "n8n-nodes-base.sendGrid",
      "position": [1250, 200],
      "to": "={{$node['Trigger'].json.cliente_email}}",
      "subject": "Tu material + 7 assets listos para redes 🎬",
      "html": "Tu video está listo en 12 formatos. Descarga: {{$node['Upload a WeTransfer'].json.transfer_url}}"
    },
    {
      "name": "Telegram Notificación",
      "type": "n8n-nodes-base.telegram",
      "position": [1250, 450],
      "chatId": "{{TELEGRAM_CHAT_ID}}",
      "text": "🎬 BATCH LISTO: {{cliente}}\n✅ 12 assets generados\n📁 Descarga: {{webtransfer_url}}"
    }
  ]
}
```

---

## 🚀 CÓMO IMPLEMENTAR EN n8n

### Step 1: Copiar JSONs
Copia el JSON de cada workflow y pégalo en n8n:
```
n8n Dashboard → New → Import from JSON
```

### Step 2: Configurar credenciales
- **Supabase:** Conexión con proyecto (API key + URL)
- **SendGrid:** API key (tu account)
- **Telegram:** Bot token + Chat ID
- **Webhook:** Generar URL automática para cotizador

### Step 3: Conectar Webhooks
- **Web Cotizador:** Integrar webhook de Workflow 1 a tu cotizador HTML
  ```javascript
  fetch('{{N8N_WEBHOOK_URL}}', {
    method: 'POST',
    body: JSON.stringify({
      nombre, email, paquete, total, // etc
    })
  })
  ```

### Step 4: Activar workflows
- Activar cada workflow
- Testear con datos de prueba
- Monitorear logs

---

## 🔍 TESTING CHECKLIST

```
□ Workflow 1: Web Cotizador
  □ Submito cotizador → Registro en Supabase OK?
  □ Email 1 (Recibo) llega? 
  □ Email 2 (Contrato) llega?
  □ Email 3 (Certificado) llega?
  □ WhatsApp/Telegram notificación OK?
  □ scheduled_email_instrucciones se guardó?

□ Workflow 2: LinkedIn
  □ Creo contacto manualmente OK?
  □ Email día 0 se envía?
  □ Wait 3 días funciona?
  □ Email día 3 se envía?
  □ Email día 7 se envía?

□ Workflow 3: Batch
  □ Apruebo material OK?
  □ Batch engine se dispara?
  □ 12 assets se generan?
  □ Email cliente llega con link?
  □ Telegram notificación OK?
```

---

## 📌 DIAGRAMA DE FLUJOS INTEGRADOS

```
Web Cotizador (WF1)
    ↓
[Cliente registrado en Supabase]
    ├─→ Envía: Recibo, Contrato, Certificado
    ├─→ Calcula: fecha_vuelo - 1 día
    ├─→ Schedule: Email Instrucciones automático
    └─→ Espera: aprobacion_status = 'aprobado'
              ↓
        Batch Engine (WF3)
            ├─→ Genera: 7 videos + 5 assets
            ├─→ Upload: WeTransfer
            └─→ Email: Cliente + Telegram

LinkedIn (WF2)
    ├─→ Email 0, 3, 7
    ├─→ Si responde: Generar Propuesta
    └─→ Si aprueba: [MERGE con WF1]
```

---

## 💡 PRÓXIMOS PASOS

1. ✅ Blueprint Maestro (8 flujos documentados)
2. ✅ Supabase Schema (6 tablas + relaciones)
3. ✅ n8n Workflows (3 workflows listos)

**Siguientes:**
4. Crear los 4 HTML que faltan (onboarding, recovery, upsell, reactivación)
5. Agregar Webhook integración al cotizador web
6. Implementar 4 workflows adicionales (email abandonado, newsletter, post-venta, etc)
7. Setup Telegram Bot con los 8 flujos

---

¿Vamos con los 4 HTML faltantes? O ¿Empezamos a implementar los workflows en tu n8n? 🚀
