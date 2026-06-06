# Cajita Data Distribution — Llenar múltiples templates HTML automáticamente

**Estado:** planning
**Iniciada:** 2026-06-10
**Última actualización:** 2026-06-10 21:50

---

## Contexto inicial

Julio tiene **5+ archivos HTML que funcionan como templates/formularios** que se usan en diferentes momentos del flujo comercial:

1. **AV4K_Recibo_Anticipo.html** (generador interactivo)
2. **Contrato_de_Servicios.html** (documento)
3. **AV4K_Certificado_Vuelo.html** (generador interactivo)
4. **AV4K_Formulario_Aprobacion.html** (formulario pre-vuelo)
5. **AV4K_Instrucciones_Dia_Vuelo.html** (instrucciones operativas)

**PROBLEMA ACTUAL:**
Cuando un cliente confirma un paquete, Julio **llena cada documento manualmente, repitiendo los mismos datos** (nombre, email, fecha vuelo, etc.) en cada uno. Toma **30+ minutos** y hay riesgo de inconsistencia (el nombre en uno, otra cosa en otro).

**SOLUCIÓN PROPUESTA:**
1. Cliente confirma paquete (vía Telegram/WhatsApp)
2. n8n extrae datos del cliente **UNA SOLA VEZ**
3. Distribuye a TODOS los templates automáticamente
4. Llena cada uno en <2 minutos
5. Algunos se envían inmediatamente (recibo, instrucciones)
6. Otros se envían condicionalmente (contrato ahora, certificado post-vuelo, etc.)

**CRITERIO DE ÉXITO:**
✅ Datos extraídos UNA VEZ en n8n
✅ Distribuidos a 5 templates simultáneamente
✅ 100% consistency (mismo "nombre" en todos)
✅ Enviados según condicionales (fecha vuelo, tipo paquete)
✅ Tiempo total: <2 min desde captura hasta documentos listos

---

## Mapeo de datos que se REPITEN en todos los templates

### DATOS CLIENTE (siempre iguales)

| Campo | Dónde aparece | Tipo |
|---|---|---|
| `cliente_nombre` | Recibo, Contrato, Certificado, Aprobación, Instrucciones | String |
| `cliente_email` | Recibo, Contrato, Certificado, Aprobación | Email |
| `cliente_telefono` | Recibo, Contrato, Certificado, Aprobación | String |
| `cliente_ruc_dni` | Recibo, Contrato, Certificado | String |
| `cliente_domicilio` | Recibo, Contrato, Certificado, Aprobación | String |
| `cliente_representante` | Contrato, Aprobación (si aplica) | String |
| `cliente_cargo` | Contrato, Aprobación (si aplica) | String |

### DATOS PROYECTO (siempre iguales)

| Campo | Dónde aparece | Tipo |
|---|---|---|
| `proyecto_nombre` | Recibo, Contrato, Certificado, Instrucciones | String |
| `proyecto_tipo` | Contrato, Certificado, Aprobación | String |
| `proyecto_locacion` | Recibo, Contrato, Certificado, Instrucciones | String |
| `proyecto_distrito` | Recibo, Contrato, Certificado, Aprobación | String |
| `fecha_vuelo` | **TODOS** | Date |
| `horario_estimado` | Contrato, Certificado, Instrucciones | Time |
| `direccion_exacta_despegue` | Contrato, Certificado, Instrucciones | String |

### DATOS ECONÓMICOS (siempre iguales)

| Campo | Dónde aparece | Tipo |
|---|---|---|
| `paquete` | Recibo, Contrato, Certificado | Enum: "Raw Air" / "Aerial Ready" / "Signature Aerial" |
| `precio_paquete` | Recibo, Contrato | Number |
| `servicios_adicionales` | Recibo, Contrato | String |
| `total` | Recibo, Contrato, Certificado | Number |
| `anticipo_50` | Recibo | Number (= total * 0.5) |
| `saldo` | Recibo | Number (= total * 0.5) |
| `metodo_pago` | Recibo | Enum: "Transferencia" / "Yape" / "Plin" / "Efectivo" |

---

## Flujo según tipo de PAQUETE

### PAQUETE 1: Raw Air (S/ 450)
**Características:** Solo tomas crudas, entrega 24h, SIN material editado

```
Cliente confirma → Datos extraídos:
  ├── recibo_anticipo.html      → Genera recibo, envía correo
  ├── contrato.html             → Genera contrato, envía correo
  ├── certificado_vuelo.html    → Genera certificado (pre-llenado)
  ├── instrucciones_vuelo.html  → Genera instrucciones, envía correo
  └── formulario_aprobacion.html → Genera formulario pre-vuelo
       ↓
  Condicionales:
  - Enviar recibo: INMEDIATAMENTE
  - Enviar contrato: INMEDIATAMENTE
  - Enviar instrucciones: 3 DÍAS ANTES del vuelo
  - Recordatorio vuelo: 1 DÍA ANTES
  - Entrega material: 24h DESPUÉS del vuelo (link WeTransfer)
```

### PAQUETE 2: Aerial Ready (S/ 1,050)
**Características:** Tomas + edición, entrega 24-48h, SIN múltiples formatos

```
Mismo flujo que Raw Air, PERO:
  - Instrucciones pre-vuelo igual
  - Email post-vuelo diferente: "Tu video estará listo en 48h"
  - Email entrega: Incluye link descarga del video editado + versión RAW
```

### PAQUETE 3: Signature Aerial (S/ 1,875)
**Características:** Todo + 3 formatos + música + 2 revisiones, entrega 5 días

```
Mismo flujo que Aerial Ready, PERO:
  - Email post-vuelo: "Tu video estará listo en 5 días hábiles"
  - Email entrega: Incluye 3 archivos (16:9, 1:1, 9:16) + RAW + música separada
  - Incluir notas de "2 revisiones incluidas, revision adicional S/ 80"
```

---

## Detalles técnicos (para Investigator)

### Estructura de datos en n8n

```javascript
{
  cliente: {
    nombre: "Teks S.A.C.",
    email: "eventos@teks.com.pe",
    telefono: "+51 987654321",
    ruc_dni: "20123456789",
    domicilio: "Av. Principal 123, Miraflores",
    representante: "María García",
    cargo: "Gerente Comercial"
  },
  proyecto: {
    nombre: "Verano 2027 - Showroom Tendencias",
    tipo: "Evento corporativo",
    locacion: "Miraflores",
    distrito: "Miraflores",
    fecha_vuelo: "2026-06-16",
    horario_estimado: "14:00",
    direccion_exacta: "Jr. Libertadores 456, Miraflores"
  },
  paquete: {
    tipo: "Signature Aerial",
    precio: 1875,
    servicios_adicionales: "Urgencia +150",
    total: 2025,
    anticipo_50: 1012.50,
    saldo: 1012.50,
    metodo_pago: "Transferencia"
  },
  fechas_envio: {
    recibo: "2026-06-10 16:00",
    contrato: "2026-06-10 16:05",
    instrucciones: "2026-06-13",       // 3 días antes
    recordatorio: "2026-06-15",        // 1 día antes
    entrega: "2026-06-22",             // 5 días después (Signature)
    certificado: "2026-06-16 19:00"    // post-vuelo
  }
}
```

### Placeholders en HTML

Cada template usa placeholders tipo `{{nombre}}` o `[NOMBRE]` que n8n reemplaza:

```
[CLIENTE_NOMBRE]
[CLIENTE_EMAIL]
[CLIENTE_TELEFONO]
[CLIENTE_RUC_DNI]
[CLIENTE_DOMICILIO]
[CLIENTE_REPRESENTANTE]
[CLIENTE_CARGO]

[PROYECTO_NOMBRE]
[PROYECTO_TIPO]
[PROYECTO_LOCACION]
[PROYECTO_DISTRITO]
[FECHA_VUELO]
[HORARIO_ESTIMADO]
[DIRECCION_DESPEGUE]

[PAQUETE_TIPO]
[PRECIO_PAQUETE]
[SERVICIOS_ADICIONALES]
[TOTAL]
[ANTICIPO_50]
[SALDO]
[METODO_PAGO]
```

---

## Restricciones según AGENTS.md

- **Regla #1:** Cero dependencias externas
  - Solución: n8n (ya está, es el workflow engine)
  - Templates son HTML vanilla (no agregar librerías)

- **Regla #3:** Sin backend propio
  - Solución: Todo corre en n8n (es el backend distribuido ya existente)
  - SendGrid envía emails (ya usado actualmente)

- **Regla #4:** Clave anon de Supabase expuesta OK
  - No relevante (estamos leyendo, no escribiendo a BD desde templates)

---

## Riesgos identificados

⚠️ **RIESGO 1: Inconsistencia de placeholders**
- Si templates usan `[CLIENTE_NOMBRE]` y uno usa `{{nombre}}`, habrá blancos
- Solución: Standarizar TODOS a `[PLACEHOLDER]` antes de empezar

⚠️ **RIESGO 2: Condicionales de tiempo complejos**
- n8n tiene límite: <1000 ejecuciones/mes en plan free
- Si distribuimos a 5 templates + múltiples condicionales, podemos saturar
- Solución: Usar nodo "Delay" de n8n (integrado, no consume ejecuciones)

⚠️ **RIESGO 3: Emails enviados múltiples veces**
- Si re-ejecutamos workflow, podrían enviarse duplicados
- Solución: Marcar en Supabase tabla `leads_captacion` con flag `emails_distribuidos: true`

⚠️ **RIESGO 4: Paquete Raw Air no tiene video editado**
- Template para "entrega post-vuelo" necesita mensaje diferente según paquete
- Solución: Condicionales simples en n8n (if paquete === "Raw Air" then enviar texto X else Y)

---

## Siguientes pasos (para Investigator)

Cuando Investigator trabaje:

1. **Verificar placeholders:** Abrir los 5 HTML y confirmar que TODOS usan el mismo formato de placeholder
2. **Mapear condiciones de tiempo:** ¿Hay campos en Supabase para guardar "fecha envío instrucciones"?
3. **Confirmar capacidad n8n:** ¿El plan actual soporta 5 nodos "SendGrid" en paralelo sin problemas?
4. **Probar con un cliente real:** Antes de automatizar, hacerlo manual una vez para validar flujo

---

## Cronología estimada

- **Investigator:** 2h (mapeo detallado + validación placeholders)
- **Implementer:** 3h (diseñar workflow n8n + testing)
- **Reviewer:** 1h (auditar condicionales + validar consistency)
- **Total:** ~6h hasta production-ready
