package com.ApiIntegration.CoreBankingBatch.infrastructure.api;

import com.ApiIntegration.CoreBankingBatch.domain.model.CuentaBancaria;
import com.ApiIntegration.CoreBankingBatch.infrastructure.adapter.CobolMasterAdapter;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;

@Service
public class CuentaService {

    private final CobolMasterAdapter cobolAdapter;

    public CuentaService(CobolMasterAdapter cobolAdapter) {
        this.cobolAdapter = cobolAdapter;
    }

    public List<CuentaBancaria> obtenerCuentasProcesadas() throws IOException {
        // En esta capa se pueden aplicar filtros de negocio,
        // ordenamiento o auditoría antes de devolver al controlador
        return cobolAdapter.leerMaestroActualizado();
    }
}