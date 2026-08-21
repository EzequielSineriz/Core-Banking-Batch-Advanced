package com.ApiIntegration.CoreBankingBatch.infrastructure.api;

import com.ApiIntegration.CoreBankingBatch.infrastructure.adapter.CobolMasterAdapter;
import com.ApiIntegration.CoreBankingBatch.infrastructure.api.dto.CuentaResponseDto;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/core-banking")
@CrossOrigin(origins = "*")
public class CuentaController {

    private final CuentaService cuentaService;

    public CuentaController(CuentaService cuentaService) {
        this.cuentaService = cuentaService;
    }

    @GetMapping("/maestro-saldos")
    public ResponseEntity<List<CuentaResponseDto>> getMaestroSaldos() {
        try {
            List<CuentaResponseDto> response = cuentaService.obtenerCuentasProcesadas()
                    .stream()
                    .map(CuentaResponseDto::fromDomain)
                    .toList();

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }
}