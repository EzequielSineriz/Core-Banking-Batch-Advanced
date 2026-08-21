import { Component, inject, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CoreBankingService } from './services/core-banking';
import { CommonModule, CurrencyPipe } from '@angular/common';

@Component({
  selector: 'app-root',
  imports: [CommonModule, CurrencyPipe],
templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  protected readonly title = signal('frontend-dashboard');

  public service = inject(CoreBankingService);

  ngOnInit() {
    this.service.cargarMaestroSaldos();
  }
}
