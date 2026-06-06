#!/usr/bin/env bash
# ============================================================
# init.sh — Aerovisuales 4K Health Check
# ============================================================
# Verifica que todo el sistema esté operativo antes de empezar
# a trabajar. Detecta problemas externos (Supabase, Railway,
# GitHub Pages) y locales (herramientas, repo limpio).
#
# Uso:   bash init.sh
# o:     ./init.sh  (después de chmod +x init.sh)
# ============================================================

set -u  # error en variables no definidas, pero NO 'set -e':
        # queremos continuar verificando aunque algo falle

# ============================================================
# CONFIGURACIÓN
# ============================================================
SITE_URL="https://www.aerovisuales4k.com"
SUPABASE_URL="https://zfekvffhpqsduwemqdxj.supabase.co"
N8N_URL="https://main-production-51c0.up.railway.app"

# Colores (si la terminal los soporta)
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'
  GRAY=$'\033[0;90m'
  BOLD=$'\033[1m'
  NC=$'\033[0m'  # No Color
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; GRAY=""; BOLD=""; NC=""
fi

# Contadores
CHECKS_OK=0
CHECKS_WARN=0
CHECKS_FAIL=0

# ============================================================
# HELPERS DE OUTPUT
# ============================================================

ok()   { echo "  ${GREEN}✓${NC} $1"; CHECKS_OK=$((CHECKS_OK+1)); }
warn() { echo "  ${YELLOW}⚠${NC} $1"; CHECKS_WARN=$((CHECKS_WARN+1)); }
fail() { echo "  ${RED}✗${NC} $1"; CHECKS_FAIL=$((CHECKS_FAIL+1)); }
info() { echo "  ${GRAY}·${NC} $1"; }

section() {
  echo ""
  echo "${BOLD}${BLUE}▸ $1${NC}"
}

# ============================================================
# HEADER
# ============================================================

clear 2>/dev/null || true
echo ""
echo "${BOLD}AEROVISUALES 4K · HEALTH CHECK${NC}"
echo "${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo "${GRAY}─────────────────────────────────────────────${NC}"

# ============================================================
# 1. HERRAMIENTAS LOCALES
# ============================================================
section "Herramientas locales"

check_tool() {
  local cmd="$1"
  local required="${2:-required}"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version=$("$cmd" --version 2>&1 | head -1 || echo "version desconocida")
    ok "$cmd disponible ${GRAY}($version)${NC}"
  else
    if [[ "$required" == "required" ]]; then
      fail "$cmd NO instalado (requerido)"
    else
      warn "$cmd NO instalado (opcional)"
    fi
  fi
}

check_tool "git"      "required"
check_tool "curl"     "required"
check_tool "python3"  "required"
check_tool "node"     "optional"

# ============================================================
# 2. ESTADO DEL REPOSITORIO
# ============================================================
section "Estado del repositorio"

if [[ -d ".git" ]]; then
  ok "Estás dentro del repo git"

  # Rama actual
  current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ "$current_branch" == "main" ]] || [[ "$current_branch" == "master" ]]; then
    ok "Rama: ${BOLD}$current_branch${NC}"
  else
    warn "Estás en rama '$current_branch' (no main/master)"
  fi

  # Cambios sin commit
  if [[ -z "$(git status --porcelain 2>/dev/null)" ]]; then
    ok "Working tree limpio (sin cambios pendientes)"
  else
    local pending
    pending=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    warn "$pending archivo(s) con cambios sin commit"
  fi

  # Sincronización con remote
  git fetch --quiet origin 2>/dev/null || true
  local ahead behind
  ahead=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo "0")
  behind=$(git rev-list --count "HEAD..@{u}" 2>/dev/null || echo "0")
  if [[ "$ahead" == "0" ]] && [[ "$behind" == "0" ]]; then
    ok "Sincronizado con origin"
  elif [[ "$ahead" != "0" ]]; then
    warn "$ahead commit(s) por hacer push"
  elif [[ "$behind" != "0" ]]; then
    warn "$behind commit(s) por hacer pull"
  fi

  # Último commit
  last_commit=$(git log -1 --format="%h · %s · %cr" 2>/dev/null || echo "?")
  info "Último commit: ${GRAY}$last_commit${NC}"
else
  fail "NO estás dentro de un repo git (¿estás en la carpeta correcta?)"
fi

# ============================================================
# 3. ARCHIVOS CRÍTICOS DEL PROYECTO
# ============================================================
section "Archivos críticos"

check_file() {
  if [[ -f "$1" ]]; then
    ok "$1"
  else
    fail "$1 NO encontrado"
  fi
}

check_file "index.html"
check_file "dashboard.html"
check_file "robots.txt"
check_file "sitemap.xml"
check_file "AGENTS.md"

# Verificar que fonts existen
if [[ -d "fonts" ]] && [[ -n "$(ls -A fonts/*.woff2 2>/dev/null)" ]]; then
  count=$(ls fonts/*.woff2 2>/dev/null | wc -l | tr -d ' ')
  ok "fonts/ existe ($count archivos .woff2)"
else
  warn "fonts/ vacía o no existe (revisar self-hosted fonts)"
fi

# ============================================================
# 4. CONECTIVIDAD A SERVICIOS EXTERNOS
# ============================================================
section "Servicios externos"

# Helper para chequear HTTP con timeout
check_http() {
  local name="$1"
  local url="$2"
  local expected="${3:-200}"
  local timeout="${4:-10}"

  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null || echo "000")

  case "$code" in
    "$expected"|"200"|"401"|"404")
      # 200=ok, 401=auth requerida (servicio vivo), 404=path no existe pero servidor responde
      if [[ "$code" == "$expected" ]] || [[ "$code" == "200" ]]; then
        ok "$name responde ${GRAY}(HTTP $code)${NC}"
      else
        ok "$name responde ${GRAY}(HTTP $code, esperado)${NC}"
      fi
      ;;
    "000")
      fail "$name NO responde ${GRAY}(timeout o sin red)${NC}"
      ;;
    "5"*)
      fail "$name caído ${GRAY}(HTTP $code)${NC}"
      ;;
    *)
      warn "$name responde con HTTP $code ${GRAY}(verificar)${NC}"
      ;;
  esac
}

check_http "Sitio público" "$SITE_URL"
check_http "Supabase REST" "$SUPABASE_URL/rest/v1/" "401"
check_http "n8n (Railway)" "$N8N_URL"

# ============================================================
# 5. ESTADO DE SUPABASE (lectura sin auth)
# ============================================================
section "Supabase — diagnóstico rápido"

# Verifica que la API REST de Supabase está viva
# (no podemos leer leads sin service_role key, pero podemos
# verificar que el endpoint público responde)
api_health=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  "$SUPABASE_URL/rest/v1/" 2>/dev/null || echo "000")

if [[ "$api_health" == "401" ]] || [[ "$api_health" == "200" ]]; then
  ok "API REST de Supabase operativa"
  info "Para leer leads: ${GRAY}entrar a https://supabase.com/dashboard${NC}"
elif [[ "$api_health" == "000" ]]; then
  fail "Supabase no responde (CRÍTICO: cotizador no funciona)"
else
  warn "Supabase responde con código inesperado: $api_health"
fi

# ============================================================
# 6. ESTADO DE n8n / RAILWAY
# ============================================================
section "n8n / Railway — diagnóstico rápido"

n8n_health=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  "$N8N_URL/healthz" 2>/dev/null || echo "000")

if [[ "$n8n_health" == "200" ]]; then
  ok "n8n healthcheck OK"
elif [[ "$n8n_health" == "404" ]]; then
  # n8n responde pero /healthz no existe en esta versión
  # verificamos que el root responda
  root_check=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
    "$N8N_URL/" 2>/dev/null || echo "000")
  if [[ "$root_check" == "200" ]] || [[ "$root_check" == "401" ]] || [[ "$root_check" == "302" ]]; then
    ok "n8n operativo ${GRAY}(root HTTP $root_check)${NC}"
  else
    warn "n8n responde raro en root: $root_check"
  fi
elif [[ "$n8n_health" == "000" ]]; then
  fail "n8n NO responde (CRÍTICO: alertas de leads están caídas)"
  info "  ${YELLOW}→ Verifica Railway: https://railway.com/project/...${NC}"
else
  warn "n8n responde con código inesperado: $n8n_health"
fi

# ============================================================
# 7. ESTADO DEL SITIO PÚBLICO
# ============================================================
section "Sitio público — diagnóstico"

# Verifica que el cotizador esté accesible
site_check=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  "$SITE_URL" 2>/dev/null || echo "000")

if [[ "$site_check" == "200" ]]; then
  ok "Sitio público accesible"

  # Verifica tiempo de respuesta (debería ser <2s)
  response_time=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 \
    "$SITE_URL" 2>/dev/null || echo "?")
  if [[ "$response_time" != "?" ]]; then
    # Comparación con bc o awk (más portable)
    is_fast=$(awk -v t="$response_time" 'BEGIN { print (t < 2.0) ? "yes" : "no" }')
    if [[ "$is_fast" == "yes" ]]; then
      ok "Tiempo de respuesta: ${response_time}s ${GRAY}(<2s, bien)${NC}"
    else
      warn "Tiempo de respuesta: ${response_time}s ${GRAY}(>2s, revisar)${NC}"
    fi
  fi
else
  fail "Sitio NO accesible (HTTP $site_check)"
fi

# ============================================================
# 8. RECORDATORIOS CONTEXTUALES
# ============================================================
section "Recordatorios"

# ¿Estamos cerca de fin de mes? Recordar revisar Railway billing
day_of_month=$(date +%d)
if [[ "$day_of_month" -ge "25" ]]; then
  warn "Cerca de fin de mes: revisar billing de Railway (Hobby \$5/mes)"
fi

# ¿Es lunes? Recordar revisar dashboard de leads
day_of_week=$(date +%u)  # 1=lunes, 7=domingo
if [[ "$day_of_week" == "1" ]]; then
  info "Lunes: buen día para revisar el dashboard de leads de la semana"
fi

# ============================================================
# RESUMEN FINAL
# ============================================================
echo ""
echo "${GRAY}─────────────────────────────────────────────${NC}"
echo "${BOLD}RESUMEN${NC}"
echo ""
echo "  ${GREEN}✓ OK:       $CHECKS_OK${NC}"
echo "  ${YELLOW}⚠ Avisos:   $CHECKS_WARN${NC}"
echo "  ${RED}✗ Fallos:   $CHECKS_FAIL${NC}"
echo ""

if [[ "$CHECKS_FAIL" -gt "0" ]]; then
  echo "${RED}${BOLD}⚠ Hay $CHECKS_FAIL fallo(s) crítico(s). Resolver antes de trabajar.${NC}"
  echo ""
  exit 1
elif [[ "$CHECKS_WARN" -gt "0" ]]; then
  echo "${YELLOW}Sistema operativo con avisos. Puedes trabajar con precaución.${NC}"
  echo ""
  exit 0
else
  echo "${GREEN}${BOLD}Todo en orden. Listo para trabajar.${NC}"
  echo ""
  exit 0
fi
