# SUPABASE SCHEMA
## Estructura completa de base de datos — Aerovisuales 4K

**Sistema de referencia única para todos los 8 flujos**

---

## 🗄️ TABLAS REQUERIDAS (6)

```
1. leads_captacion         (tabla maestro)
2. propuestas             (propuestas comerciales)
3. batch_assets           (assets generados)
4. newsletter_suscriptores (lista email)
5. referidos              (programa de referidos)
6. audit_log              (registro de movimientos)
```

---

## 📋 TABLA 1: leads_captacion

**Descripción:** Tabla maestra. TODO prospecto/cliente va aquí.

```sql
CREATE TABLE leads_captacion (
  -- IDENTIDAD
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fecha_creacion          TIMESTAMP DEFAULT now(),
  fecha_actualizacion     TIMESTAMP DEFAULT now(),

  -- DATOS CLIENTE
  cliente_nombre          VARCHAR(200) NOT NULL,
  cliente_email           VARCHAR(255) UNIQUE,
  cliente_telefono        VARCHAR(20),
  cliente_ruc_dni         VARCHAR(20),
  cliente_domicilio       TEXT,
  cliente_representante   VARCHAR(200),
  cliente_cargo           VARCHAR(100),

  -- DATOS EMPRESA
  empresa_nombre          VARCHAR(255),
  empresa_sector          VARCHAR(100),
  empresa_distrito        VARCHAR(100),

  -- CONTEXTO DE ORIGEN
  lead_source             VARCHAR(50) NOT NULL,
    -- Valores: 'web_cotizador' | 'linkedin' | 'email_frio' | 
    --          'newsletter' | 'referencia' | 'web_abandonado' | 'evento'
  lead_contexto           TEXT,  -- "Visto en LinkedIn" / "Referencia de Juan" / etc
  referrer_id             UUID REFERENCES leads_captacion(id),  -- Si vino por referido

  -- ESTADO CLIENTE
  estado_cliente          VARCHAR(50) NOT NULL DEFAULT 'prospecto',
    -- Valores: 'prospecto_frio' | 'prospecto_warm' | 'comprador' | 
    --          'cliente_activo' | 'vip_miembro' | 'cliente_inactivo'
  estado_fecha            TIMESTAMP,  -- Cuándo cambió de estado

  -- DATOS DE PROYECTO/VUELO
  proyecto_nombre         VARCHAR(255),
  proyecto_tipo           VARCHAR(100),
  proyecto_locacion       VARCHAR(200),
  proyecto_distrito       VARCHAR(100),
  fecha_vuelo             DATE,
  horario_estimado        TIME,
  direccion_exacta        TEXT,
  punto_encuentro         TEXT,
  observaciones           TEXT,

  -- DATOS ECONÓMICOS
  paquete_tipo            VARCHAR(50),
    -- Valores: 'Raw Air' | 'Aerial Ready' | 'Signature Aerial'
  paquete_precio          DECIMAL(10,2),
  servicios_adicionales   TEXT,  -- JSON: [{servicio, precio}]
  monto_total             DECIMAL(10,2),
  monto_anticipo          DECIMAL(10,2),  -- 50% del total
  monto_saldo             DECIMAL(10,2),  -- 50% del total
  metodo_pago             VARCHAR(50),
    -- Valores: 'Transferencia' | 'Yape' | 'Plin' | 'Efectivo'
  fecha_pago              TIMESTAMP,
  comprobante_pago        VARCHAR(255),  -- Número de transferencia/voucher

  -- DOCUMENTOS
  recibo_numero           VARCHAR(50) UNIQUE,
    -- Auto-generated: REC-AV4K-YYYY-NNNN
  contrato_numero         VARCHAR(50),
    -- Auto-generated: CTR-AV4K-YYYY-NNNN
  contrato_firmado        BOOLEAN DEFAULT false,
  contrato_fecha_firma    TIMESTAMP,

  -- EMAILS ENVIADOS (CONTROL DE IDEMPOTENCIA)
  emails_enviados         JSONB DEFAULT '[]',
    -- Array: [{email_type, sent_date, status, open_date, click_date}]
    -- Ejemplo: 
    -- [
    --   {type: 'recibo', sent: '2026-06-10T16:00:00Z', status: 'sent', opened: '2026-06-10T16:05:00Z'},
    --   {type: 'contrato', sent: '2026-06-10T16:01:00Z', status: 'sent', opened: null},
    --   {type: 'instrucciones', sent: '2026-06-15T14:00:00Z', status: 'scheduled', opened: null}
    -- ]

  -- TRACKING DE EVENTOS
  linkedin_contactado     BOOLEAN DEFAULT false,
  linkedin_contactado_fecha TIMESTAMP,
  linkedin_respuesta      BOOLEAN DEFAULT false,
  linkedin_respuesta_fecha TIMESTAMP,

  propuesta_enviada       BOOLEAN DEFAULT false,
  propuesta_fecha         TIMESTAMP,
  propuesta_numero        VARCHAR(50),
  propuesta_aprobada      BOOLEAN DEFAULT false,
  propuesta_aprobada_fecha TIMESTAMP,

  vuelo_completado        BOOLEAN DEFAULT false,
  vuelo_fecha_real        TIMESTAMP,

  aprobacion_status       VARCHAR(50) DEFAULT 'pendiente',
    -- Valores: 'pendiente' | 'aprobado' | 'requiere_cambios'
  aprobacion_fecha        TIMESTAMP,
  aprobacion_cambios      TEXT,

  -- BATCH ENGINE
  batch_assets_generados  BOOLEAN DEFAULT false,
  batch_timestamp         TIMESTAMP,
  batch_folder_url        TEXT,  -- URL a carpeta con 12 assets
  batch_assets_count      INTEGER,  -- Debería ser 12

  -- POST-VENTA
  guia_uso_enviada        BOOLEAN DEFAULT false,
  reseña_solicitada       BOOLEAN DEFAULT false,
  reseña_recibida         BOOLEAN DEFAULT false,
  reseña_rating           INTEGER,  -- 1-5
  reseña_texto            TEXT,
  reseña_fecha            TIMESTAMP,

  vip_miembro             BOOLEAN DEFAULT false,
  vip_fecha_inicio        TIMESTAMP,
  vip_comision_rate       DECIMAL(5,2) DEFAULT 0.00,

  referidos_count         INTEGER DEFAULT 0,
  referidos_ganado        DECIMAL(10,2) DEFAULT 0.00,

  -- SEGUIMIENTO
  abandonded_checkout     BOOLEAN DEFAULT false,
  abandoned_checkout_fecha TIMESTAMP,
  abandoned_recovery_intento INTEGER DEFAULT 0,

  -- PRÓXIMAS ACCIONES PROGRAMADAS
  scheduled_email_instrucciones TIMESTAMP,  -- Cuándo enviar instrucciones
  scheduled_email_resena  TIMESTAMP,
  scheduled_email_vip     TIMESTAMP,
  scheduled_email_referidos TIMESTAMP,

  -- NEWSLETTER
  subscriber_email_list   BOOLEAN DEFAULT false,
  subscriber_type         VARCHAR(50) DEFAULT 'prospecto',
    -- Valores: 'prospecto' | 'cliente' | 'vip'
  subscriber_status       VARCHAR(50) DEFAULT 'activo',
    -- Valores: 'activo' | 'inactivo' | 'bounced' | 'unsubscribed'
  subscriber_since        TIMESTAMP,
  subscriber_unsubscribe_date TIMESTAMP,

  -- NOTAS INTERNAS
  notas_internas          TEXT,
  tags                    TEXT[],  -- Array: ['urgente', 'high-value', 'problema']

  -- AUDIT
  created_by              VARCHAR(100),
  updated_by              VARCHAR(100),
  audit_log               JSONB DEFAULT '[]'
    -- Array de cambios: [{field, old_value, new_value, timestamp, changed_by}]
);

-- ÍNDICES
CREATE INDEX idx_leads_email ON leads_captacion(cliente_email);
CREATE INDEX idx_leads_lead_source ON leads_captacion(lead_source);
CREATE INDEX idx_leads_estado ON leads_captacion(estado_cliente);
CREATE INDEX idx_leads_fecha_vuelo ON leads_captacion(fecha_vuelo);
CREATE INDEX idx_leads_subscriber ON leads_captacion(subscriber_email_list);
```

---

## 📋 TABLA 2: propuestas

**Descripción:** Historial de propuestas comerciales enviadas.

```sql
CREATE TABLE propuestas (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fecha_creacion          TIMESTAMP DEFAULT now(),
  
  -- RELACIÓN
  lead_id                 UUID NOT NULL REFERENCES leads_captacion(id),
  
  -- IDENTIFICACIÓN
  propuesta_numero        VARCHAR(50) UNIQUE,
    -- Auto-generated: PROP-AV4K-YYYY-NNNN
  estado                  VARCHAR(50) DEFAULT 'enviada',
    -- Valores: 'enviada' | 'visto' | 'aprobada' | 'rechazada'
  
  -- CONTENIDO
  empresa_cliente         VARCHAR(255),
  sector_cliente          VARCHAR(100),
  descripcion_proyecto    TEXT,
  alcance_proyecto        TEXT,
  
  -- ECONOMIC
  monto_propuesto         DECIMAL(10,2),
  desglose                JSONB,  -- [{concepto, monto}]
  plazo_validez           DATE,
  
  -- SEGUIMIENTO
  enviada_fecha           TIMESTAMP,
  abierta_fecha           TIMESTAMP,
  aprobada_fecha          TIMESTAMP,
  rechazada_fecha         TIMESTAMP,
  
  -- NOTAS
  notas                   TEXT,
  
  created_by              VARCHAR(100)
);

CREATE INDEX idx_propuestas_lead ON propuestas(lead_id);
CREATE INDEX idx_propuestas_numero ON propuestas(propuesta_numero);
```

---

## 📋 TABLA 3: batch_assets

**Descripción:** Registro de assets generados automáticamente.

```sql
CREATE TABLE batch_assets (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fecha_creacion          TIMESTAMP DEFAULT now(),
  
  -- RELACIÓN
  lead_id                 UUID NOT NULL REFERENCES leads_captacion(id),
  
  -- IDENTIFICACIÓN
  batch_id                VARCHAR(50) UNIQUE,
    -- Auto-generated: BATCH-AV4K-YYYY-NNNN
  
  -- METADATA
  cliente_nombre          VARCHAR(255),
  fecha_vuelo             DATE,
  duracion_segundos       INTEGER,
  
  -- ASSETS GENERADOS
  assets                  JSONB,
    -- {
    --   "video_16_9": {url: "...", size: 450000, codec: "h264"},
    --   "video_1_1": {url: "...", size: 380000, codec: "h264"},
    --   "video_9_16": {url: "...", size: 420000, codec: "h264"},
    --   "thumbnail_youtube": {url: "...", size: 250000},
    --   "thumbnail_social": {url: "...", size: 180000},
    --   "thumbnail_instagram": {url: "...", size: 200000},
    --   "carrusel_instagram": {url: "...", size: 1200000},
    --   "gif_loop": {url: "...", size: 5000000},
    --   "clip_1_15s": {url: "...", size: 80000},
    --   "clip_2_15s": {url: "...", size: 85000},
    --   "clip_3_15s": {url: "...", size: 88000},
    --   "clip_4_15s": {url: "...", size: 82000}
    -- }
  
  -- ESTADO
  status                  VARCHAR(50) DEFAULT 'processing',
    -- Valores: 'processing' | 'complete' | 'error'
  error_message           TEXT,
  
  -- DESCARGAS
  descargas_count         INTEGER DEFAULT 0,
  ultima_descarga         TIMESTAMP,
  
  -- NOTAS
  notas                   TEXT
);

CREATE INDEX idx_batch_lead ON batch_assets(lead_id);
CREATE INDEX idx_batch_id ON batch_assets(batch_id);
```

---

## 📋 TABLA 4: newsletter_suscriptores

**Descripción:** Lista de suscriptores a newsletter.

```sql
CREATE TABLE newsletter_suscriptores (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fecha_creacion          TIMESTAMP DEFAULT now(),
  
  -- RELACIÓN
  lead_id                 UUID REFERENCES leads_captacion(id),
  
  -- EMAIL
  email                   VARCHAR(255) UNIQUE NOT NULL,
  nombre                  VARCHAR(200),
  
  -- SEGMENTACIÓN
  tipo_suscriptor         VARCHAR(50) DEFAULT 'prospecto',
    -- Valores: 'prospecto' | 'cliente' | 'vip'
  
  -- ESTADO
  status                  VARCHAR(50) DEFAULT 'activo',
    -- Valores: 'activo' | 'inactivo' | 'bounced' | 'unsubscribed'
  
  -- SEGUIMIENTO DE EMAILS
  emails_recibidos        INTEGER DEFAULT 0,
  emails_abiertos         INTEGER DEFAULT 0,
  emails_clicados         INTEGER DEFAULT 0,
  
  open_rate               DECIMAL(5,2),  -- Calculado
  click_rate              DECIMAL(5,2),  -- Calculado
  
  -- PREFERENCIAS
  frecuencia_email        VARCHAR(50) DEFAULT 'semanal',
    -- Valores: 'semanal' | 'mensual' | 'nunca'
  
  -- DATES
  fecha_suscripcion       TIMESTAMP DEFAULT now(),
  fecha_unsuscripcion     TIMESTAMP,
  
  -- NOTAS
  razon_unsub             TEXT,
  
  -- TRACKING
  last_email_date         TIMESTAMP,
  last_click_date         TIMESTAMP
);

CREATE INDEX idx_newsletter_email ON newsletter_suscriptores(email);
CREATE INDEX idx_newsletter_lead ON newsletter_suscriptores(lead_id);
CREATE INDEX idx_newsletter_status ON newsletter_suscriptores(status);
```

---

## 📋 TABLA 5: referidos

**Descripción:** Programa de referidos - quién refirió a quién.

```sql
CREATE TABLE referidos (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fecha_creacion          TIMESTAMP DEFAULT now(),
  
  -- RELACIONES
  referrer_id             UUID NOT NULL REFERENCES leads_captacion(id),
    -- Cliente que hace la referencia
  referido_id             UUID NOT NULL REFERENCES leads_captacion(id),
    -- Cliente nuevo que fue referido
  
  -- IDENTIFICACIÓN
  referral_code           VARCHAR(50) UNIQUE,
    -- Auto-generated: REF-{{referrer_id}}-{{random}}
  
  -- ESTADO
  status                  VARCHAR(50) DEFAULT 'pendiente',
    -- Valores: 'pendiente' | 'contactado' | 'compra_realizada' | 'comision_pagada'
  
  -- FECHA DE COMPRA
  compra_fecha            TIMESTAMP,
  compra_monto            DECIMAL(10,2),
  
  -- COMISIÓN
  comision_rate           DECIMAL(5,2),  -- % que gana referrer
  comision_monto          DECIMAL(10,2),  -- Monto exacto ganado
  comision_pagada         BOOLEAN DEFAULT false,
  comision_pago_fecha     TIMESTAMP,
  comision_comprobante    VARCHAR(255),
  
  -- NOTAS
  notas                   TEXT
);

CREATE INDEX idx_referidos_referrer ON referidos(referrer_id);
CREATE INDEX idx_referidos_referido ON referidos(referido_id);
CREATE INDEX idx_referidos_code ON referidos(referral_code);
```

---

## 📋 TABLA 6: audit_log

**Descripción:** Log de TODOS los movimientos (para debugging + compliance).

```sql
CREATE TABLE audit_log (
  id                      UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  timestamp               TIMESTAMP DEFAULT now(),
  
  -- CONTEXTO
  tabla_afectada          VARCHAR(100),
  registro_id             UUID,
  
  -- CAMBIO
  accion                  VARCHAR(50),
    -- Valores: 'INSERT' | 'UPDATE' | 'DELETE' | 'EMAIL_ENVIADO' | 
    --          'DOCUMENTO_GENERADO' | 'BATCH_INICIADO' | 'COMISION_PAGADA'
  
  campos_antes            JSONB,
  campos_despues          JSONB,
  
  -- QUIÉN LO HIZO
  usuario                 VARCHAR(100),  -- 'n8n' | 'julio@...' | 'sistema'
  fuente                  VARCHAR(100),  -- 'n8n_webhook' | 'form' | 'cron_job'
  
  -- DETALLES
  descripcion             TEXT,
  error_message           TEXT,
  
  created_by              VARCHAR(100)
);

CREATE INDEX idx_audit_tabla ON audit_log(tabla_afectada);
CREATE INDEX idx_audit_registro ON audit_log(registro_id);
CREATE INDEX idx_audit_timestamp ON audit_log(timestamp);
```

---

## 🔗 RELACIONES Y CONSTRAINTS

```
leads_captacion ──┬─→ propuestas (1:N)
                  ├─→ batch_assets (1:N)
                  ├─→ referidos (referrer_id, 1:N)
                  ├─→ referidos (referido_id, 1:N)
                  └─→ newsletter_suscriptores (1:1 optional)

referidos ────────┬─→ leads_captacion (referrer_id)
                  └─→ leads_captacion (referido_id)
```

---

## 🔐 POLICIES (ROW-LEVEL SECURITY)

```sql
-- Solo Julio (seu admin user) puede ver/editar todos
CREATE POLICY leads_admin_policy ON leads_captacion
  USING (auth.email() = 'julio@aerovisuales.pe');

-- n8n service role (sin restricciones, solo para workflows)
CREATE POLICY leads_n8n_policy ON leads_captacion
  USING (auth.role() = 'service_role');

-- Clientes solo ven sus propios datos (future feature)
CREATE POLICY leads_client_policy ON leads_captacion
  USING (cliente_email = auth.email());
```

---

## 📊 VISTAS (DASHBOARDS)

```sql
-- Vista: Conversión por lead_source
CREATE VIEW conversion_by_source AS
SELECT 
  lead_source,
  COUNT(*) as total_leads,
  COUNT(CASE WHEN estado_cliente IN ('comprador', 'cliente_activo', 'vip_miembro') THEN 1 END) as compras,
  ROUND(100.0 * COUNT(CASE WHEN estado_cliente IN ('comprador', 'cliente_activo', 'vip_miembro') THEN 1 END) / COUNT(*), 2) as conversion_rate
FROM leads_captacion
GROUP BY lead_source;

-- Vista: Revenue por paquete
CREATE VIEW revenue_by_package AS
SELECT
  paquete_tipo,
  COUNT(*) as quantity,
  SUM(monto_total) as total_revenue,
  AVG(monto_total) as avg_order_value
FROM leads_captacion
WHERE estado_cliente IN ('comprador', 'cliente_activo', 'vip_miembro')
GROUP BY paquete_tipo;

-- Vista: Referidos performance
CREATE VIEW referidos_performance AS
SELECT
  r.referrer_id,
  l.cliente_nombre,
  COUNT(*) as referidos_totales,
  COUNT(CASE WHEN r.status = 'compra_realizada' THEN 1 END) as conversiones,
  SUM(r.comision_monto) as total_comision_ganada
FROM referidos r
LEFT JOIN leads_captacion l ON r.referrer_id = l.id
GROUP BY r.referrer_id, l.cliente_nombre;
```

---

## 🚀 CÓMO MIGRAR A SUPABASE

### Step 1: Crear tablas
```bash
# Copiar el SQL anterior y ejecutar en Supabase SQL editor
```

### Step 2: Habilitar RLS
```bash
# En Supabase Dashboard → Authentication → Policies
# Crear policies según POLICIES section anterior
```

### Step 3: Crear vistas
```bash
# Ejecutar SQL de VISTAS section
```

### Step 4: Habilitar webhooks
```bash
# Supabase Dashboard → Database → Webhooks
# Crear webhooks para tabla leads_captacion
# Evento: INSERT, UPDATE
# URL: n8n webhook URL
# Payload: JSON con changed_record
```

### Step 5: Crear funciones para auto-increment
```sql
-- Para recibo_numero
CREATE SEQUENCE recibo_seq START WITH 1;
ALTER TABLE leads_captacion 
ADD CONSTRAINT ensure_recibo_unique 
UNIQUE(recibo_numero);

-- Trigger que genera recibo_numero en INSERT
CREATE TRIGGER generate_recibo_numero
BEFORE INSERT ON leads_captacion
FOR EACH ROW
BEGIN
  IF NEW.recibo_numero IS NULL AND NEW.monto_total > 0 THEN
    NEW.recibo_numero := 'REC-AV4K-' || TO_CHAR(NOW(), 'YYYY') || '-' || LPAD(nextval('recibo_seq')::text, 4, '0');
  END IF;
END;
```

---

## 📌 SIGUIENTE PASO: n8n WORKFLOWS

El Schema está listo. Ahora necesitamos diseñar **3 workflows n8n** que implementen los flujos:

1. **Workflow 1: Web Cotizador → Documentos**
2. **Workflow 2: LinkedIn → Email Secuencia → Propuesta**
3. **Workflow 3: Batch Engine Automático**

¿Pasamos a n8n Workflows? 👇
