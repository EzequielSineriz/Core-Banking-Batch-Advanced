# 🏦 Core Banking Modernization: Batch Processing & API Integration

![Architecture](https://img.shields.io/badge/Architecture-Hexagonal%20%2F%20Clean-blue)
![Java](https://img.shields.io/badge/Java-21-orange)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.x-brightgreen)
![Angular](https://img.shields.io/badge/Angular-Signals%20%2F%20Standalone-red)
![IBM Mainframe](https://img.shields.io/badge/Mainframe-COBOL%20%2F%20JCL-darkblue)

## 📌 Visión General
Este proyecto demuestra un flujo **End-to-End de Modernización de Core Banking**, integrando sistemas batch legados de procesamiento transaccional en **COBOL/JCL** con microservicios en **Java 21 / Spring Boot** bajo **Arquitectura Hexagonal**, expuestos hacia un dashboard de auditoría y monitoreo reactivo en **Angular con Signals**.

El caso de estudio implementa la ingesta de transacciones masivas de cuentas bancarias, cálculo de saldos con reglas de negocio bancarias (procesamiento Balance Line) y la exposición en tiempo real del estado de saldos y trazabilidad de auditoría.

---

## 🏗️ Arquitectura de 3 Capas ("El Tridente")

```text
┌─────────────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐
│     CAPA 1: BATCH       │      │     CAPA 2: BACKEND     │      │    CAPA 3: FRONTEND     │
│       (Legacy)          │ ───► │      (Modernization)    │ ───► │      (Monitoring)       │
│  COBOL + JCL Engine     │      │ Spring Boot + Java 21   │      │    Angular + Signals    │
│  Genera: .DAT (LRECL40) │      │  Hexagonal Architecture │      │   Audit Dashboard UI    │
└─────────────────────────┘      └─────────────────────────┘      └─────────────────────────┘
```

 ### 1. Engine Batch (COBOL / JCL)
Motor Transaccional (BANK002.cbl): Procesa el archivo de novedades sobre el maestro de cuentas usando el algoritmo Balance Line. Aplica validaciones estrictas de saldos, cortes de control por sucursal y detección de rechazos.

Orquestación z/OS (BANK002J.jcl): Definición de Data Sets (DD), gestión de DISP=(OLD,KEEP,NEW), ejecución de pasos en IBM Mainframe y manejo de códigos de retorno (RC 00/04/08) para auditoría.

### 2. API REST & Integration Layer (Java 21 / Spring Boot)
Arquitectura Hexagonal: Separación de capas en Domain, Application e Infrastructure para garantizar un diseño desacoplado e inmutable.

CobolMasterAdapter: Adaptador de infraestructura que lee e interpreta por posiciones fijas (Copybook Layout) el archivo plano físico .dat derivado del lote COBOL.

DTOs & Java Records: Uso de CuentaResponseDto con Records de Java 21 para inmutabilidad y transferencia eficiente hacia el cliente.

### 3. Frontend Audit Dashboard (Angular)
Reactividad con Signals: Manejo de estado reactivo asincrónico para la carga y monitoreo de saldos en tiempo real.

Standalone Architecture: Componentes desacoplados sin necesidad de NgModules complejos, garantizando modularidad y tiempos de carga reducidos.


## 📌 Descripción del Proyecto

**BANK002** es un módulo transaccional batch diseñado para procesar lotes masivos de movimientos financieros (depósitos y extracciones) sobre un maestro de cuentas. El sistema aplica validaciones de negocio rigurosas, actualiza los saldos en un archivo maestro consolidado, registra transacciones rechazadas con motivo explícito y genera un informe de auditoría por cortes de control (sucursales).


## ⚙️ Orquestación Mainframe (z/OS JCL)

El proyecto incluye el trabajo por lotes **`JOBBANK02.jcl`** listo para ser enviado al JES2/JES3 en entornos IBM z/OS.

### Mapeo de Sentencias DD (Data Definition)

| DD Name | Flujo | Data Set Físico (z/OS) | Formato (DCB) |
| :--- | :--- | :--- | :--- |
| `MAEENT` | Entrada | `PRD.BANK.MAESTRO.ENTRADA` | `RECFM=FB, LRECL=40` |
| `NOVENT` | Entrada | `PRD.BANK.NOVEDADES.ENTRADA` | `RECFM=FB, LRECL=21` |
| `MAESAL` | Salida | `PRD.BANK.MAESTRO.SALIDA` | `RECFM=FB, LRECL=40` |
| `RECSAL` | Salida | `PRD.BANK.RECHAZOS.SALIDA` | `RECFM=FB, LRECL=41` |
| `REPSAL` | Salida | `PRD.BANK.REPORTE.AUDITORIA` | `RECFM=FB, LRECL=80` |

### Pasos de Ejecución del Job
1. **`CLEANUP` (`IDCAMS`):** Purga preventiva de Data Sets de salida generados en ejecuciones anteriores para evitar duplicaciones.
2. **`STEP010` (`PGM=BANK002`):** Asignación dinámica de recursos de disco (`SPACE=(TRK,...)`), ejecución del binario alojado en la `STEPLIB` y retorno de código de condición (`MAXCC / RETURN-CODE`).

---

## 🛠️ Arquitectura y Patrones de Diseño

El desarrollo sigue los estándares y patrones tradicionales de sistemas *mainframe* y procesamiento batch de alto rendimiento:

1. **Algoritmo Balance Line (Apareamiento de Archivos):**
   * Sincronización ordenada por clave primaria (`Nro. de Cuenta`) entre el Maestro y el archivo de Novedades.
   * Manejo eficiente de ciclos de lectura sin bloqueos de memoria ni lecturas redundantes.
2. **Corte de Control por Sucursal (*Group-By* Batch):**
   * Acumulación y ruptura de totales parciales de depósitos y extracciones por unidad organizativa (`Sucursal`).
3. **Resiliencia ante Salto de Línea Multiplataforma (`CRLF` / `LF`):**
   * Higienización activa de caracteres no imprimibles mediante `INSPECT ... REPLACING ALL x"0D" BY SPACES`.
   * Evaluación de estados vía niveles `88` condicionales para tolerancia a rellenos de espacio en disco.
4. **Manejo de Retorno Batch (`RETURN-CODE`):**
   * Cumplimiento de estándar bancario: retorna `0` en ejecuciones 100% limpias y `4` (Warning) si existieron rechazos para alertar al orquestador (JCL / Control-M).

---

## 🔄 Diagrama del Flujo de Procesamiento

```text
[ BANK002J.jcl ] (Job Control)
                                |
[ Maestro Entrada ] ───┐        v
                       ├───> [ BANK002 ] ───┬───> [ Maestro Actualizado ]
[ Novedades Raw   ] ───┘   (Balance Line)   ├───> [ Log de Rechazados   ]
                                            └───> [ Reporte Auditoría   ]

```

## 📂 Estructura de Archivos e Interfaces

```
bin/
├── cobol/
│   ├── BANK002.cbl             # Motor Batch COBOL de actualización de saldos
│   └── bin/
│       └── output/             # Archivos físicamente generados por el lote (.dat)
├── jcl/
│   └── JOBBANK02.jcl            # Job Control Language para ejecución en z/OS
├── CoreBankingBatch/           # Backend Spring Boot (Java 21)
│   ├── src/main/java/com/ApiIntegration/CoreBankingBatch/
│   │   ├── application/        # Servicios de aplicación (CuentaService)
│   │   ├── domain/             # Modelo de Dominio puro (CuentaBancaria)
│   │   └── infrastructure/     # Adaptadores de lectura (CobolMasterAdapter) y REST API
│   └── pom.xml
├── frontend-dashboard/         # Frontend Angular Audit UI
│   └── src/app/
│       ├── services/           # Service HTTP con Signals (CoreBankingService)
│       └── app.component.ts    # Dashboard UI de auditoría
└── README.md
```

## 🛠️ Tecnologías Utilizadas
Backend & Integración: Java 21, Spring Boot 3, Spring Web, Lombok, Maven.

Frontend: Angular 17+, TypeScript, RxJS, Signals, CSS Custom Properties.

Legacy Core: COBOL ANSI/IBM, JCL (Job Control Language), Fixed-Width Data Parsing.

Herramientas & Asistencia AI: Cursor, GitHub Copilot, Git, VS Code, IntelliJ IDEA.



## Especificación de Registros (Layouts)

Maestro (maestro_cuentas.dat) — Largo: 40 bytes

01-06 : Número de Cuenta (PIC 9(6))

07-26 : Nombre del Titular (PIC X(20))

27-36 : Saldo Actual (PIC 9(8)V99)

37-40 : Estado de la Cuenta (PIC X(4)) -> "ACTI"

Novedades (novedades_raw.dat) — Largo: 21 bytes

01-06 : Número de Cuenta (PIC 9(6))

07-07 : Tipo de Operación ('D' Depósito / 'E' Extracción)

08-17 : Importe (PIC 9(8)V99)

18-21 : Código de Sucursal (PIC X(4))

## ⚡ Reglas de Negocio Validadas
Existencia de Cuenta: Si la novedad hace referencia a un número de cuenta que no figura en el maestro, se cataloga como "CUENTA INEXISTENTE".

Estado Activo: Solo las cuentas en estado "ACTI" (o sus variantes de formato "ACT ") pueden operar. Cuentas en otro estado se rechazan como "CUENTA BLOQUEADA".

Control de Saldo: En extracciones ('E'), si Importe > Saldo Actual, la transacción rebota como "SALDO INSUFICIENTE".

Tipo de Operación Validado: Operaciones distintas a 'D' o 'E' se rechazan por "TIPO OP INVALIDO".


## 📊 Ejemplo de Salida (output/reporte_control.txt)

``` Plaintext
BANCO MAINFRAME S.A-     REPORTE AUDITORIA BATCH
================================================
SUC: 0001 | 000100 | DEPOSITO   | $     5,000.00
TOTAL SUCURSAL 0001: DEP=$5,000.00 \vert{} EXT=$         0.00
----------------------------------
SUC: 0002 | 000200 | EXTRACCION | $     3,000.00
TOTAL SUCURSAL 0002: DEP=$0.00 \vert{} EXT=$     3,000.00
----------------------------------
==================================
RESUMEN GLOBAL DE AUDITORIA:
PROCESADOS EXITOSOS:     2 | RECHAZADOS:      1
```


## ⚙️ Bitácora de Optimización y Resolución de Problemas
Durante el ciclo de desarrollo y refinamiento del software se resolvieron los siguientes desafíos técnicos:

Eliminación de Bucle Infinito en Bucle Secundario: Se refactorizó la lógica condicional que causaba la iteración infinita al procesar novedades consecutivas no válidas. Se migró a un estándar Balance Line unificado sobre un EVALUATE TRUE directo.

Normalización de Formato de Archivos (CRLF/LF): Se implementó una técnica de sanitización mediante INSPECT para eliminar retornos de carro (\r / x"0D") inyectados por editores bajo sistemas operativos Windows.

Encadenamiento y Sincronización de Banderas: Se eliminaron evaluaciones booleanas redundantes que reescribían la bandera NOV-INVALIDA, permitiendo que el reporte de auditoría se imprima correctamente antes del resumen global.

Desarrollado como módulo core de procesamiento batch financiero.


## Adaptación en COBOL para Entornos Mainframe
Para que este JCL conecte de forma transparente con tu programa COBOL en un mainframe real, la cláusula ASSIGN en la FILE-CONTROL debe apuntar directamente a los DD Names del JCL (sin comillas ni rutas de carpetas de Windows/Linux):

```COBOL
ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MAESTRO-ENTRADA  ASSIGN TO MAEENT
                  ORGANIZATION IS LINE SEQUENTIAL.
           SELECT NOVEDADES-ENTRADA ASSIGN TO NOVENT
                  ORGANIZATION IS LINE SEQUENTIAL.
           SELECT MAESTRO-SALIDA   ASSIGN TO MAESAL
                  ORGANIZATION IS LINE SEQUENTIAL.
           SELECT RECHAZOS-SALIDA  ASSIGN TO RECSAL
                  ORGANIZATION IS LINE SEQUENTIAL.
           SELECT REPORTE-SALIDA   ASSIGN TO REPSAL
                  ORGANIZATION IS LINE SEQUENTIAL.
```

## 🚀 Guía de Ejecución Local
Prerrequisitos
Java 21 JDK instalado.

Node.js (v18+) y Angular CLI (npm install -g @angular/cli).

Compilador COBOL (GnuCOBOL / COBOL-IT) opcional si se utiliza el binario procesado preexistente.

### 1. Iniciar el Backend (Spring Boot)

```bash
cd CoreBankingBatch
./mvnw spring-boot:run
```

El servicio quedará escuchando en http://localhost:8080/api/v1/core-banking/maestro-saldos.


### 2. Iniciar el Frontend (Angular)

```bash
cd frontend-dashboard
npm install
ng serve -oa
```
Navega a http://localhost:4200 para visualizar el Dashboard de Auditoría conectado al backend.


##  Explicación de Parámetros del JCL

JOB: Define la tarjeta del trabajo (Nombre del Job BANK002J, clase de ejecución CLASS=A y destino de mensajes MSGCLASS=X).

IDCAMS (Paso 1): Utility de IBM que elimina los Data Sets de salida generados en ejecuciones anteriores para evitar errores de duplicación (DUPLICATE DATASET).

STEPLIB: Indica la librería de carga (Load Library) donde se encuentra alojado el ejecutable compilado BANK002.

DISP=(NEW,CATLG,DELETE): Insttruye al sistema operativo a crear un archivo nuevo, catalogarlo si el programa finaliza exitosamente o borrarlo si ocurre un error (Abend).

DCB (Data Control Block):

RECFM=FB: Formato de registro fijo bloqueado (Fixed Blocked).

LRECL: Longitud exacta de línea que definiste en la FD del COBOL (40 bytes para el maestro, 80 bytes para el reporte).


## 👤 Autor
Ezequiel Siñeriz - Desarrollador Backend / Full-Stack / COBOL / JCL









