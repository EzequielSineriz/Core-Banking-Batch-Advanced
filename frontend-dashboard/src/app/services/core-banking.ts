import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';

export interface CuentaBancaria {
  nroCuenta: string;
  titular: string;
  saldo: number;
  estado: string;
  activa: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class CoreBankingService {
  private http = inject(HttpClient);
  private apiUrl = 'http://localhost:8080/api/v1/core-banking/maestro-saldos';

  // Estados Reactivos con Signals
  public cuentas = signal<CuentaBancaria[]>([]);
  public loading = signal<boolean>(false);
  public error = signal<string | null>(null);

  cargarMaestroSaldos(): void {
    this.loading.set(true);
    this.error.set(null);

    this.http.get<CuentaBancaria[]>(this.apiUrl).subscribe({
      next: (data) => {
        this.cuentas.set(data);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Error al conectar con la API Core:', err);
        this.error.set('No se pudo conectar con el Backend Spring Boot / Archivo COBOL.');
        this.loading.set(false);
      }
    });
  }
}
