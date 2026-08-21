import { TestBed } from '@angular/core/testing';

import { CoreBanking } from './core-banking';

describe('CoreBanking', () => {
  let service: CoreBanking;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(CoreBanking);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
