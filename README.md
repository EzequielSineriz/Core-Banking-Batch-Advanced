# Core Banking Batch & Audit System (COBOL)

Sistema de actualización de maestro de cuentas bancarias y generación de reportes de auditoría en tiempo de ejecución *Batch*, implementado en **COBOL ANSI85** bajo arquitectura **Balance Line**.

![COBOL](https://img.shields.io/badge/Language-COBOL_ANSI85-blue?style=for-the-badge&logo=gnu)
![Build](https://img.shields.io/badge/Compiler-GnuCOBOL_v3.1+-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Core_Banking-Batch_Processing-orange?style=for-the-badge)

---

## 📌 Descripción del Proyecto

**BANK002** es un módulo transaccional batch diseñado para procesar lotes masivos de movimientos financieros (depósitos y extracciones) sobre un maestro de cuentas. El sistema aplica validaciones de negocio rigurosas, actualiza los saldos en un archivo maestro consolidado, registra transacciones rechazadas con motivo explícito y genera un informe de auditoría por cortes de control (sucursales).

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
[ Maestro Entrada ] ───┐
                       ├───> [ BANK002.exe ] ───┬───> [ Maestro Actualizado ]
[ Novedades Raw   ] ───┘     (Balance Line)     ├───> [ Log de Rechazados   ]
                                                └───> [ Reporte Auditoría   ]

```

## 📂 Estructura de Archivos e Interfaces

```
bin/
│  └── BANK002.exe          # Binario compilado
├── data/
│   ├── maestro_cuentas.dat      # Archivo Maestro de Cuentas (Entrada)
│   └── novedades_raw.dat        # Archivo de Transacciones/Novedades (Entrada)
└── output/
|    ├── maestro_actualizado.dat  # Maestro procesado con saldos finales
|    ├── rechazados.dat           # Log de novedades invalidadas con causa
|    └── reporte_control.txt      # Reporte impreso de auditoría y cortes
|__ jol/
     ├── 
```


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

