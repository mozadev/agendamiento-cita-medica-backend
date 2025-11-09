#!/bin/bash

# Script para eliminar instancias RDS y DB Subnet Groups
# Uso: ./cleanup-rds.sh [project-name] [environment]
# Ejemplo: ./cleanup-rds.sh agendamiento-v2 prod

PROJECT_NAME=${1:-"agendamiento-v2"}
ENVIRONMENT=${2:-"prod"}
REGION="us-east-1"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🗑️  Limpieza de RDS y DB Subnet Groups                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Proyecto: $PROJECT_NAME"
echo "Ambiente: $ENVIRONMENT"
echo "Región: $REGION"
echo ""
echo "⚠️  ADVERTENCIA: Este script eliminará instancias RDS"
echo "   Esto puede tardar 10-15 minutos y perderás los datos"
echo ""
echo "   Presiona Enter para continuar, Ctrl+C para cancelar"
read -r

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Verificando instancias RDS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

RDS_INSTANCES=$(aws rds describe-db-instances --region $REGION --query "DBInstances[?contains(DBInstanceIdentifier, '${PROJECT_NAME}-${ENVIRONMENT}')].DBInstanceIdentifier" --output text)

if [ -z "$RDS_INSTANCES" ]; then
  echo "✅ No hay instancias RDS para eliminar"
else
  echo "📊 Instancias RDS encontradas:"
  for INSTANCE in $RDS_INSTANCES; do
    STATUS=$(aws rds describe-db-instances --region $REGION --db-instance-identifier $INSTANCE --query 'DBInstances[0].DBInstanceStatus' --output text)
    echo "  - $INSTANCE (Estado: $STATUS)"
  done
  
  echo ""
  echo "🗑️  Eliminando instancias RDS..."
  for INSTANCE in $RDS_INSTANCES; do
    echo ""
    echo "Eliminando: $INSTANCE"
    aws rds delete-db-instance \
      --db-instance-identifier $INSTANCE \
      --skip-final-snapshot \
      --delete-automated-backups \
      --region $REGION 2>&1 && \
      echo "  ✅ $INSTANCE eliminándose (tardará ~10-15 min)..." || \
      echo "  ⚠️  Error al eliminar $INSTANCE"
  done
  
  echo ""
  echo "⏳ Esperando 2 minutos para que las instancias inicien eliminación..."
  sleep 120
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Eliminando DB Subnet Groups"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

SUBNET_GROUP_NAME="${PROJECT_NAME}-${ENVIRONMENT}-db-subnet-group"

if aws rds describe-db-subnet-groups --region $REGION --db-subnet-group-name $SUBNET_GROUP_NAME >/dev/null 2>&1; then
  echo "🗑️  Eliminando DB Subnet Group: $SUBNET_GROUP_NAME"
  
  # Verificar si aún está en uso
  IN_USE=$(aws rds describe-db-instances --region $REGION --query "DBInstances[?DBSubnetGroup.DBSubnetGroupName=='${SUBNET_GROUP_NAME}'].DBInstanceIdentifier" --output text)
  
  if [ ! -z "$IN_USE" ]; then
    echo "  ⚠️  Aún está en uso por: $IN_USE"
    echo "  ⏳ Esperando a que las instancias se eliminen completamente..."
    echo "  (Esto puede tardar 10-15 minutos más)"
    echo ""
    echo "  Puedes verificar el estado con:"
    echo "    aws rds describe-db-instances --region $REGION --query \"DBInstances[?contains(DBInstanceIdentifier, '${PROJECT_NAME}')].[DBInstanceIdentifier,DBInstanceStatus]\" --output table"
    echo ""
    echo "  Cuando las instancias estén eliminadas, ejecuta:"
    echo "    aws rds delete-db-subnet-group --db-subnet-group-name $SUBNET_GROUP_NAME --region $REGION"
  else
    aws rds delete-db-subnet-group --db-subnet-group-name $SUBNET_GROUP_NAME --region $REGION 2>&1 && \
      echo "  ✅ DB Subnet Group eliminado" || \
      echo "  ⚠️  Error"
  fi
else
  echo "✅ DB Subnet Group $SUBNET_GROUP_NAME no existe"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Verificación Final"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📊 Instancias RDS restantes (${PROJECT_NAME}):"
aws rds describe-db-instances --region $REGION --query "DBInstances[?contains(DBInstanceIdentifier, '${PROJECT_NAME}')].[DBInstanceIdentifier,DBInstanceStatus]" --output table 2>/dev/null || echo "  Ninguna"

echo ""
echo "📊 DB Subnet Groups restantes (${PROJECT_NAME}):"
aws rds describe-db-subnet-groups --region $REGION --query "DBSubnetGroups[?contains(DBSubnetGroupName, '${PROJECT_NAME}')].DBSubnetGroupName" --output table 2>/dev/null || echo "  Ninguno"

echo ""
echo "✅ Proceso completado!"
echo ""
echo "💡 Si las instancias RDS aún se están eliminando, espera 10-15 minutos"
echo "   antes de triggear el redeploy"

