#!/bin/bash

# ===============================================
# Script para inicializar schemas en RDS
# ===============================================
# Uso: ./scripts/init-database.sh

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Inicializando Schemas MySQL${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Verificar mysql client
if ! command -v mysql &> /dev/null; then
    echo -e "${RED}❌ MySQL client no está instalado${NC}"
    echo "Instala con: brew install mysql-client (macOS)"
    exit 1
fi

# Cargar variables desde .env
if [ ! -f .env ]; then
    echo -e "${RED}❌ Archivo .env no encontrado${NC}"
    echo "Ejecuta primero: ./scripts/create-rds.sh"
    exit 1
fi

source .env

# Verificar schema SQL
if [ ! -f docs/database-schema.sql ]; then
    echo -e "${RED}❌ Archivo docs/database-schema.sql no encontrado${NC}"
    exit 1
fi

# Función para inicializar base de datos
init_database() {
    local host=$1
    local database=$2
    local user=$3
    local password=$4
    local country=$5
    
    echo -e "${YELLOW}🔧 Inicializando base de datos de ${country}...${NC}"
    echo -e "   Host: ${host}"
    echo -e "   Database: ${database}\n"
    
    # Verificar conexión
    if ! mysql -h "$host" -u "$user" -p"$password" -e "SELECT 1;" &> /dev/null; then
        echo -e "${RED}❌ No se pudo conectar a ${country}${NC}"
        echo -e "${YELLOW}⚠️  Verifica:"
        echo -e "   1. Security Group permite conexión desde tu IP"
        echo -e "   2. Credenciales son correctas"
        echo -e "   3. RDS está en estado 'available'${NC}\n"
        return 1
    fi
    
    echo -e "${GREEN}✅ Conexión exitosa${NC}"
    
    # Ejecutar schema
    echo -e "${YELLOW}📝 Ejecutando schema SQL...${NC}"
    mysql -h "$host" -u "$user" -p"$password" "$database" < docs/database-schema.sql
    
    echo -e "${GREEN}✅ Schema ejecutado correctamente${NC}"
    
    # Verificar tablas creadas
    echo -e "${YELLOW}🔍 Verificando tablas...${NC}"
    TABLES=$(mysql -h "$host" -u "$user" -p"$password" "$database" -e "SHOW TABLES;" -s)
    
    if [ -z "$TABLES" ]; then
        echo -e "${RED}❌ No se crearon tablas${NC}\n"
        return 1
    fi
    
    echo -e "${GREEN}✅ Tablas creadas:${NC}"
    echo "$TABLES" | while read -r table; do
        echo -e "   - $table"
    done
    echo ""
}

# Inicializar Perú
if [ -n "$RDS_PE_HOST" ] && [ "$RDS_PE_HOST" != "localhost" ]; then
    init_database \
        "$RDS_PE_HOST" \
        "$RDS_PE_DATABASE" \
        "$RDS_PE_USER" \
        "$RDS_PE_PASSWORD" \
        "Perú"
else
    echo -e "${YELLOW}⚠️  RDS de Perú no configurado en .env${NC}\n"
fi

# Inicializar Chile
if [ -n "$RDS_CL_HOST" ] && [ "$RDS_CL_HOST" != "localhost" ]; then
    init_database \
        "$RDS_CL_HOST" \
        "$RDS_CL_DATABASE" \
        "$RDS_CL_USER" \
        "$RDS_CL_PASSWORD" \
        "Chile"
else
    echo -e "${YELLOW}⚠️  RDS de Chile no configurado en .env${NC}\n"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ¡Bases de datos inicializadas!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "Siguiente paso:"
echo -e "${YELLOW}npm run deploy:dev${NC}\n"

