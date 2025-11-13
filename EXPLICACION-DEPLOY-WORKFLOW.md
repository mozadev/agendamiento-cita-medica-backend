# 🍎 Explicación del Workflow de Deploy - Línea por Línea

## 📋 Índice
1. [Configuración General (Líneas 1-27)](#1-configuración-general)
2. [Job: Test and Build (Líneas 33-84)](#2-job-test-and-build)
3. [Job: Deploy Terraform (Líneas 88-915)](#3-job-deploy-terraform)
4. [Job: Deploy SAM (Líneas 919-1295)](#4-job-deploy-sam)
5. [Job: Init Databases (Líneas 1299-1339)](#5-job-init-databases)
6. [Job: Integration Tests (Líneas 1344-1389)](#6-job-integration-tests)
7. [Job: Notify (Líneas 1394-1418)](#7-job-notify)

---

## 1. Configuración General (Líneas 1-27)

### Líneas 1-2: Nombre del Workflow
```yaml
name: Deploy Infrastructure and Application
```
**🍎 Simple**: Es como ponerle un nombre a una receta. Cuando veas este workflow en GitHub Actions, verás este nombre.
 
**🔧 Técnico**: Define el nombre visible del workflow en la interfaz de GitHub Actions.

---

### Líneas 3-22: Triggers (Cuándo se ejecuta)
```yaml
on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod
```

**🍎 Simple**: 
- `push`: Se ejecuta automáticamente cuando alguien hace push a `main` o `develop` (como cuando guardas un archivo y lo subes)
- `pull_request`: Se ejecuta cuando alguien crea un PR hacia `main` o `develop` (para verificar que todo funciona antes de fusionar)
- `workflow_dispatch`: Te permite ejecutarlo manualmente desde GitHub, eligiendo el ambiente (dev/staging/prod)

**🔧 Técnico**:
- `on.push`: Trigger automático basado en eventos de Git push
- `on.pull_request`: Trigger para validaciones en PRs (CI)
- `on.workflow_dispatch`: Permite ejecución manual con inputs interactivos
- `inputs`: Define parámetros que el usuario puede elegir al ejecutar manualmente

---

### Líneas 24-27: Variables de Entorno Globales
```yaml
env:
  AWS_REGION: us-east-1
  NODE_VERSION: '20'
  TERRAFORM_VERSION: '1.6.0'
```

**🍎 Simple**: Son como "configuraciones globales" que todos los jobs pueden usar. Es como tener un cuaderno con información que todos pueden leer.

**🔧 Técnico**: Variables de entorno disponibles en todos los jobs del workflow. Evita repetir valores y facilita el mantenimiento.

---

## 2. Job: Test and Build (Líneas 33-84)

### Líneas 33-35: Definición del Job
```yaml
test-and-build:
  name: Test and Build
  runs-on: ubuntu-latest
```

**🍎 Simple**: Es como contratar a un trabajador llamado "Test and Build" que trabaja en una máquina Ubuntu (Linux).

**🔧 Técnico**: Define un job que se ejecuta en un runner de GitHub Actions con Ubuntu. Cada job corre en un contenedor limpio.

---

### Líneas 38-39: Checkout del Código
```yaml
- name: Checkout code
  uses: actions/checkout@v4
```

**🍎 Simple**: Es como descargar tu proyecto desde GitHub a la computadora que va a trabajar.

**🔧 Técnico**: La acción `checkout@v4` clona el repositorio en el runner, permitiendo que los pasos siguientes accedan al código.

---

### Líneas 41-49: Verificar package-lock.json
```yaml
- name: Verify package-lock.json exists
  run: |
    if [ ! -f package-lock.json ]; then
      echo "❌ Error: package-lock.json not found!"
      ls -la
      exit 1
    fi
    echo "✅ package-lock.json found"
    ls -lh package-lock.json
```

**🍎 Simple**: Verifica que existe el archivo `package-lock.json` (como verificar que tienes la lista de ingredientes antes de cocinar).

**🔧 Técnico**: 
- `if [ ! -f package-lock.json ]`: Condición bash que verifica si el archivo NO existe
- `exit 1`: Falla el step si no encuentra el archivo
- `ls -lh`: Muestra información del archivo (tamaño, permisos)

---

### Líneas 51-56: Setup Node.js
```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: ${{ env.NODE_VERSION }}
    cache: 'npm'
    cache-dependency-path: package-lock.json
```

**🍎 Simple**: Instala Node.js versión 20 y configura un "cajón" (cache) para guardar las dependencias instaladas, así no tiene que descargarlas cada vez.

**🔧 Técnico**:
- `setup-node@v4`: Acción oficial de GitHub para instalar Node.js
- `cache: 'npm'`: Habilita cache de npm para acelerar instalaciones
- `cache-dependency-path`: Especifica qué archivo usar para invalidar el cache (si cambia package-lock.json, se regenera el cache)

---

### Líneas 58-59: Instalar Dependencias
```yaml
- name: Install dependencies
  run: npm ci
```

**🍎 Simple**: Instala todas las librerías que tu proyecto necesita (como instalar todas las herramientas antes de empezar a trabajar).

**🔧 Técnico**: `npm ci` (clean install) instala dependencias exactas según `package-lock.json`. Es más rápido y determinístico que `npm install`.

---

### Líneas 61-62: Linter
```yaml
- name: Run linter
  run: npm run lint || echo "Linting completed"
```

**🍎 Simple**: Revisa que el código esté bien escrito (como un corrector ortográfico para código).

**🔧 Técnico**: Ejecuta el linter (ESLint). El `|| echo` hace que no falle el workflow si hay errores de linting (solo muestra el mensaje).

---

### Líneas 64-65: Tests
```yaml
- name: Run tests
  run: npm test
```

**🍎 Simple**: Ejecuta todos los tests para verificar que todo funciona (como hacer una prueba antes de entregar un trabajo).

**🔧 Técnico**: Ejecuta Jest con cobertura. Si algún test falla, el workflow se detiene.

---

### Líneas 67-68: Build TypeScript
```yaml
- name: Build TypeScript
  run: npm run build
```

**🍎 Simple**: Convierte el código TypeScript a JavaScript (como compilar un libro antes de publicarlo).

**🔧 Técnico**: Ejecuta `tsc` para compilar TypeScript a JavaScript en la carpeta `dist/`. También copia `database-schema.sql` a `dist/docs/`.

---

### Líneas 70-75: Subir Artifacts
```yaml
- name: Upload build artifacts
  uses: actions/upload-artifact@v4
  with:
    name: dist
    path: dist/
    retention-days: 7
```

**🍎 Simple**: Guarda la carpeta `dist/` (código compilado) en un "almacén" para que otros jobs puedan usarla (como guardar algo en un locker compartido).

**🔧 Técnico**: Sube la carpeta `dist/` como artifact de GitHub Actions. Otros jobs pueden descargarla con `download-artifact`. Se elimina después de 7 días.

---

### Líneas 77-83: Subir Coverage
```yaml
- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/lcov.info
    flags: unittests
    name: codecov-umbrella
    fail_ci_if_error: false
```

**🍎 Simple**: Sube el reporte de cobertura de tests a Codecov (como subir las calificaciones de un examen a un sistema de notas).

**🔧 Técnico**: Sube el reporte LCOV a Codecov para visualizar cobertura de código. `fail_ci_if_error: false` evita que falle el workflow si Codecov no está disponible.

---

## 3. Job: Deploy Terraform (Líneas 88-915)

### Líneas 88-94: Configuración del Job
```yaml
deploy-terraform:
  name: Deploy Infrastructure (Terraform)
  needs: test-and-build
  runs-on: ubuntu-latest
  environment: 
    name: ${{ github.ref == 'refs/heads/main' && 'prod' || github.ref == 'refs/heads/develop' && 'staging' || 'dev' }}
```

**🍎 Simple**: Este job crea la infraestructura (VPC, RDS, etc.). Solo se ejecuta después de que `test-and-build` termine. El ambiente se elige automáticamente según la rama.

**🔧 Técnico**:
- `needs: test-and-build`: Dependencia - este job espera a que el anterior termine
- `environment`: Usa GitHub Environments (dev/staging/prod) que pueden tener secrets específicos
- La expresión ternaria determina el ambiente según la rama Git

---

### Líneas 95-111: Outputs del Job
```yaml
outputs:
  vpc_id: ${{ steps.tf-outputs.outputs.vpc_id }}
  private_subnet_ids: ${{ steps.tf-outputs.outputs.private_subnet_ids }}
  # ... más outputs
```

**🍎 Simple**: Son como "resultados" que este job produce y que otros jobs pueden usar (como pasar una nota con información al siguiente trabajador).

**🔧 Técnico**: Outputs de Terraform que se pasan al job `deploy-sam` como inputs. Permiten compartir información entre jobs.

---

### Líneas 117-125: Instalar jq
```yaml
- name: Install jq (if needed)
  run: |
    if ! command -v jq >/dev/null 2>&1; then
      echo "📦 Instalando jq..."
      sudo apt-get update && sudo apt-get install -y jq
    else
      echo "✅ jq ya está instalado"
    fi
    jq --version
```

**🍎 Simple**: Instala `jq` (herramienta para leer JSON) solo si no está instalado (como verificar si tienes un martillo antes de comprarlo).

**🔧 Técnico**: `jq` es necesario para parsear outputs de Terraform (que vienen en JSON). El check evita reinstalarlo innecesariamente.

---

### Líneas 127-131: Setup Terraform
```yaml
- name: Setup Terraform
  uses: hashicorp/setup-terraform@v3
  with:
    terraform_version: ${{ env.TERRAFORM_VERSION }}
    terraform_wrapper: false
```

**🍎 Simple**: Instala Terraform versión 1.6.0 (como instalar una herramienta específica para construir).

**🔧 Técnico**: Instala Terraform en el PATH del runner. `terraform_wrapper: false` desactiva el wrapper que añade logging automático.

---

### Líneas 133-138: Configurar AWS Credentials
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}
```

**🍎 Simple**: Configura las "credenciales" (usuario y contraseña) para poder trabajar con AWS (como iniciar sesión en una cuenta).

**🔧 Técnico**: Configura variables de entorno `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` para que AWS CLI funcione. Los secrets vienen de GitHub Secrets.

---

### Líneas 140-149: Determinar Ambiente
```yaml
- name: Determine environment
  id: determine-env
  run: |
    if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
      echo "environment=prod" >> $GITHUB_OUTPUT
    elif [[ "${{ github.ref }}" == "refs/heads/develop" ]]; then
      echo "environment=staging" >> $GITHUB_OUTPUT
    else
      echo "environment=dev" >> $GITHUB_OUTPUT
    fi
```

**🍎 Simple**: Decide qué ambiente usar según la rama (main = producción, develop = staging, otras = dev).

**🔧 Técnico**: Usa `github.ref` (referencia Git) para determinar el ambiente. Guarda el resultado en `$GITHUB_OUTPUT` para usarlo en pasos siguientes.

---

### Líneas 151-153: Terraform Init
```yaml
- name: Terraform Init
  working-directory: ./terraform
  run: terraform init
```

**🍎 Simple**: Inicializa Terraform (como preparar las herramientas antes de empezar a construir).

**🔧 Técnico**: `terraform init` descarga providers (plugins) necesarios y configura el backend (donde se guarda el estado).

---

### Líneas 163-377: Limpiar VPCs Duplicadas
```yaml
- name: Cleanup Duplicate VPCs
  if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
  continue-on-error: true
  run: |
    # ... código largo de limpieza
```

**🍎 Simple**: Busca y elimina VPCs viejas o duplicadas para no llenar el límite de AWS (como limpiar el garaje antes de traer cosas nuevas).

**🔧 Técnico**:
- `if`: Solo se ejecuta en push o ejecución manual (no en PRs)
- `continue-on-error: true`: No falla el workflow si hay errores
- El script busca VPCs con el mismo nombre, verifica si tienen RDS, y elimina las duplicadas (manteniendo la más reciente)

**Lógica clave**:
1. Busca VPCs con nombre `agendamiento-v2-{env}-vpc`
2. Si hay más de una, elimina las viejas (excepto la más reciente)
3. Verifica límite de VPCs (5 por cuenta AWS)
4. Si está al límite, elimina VPCs de proyectos anteriores (`agendamiento-citas-*`)
5. Limpia Elastic IPs no utilizados

---

### Líneas 379-799: Importar Recursos Existentes
```yaml
- name: Import Existing Resources (if any)
  if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
  working-directory: ./terraform
  continue-on-error: true
  env:
    TF_VAR_environment: ${{ steps.determine-env.outputs.environment }}
    TF_VAR_rds_pe_master_username: ${{ secrets.RDS_PE_USERNAME }}
    # ... más variables
  run: |
    # ... código de importación
```

**🍎 Simple**: Si ya existen recursos en AWS (de un deploy anterior), los "importa" al estado de Terraform (como registrar cosas que ya tienes en tu inventario).

**🔧 Técnico**: 
- `terraform import` trae recursos existentes en AWS al estado de Terraform
- Evita errores de "recurso ya existe"
- Importa: VPC, Subnets, Security Groups, Route Tables, NAT Gateways, RDS, DynamoDB, EventBridge, Secrets Manager

**Recursos importados**:
- `aws_vpc.main`: VPC principal
- `aws_subnet.public[0/1]`, `aws_subnet.private[0/1]`, `aws_subnet.database[0/1]`: Subnets
- `aws_security_group.lambda`, `aws_security_group.rds`: Security Groups
- `aws_route_table.*`: Route Tables y sus asociaciones
- `aws_nat_gateway.main[0/1]`: NAT Gateways
- `aws_db_instance.peru`, `aws_db_instance.chile`: Instancias RDS
- `aws_dynamodb_table.appointments`: Tabla DynamoDB
- `aws_cloudwatch_event_bus.main`: EventBridge Bus
- `aws_secretsmanager_secret.rds_peru`, `aws_secretsmanager_secret.rds_chile`: Secrets

---

### Líneas 801-812: Terraform Plan
```yaml
- name: Terraform Plan (after import)
  if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
  working-directory: ./terraform
  run: |
    terraform plan \
      -var="environment=${{ steps.determine-env.outputs.environment }}" \
      -var="rds_pe_master_username=${{ secrets.RDS_PE_USERNAME }}" \
      # ... más variables
      -out=tfplan
```

**🍎 Simple**: Crea un "plan" de lo que Terraform va a hacer (crear, modificar, eliminar) sin hacerlo todavía (como hacer una lista de compras antes de ir al supermercado).

**🔧 Técnico**:
- `terraform plan` compara el estado actual con el código y genera un plan de cambios
- `-out=tfplan`: Guarda el plan en un archivo para aplicarlo después
- Las variables `-var` pasan valores necesarios (como credenciales de RDS)

---

### Líneas 814-871: Esperar RDS Disponible
```yaml
- name: Wait for RDS Instances to be Available
  if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
  run: |
    # ... código de espera
```

**🍎 Simple**: Espera a que las bases de datos RDS estén listas antes de continuar (como esperar a que el horno se caliente antes de meter el pastel).

**🔧 Técnico**: 
- Verifica el estado de las instancias RDS (`available`, `modifying`, etc.)
- Espera hasta 30 intentos (15 minutos) con sleep de 30 segundos
- Si está en `modifying` o `backing-up`, espera más tiempo
- Evita errores de `InvalidDBInstanceState` en Terraform

---

### Líneas 873-878: Terraform Apply
```yaml
- name: Terraform Apply
  if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
  working-directory: ./terraform
  run: |
    terraform apply -auto-approve tfplan
```

**🍎 Simple**: Aplica el plan creado anteriormente (como ejecutar la lista de compras y comprar todo).

**🔧 Técnico**: 
- `terraform apply -auto-approve`: Aplica el plan sin pedir confirmación (necesario en CI/CD)
- `tfplan`: Usa el plan guardado anteriormente (asegura que se aplica exactamente lo planeado)

---

### Líneas 880-914: Obtener Outputs de Terraform
```yaml
- name: Get Terraform Outputs
  id: tf-outputs
  if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
  working-directory: ./terraform
  run: |
    # Verificar que el state tiene outputs
    if ! terraform output vpc_id > /dev/null 2>&1; then
      echo "❌ Error: Terraform outputs no están disponibles"
      exit 1
    fi
    
    # Obtener outputs
    echo "vpc_id=$(terraform output -raw vpc_id)" >> $GITHUB_OUTPUT
    PRIVATE_SUBNETS=$(terraform output -json private_subnet_ids | jq -r 'join(",")')
    echo "private_subnet_ids=$PRIVATE_SUBNETS" >> $GITHUB_OUTPUT
    # ... más outputs
```

**🍎 Simple**: Obtiene información importante creada por Terraform (como IDs de VPC, subnets, etc.) y la guarda para que otros jobs la usen.

**🔧 Técnico**:
- `terraform output`: Obtiene valores de salida definidos en `outputs.tf`
- `-raw`: Obtiene el valor sin formato JSON
- `-json` + `jq`: Para listas, convierte JSON a string separado por comas
- `>> $GITHUB_OUTPUT`: Guarda en outputs del step para usar en otros jobs

**Outputs obtenidos**:
- `vpc_id`: ID de la VPC
- `private_subnet_ids`: IDs de subnets privadas (lista → string separado por comas)
- `lambda_sg_id`: ID del Security Group para Lambda
- `dynamodb_table`, `dynamodb_table_arn`: Nombre y ARN de DynamoDB
- `sns_peru_arn`, `sns_chile_arn`: ARNs de topics SNS
- `sqs_queue_url_peru`, `sqs_queue_url_chile`: URLs de colas SQS
- `sqs_queue_arn_peru`, `sqs_queue_arn_chile`: ARNs de colas SQS
- `sqs_completion_queue_url`, `sqs_completion_queue_arn`: Cola de completación
- `eventbridge_bus_name`: Nombre del bus EventBridge
- `rds_peru_secret_arn`, `rds_chile_secret_arn`: ARNs de secrets de RDS

---

## 4. Job: Deploy SAM (Líneas 919-1295)

### Líneas 919-925: Configuración del Job
```yaml
deploy-sam:
  name: Deploy Lambda Functions (SAM)
  needs: [test-and-build, deploy-terraform]
  runs-on: ubuntu-latest
  if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
  environment: 
    name: ${{ github.ref == 'refs/heads/main' && 'prod' || github.ref == 'refs/heads/develop' && 'staging' || 'dev' }}
```

**🍎 Simple**: Este job despliega las funciones Lambda y API Gateway. Espera a que los tests pasen Y que la infraestructura esté lista.

**🔧 Técnico**:
- `needs: [test-and-build, deploy-terraform]`: Espera a que AMBOS jobs terminen
- `if`: Solo se ejecuta en push o ejecución manual (no en PRs)

---

### Líneas 941-945: Descargar Artifacts
```yaml
- name: Download build artifacts
  uses: actions/download-artifact@v4
  with:
    name: dist
    path: dist/
```

**🍎 Simple**: Descarga el código compilado que el job `test-and-build` guardó (como recibir un paquete que alguien te envió).

**🔧 Técnico**: Descarga el artifact `dist` (código TypeScript compilado) para empaquetarlo en las funciones Lambda.

---

### Líneas 947-950: Setup AWS SAM
```yaml
- name: Setup AWS SAM
  uses: aws-actions/setup-sam@v2
  with:
    use-installer: true
```

**🍎 Simple**: Instala AWS SAM CLI (herramienta para desplegar funciones Lambda).

**🔧 Técnico**: Instala SAM CLI en el PATH del runner para poder ejecutar `sam build` y `sam deploy`.

---

### Líneas 974-1010: Validar Parámetros SAM
```yaml
- name: Validate SAM Parameters
  run: |
    echo "🔍 Validando parámetros para SAM Deploy..."
    
    VPC_ID="${{ needs.deploy-terraform.outputs.vpc_id }}"
    SUBNETS="${{ needs.deploy-terraform.outputs.private_subnet_ids }}"
    SG_ID="${{ needs.deploy-terraform.outputs.lambda_sg_id }}"
    
    # Verificar VPC
    if ! aws ec2 describe-vpcs --vpc-ids "$VPC_ID" --region ${{ env.AWS_REGION }} >/dev/null 2>&1; then
      echo "❌ VPC $VPC_ID no existe"
      exit 1
    fi
    echo "✅ VPC existe"
    
    # Verificar Security Group
    # Verificar Subnets
```

**🍎 Simple**: Verifica que todos los recursos de red (VPC, Security Groups, Subnets) existan antes de desplegar Lambda (como verificar que tienes todos los materiales antes de construir).

**🔧 Técnico**: 
- Usa `aws ec2 describe-*` para verificar que los recursos existen
- Si alguno no existe, falla el workflow antes de intentar el deploy
- Evita errores costosos en tiempo de ejecución

---

### Líneas 1012-1184: Verificar y Arreglar Estado de CloudFormation
```yaml
- name: Check and Fix CloudFormation Stack State
  continue-on-error: false
  run: |
    STACK_NAME="agendamiento-citas-${{ steps.determine-env.outputs.environment }}"
    # ... código largo
```

**🍎 Simple**: Verifica el estado del stack de CloudFormation. Si está en un estado fallido (como `ROLLBACK_COMPLETE`), lo elimina para poder crear uno nuevo (como limpiar un intento fallido antes de intentar de nuevo).

**🔧 Técnico**:
- CloudFormation stacks pueden quedar en estados fallidos (`ROLLBACK_COMPLETE`, `CREATE_FAILED`, etc.)
- Estos estados bloquean nuevos deploys
- El script:
  1. Verifica el estado del stack
  2. Si está en `DELETE_IN_PROGRESS`, espera hasta 5 minutos adicionales
  3. Si está en estado fallido, lo elimina
  4. Espera hasta 20 minutos para que se elimine (Lambda en VPC tarda mucho)
  5. Si alcanza timeout pero está en `DELETE_IN_PROGRESS`, continúa (no falla)

**Estados manejados**:
- `ROLLBACK_IN_PROGRESS`, `ROLLBACK_COMPLETE`, `ROLLBACK_FAILED`
- `DELETE_FAILED`, `CREATE_FAILED`
- `UPDATE_ROLLBACK_IN_PROGRESS`, `UPDATE_ROLLBACK_COMPLETE`, `UPDATE_ROLLBACK_FAILED`

---

### Líneas 1186-1241: SAM Deploy
```yaml
- name: SAM Deploy
  working-directory: ./sam
  timeout-minutes: 30
  run: |
    echo "🚀 Iniciando SAM Deploy..."
    
    set +e  # No salir inmediatamente en error
    sam deploy \
      --stack-name agendamiento-citas-${{ steps.determine-env.outputs.environment }} \
      --resolve-s3 \
      --parameter-overrides \
        Environment=${{ steps.determine-env.outputs.environment }} \
        VpcId=${{ needs.deploy-terraform.outputs.vpc_id }} \
        # ... más parámetros
      --capabilities CAPABILITY_IAM \
      --no-confirm-changeset \
      --no-fail-on-empty-changeset \
      --disable-rollback \
      --debug
    
    SAM_EXIT_CODE=$?
    set -e  # Reactivar salir en error
    
    if [ $SAM_EXIT_CODE -ne 0 ]; then
      # Mostrar errores
      exit 1
    fi
```

**🍎 Simple**: Despliega las funciones Lambda y API Gateway usando SAM. Pasa todos los parámetros necesarios (VPC, subnets, etc.) que vienen de Terraform.

**🔧 Técnico**:
- `sam deploy`: Despliega el stack de CloudFormation definido en `sam/template.yaml`
- `--resolve-s3`: Crea automáticamente un bucket S3 para guardar el código de Lambda
- `--parameter-overrides`: Pasa parámetros al template SAM (vienen de outputs de Terraform)
- `--capabilities CAPABILITY_IAM`: Permite crear roles IAM (requerido por CloudFormation)
- `--no-confirm-changeset`: No pide confirmación (automático en CI/CD)
- `--no-fail-on-empty-changeset`: No falla si no hay cambios
- `--disable-rollback`: No elimina el stack si falla (permite debugging)
- `--debug`: Muestra logs detallados
- `set +e` / `set -e`: Manejo de errores - captura el código de salida antes de verificar

**Parámetros pasados**:
- `Environment`: dev/staging/prod
- `VpcId`: ID de la VPC
- `PrivateSubnetIds`: IDs de subnets privadas (comma-separated)
- `LambdaSecurityGroupId`: ID del Security Group
- `DynamoDBTableName`, `DynamoDBTableArn`: Info de DynamoDB
- `SNSTopicArnPeru`, `SNSTopicArnChile`: ARNs de SNS
- `SQSQueueUrlPeru`, `SQSQueueUrlChile`: URLs de SQS
- `SQSQueueArnPeru`, `SQSQueueArnChile`: ARNs de SQS
- `SQSCompletionQueueUrl`, `SQSCompletionQueueArn`: Cola de completación
- `EventBridgeBusName`: Nombre del bus
- `RDSPeruSecretArn`, `RDSChileSecretArn`: ARNs de secrets de RDS

---

### Líneas 1243-1271: Obtener API URL
```yaml
- name: Get API URL
  id: sam-deploy
  run: |
    STACK_NAME="agendamiento-citas-${{ steps.determine-env.outputs.environment }}"
    
    echo "🔍 Obteniendo API URL del stack: $STACK_NAME"
    
    # Esperar a que el stack esté completamente actualizado
    sleep 10
    
    # Get API URL
    API_URL=$(aws cloudformation describe-stacks \
      --stack-name "$STACK_NAME" \
      --region ${{ env.AWS_REGION }} \
      --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
      --output text)
    
    if [ -z "$API_URL" ] || [ "$API_URL" == "None" ]; then
      echo "❌ No se pudo obtener API URL"
      exit 1
    fi
    
    echo "✅ API URL obtenida: $API_URL"
    echo "api_url=$API_URL" >> $GITHUB_OUTPUT
```

**🍎 Simple**: Obtiene la URL del API Gateway que se acaba de crear (como obtener la dirección de una tienda que acabas de abrir).

**🔧 Técnico**:
- `sleep 10`: Espera a que CloudFormation termine de crear el stack
- `aws cloudformation describe-stacks`: Obtiene información del stack
- `--query`: Filtra el output `ApiUrl` del stack
- Guarda la URL en `$GITHUB_OUTPUT` para usarla en otros jobs

---

### Líneas 1273-1288: Mostrar Eventos en Caso de Falla
```yaml
- name: Show CloudFormation Events on Failure
  if: failure()
  run: |
    # Obtener los últimos 20 eventos del stack
    aws cloudformation describe-stack-events \
      --stack-name "$STACK_NAME" \
      --max-items 20 \
      --query 'StackEvents[].[Timestamp,LogicalResourceId,ResourceType,ResourceStatus,ResourceStatusReason]' \
      --output table
```

**🍎 Simple**: Si algo falla, muestra los últimos eventos de CloudFormation para ayudar a entender qué salió mal (como mostrar el registro de errores cuando algo falla).

**🔧 Técnico**: 
- `if: failure()`: Solo se ejecuta si algún step anterior falló
- Muestra eventos de CloudFormation en formato tabla para debugging

---

## 5. Job: Init Databases (Líneas 1299-1339)

### Líneas 1299-1307: Configuración (Deshabilitado)
```yaml
init-databases:
  name: Initialize RDS Databases
  needs: [deploy-terraform]
  runs-on: ubuntu-latest
  if: false  # Deshabilitado: La inicialización de DB se hará manualmente
  continue-on-error: true
```

**🍎 Simple**: Este job está deshabilitado. La inicialización de bases de datos se hace manualmente usando el workflow "Database Migrations".

**🔧 Técnico**: 
- `if: false`: El job nunca se ejecuta
- Está comentado porque RDS está en subnets privadas y GitHub Actions no puede conectarse directamente
- Se usa una Lambda function para ejecutar las migraciones (workflow separado)

---

## 6. Job: Integration Tests (Líneas 1344-1389)

### Líneas 1344-1351: Configuración (Deshabilitado)
```yaml
integration-tests:
  name: Integration Tests
  needs: [deploy-sam]
  runs-on: ubuntu-latest
  if: false  # Deshabilitado temporalmente - Implementar tests reales
  continue-on-error: true
```

**🍎 Simple**: Este job también está deshabilitado. Los tests de integración se implementarán cuando la base de datos esté lista.

**🔧 Técnico**: 
- `if: false`: No se ejecuta
- Está deshabilitado porque requiere:
  1. Base de datos inicializada
  2. Tests reales implementados (no solo curl básico)

---

## 7. Job: Notify (Líneas 1394-1418)

### Líneas 1394-1398: Configuración
```yaml
notify:
  name: Send Notification
  needs: [deploy-sam]
  runs-on: ubuntu-latest
  if: always() && (github.event_name == 'push' || github.event_name == 'workflow_dispatch')
```

**🍎 Simple**: Este job siempre se ejecuta (incluso si algo falló) y muestra un resumen del deploy.

**🔧 Técnico**:
- `if: always()`: Se ejecuta sin importar si los jobs anteriores fallaron
- `needs: [deploy-sam]`: Espera a que el deploy de SAM termine (exitoso o fallido)

---

### Líneas 1401-1411: Notificación de Éxito
```yaml
- name: Send success notification
  if: needs.deploy-sam.result == 'success'
  run: |
    echo "✅ Deployment successful!"
    echo "🚀 API URL: ${{ needs.deploy-sam.outputs.api_url }}"
    echo "🌍 Environment: ${{ github.ref }}"
    echo ""
    echo "📝 Próximos pasos:"
    echo "   1. Ejecutar workflow 'Database Migrations' para inicializar DBs"
    echo "   2. Probar endpoints de la API"
    echo "   3. Habilitar integration tests cuando DB esté lista"
```

**🍎 Simple**: Si el deploy fue exitoso, muestra un mensaje con la URL del API y los próximos pasos.

**🔧 Técnico**: 
- `if: needs.deploy-sam.result == 'success'`: Solo se ejecuta si el deploy fue exitoso
- Muestra información útil: API URL, ambiente, próximos pasos

---

### Líneas 1413-1417: Notificación de Falla
```yaml
- name: Send failure notification
  if: needs.deploy-sam.result != 'success'
  run: |
    echo "❌ Deployment failed!"
    echo "🔍 Check the logs for details"
```

**🍎 Simple**: Si el deploy falló, muestra un mensaje indicando que hay que revisar los logs.

**🔧 Técnico**: Mensaje simple de error. Los detalles están en los logs de los jobs anteriores.

---

## 🎯 Resumen del Flujo Completo

### Flujo Visual:
```
1. Push a main/develop
   ↓
2. test-and-build
   - Instala dependencias
   - Ejecuta tests
   - Compila TypeScript
   - Guarda artifacts
   ↓
3. deploy-terraform (espera a test-and-build)
   - Limpia VPCs viejas
   - Importa recursos existentes
   - Crea/actualiza infraestructura (VPC, RDS, DynamoDB, etc.)
   - Guarda outputs (VPC ID, Subnets, etc.)
   ↓
4. deploy-sam (espera a test-and-build Y deploy-terraform)
   - Descarga código compilado
   - Valida parámetros
   - Verifica/limpia stack de CloudFormation
   - Despliega Lambda functions y API Gateway
   - Obtiene API URL
   ↓
5. notify (siempre se ejecuta)
   - Muestra resultado (éxito o fallo)
   - Muestra próximos pasos
```

### Jobs Deshabilitados:
- `init-databases`: Se hace manualmente con workflow "Database Migrations"
- `integration-tests`: Se implementará cuando DB esté lista

---

## 🔑 Conceptos Clave

### 1. **Dependencias entre Jobs** (`needs`)
- `deploy-terraform` necesita `test-and-build`
- `deploy-sam` necesita `test-and-build` Y `deploy-terraform`
- Esto asegura que todo se ejecute en el orden correcto

### 2. **Compartir Información entre Jobs** (`outputs`)
- Terraform crea recursos y guarda IDs en `outputs`
- SAM recibe esos outputs como `parameter-overrides`
- Permite que los jobs se comuniquen

### 3. **Manejo de Errores**
- `continue-on-error: true`: No falla el workflow si este step falla
- `if: failure()`: Se ejecuta solo si algo falló
- `set +e` / `set -e`: Controla si el script se detiene en errores

### 4. **Idempotencia**
- Terraform importa recursos existentes antes de crear nuevos
- Evita errores de "recurso ya existe"
- Permite re-ejecutar el workflow sin problemas

### 5. **Ambientes**
- Se determina automáticamente según la rama
- `main` → `prod`
- `develop` → `staging`
- Otras → `dev`

---

## 📚 Recursos Adicionales

- **GitHub Actions**: https://docs.github.com/en/actions
- **Terraform**: https://www.terraform.io/docs
- **AWS SAM**: https://docs.aws.amazon.com/serverless-application-model/
- **CloudFormation**: https://docs.aws.amazon.com/cloudformation/

---

¿Tienes preguntas sobre alguna sección específica? 🤔

