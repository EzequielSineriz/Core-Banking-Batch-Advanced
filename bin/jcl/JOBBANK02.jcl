//BANK002J JOB (ACCT01),'BANK002 EXECUTION',
//             CLASS=A,
//             MSGCLASS=X,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID
//*
//*********************************************************************
//* JOB: BANK002J                                                     *
//* DESCRIPCION: PROCESAMIENTO BATCH MAESTRO Y AUDITORIA BANCARIA     *
//* APLICACION: CORE BANKING                                          *
//*********************************************************************
//*
//* ------------------------------------------------------------------*
//* PASO 1: BORRADO PREVIO DE ARCHIVOS DE SALIDA (IDCAMS)             *
//* ------------------------------------------------------------------*
//CLEANUP  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE PRD.BANK.MAESTRO.SALIDA PURGE
  DELETE PRD.BANK.RECHAZOS.SALIDA PURGE
  DELETE PRD.BANK.REPORTE.AUDITORIA PURGE
  SET MAXCC = 0
/*
//*
//* ------------------------------------------------------------------*
//* PASO 2: EJECUCION DEL PROGRAMA COBOL BANK002                      *
//* ------------------------------------------------------------------*
//STEP010  EXEC PGM=BANK002
//STEPLIB  DD DSN=PRD.BANK.LOADLIB,DISP=SHR
//*
//* --- ARCHIVOS DE ENTRADA ---
//MAEENT   DD DSN=PRD.BANK.MAESTRO.ENTRADA,
//            DISP=SHR
//NOVENT   DD DSN=PRD.BANK.NOVEDADES.ENTRADA,
//            DISP=SHR
//*
//* --- ARCHIVOS DE SALIDA ---
//MAESAL   DD DSN=PRD.BANK.MAESTRO.SALIDA,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(TRK,(10,5),RLSE),
//            DCB=(RECFM=FB,LRECL=40,BLKSIZE=0)
//*
//RECSAL   DD DSN=PRD.BANK.RECHAZOS.SALIDA,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(TRK,(5,2),RLSE),
//            DCB=(RECFM=FB,LRECL=41,BLKSIZE=0)
//*
//REPSAL   DD DSN=PRD.BANK.REPORTE.AUDITORIA,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(TRK,(15,5),RLSE),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=0)
//*
//* --- SALIDAS DE SISTEMA Y TRACE ---
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//