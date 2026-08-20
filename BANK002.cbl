******************************************************************
      * Autor: Ezequiel Sineriz
      * Proposito: Actualizacion de maestro de cuentas bancarias y
      *            generacion de informe de auditoria por sucursal.
      * Tecnica: Algoritmo de Apareamiento (Balance Line Algorithm).
      * Compilador: GnuCOBOL / OPENCobolIDE
      ******************************************************************
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK002.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *> Definicion de archivos fisicos asociados a logicos
           SELECT MAESTRO-ENTRADA ASSIGN TO "data/maestro_cuentas.dat"
                  ORGANIZATION IS LINE SEQUENTIAL.
           SELECT NOVEDADES-ENTRADA ASSIGN TO "data/novedades_raw.dat"
                  ORGANIZATION IS LINE SEQUENTIAL.
           SELECT MAESTRO-SALIDA
                  ASSIGN TO "output/maestro_actualizado.dat"
                  ORGANIZATION IS LINE SEQUENTIAL.
           SELECT RECHAZOS-SALIDA ASSIGN TO "output/rechazados.dat"
                  ORGANIZATION IS LINE SEQUENTIAL.
           SELECT REPORTE-SALIDA ASSIGN TO "output/reporte_control.txt"
                  ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
      *> Estructura del Archivo Maestro de Entrada (40 bytes por linea)
       FD  MAESTRO-ENTRADA.
       01  REG-MAE-ENT.
           05 MAE-ENT-CUENTA     PIC 9(6).
           05 MAE-ENT-TITULAR    PIC X(20).
           05 MAE-ENT-SALDO      PIC 9(8)V99.
           05 MAE-ENT-ESTADO     PIC X(4).

      *> Estructura del Archivo de Novedades / Transacciones (21 bytes)
       FD  NOVEDADES-ENTRADA.
       01  REG-NOV-ENT.
           05 NOV-ENT-CUENTA     PIC 9(6).
           05 NOV-ENT-TIPO       PIC X(1).
           05 NOV-ENT-IMPORTE    PIC 9(8)V99.
           05 NOV-ENT-SUCURSAL-X PIC X(4).

      *> Estructura para el Maestro Actualizado
       FD  MAESTRO-SALIDA.
       01  REG-MAE-SAL.
           05 MAE-SAL-CUENTA     PIC 9(6).
           05 MAE-SAL-TITULAR    PIC X(20).
           05 MAE-SAL-SALDO      PIC 9(8)V99.
           05 MAE-SAL-ESTADO     PIC X(4).

      *> Estructura para la grabacion de novedades rechazadas
       FD  RECHAZOS-SALIDA.
       01  REG-REC-SAL.
           05 REC-SAL-NOV        PIC X(21).
           05 REC-SAL-MOTIVO     PIC X(20).

      *> Registro de salida para el informe impreso
       FD  REPORTE-SALIDA.
       01  REG-REP-SAL           PIC X(80).

       WORKING-STORAGE SECTION.
      *> Flags de Fin de Archivo (EOF) y Validacion
       01  WS-FLAGS.
           05 WS-EOF-MAE         PIC X(1) VALUE 'N'.
              88 FIN-MAE                  VALUE 'Y'.
           05 WS-EOF-NOV         PIC X(1) VALUE 'N'.
              88 FIN-NOV                  VALUE 'Y'.
           05 WS-VALIDO          PIC X(1) VALUE 'V'.
              88 NOV-VALIDA               VALUE 'V'.
              88 NOV-INVALIDA             VALUE 'I'.

      *> Variables auxiliares de trabajo
       01  WS-MOTIVO-TEMP        PIC X(20) VALUE SPACES.
       01  WS-SUCURSAL-NUM       PIC 9(4)  VALUE 0.

      *> Acumuladores globales para metricas finales de auditoria
       01  WS-ACUMULADORES.
           05 WS-TOT-PROCESADOS  PIC 9(5)      VALUE 0.
           05 WS-TOT-RECHAZADOS  PIC 9(5)      VALUE 0.
           05 WS-IMP-DEPOSITOS   PIC 9(10)V99  VALUE 0.
           05 WS-IMP-EXTRACCIONES PIC 9(10)V99 VALUE 0.

      *> Variables para Control de Corte por Sucursal
       01  WS-CORTE-SUCURSAL.
           05 WS-SUCURSAL-PREVIA PIC 9(4)     VALUE 0.
           05 WS-SUBTOT-DEPOSITO PIC 9(10)V99 VALUE 0.
           05 WS-SUBTOT-EXTRA    PIC 9(10)V99 VALUE 0.

      *> Registro en memoria para procesar la cuenta actual
       01  WS-MAESTRO-ACTUAL.
           05 WS-MAE-CUENTA     PIC 9(6)    VALUE 0.
           05 WS-MAE-TITULAR    PIC X(20)   VALUE SPACES.
           05 WS-MAE-SALDO      PIC 9(8)V99 VALUE 0.
           05 WS-MAE-ESTADO     PIC X(4)    VALUE SPACES.
      *> Evaluador 88: Tolera variaciones de fin de línea Windows (CRLF) o espacios
              88 MAE-ACTIVO                 VALUE "ACTI", "ACT ", "ACT".

      *> Layouts de formato para el reporte impreso
       01  REP-CABECERA.
           05 FILLER             PIC X(25) VALUE "BANCO MAINFRAME S.A-".
           05 FILLER             PIC X(25) VALUE "REPORTE AUDI BATCH".
           05 FILLER             PIC X(30) VALUE SPACES.

       01  REP-DETALLE.
           05 FILLER             PIC X(5)  VALUE "SUC: ".
           05 DET-SUCURSAL       PIC 9(4).
           05 FILLER             PIC X(3)  VALUE " | ".
           05 DET-CUENTA         PIC 9(6).
           05 FILLER             PIC X(3)  VALUE " | ".
           05 DET-TIPO           PIC X(10).
           05 FILLER             PIC X(4)  VALUE " | $".
           05 DET-IMPORTE        PIC ZZ,ZZZ,ZZ9.99.

       01  REP-SUBTOTAL.
           05 FILLER             PIC X(15) VALUE "TOTAL SUCURSAL ".
           05 SUB-SUCURSAL       PIC 9(4).
           05 FILLER             PIC X(7)  VALUE ": DEP=$".
           05 SUB-DEP            PIC ZZ,ZZZ,ZZ9.99.
           05 FILLER             PIC X(8)  VALUE " | EXT=$".
           05 SUB-EXT            PIC ZZ,ZZZ,ZZ9.99.

       01  REP-TOTAL-GLOBAL.
           05 FILLER             PIC X(20) VALUE "PROCESADOS EXITOSOS:".
           05 GLOB-PROCESADOS    PIC ZZ,ZZ9.
           05 FILLER             PIC X(15) VALUE " | RECHAZADOS: ".
           05 GLOB-RECHAZADOS    PIC ZZ,ZZ9.

       PROCEDURE DIVISION.
      *----------------------------------------------------------------*
      * 1000-MAIN: Flujo principal de ejecucion del programa.
      *----------------------------------------------------------------*
       1000-MAIN.
           PERFORM 1100-INICIALIZAR.
           PERFORM 2000-PROCESAR-LOTE UNTIL FIN-MAE AND FIN-NOV.
           PERFORM 3000-FINALIZAR.
           STOP RUN.

      *----------------------------------------------------------------*
      * 1100-INICIALIZAR: Apertura de archivos, lectura inicial y      *
      *                   escritura de cabeceras.                      *
      *----------------------------------------------------------------*
       1100-INICIALIZAR.
           OPEN INPUT  MAESTRO-ENTRADA NOVEDADES-ENTRADA
                OUTPUT MAESTRO-SALIDA RECHAZOS-SALIDA REPORTE-SALIDA.

           WRITE REG-REP-SAL FROM REP-CABECERA.
           WRITE REG-REP-SAL
                 FROM "================================================".

      *> Carga inicial de registros (Prime Read)
           PERFORM 1200-LEER-MAESTRO.
           PERFORM 1300-LEER-NOVEDAD.

           IF NOT FIN-NOV
               MOVE WS-SUCURSAL-NUM TO WS-SUCURSAL-PREVIA
           END-IF.

      *----------------------------------------------------------------*
      * 1200-LEER-MAESTRO: Lee el maestro e higieniza caracteres invisibles.*
      *----------------------------------------------------------------*
       1200-LEER-MAESTRO.
           IF NOT FIN-MAE
               READ MAESTRO-ENTRADA
                   AT END
                       SET FIN-MAE TO TRUE
                       MOVE 999999 TO MAE-ENT-CUENTA
                   NOT AT END
                       MOVE REG-MAE-ENT TO WS-MAESTRO-ACTUAL
      *> Limpieza de caracteres de salto de linea estilo Windows (\r\n)
                    INSPECT WS-MAE-ESTADO REPLACING ALL x"0D" BY SPACES
                    INSPECT WS-MAE-ESTADO REPLACING ALL x"0A" BY SPACES
               END-READ
           END-IF.

      *----------------------------------------------------------------*
      * 1300-LEER-NOVEDAD: Lee la novedad y convierte sucursal a entero.*
      *----------------------------------------------------------------*
       1300-LEER-NOVEDAD.
           IF NOT FIN-NOV
               READ NOVEDADES-ENTRADA
                   AT END
                       SET FIN-NOV TO TRUE
                       MOVE 999999 TO NOV-ENT-CUENTA
                   NOT AT END
                       IF NOV-ENT-SUCURSAL-X IS NUMERIC
                           MOVE NOV-ENT-SUCURSAL-X TO WS-SUCURSAL-NUM
                       ELSE
                           COMPUTE WS-SUCURSAL-NUM =
                                   FUNCTION NUMVAL(NOV-ENT-SUCURSAL-X)
                       END-IF
               END-READ
           END-IF.

      *----------------------------------------------------------------*
      * 2000-PROCESAR-LOTE: Algoritmo Balance Line (Apareamiento por  *
      *                     llave primaria: Nro de Cuenta).            *
      *----------------------------------------------------------------*
       2000-PROCESAR-LOTE.
           EVALUATE TRUE
      *> CASO 1: Coincidencia de llave. Se aplica la novedad a la cuenta.
               WHEN MAE-ENT-CUENTA = NOV-ENT-CUENTA
                   PERFORM 2100-APLICAR-TRANSACCION
                   PERFORM 1300-LEER-NOVEDAD

      *> CASO 2: La cuenta no tiene mas novedades. Se graba y avanza maestro.
               WHEN MAE-ENT-CUENTA < NOV-ENT-CUENTA
                   PERFORM 2200-GRABAR-MAESTRO
                   PERFORM 1200-LEER-MAESTRO

      *> CASO 3: Novedad para una cuenta que no existe en el maestro.
               WHEN MAE-ENT-CUENTA > NOV-ENT-CUENTA
                   PERFORM 2300-RECHAZAR-CUENTA-INEX
                   PERFORM 1300-LEER-NOVEDAD
           END-EVALUATE.

      *----------------------------------------------------------------*
      * 2100-APLICAR-TRANSACCION: Valida reglas de negocio y actualiza *
      *                           el saldo en memoria si es correcto.  *
      *----------------------------------------------------------------*
       2100-APLICAR-TRANSACCION.
           SET NOV-VALIDA TO TRUE.

      *> 1. Control de cambio de sucursal para corte de control
           IF WS-SUCURSAL-NUM NOT = WS-SUCURSAL-PREVIA
               IF WS-SUBTOT-DEPOSITO > 0 OR WS-SUBTOT-EXTRA > 0
                   PERFORM 2400-IMPRIMIR-CORTE-SUCURSAL
               ELSE
                   MOVE WS-SUCURSAL-NUM TO WS-SUCURSAL-PREVIA
               END-IF
           END-IF.

      *> 2. Validacion de Estado Activo usando la regla 88 (MAE-ACTIVO)
           IF NOT MAE-ACTIVO
               SET NOV-INVALIDA TO TRUE
               MOVE "CUENTA BLOQUEADA   " TO WS-MOTIVO-TEMP
               PERFORM 2350-GRABAR-RECHAZO
           END-IF.

      *> 3. Validacion de Saldo Suficiente para Extracciones
           IF NOV-VALIDA AND NOV-ENT-TIPO = 'E'
               AND WS-MAE-SALDO < NOV-ENT-IMPORTE
               SET NOV-INVALIDA TO TRUE
               MOVE "SALDO INSUFICIENTE " TO WS-MOTIVO-TEMP
               PERFORM 2350-GRABAR-RECHAZO
           END-IF.

      *> 4. Aplicacion de la Operacion Financiera
           IF NOV-VALIDA
               EVALUATE NOV-ENT-TIPO
                   WHEN 'D'
                       ADD NOV-ENT-IMPORTE TO WS-MAE-SALDO
                       ADD NOV-ENT-IMPORTE TO WS-SUBTOT-DEPOSITO
                       ADD NOV-ENT-IMPORTE TO WS-IMP-DEPOSITOS
                       MOVE "DEPOSITO  " TO DET-TIPO
                   WHEN 'E'
                       SUBTRACT NOV-ENT-IMPORTE FROM WS-MAE-SALDO
                       ADD NOV-ENT-IMPORTE TO WS-SUBTOT-EXTRA
                       ADD NOV-ENT-IMPORTE TO WS-IMP-EXTRACCIONES
                       MOVE "EXTRACCION" TO DET-TIPO
                   WHEN OTHER
                       SET NOV-INVALIDA TO TRUE
                       MOVE "TIPO OP INVALIDO  " TO WS-MOTIVO-TEMP
                       PERFORM 2350-GRABAR-RECHAZO
               END-EVALUATE
           END-IF.

      *> 5. Registro de la linea exitosa en el informe de auditoria
           IF NOV-VALIDA
               ADD 1 TO WS-TOT-PROCESADOS
               MOVE WS-SUCURSAL-NUM TO DET-SUCURSAL
               MOVE NOV-ENT-CUENTA   TO DET-CUENTA
               MOVE NOV-ENT-IMPORTE  TO DET-IMPORTE
               WRITE REG-REP-SAL FROM REP-DETALLE
           END-IF.

      *----------------------------------------------------------------*
      * 2200-GRABAR-MAESTRO: Vuelca el registro actualizado al archivo.*
      *----------------------------------------------------------------*
       2200-GRABAR-MAESTRO.
           IF NOT FIN-MAE
               MOVE WS-MAESTRO-ACTUAL TO REG-MAE-SAL
               WRITE REG-MAE-SAL
           END-IF.

      *----------------------------------------------------------------*
      * 2300-RECHAZAR-CUENTA-INEX: Transacción sin cuenta en maestro.  *
      *----------------------------------------------------------------*
       2300-RECHAZAR-CUENTA-INEX.
           SET NOV-INVALIDA TO TRUE.
           MOVE "CUENTA INEXISTENTE " TO WS-MOTIVO-TEMP.
           PERFORM 2350-GRABAR-RECHAZO.

      *----------------------------------------------------------------*
      * 2350-GRABAR-RECHAZO: Escribe el registro en el log de fallos.  *
      *----------------------------------------------------------------*
       2350-GRABAR-RECHAZO.
           ADD 1 TO WS-TOT-RECHAZADOS.
           MOVE REG-NOV-ENT    TO REC-SAL-NOV.
           MOVE WS-MOTIVO-TEMP TO REC-SAL-MOTIVO.
           WRITE REG-REC-SAL.

      *----------------------------------------------------------------*
      * 2400-IMPRIMIR-CORTE-SUCURSAL: Emision de subtotales por sucursal.*
      *----------------------------------------------------------------*
       2400-IMPRIMIR-CORTE-SUCURSAL.
           MOVE WS-SUCURSAL-PREVIA TO SUB-SUCURSAL.
           MOVE WS-SUBTOT-DEPOSITO TO SUB-DEP.
           MOVE WS-SUBTOT-EXTRA    TO SUB-EXT.
           WRITE REG-REP-SAL FROM REP-SUBTOTAL.
           WRITE REG-REP-SAL FROM "----------------------------------".
           MOVE WS-SUCURSAL-NUM TO WS-SUCURSAL-PREVIA.
           MOVE 0 TO WS-SUBTOT-DEPOSITO WS-SUBTOT-EXTRA.

      *----------------------------------------------------------------*
      * 3000-FINALIZAR: Cierre de proceso, totales generales y return-code.*
      *----------------------------------------------------------------*
       3000-FINALIZAR.
      *> Imprimir el ultimo corte pendiente si existieron operaciones
           IF WS-SUBTOT-DEPOSITO > 0 OR WS-SUBTOT-EXTRA > 0
               PERFORM 2400-IMPRIMIR-CORTE-SUCURSAL
           END-IF.

           WRITE REG-REP-SAL FROM "==================================".
           WRITE REG-REP-SAL FROM "RESUMEN GLOBAL DE AUDITORIA:".

           MOVE WS-TOT-PROCESADOS TO GLOB-PROCESADOS.
           MOVE WS-TOT-RECHAZADOS TO GLOB-RECHAZADOS.
           WRITE REG-REP-SAL FROM REP-TOTAL-GLOBAL.

           CLOSE MAESTRO-ENTRADA NOVEDADES-ENTRADA MAESTRO-SALIDA
                 RECHAZOS-SALIDA REPORTE-SALIDA.

      *> Codigo de retorno batch (Return Code 4 indica advertencia/rechazos)
           IF WS-TOT-RECHAZADOS > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
