#!/bin/bash

# Script para eliminar VPCs viejas después de que NAT Gateways se hayan eliminado
# Ejecutar: ./delete-old-vpcs.sh

REGION="us-east-1"

# VPCs a eliminar
OLD_VPCS=(
  "vpc-0ca8b85338cfe7066"
  "vpc-0a1af845caf8374ec"
  "vpc-06c4605cf7bbc27e2"
)

echo "🕐 Esperando a que NAT Gateways se eliminen completamente..."
echo "   (esto puede tardar 3-5 minutos)"
echo ""

# Esperar 3 minutos
for i in {1..3}; do
  echo "⏳ Esperando... $i/3 minutos"
  sleep 60
done

echo ""
echo "🗑️  Intentando eliminar VPCs..."
echo ""

for VPC_ID in "${OLD_VPCS[@]}"; do
  echo "Eliminando VPC: $VPC_ID"
  
  if aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>&1; then
    echo "✅ VPC $VPC_ID eliminada"
  else
    echo "⚠️  VPC $VPC_ID aún tiene recursos. Esperando más..."
    sleep 60
    # Reintentar
    if aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>&1; then
      echo "✅ VPC $VPC_ID eliminada"
    else
      echo "❌ No se pudo eliminar VPC $VPC_ID"
      echo "   Elimínala manualmente desde la consola de AWS"
    fi
  fi
  echo ""
done

echo "📊 VPCs restantes:"
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[].[VpcId,Tags[?Key==`Name`].Value|[0],IsDefault]' --output table

echo ""
echo "✅ Proceso completado"

