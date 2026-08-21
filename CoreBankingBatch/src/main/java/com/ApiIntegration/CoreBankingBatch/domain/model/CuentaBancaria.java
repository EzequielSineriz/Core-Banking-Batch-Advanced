package com.ApiIntegration.CoreBankingBatch.domain.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CuentaBancaria {
    private String nroCuenta;
    private String titular;
    private BigDecimal saldo;
    private String estado;
}