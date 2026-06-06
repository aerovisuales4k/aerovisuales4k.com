# BLUEPRINT MAESTRO
## Arquitectura de 8 flujos integrados — Aerovisuales 4K

**Sistema operacional completo con 35 HTML inteligentemente orquestados**

Última actualización: 2026-06-10
Autor: Julio César Cornejo + Claude (AI Architecture)

---

## 📍 PRINCIPIOS DE DISEÑO

1. **Single Source of Truth:** Supabase es la única BD de referencia
2. **Event-Driven:** Todo se dispara por condiciones (lead_source, estado, días transcurridos)
3. **Data Inheritance:** Un prospecto recibe datos de etapas anteriores (nombre, email, paquete elegido, etc.)
4. **Idempotency:** Si un email ya se envió, no se envía de nuevo (flag en Supabase)
5. **Transparency:** Cada movimiento se logguea (para audits + debugging)

---

## 🌊 FLUJO 1: WEB COTIZADOR → COMPRADOR

**Entry Point:** Cliente llena cotizador en aerovisuales4k.com
**Lead Source:** `web_cotizador`
**Duración:** 5 min (de cotizador a documentos)

```
TRIGGER: Cliente clickea "Confirmar Paquete" en cotizador
│
├─ ACCIÓN 1 [Supabase INSERT]
│  └─ Tabla: leads_captacion
│     └─ Insertar: nombre, email, telefono, ruc, paquete, total, fecha_vuelo, 
│        horario, locacion, metodo_pago, lead_source="web_cotizador"
│
├─ ACCIÓN 2 [Generar Documento → n8n]
│  └─ Triggers: n8n recibe webhook desde Supabase
│     ├─ Genera: AV4K_Recibo_Anticipo.html
│     │  (pre-llena con: nombre, email, paquete, total, anticipo_50, saldo)
│     ├─ Genera: Contrato_de_Servicios.html
│     │  (pre-llena con: cliente_nombre, ruc, proyecto_nombre, paquete, total)
│     └─ Genera: AV4K_Certificado_Vuelo.html
│        (pre-llena con: cliente, proyecto, fecha, horario, locacion)
│
├─ ACCIÓN 3 [Enviar Email Inmediato]
│  └─ SendGrid email (con firma AV_Firma_Email.html):
│     Asunto: "Tu reserva está confirmada ✓ · {{paquete_nombre}} · S/{{total}}"
│     Adjuntos: Recibo (PDF), Contrato (PDF), Certificado (preview)
│     
├─ ACCIÓN 4 [Enviar WhatsApp confirmation]
│  └─ Telegram Bot:
│     Mensaje a @aerovisuales4k_leads_bot:
│     "✅ NUEVA VENTA WEB
│      Cliente: {{nombre}}
│      Email: {{email}}
│      Paquete: {{paquete}}
│      Total: S/{{total}}
│      Fecha vuelo: {{fecha_vuelo}}"
│
├─ ACCIÓN 5 [Schedule: Pre-Vuelo Sequence]
│  └─ Calcular: fecha_vuelo - 1 día
│     Guardar en Supabase: scheduled_email_instrucciones = fecha_vuelo - 24h
│     (Será disparado por cron job de n8n)
│
└─ ACCIÓN 6 [Guardar Flags]
   └─ emails_enviados = ["recibo", "contrato", "certificado"]
      estado_cliente = "comprador"
      recibo_numero = auto-increment
      fecha_compra = TODAY()

═══════════════════════════════════════════════════════════════════

[24 HORAS ANTES DE FECHA_VUELO]

TRIGGER: n8n cron job: "Es 1 día antes de fecha_vuelo?"
│
├─ ACCIÓN 1 [Generar Documento]
│  └─ AV4K_Instrucciones_Dia_Vuelo.html
│     (pre-llena con: cliente_nombre, fecha, horario, locacion, punto_encuentro, numero_julio)
│
├─ ACCIÓN 2 [Enviar Email + WhatsApp]
│  ├─ SendGrid: "Tu vuelo es MAÑANA 🚁"
│  │  Adjunto: Instrucciones (PDF)
│  │  Incluye: Qué llevar, dónde estar, con quién contactar
│  └─ Telegram Bot: "RECORDATORIO: Vuelo mañana {{fecha}} {{horario}}"
│
└─ ACCIÓN 3 [Guardar Flag]
   └─ emails_enviados.push("instrucciones")

═══════════════════════════════════════════════════════════════════

[DÍA DE VUELO → POST-VUELO]

TRIGGER: Julio completa vuelo, marca en Telegram: "Vuelo completado ✓"
│
├─ ACCIÓN 1 [24h POST-VUELO: Enviar Email Aprobación]
│  └─ Generar + Enviar: AV4K_Formulario_Aprobacion.html
│     Email: "¿Te gustó el material? Aprueba aquí"
│     Link a formulario web donde cliente confirma "Aprobado" o "Revisar cambios"
│
├─ ACCIÓN 2 [Cuando Cliente Aprueba]
│  └─ Flag: aprobacion_status = "aprobado"
│
├─ ACCIÓN 3 [INMEDIATO POST-APROBACIÓN: BATCH ENGINE]
│  └─ Disparar: batch_engine_7_1.html
│     Input: video_source (URL WeTransfer), duracion, estilo
│     Output: AUTO-genera 7 assets
│        • video_16_9.mp4 (YouTube)
│        • video_1_1.mp4 (Instagram feed)
│        • video_9_16.mp4 (Reels/Stories)
│        • thumbnail_1.png
│        • thumbnail_2.png
│        • carrusel_6slides.html
│        • gif_loop_3s.gif
│        • 4x clip_15s.mp4
│
│     Telegram notificación: "Batch listo: [7 archivos generados]"
│     Email a cliente: "Tu material + 7 assets listos para redes"
│
├─ ACCIÓN 4 [Enviar Guía de Uso]
│  └─ AV4K_Guia_Uso_Material.html
│     Email: "Cómo usar tu material: derechos, formatos, tips"
│
├─ ACCIÓN 5 [Schedule: Email Reseña 5-7 días después]
│  └─ n8n cron: fecha_compra + 5 días
│     Enviar: AV4K_Email_Resena.html
│     Email: "¿Cómo nos fue? Tu reseña nos ayuda mucho"
│     Link: Flujo_de_Resenas.html (formulario web)
│
├─ ACCIÓN 6 [Schedule: VIP Offer 10-15 días después]
│  └─ n8n cron: fecha_compra + 10 días
│     Enviar: AV4K_VIP_Programa.html
│     Email: "Upgrade a VIP: beneficios exclusivos + descuento 20%"
│
├─ ACCIÓN 7 [Schedule: Referidos Offer 15-20 días después]
│  └─ n8n cron: fecha_compra + 15 días
│     Enviar: AV4K_Sistema_Referidos.html
│     Email: "Refiere a un amigo, gana comisión"
│
└─ ACCIÓN 8 [Guardar Flags]
   └─ emails_enviados = ["recibo", "contrato", "certificado", "instrucciones", 
                         "aprobacion", "guia", "resena", "vip", "referidos"]
      estado_cliente = "cliente_activo"
      batch_assets_generados = true
      batch_timestamp = NOW()

═══════════════════════════════════════════════════════════════════

FIN DEL FLUJO: Cliente tiene:
✅ Video + 7 assets listos
✅ Oferta VIP en inbox
✅ Programa referidos activado
✅ Está en newsletter
```

---

## 🎯 FLUJO 2: LINKEDIN → PROSPECTO → PROPUESTA → COMPRADOR

**Entry Point:** Julio envía DM en LinkedIn (prospecto = desconocido)
**Lead Source:** `linkedin`
**Duración:** 3-14 días

```
TRIGGER: Julio registra contacto LinkedIn manualmente en formulario
│
├─ ACCIÓN 1 [Supabase INSERT]
│  └─ Tabla: leads_captacion
│     └─ Insertar: nombre, email (si tiene), empresa, sector, 
│        lead_source="linkedin", estado_cliente="prospecto_frio"
│
├─ ACCIÓN 2 [Email Secuencia: Plantilla 1]
│  └─ Day 0: SendGrid email
│     Asunto: "Te vi en LinkedIn, esto podría interesarte"
│     Contenido: Pantillas_de_email.html (template 1: "Contacto LinkedIn")
│     Incluye: ¿Quiénes somos, 1 caso de estudio, CTA "Ver portafolio"
│
├─ ACCIÓN 3 [Email Secuencia: Plantilla 2]
│  └─ Day 3: SendGrid email (si no respondió)
│     Asunto: "Caso de éxito similar a tu sector"
│     Contenido: Pantillas_de_email.html (template 2: "Caso estudio")
│     Incluye: Casos_de_Estudio.html (video case), CTA "Charlemos"
│
├─ ACCIÓN 4 [Email Secuencia: Plantilla 3]
│  └─ Day 7: SendGrid email (si aún no respondió)
│     Asunto: "Propuesta especial: producción aérea para {{sector}}"
│     Contenido: Pantillas_de_email.html (template 3: "Propuesta limitada")
│     Incluye: Comparador_Paquetes.html (selector visual), CTA "Quiero cotización"
│
├─ ACCIÓN 5 [IF Cliente Responde Positivamente]
│  ├─ Flag: linkedin_respuesta = true, respuesta_fecha = NOW()
│  │
│  ├─ Generar + Enviar: Creador_de_propuestas_comerciales.html
│  │  Email: "Basado en tu sector {{sector}}, creé esta propuesta"
│  │  Adjunto: Propuesta_Comercial.html (PDF customizado)
│  │  Incluye: Especificaciones (videospecsheet.html), FAQ (FAQ_Objeciones.html)
│  │
│  ├─ Flag: propuesta_enviada = true, propuesta_fecha = NOW()
│  │
│  └─ [ESPERA: Cliente aprueba propuesta (máx 7 días)]
│
├─ ACCIÓN 6 [IF Cliente Aprueba Propuesta]
│  ├─ Flag: propuesta_aprobada = true
│  │
│  ├─ [MERGE CON FLUJO WEB COTIZADOR] 
│  │  → Activa: Recibo, Contrato, Certificado
│  │  → Activa: Instrucciones pre-vuelo
│  │  → Activa: Post-vuelo secuence (aprobación, batch, guía, reseña, vip, referidos)
│  │
│  └─ Lead source histórico: "linkedin" (para analytics)
│
└─ ACCIÓN 7 [IF Cliente NO Responde en 14 días]
   └─ Flag: linkedin_abandonado = true
      → Puede re-contactarse en 30 días (leads_captacion.recontacto_fecha)

═══════════════════════════════════════════════════════════════════

FIN DEL FLUJO: 
- Si conversión: cliente activo (merge con flujo web)
- Si no: prospecto en follow-up
```

---

## 📧 FLUJO 3: EMAIL FRÍO → SECUENCIA → PROPUESTA → COMPRADOR

**Entry Point:** Email masivo a lista (o prospecto que encontraste)
**Lead Source:** `email_frio`
**Duración:** 7-30 días
**Risk:** Alto spam, requiere contexto

```
TRIGGER: Julio envía email manual (con contexto: LinkedIn visto, evento, etc.)
│
├─ ACCIÓN 1 [Supabase INSERT]
│  └─ Tabla: leads_captacion
│     └─ Insertar: email, empresa (si tiene), lead_source="email_frio"
│        contexto="[visto en LinkedIn/evento/referencia]"
│
├─ ACCIÓN 2 [Email 1: Presentación]
│  └─ Day 0: SendGrid email
│     Asunto: "Vi {{empresa}}, esto te podría interesar"
│     Contenido: Pantillas_de_email.html (template: "Email frío intro")
│     Objetivo: Que abra email (no vender, solo rapport)
│
├─ ACCIÓN 3 [Email 2: Social Proof]
│  └─ Day 3: SendGrid email
│     Asunto: "Empresas como {{sector}} nos confían"
│     Contenido: Pantillas_de_email.html + Casos_de_Estudio.html
│     Objetivo: Generar credibilidad
│
├─ ACCIÓN 4 [Email 3: Oferta]
│  └─ Day 7: SendGrid email
│     Asunto: "Propuesta especial solo hasta fin de semana"
│     Contenido: Creador_de_propuestas_comerciales.html (form)
│     Objetivo: Que llene detalles para propuesta custom
│
├─ ACCIÓN 5 [IF Cliente Hace Clic o Responde]
│  └─ Flag: email_frio_engagement = true, engagement_fecha = NOW()
│     → Enviar: Comparador_Paquetes.html (decision aid)
│     → Enviar: FAQ_Objeciones.html (responder objeciones)
│
└─ ACCIÓN 6 [IF No Hay Engagement]
   └─ Flag: email_frio_abandonado = true
      → Pause secuencia por 30 días
      → Reactivar con "última oportunidad" email (descuento temporal)

═══════════════════════════════════════════════════════════════════

FIN DEL FLUJO:
- Si engagement: prospecto warm (calificado)
- Si venta: [merge con flujo web]
- Si no: base de datos para re-contacto
```

---

## 📬 FLUJO 4: ABANDONED CHECKOUT → RECOVERY

**Entry Point:** Cliente ingresa cotizador, elige paquete, PERO no confirma
**Lead Source:** `web_abandonado`
**Duración:** 1-7 días
**Objetivo:** Recuperar ~20-30% de abandonos

```
TRIGGER: n8n detecta: (Cliente vio cotizador AND fecha_visitada < 24h) 
         AND email_no_confirmado=true
│
├─ ACCIÓN 1 [Supabase UPDATE]
│  └─ Tabla: leads_captacion
│     └─ Update: lead_source="web_abandonado", 
│        paquete_visto="{{paquete_nombre}}", 
│        precio_visto={{precio}}, 
│        abandoned_checkout=true
│
├─ ACCIÓN 2 [Email Day 1: Soft Reminder]
│  └─ SendGrid email (24h después de visita)
│     Asunto: "Vimos que miraste {{paquete_nombre}}"
│     Contenido: 
│        • Reminder amable (no aggressive)
│        • Reiterar especificaciones
│        • Comparador_Paquetes.html (para que revea opciones)
│        • CTA suave: "¿Tenés dudas? Aquí va FAQ"
│
├─ ACCIÓN 3 [Incluir FAQ + Comparador]
│  └─ Adjuntar: 
│     • FAQ_Objeciones.html (resp. dudas comunes)
│     • Comparador_Paquetes.html (ver alternativas)
│
├─ ACCIÓN 4 [Email Day 4: Social Proof]
│  └─ SendGrid email (si no hizo clic)
│     Asunto: "Clientes como vos confían en nosotros"
│     Contenido: Casos_de_Estudio.html (videos demuestran calidad)
│
├─ ACCIÓN 5 [Email Day 7: Descuento Temporal]
│  └─ SendGrid email (última oportunidad)
│     Asunto: "Descuento especial: solo hoy -10%"
│     Contenido: 
│        • {{paquete_nombre}}: S/{{precio_original}} → S/{{precio - 10%}}
│        • Válido: hoy nomás
│        • CTA URGENTE: "Reservar ahora"
│
├─ ACCIÓN 6 [IF Cliente Hace Clic]
│  ├─ Flag: abandoned_recovery_sucesso = true
│  ├─ Redirige a cotizador (con paquete pre-seleccionado + descuento aplicado)
│  └─ [Si confirma] → [MERGE CON FLUJO WEB COTIZADOR]
│
└─ ACCIÓN 7 [IF No Hay Conversion]
   └─ Flag: abandoned_conversion_failed = true
      → Guardar para re-contacto en 30 días
      → Email futura: "Actualización: nuevos paquetes"

═══════════════════════════════════════════════════════════════════

METRICS:
- Tasa de abandono esperada: ~60-70% (web estándar)
- Tasa de recovery esperada: ~20-30% de abandonos
- ROI: Alto (cliente casi convencido, solo necesita un push)
```

---

## 📰 FLUJO 5: NEWSLETTER → SEGMENTADO → ACCIÓN

**Entry Point:** Suscriptor en lista email
**Lead Source:** `newsletter`
**Duración:** Continuo
**Objetivos:** Engagement + upsell + referrals

```
TRIGGER: n8n weekly cron: "Es miércoles 10am?"
│
├─ ACCIÓN 1 [Segmentación]
│  └─ Tabla: leads_captacion, columna: subscriber_type
│     ├─ subscriber_type = "prospecto" 
│     │  → Newsletter_Sistema.html + template: "Inspiración"
│     │  → Contenido: Casos, tips, sin vender
│     │
│     ├─ subscriber_type = "cliente"
│     │  → Newsletter_Sistema.html + template: "Tips uso material"
│     │  → Contenido: Guías, casos nuevos, ideas para redes
│     │
│     └─ subscriber_type = "vip"
│        → Newsletter_Sistema.html + template: "VIP Exclusive"
│        → Contenido: Early access nuevos servicios, descuentos
│
├─ ACCIÓN 2 [Usar Header Reutilizable]
│  └─ Email_Header_Newsletter.html (header visual)
│     + Pantillas_de_email.html (template variado)
│     + Firma_Email.html (footer)
│
├─ ACCIÓN 3 [Lógica de CTA según segment]
│  ├─ Prospecto → CTA: "Ver portafolio" / "Cotizar"
│  ├─ Cliente → CTA: "Descargar material" / "Compartir en redes"
│  └─ VIP → CTA: "Acceso exclusivo" / "Invitar amigo"
│
├─ ACCIÓN 4 [Tracking]
│  └─ Supabase tabla: newsletter_engagement
│     ├─ subscriber_email
│     ├─ sent_date
│     ├─ opened = (si SendGrid webhook open)
│     ├─ clicked = (si SendGrid webhook click)
│     └─ click_link = (qué botón clickeó)
│
├─ ACCIÓN 5 [Smart Follow-up]
│  └─ If clicked CTA → Enviar email relevante
│     ├─ Si "Cotizar" → Enviar: Comparador_Paquetes.html
│     ├─ Si "Ver portafolio" → Enviar: Casos_de_Estudio.html
│     └─ Si "VIP exclusive" → Enviar: VIP_Programa.html
│
└─ ACCIÓN 6 [Unsubscribe Safe]
   └─ Cada email incluye link unsubscribe
      Flag: subscriber_status = "inactive"
      (No borrar, guardar para re-engagement futura)

═══════════════════════════════════════════════════════════════════

CADENCIA:
- Prospecto: semanal (engagement)
- Cliente: mensual (tips + community)
- VIP: semanal (exclusive offers)
```

---

## 🎬 FLUJO 6: POST-VENTA RETENTION

**Entry Point:** Cliente tiene material entregado + aprobado
**Lead Source:** Cualquiera (heredado)
**Duración:** Continuo
**Objetivo:** Repeat business + referrals

```
TRIGGER: Flag cliente_material_entregado = true (desde Flujo 1 ACCIÓN 3)
│
├─ ACCIÓN 1 [Day 10: VIP Offer]
│  └─ Generar + Enviar: AV4K_VIP_Programa.html
│     Email: "Te gustó? Únete a VIP y obtén descuentos"
│     Beneficios: 20% off, priority booking, exclusive content
│     Link: Formulario de upgrade VIP
│
├─ ACCIÓN 2 [IF VIP Upgrade]
│  ├─ Flag: vip_miembro = true, vip_fecha_inicio = NOW()
│  ├─ Update: subscriber_type = "vip"
│  └─ Adicionar a newsletter VIP
│
├─ ACCIÓN 3 [Day 15: Referidos Program]
│  └─ Generar + Enviar: AV4K_Sistema_Referidos.html
│     Email: "Refiere amigos, gana comisión"
│     Estructura:
│        • Referido compra Raw Air (S/450) → Tú ganas S/50
│        • Referido compra Aerial Ready (S/1,050) → Tú ganas S/150
│        • Referido compra Signature (S/1,875) → Tú ganas S/300
│     Link: Único referral_code por cliente (stored in Supabase)
│
├─ ACCIÓN 4 [IF Referido Compra]
│  ├─ Flag: cliente_referidos_count += 1
│  ├─ Crear: nuevo lead con referrer_id = cliente_id
│  ├─ Generar: Link pago comisión (vía Interbank invoice)
│  └─ Enviar: Confirmación comisión ganada
│
├─ ACCIÓN 5 [Day 60: Upsell Dinámico]
│  └─ Lógica:
│     ├─ Si compró Raw Air → Ofrecer: "Upgrade a Aerial Ready: S/600 más"
│     ├─ Si compró Aerial Ready → Ofrecer: "Full Signature: S/825 más"
│     └─ Si compró Signature → Ofrecer: "2do video: 15% descuento"
│     
│     Email: Personalizado según histórico
│     Adjunto: Comparador_Paquetes.html (mostrar diferencias)
│
├─ ACCIÓN 6 [Day 120: Reactivación]
│  └─ Email: "¿Tuviste otro proyecto aéreo?"
│     Contenido: Newsletter_Sistema.html + tips nuevos
│     CTA: "Cotizar nuevo proyecto"
│
└─ ACCIÓN 7 [Continuous: Newsletter VIP]
   └─ Mensual: contenido exclusivo + early access offers

═══════════════════════════════════════════════════════════════════

METRICS:
- VIP conversion rate: ~30% de clientes
- Referido conversion: ~20% (depende del cliente)
- Repeat purchase: ~40% dentro de 12 meses
- Lifetime value: Cliente inicial S/1,875 → S/5,000+ en 2 años
```

---

## 🔄 FLUJO 7: BATCH ENGINE AUTOMATION

**Entry Point:** Cliente aprueba material (Flujo 1, ACCIÓN 2)
**Lead Source:** Cualquiera
**Duración:** 2-5 minutos
**Objetivo:** Generar 7+ assets sin intervención manual

```
TRIGGER: Flag formulario_aprobacion_status = "aprobado"
│
├─ ACCIÓN 1 [n8n detecta aprobación]
│  └─ Webhook: Supabase flag changed
│     └─ Buscar: batch_engine_entrada (URL video, duración, cliente_nombre)
│
├─ ACCIÓN 2 [Disparar: batch_engine_7_1.html]
│  └─ Input: 
│     • video_url = "{{video_descarga_url}}"
│     • duracion_segundos = {{duracion}}
│     • estilo = "aerovisuales" (brand colors)
│     • cliente_nombre = "{{cliente_nombre}}"
│     • fecha = "{{fecha_vuelo}}"
│
├─ ACCIÓN 3 [Batch genera AUTOMÁTICAMENTE]
│  └─ Output (todo en paralelo):
│     
│     ✅ VIDEO_16_9.mp4
│        └─ Resolución: 1920x1080
│        └─ Codec: H.264
│        └─ Uso: YouTube, web, email
│        └─ Tiempo procesamiento: 1 min
│     
│     ✅ VIDEO_1_1.mp4
│        └─ Resolución: 1080x1080
│        └─ Uso: Instagram feed
│        └─ Tiempo procesamiento: 1 min
│     
│     ✅ VIDEO_9_16.mp4
│        └─ Resolución: 1080x1920
│        └─ Uso: Instagram Reels, TikTok, Stories
│        └─ Tiempo procesamiento: 1 min
│     
│     ✅ THUMBNAILS (3 variantes)
│        └─ 1920x1080 para YouTube
│        └─ 1200x630 para LinkedIn/Facebook
│        └─ 1080x1080 para Instagram preview
│        └─ Tiempo procesamiento: 30 seg
│     
│     ✅ CARRUSEL_6SLIDES.html
│        └─ Slide 1: Teaser (logo + texto teaser)
│        └─ Slide 2-4: BTS (behind the scenes)
│        └─ Slide 5: Specs (4K, drone, DGAC)
│        └─ Slide 6: CTA (link a Aerovisuales)
│        └─ Optimizado: 1080x1350 cada slide
│        └─ Tiempo procesamiento: 1 min
│     
│     ✅ GIF_LOOP_3S.gif
│        └─ Loop infinito
│        └─ Duración: 3 segundos
│        └─ Resolución: 800x600
│        └─ Uso: WhatsApp, email, social preview
│        └─ Tiempo procesamiento: 30 seg
│     
│     ✅ CLIPS_4x15S.mp4
│        └─ 4 clips diferentes (15 seg cada uno)
│        └─ Uso: TikTok, shorts, reels
│        └─ Tiempo procesamiento: 2 min
│
├─ ACCIÓN 4 [Guardar outputs]
│  └─ Crear carpeta: /outputs/{{cliente_nombre}}_{{fecha_vuelo}}/
│     ├─ video_16_9.mp4
│     ├─ video_1_1.mp4
│     ├─ video_9_16.mp4
│     ├─ thumbnail_youtube.png
│     ├─ thumbnail_social.png
│     ├─ thumbnail_instagram.png
│     ├─ carrusel_instagram.html
│     ├─ gif_loop.gif
│     ├─ clip_1_15s.mp4
│     ├─ clip_2_15s.mp4
│     ├─ clip_3_15s.mp4
│     └─ clip_4_15s.mp4
│
├─ ACCIÓN 5 [Supabase UPDATE]
│  └─ Tabla: leads_captacion
│     ├─ batch_assets_generados = true
│     ├─ batch_timestamp = NOW()
│     ├─ batch_assets_count = 12
│     └─ batch_folder_url = "{{carpeta_outputs}}"
│
├─ ACCIÓN 6 [Notificar a Julio]
│  └─ Telegram bot message:
│     "🎬 BATCH LISTO: Cliente {{cliente_nombre}}
│      ✅ 1 video 16:9
│      ✅ 1 video 1:1
│      ✅ 1 video 9:16
│      ✅ 3 thumbnails
│      ✅ 1 carrusel (6 slides)
│      ✅ 1 GIF loop
│      ✅ 4 clips de 15s
│      
│      Total: 12 assets en {{tiempo_procesamiento}}
│      Descarga: {{link_carpeta}}"
│
├─ ACCIÓN 7 [Email a Cliente]
│  └─ SendGrid email:
│     Asunto: "Tu material + 7 assets listos para redes 🎬"
│     Contenido: 
│        • "Aquí está tu video en todos los formatos"
│        • "También generamos automáticamente:"
│        •   - 3 formatos video (YouTube, Insta, Reels)
│        •   - 3 thumbnails optimizados
│        •   - Carrusel Instagram (listo para publicar)
│        •   - GIF animado (WhatsApp, email)
│        •   - 4 clips de 15s (TikTok, Reels)
│     Adjuntos: ZIP con todos los assets
│     Instrucciones: Qué publicar dónde
│
└─ ACCIÓN 8 [Completar flujo]
   └─ Flag: cliente_batch_notificado = true
      Listo para siguiente paso: VIP offer (Day 10)

═══════════════════════════════════════════════════════════════════

IMPACTO:
- Sin Batch: 30 min manual de editing x cliente
- Con Batch: 2 min automático
- Multiplicador: 15x FASTER
- Valor: Cliente tiene 12 assets listos para publicar SIN ESPERAR

```

---

## 📊 MATRIZ RESUMEN: TODOS LOS FLUJOS

| Flujo | Entry | Lead Source | Duración | HTML Principales | Objetivo |
|---|---|---|---|---|---|
| 1️⃣ Web Cotizador | aerovisuales4k.com | `web_cotizador` | 5 min | Recibo, Contrato, Cert, Instr | Venta inmediata |
| 2️⃣ LinkedIn | DM LinkedIn | `linkedin` | 3-14 d | Email seq, Propuesta, Recibo | Venta nurture |
| 3️⃣ Email Frío | Email masivo | `email_frio` | 7-30 d | Email seq, FAQ, Propuesta | Venta cold |
| 4️⃣ Abandoned | Cotizador sin confirmar | `web_abandonado` | 1-7 d | Comparador, FAQ, Descuento | Recovery |
| 5️⃣ Newsletter | Suscriptor lista | `newsletter` | Continuo | Newsletter, Pantillas vars | Engagement |
| 6️⃣ Post-venta | Cliente entregado | (heredado) | Continuo | VIP, Referidos, Upsell | Retention |
| 7️⃣ Batch | Aprobación material | (heredado) | 2-5 min | batch_engine_7.1 | Escala |

---

## 🔐 PRINCIPIOS DE IMPLEMENTACIÓN

### ✅ Data Integrity
- Single source: Supabase (no duplicados)
- Timestamps en todo (auditability)
- Flags para idempotency (no re-procesar)

### ✅ User Privacy
- GDPR compliant: unsubscribe links
- Rate limiting: máx 1 email por cliente por día
- Opt-in required: newsletter solo si consintió

### ✅ Error Handling
- Retry logic: Si SendGrid falla, reintentar 3x
- Fallback: Si Supabase cae, queue en Redis
- Logging: Cada movimiento en `leads_captacion.audit_log` (JSON)

### ✅ Monitoring
- Telegram alerts: "Error en flujo LinkedIn"
- Dashboard: Conversión rates por flujo
- Metrics: Open rate, click rate, conversion rate

---

## 📌 SIGUIENTE PASO: SUPABASE SCHEMA

El Blueprint está completo. Ahora necesitamos definir **exactamente qué columnas va a tener la tabla `leads_captacion`** (la BD de referencia).

¿Pasamos al Supabase Schema? 👇
