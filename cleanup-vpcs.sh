#!/bin/bash

# Script para eliminar VPCs duplicadas
# Ejecutar: chmod +x cleanup-vpcs.sh && ./cleanup-vpcs.sh

REGION="us-east-1"

echo "🧹 Limpiando VPCs duplicadas..."
echo ""

# Lista de VPCs duplicadas a eliminar (las 3 más viejas)
OLD_VPCS=(
  "vpc-0ca8b85338cfe7066"
  "vpc-0a1af845caf8374ec"
  "vpc-06c4605cf7bbc27e2"
)

for VPC_ID in "${OLD_VPCS[@]}"; do
  echo "🗑️  Intentando eliminar VPC: $VPC_ID"
  
  if aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null; then
    echo "✅ VPC $VPC_ID eliminada exitosamente"
  else
    echo "⚠️  No se pudo eliminar $VPC_ID directamente (tiene recursos asociados)"
    echo "   Intentando eliminar recursos asociados..."
    
    # Intentar eliminar Internet Gateways
    IGW=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --region $REGION --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
    if [ "$IGW" != "None" ] && [ ! -z "$IGW" ]; then
      echo "   Desconectando Internet Gateway: $IGW"
      aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID --region $REGION 2>/dev/null
      aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION 2>/dev/null
    fi
    
    # Eliminar Subnets
    SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'Subnets[].SubnetId' --output text 2>/dev/null)
    for SUBNET in $SUBNETS; do
      echo "   Eliminando Subnet: $SUBNET"
      aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION 2>/dev/null
    done
    
    # Eliminar Security Groups (excepto default)
    SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --region $REGION --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>/dev/null)
    for SG in $SGS; do
      echo "   Eliminando Security Group: $SG"
      aws ec2 delete-security-group --group-id $SG --region $REGION 2>/dev/null
    done
    
    # Intentar eliminar VPC de nuevo
    echo "   Reintentando eliminar VPC..."
    if aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null; then
      echo "✅ VPC $VPC_ID eliminada exitosamente"
    else
      echo "❌ No se pudo eliminar $VPC_ID. Puede tener recursos complejos (NAT Gateways, etc.)"
      echo "   Usa la consola de AWS para eliminar esta VPC manualmente"
    fi
  fi
  echo ""
done

echo "📊 VPCs restantes:"
aws ec2 describe-vpcs --region $REGION --query 'Vpcs[].[VpcId,Tags[?Key==`Name`].Value|[0],IsDefault]' --output table

echo ""
echo "✅ Proceso completado"
echo "Si quedan VPCs viejas, elimínalas desde la consola de AWS"

