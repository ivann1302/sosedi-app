import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';
import { ApiError } from '../http/api-response';
import { redactSensitiveData } from '../logging/sensitive-data-redactor';

type NestErrorResponse = {
  code?: string;
  error?: string;
  message?: string | string[];
};

type TransportError = Error & {
  status?: unknown;
  statusCode?: unknown;
};

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : this.getTransportStatus(exception);

    if (status >= 500 && exception instanceof Error) {
      console.error(redactSensitiveData(exception));
    }

    response.status(status).json({
      success: false,
      data: null,
      error: this.getError(exception, status),
    });
  }

  private getError(exception: unknown, status: number): ApiError {
    if (!(exception instanceof HttpException)) {
      if (status === Number(HttpStatus.PAYLOAD_TOO_LARGE)) {
        return {
          code: 'PAYLOAD_TOO_LARGE',
          message: 'Тело запроса превышает допустимый размер',
        };
      }

      return {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'Внутренняя ошибка сервера',
      };
    }

    const body = exception.getResponse();
    if (typeof body === 'string') {
      return {
        code: this.getCodeByStatus(status),
        message: body,
      };
    }

    const errorBody = body as NestErrorResponse;
    const message = Array.isArray(errorBody.message)
      ? errorBody.message.join('; ')
      : (errorBody.message ?? exception.message);

    return {
      code: errorBody.code ?? this.getCodeByStatus(status, errorBody.error),
      message,
    };
  }

  private getCodeByStatus(status: number, fallback?: string): string {
    if (status === Number(HttpStatus.BAD_REQUEST)) {
      return 'VALIDATION_ERROR';
    }

    if (fallback) {
      return fallback.toUpperCase().replace(/\s+/g, '_');
    }

    return HttpStatus[status] ?? 'HTTP_ERROR';
  }

  private getTransportStatus(exception: unknown): number {
    if (!(exception instanceof Error)) {
      return HttpStatus.INTERNAL_SERVER_ERROR;
    }

    const transportError = exception as TransportError;
    const status =
      typeof transportError.status === 'number'
        ? transportError.status
        : transportError.statusCode;
    if (
      typeof status === 'number' &&
      Number.isInteger(status) &&
      status >= 400 &&
      status < 500
    ) {
      return status;
    }

    return HttpStatus.INTERNAL_SERVER_ERROR;
  }
}
