#!/bin/bash

# Script para forzar eliminación de una VPC y todas sus dependencias
# Uso: ./force-delete-vpc.sh vpc-XXXXXXXXX

if [ -z "$1" ]; then
  echo "❌ Error: Debes proporcionar un VPC ID"
  echo "Uso: ./force-delete-vpc.sh vpc-XXXXXXXXX"
  exit 1
fi

VPC_ID=$1
REGION="us-east-1"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  🗑️  Eliminación Forzada de VPC: $VPC_ID"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Función para intentar eliminar y continuar si falla
try_delete() {
  local resource=$1
  local command=$2
  echo "🗑️  Eliminando $resource..."
  if eval "$command" 2>/dev/null; then
    echo "   ✅ Eliminado"
  else
    echo "   ⚠️  Ya eliminado o no existe"
  fi
}

# 1. Eliminar NAT Gateways
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  NAT Gateways"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
NAT_GWS=$(aws ec2 describe-nat-gateways --region $REGION --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available,pending,deleting" --query 'NatGateways[].NatGatewayId' --output text)
for NAT in $NAT_GWS; do
  try_delete "NAT Gateway $NAT" "aws ec2 delete-nat-gateway --nat-gateway-id $NAT --region $REGION"
done
if [ ! -z "$NAT_GWS" ]; then
  echo "⏳ Esperando 30s para que NAT Gateways empiecen a eliminarse..."
  sleep 30
fi

# 2. Desconectar y eliminar Internet Gateways
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Internet Gateways"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
IGW=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
if [ "$IGW" != "None" ] && [ ! -z "$IGW" ]; then
  try_delete "Internet Gateway (detach)" "aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID --region $REGION"
  try_delete "Internet Gateway (delete)" "aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION"
fi

# 3. Eliminar VPC Endpoints
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  VPC Endpoints"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
VPC_ENDPOINTS=$(aws ec2 describe-vpc-endpoints --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'VpcEndpoints[].VpcEndpointId' --output text)
for ENDPOINT in $VPC_ENDPOINTS; do
  try_delete "VPC Endpoint $ENDPOINT" "aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $ENDPOINT --region $REGION"
done

# 4. Eliminar instancias EC2
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  EC2 Instances"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
INSTANCES=$(aws ec2 describe-instances --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped" --query 'Reservations[].Instances[].InstanceId' --output text)
for INSTANCE in $INSTANCES; do
  echo "⚠️  EC2 Instance encontrada: $INSTANCE"
  echo "   No se eliminará automáticamente (requiere confirmación manual)"
  echo "   Para eliminarla: aws ec2 terminate-instances --instance-ids $INSTANCE --region $REGION"
done

# 5. Eliminar Network Interfaces
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  Network Interfaces (ENIs)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ENIS=$(aws ec2 describe-network-interfaces --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'NetworkInterfaces[?Status!=`in-use`].NetworkInterfaceId' --output text)
for ENI in $ENIS; do
  try_delete "ENI $ENI" "aws ec2 delete-network-interface --network-interface-id $ENI --region $REGION"
done

# 6. Eliminar Security Groups (excepto default)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  Security Groups"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SGS=$(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)
for SG in $SGS; do
  # Primero eliminar reglas
  aws ec2 describe-security-groups --region $REGION --group-ids $SG --query 'SecurityGroups[0].IpPermissions' --output json > /tmp/sg_rules_ingress_$SG.json 2>/dev/null
  if [ -s /tmp/sg_rules_ingress_$SG.json ] && [ "$(cat /tmp/sg_rules_ingress_$SG.json)" != "[]" ]; then
    aws ec2 revoke-security-group-ingress --region $REGION --group-id $SG --ip-permissions file:///tmp/sg_rules_ingress_$SG.json 2>/dev/null
  fi
  
  aws ec2 describe-security-groups --region $REGION --group-ids $SG --query 'SecurityGroups[0].IpPermissionsEgress' --output json > /tmp/sg_rules_egress_$SG.json 2>/dev/null
  if [ -s /tmp/sg_rules_egress_$SG.json ] && [ "$(cat /tmp/sg_rules_egress_$SG.json)" != "[]" ]; then
    aws ec2 revoke-security-group-egress --region $REGION --group-id $SG --ip-permissions file:///tmp/sg_rules_egress_$SG.json 2>/dev/null
  fi
  
  try_delete "Security Group $SG" "aws ec2 delete-security-group --group-id $SG --region $REGION"
done

# 7. Eliminar Subnets
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7️⃣  Subnets"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].SubnetId' --output text)
for SUBNET in $SUBNETS; do
  try_delete "Subnet $SUBNET" "aws ec2 delete-subnet --subnet-id $SUBNET --region $REGION"
done

# 8. Eliminar Route Tables (excepto main)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8️⃣  Route Tables"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ROUTE_TABLES=$(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text)
for RT in $ROUTE_TABLES; do
  # Desasociar de subnets
  ASSOCS=$(aws ec2 describe-route-tables --region $REGION --route-table-ids $RT --query 'RouteTables[0].Associations[?SubnetId!=`null`].RouteTableAssociationId' --output text)
  for ASSOC in $ASSOCS; do
    try_delete "Route Table Association $ASSOC" "aws ec2 disassociate-route-table --association-id $ASSOC --region $REGION"
  done
  
  try_delete "Route Table $RT" "aws ec2 delete-route-table --route-table-id $RT --region $REGION"
done

# 9. Liberar Elastic IPs
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "9️⃣  Elastic IPs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Buscar EIPs asociados a ENIs de esta VPC
EIPS=$(aws ec2 describe-addresses --region $REGION --query "Addresses[?NetworkInterfaceId!=null].AllocationId" --output text 2>/dev/null)
for EIP in $EIPS; do
  # Verificar si el ENI pertenece a esta VPC
  ENI=$(aws ec2 describe-addresses --region $REGION --allocation-ids $EIP --query 'Addresses[0].NetworkInterfaceId' --output text)
  ENI_VPC=$(aws ec2 describe-network-interfaces --region $REGION --network-interface-ids $ENI --query 'NetworkInterfaces[0].VpcId' --output text 2>/dev/null)
  if [ "$ENI_VPC" == "$VPC_ID" ]; then
    try_delete "Elastic IP $EIP" "aws ec2 release-address --allocation-id $EIP --region $REGION"
  fi
done

# 10. Intentar eliminar VPC
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 Eliminando VPC"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>&1; then
  echo "✅ VPC $VPC_ID eliminada exitosamente!"
else
  echo "❌ No se pudo eliminar VPC $VPC_ID"
  echo ""
  echo "Posibles causas:"
  echo "- NAT Gateways aún eliminándose (espera 3-5 min)"
  echo "- ENIs en uso (Lambda functions activas)"
  echo "- RDS instances activas"
  echo ""
  echo "Reintenta en 5 minutos: ./force-delete-vpc.sh $VPC_ID"
fi

echo ""
echo "╚════════════════════════════════════════════════════════════╝"

