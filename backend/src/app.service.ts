import { Injectable } from '@nestjs/common';

export type HealthResponse = {
  status: 'ok';
};

@Injectable()
export class AppService {
  getHealth(): HealthResponse {
    return { status: 'ok' };
  }
}
