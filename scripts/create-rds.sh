#!/bin/bash

# ===============================================
# Script para crear instancias RDS MySQL
# ===============================================
# Uso: ./scripts/create-rds.sh

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Creando Instancias RDS MySQL${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI no está instalado${NC}"
    echo "Instala desde: https://aws.amazon.com/cli/"
    exit 1
fi

# Verificar credenciales
echo -e "${YELLOW}🔍 Verificando credenciales AWS...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ No se encontraron credenciales AWS válidas${NC}"
    echo "Ejecuta: aws configure"
    exit 1
fi
echo -e "${GREEN}✅ Credenciales verificadas${NC}\n"

# Variables (puedes modificar según necesites)
REGION="us-east-1"
DB_INSTANCE_CLASS="db.t3.micro"  # Free tier eligible
ENGINE="mysql"
ENGINE_VERSION="8.0"
ALLOCATED_STORAGE=20
MASTER_USERNAME="admin"

# Pedir contraseña
echo -e "${YELLOW}🔐 Ingresa una contraseña para el RDS (mínimo 8 caracteres):${NC}"
read -s DB_PASSWORD
echo ""

if [ ${#DB_PASSWORD} -lt 8 ]; then
    echo -e "${RED}❌ La contraseña debe tener al menos 8 caracteres${NC}"
    exit 1
fi

# Función para crear RDS
create_rds() {
    local db_identifier=$1
    local db_name=$2
    local country=$3

    echo -e "${YELLOW}📦 Creando RDS para ${country}...${NC}"
    
    # Verificar si ya existe
    if aws rds describe-db-instances \
        --db-instance-identifier "$db_identifier" \
        --region "$REGION" &> /dev/null; then
        echo -e "${YELLOW}⚠️  RDS '$db_identifier' ya existe, saltando...${NC}\n"
        return
    fi

    # Crear instancia
    aws rds create-db-instance \
        --db-instance-identifier "$db_identifier" \
        --db-instance-class "$DB_INSTANCE_CLASS" \
        --engine "$ENGINE" \
        --engine-version "$ENGINE_VERSION" \
        --master-username "$MASTER_USERNAME" \
        --master-user-password "$DB_PASSWORD" \
        --allocated-storage "$ALLOCATED_STORAGE" \
        --db-name "$db_name" \
        --backup-retention-period 7 \
        --publicly-accessible \
        --storage-type gp2 \
        --region "$REGION" \
        --tags Key=Project,Value=AgendamientoCitas Key=Country,Value="$country" \
        > /dev/null

    echo -e "${GREEN}✅ RDS '$db_identifier' creado exitosamente${NC}\n"
}

# Crear RDS para Perú
create_rds "appointments-pe-db" "appointments_pe" "Peru"

# Crear RDS para Chile
create_rds "appointments-cl-db" "appointments_cl" "Chile"

# Esperar a que estén disponibles
echo -e "${YELLOW}⏳ Esperando a que las instancias estén disponibles...${NC}"
echo -e "${YELLOW}   (Esto puede tomar 5-10 minutos)${NC}\n"

wait_for_rds() {
    local db_identifier=$1
    local country=$2
    
    echo -e "${YELLOW}Esperando RDS de ${country}...${NC}"
    
    while true; do
        STATUS=$(aws rds describe-db-instances \
            --db-instance-identifier "$db_identifier" \
            --region "$REGION" \
            --query 'DBInstances[0].DBInstanceStatus' \
            --output text 2>/dev/null || echo "not-found")
        
        if [ "$STATUS" = "available" ]; then
            echo -e "${GREEN}✅ RDS de ${country} está disponible${NC}\n"
            break
        elif [ "$STATUS" = "not-found" ]; then
            echo -e "${RED}❌ RDS no encontrado${NC}"
            exit 1
        else
            echo -e "   Estado: $STATUS - esperando..."
            sleep 30
        fi
    done
}

wait_for_rds "appointments-pe-db" "Perú"
wait_for_rds "appointments-cl-db" "Chile"

# Obtener endpoints
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Instancias RDS Creadas${NC}"
echo -e "${GREEN}========================================${NC}\n"

get_endpoint() {
    local db_identifier=$1
    local country=$2
    
    ENDPOINT=$(aws rds describe-db-instances \
        --db-instance-identifier "$db_identifier" \
        --region "$REGION" \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text)
    
    echo -e "${GREEN}🇵🇪 RDS ${country}:${NC}"
    echo -e "   Endpoint: ${ENDPOINT}"
    echo -e "   Database: $(echo $db_identifier | sed 's/-db//')"
    echo -e "   Username: ${MASTER_USERNAME}"
    echo -e "   Port: 3306\n"
    
    # Guardar en archivo temporal
    echo "RDS_${country}_HOST=${ENDPOINT}" >> .env.rds.tmp
}

# Limpiar archivo temporal
rm -f .env.rds.tmp

get_endpoint "appointments-pe-db" "PE"
get_endpoint "appointments-cl-db" "CL"

# Crear/actualizar .env
echo -e "${YELLOW}📝 Actualizando archivo .env...${NC}"

if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}✅ Archivo .env creado desde .env.example${NC}"
fi

# Agregar endpoints al .env
if [ -f .env.rds.tmp ]; then
    while IFS= read -r line; do
        KEY=$(echo "$line" | cut -d= -f1)
        VALUE=$(echo "$line" | cut -d= -f2)
        
        # Reemplazar si existe, agregar si no
        if grep -q "^${KEY}=" .env; then
            sed -i.bak "s|^${KEY}=.*|${line}|" .env
        else
            echo "$line" >> .env
        fi
    done < .env.rds.tmp
    
    rm -f .env.rds.tmp .env.bak
    echo -e "${GREEN}✅ Variables de entorno actualizadas en .env${NC}\n"
fi

# Información de Security Group
echo -e "${YELLOW}⚠️  IMPORTANTE: Configurar Security Group${NC}"
echo -e "1. Ve a AWS Console → RDS → appointments-pe-db"
echo -e "2. Click en el Security Group"
echo -e "3. Agregar Inbound Rule:"
echo -e "   - Type: MySQL/Aurora (3306)"
echo -e "   - Source: 0.0.0.0/0 (para dev) o tu IP"
echo -e "4. Repetir para appointments-cl-db\n"

# Siguiente paso
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Siguientes Pasos${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo -e "1. Configurar Security Groups (ver arriba)"
echo -e "2. Inicializar schemas:"
echo -e "   ${YELLOW}./scripts/init-database.sh${NC}"
echo -e "3. Desplegar aplicación:"
echo -e "   ${YELLOW}npm run deploy:dev${NC}\n"

echo -e "${GREEN}✅ ¡Instancias RDS creadas exitosamente!${NC}"

