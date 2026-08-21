package com.ApiIntegration.CoreBankingBatch.infrastructure.adapter;

import com.ApiIntegration.CoreBankingBatch.domain.model.CuentaBancaria;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Component
public class CobolMasterAdapter {
    private static final String MASTER_FILE_PATH = "../bin/output/maestro_actualizado.dat";

    public List<CuentaBancaria> leerMaestroActualizado() throws IOException {
        List<CuentaBancaria> cuentas = new ArrayList<>();

        try (BufferedReader reader = new BufferedReader(new FileReader(MASTER_FILE_PATH))) {
            String linea;
            while ((linea = reader.readLine()) != null) {
                if (linea.length() >= 40) {
                    // Extracción por posiciones fijas (Copybook COBOL Layout)
                    String nroCuenta = linea.substring(0, 6).trim();
                    String titular = linea.substring(6, 26).trim();
                    String saldoRaw = linea.substring(26, 36).trim(); // PIC 9(8)V99
                    String estado = linea.substring(36, 40).trim();

                    // Conversión de formato decimal implícito de COBOL a BigDecimal
                    BigDecimal saldo = new BigDecimal(saldoRaw).divide(new BigDecimal(100));

                    cuentas.add(new CuentaBancaria(nroCuenta, titular, saldo, estado));
                }
            }
        }
        return cuentas;
    }
}
