package com.ApiIntegration.CoreBankingBatch.infrastructure.api.dto;

import java.math.BigDecimal;

public record CuentaResponseDto(
        String nroCuenta,
        String titular,
        BigDecimal saldo,
        String estado,
        boolean activa
) {
    // Constructor estático para transformar el Modelo al DTO
    public static CuentaResponseDto fromDomain(com.ApiIntegration.CoreBankingBatch.domain.model.CuentaBancaria domain) {
        boolean esActiva = "ACTI".equalsIgnoreCase(domain.getEstado());
        return new CuentaResponseDto(
                domain.getNroCuenta(),
                domain.getTitular(),
                domain.getSaldo(),
                domain.getEstado(),
                esActiva
        );
    }
}