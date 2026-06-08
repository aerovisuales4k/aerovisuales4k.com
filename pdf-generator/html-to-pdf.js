#!/usr/bin/env node
/**
 * html-to-pdf.js — HTTP server · Convierte HTML a PDF · Aerovisuales 4K
 *
 * Arquitectura: servicio Railway independiente del proceso n8n.
 * n8n no puede ejecutar child_process ni importar puppeteer directamente
 * (sandbox VM2), por eso este script corre como microservicio HTTP aparte.
 *
 * ── ENDPOINT ───────────────────────────────────────────────────────────
 *
 *   POST /convert
 *   Content-Type: application/json
 *   Body: { "html": "<html>...</html>", "filename": "recibo_001.pdf" }
 *
 *   → 200 { "success": true, "pdf_base64": "JVBERi0x...", "filename": "recibo_001.pdf" }
 *   → 400 { "success": false, "error": "html field is required" }
 *   → 500 { "success": false, "error": "Puppeteer: ..." }
 *
 *   GET /health
 *   → 200 { "status": "ok" }
 *
 * ── CONFIGURACIÓN EN n8n (HTTP Request node) ───────────────────────────
 *
 *   Method : POST
 *   URL    : https://<tu-servicio>.railway.app/convert
 *   Body   : JSON → { "html": "{{ $json.html }}", "filename": "recibo_{{ $json.id }}.pdf" }
 *   Output : $json.pdf_base64  ← úsalo en Send Email como adjunto base64
 *
 * ── VARIABLES DE ENTORNO ───────────────────────────────────────────────
 *
 *   PORT                      : Railway lo inyecta automáticamente (requerido)
 *   PUPPETEER_EXECUTABLE_PATH : ruta a Chromium externo si el bundleado no arranca
 */

'use strict';

const http      = require('http');
const puppeteer = require('puppeteer');

const PORT = process.env.PORT || 3000;

// Flags requeridos para Chromium en Railway/Docker:
const BROWSER_ARGS = [
  '--no-sandbox',
  '--disable-setuid-sandbox',
  '--disable-dev-shm-usage',
  '--disable-gpu',
  '--disable-extensions',
];

// ── LÓGICA PUPPETEER ─────────────────────────────────────────────────────────

function buildFilename(raw) {
  if (!raw) return `doc_${Date.now()}.pdf`;
  const safe = raw.replace(/[^a-zA-Z0-9_\-\.]/g, '_');
  return safe.endsWith('.pdf') ? safe : `${safe}.pdf`;
}

async function convertHtmlToPdfBase64(html, filenameRaw) {
  const filename = buildFilename(filenameRaw);

  const launchOptions = {
    headless: true,
    args: BROWSER_ARGS,
  };

  if (process.env.PUPPETEER_EXECUTABLE_PATH) {
    launchOptions.executablePath = process.env.PUPPETEER_EXECUTABLE_PATH;
  }

  const browser = await puppeteer.launch(launchOptions);

  let pdfBuffer;
  try {
    const page = await browser.newPage();
    await page.setContent(html, { waitUntil: 'load', timeout: 30_000 });

    // Sin 'path' → Puppeteer devuelve el PDF como Buffer en memoria
    pdfBuffer = await page.pdf({
      format:          'A4',
      printBackground: true,
      margin: { top: '12mm', right: '12mm', bottom: '12mm', left: '12mm' },
    });
  } finally {
    await browser.close();
  }

  // Convertir Buffer a base64 string para enviarlo en JSON
  return {
    pdf_base64: pdfBuffer.toString('base64'),
    filename,
  };
}

// ── HELPERS HTTP ─────────────────────────────────────────────────────────────

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    let size = 0;
    const LIMIT = 5 * 1024 * 1024;

    req.on('data', chunk => {
      size += chunk.length;
      if (size > LIMIT) {
        reject(new Error('Payload demasiado grande (máx 5 MB)'));
        req.destroy();
        return;
      }
      raw += chunk;
    });

    req.on('end', () => resolve(raw));
    req.on('error', reject);
  });
}

function sendJSON(res, statusCode, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(statusCode, {
    'Content-Type':   'application/json',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

// ── REQUEST HANDLER ──────────────────────────────────────────────────────────

async function handleRequest(req, res) {
  if (req.method === 'GET' && req.url === '/health') {
    sendJSON(res, 200, { status: 'ok' });
    return;
  }

  if (req.method !== 'POST' || req.url !== '/convert') {
    sendJSON(res, 404, { success: false, error: 'Usa POST /convert' });
    return;
  }

  let body;
  try {
    const raw = await readBody(req);
    body = JSON.parse(raw);
  } catch (err) {
    sendJSON(res, 400, { success: false, error: `JSON inválido: ${err.message}` });
    return;
  }

  const html = (body.html || '').trim();
  if (!html) {
    sendJSON(res, 400, { success: false, error: 'El campo "html" es requerido y no puede estar vacío' });
    return;
  }

  try {
    const result = await convertHtmlToPdfBase64(html, body.filename);
    sendJSON(res, 200, { success: true, ...result });
  } catch (err) {
    sendJSON(res, 500, { success: false, error: err.message });
  }
}

// ── SERVER ────────────────────────────────────────────────────────────────────

const server = http.createServer((req, res) => {
  handleRequest(req, res).catch(err => {
    sendJSON(res, 500, { success: false, error: `Error interno: ${err.message}` });
  });
});

server.listen(PORT, () => {
  process.stdout.write(`[av4k-pdf] Servidor corriendo en puerto ${PORT}\n`);
  process.stdout.write(`[av4k-pdf] Modo: base64 en memoria (sin disco)\n`);
});

process.on('SIGTERM', () => {
  process.stdout.write('[av4k-pdf] SIGTERM recibido — cerrando servidor\n');
  server.close(() => process.exit(0));
});
