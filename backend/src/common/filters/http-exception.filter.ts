import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';
import { ApiError } from '../http/api-response';

type NestErrorResponse = {
  code?: string;
  error?: string;
  message?: string | string[];
};

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    if (!(exception instanceof HttpException) && exception instanceof Error) {
      console.error(exception);
    }

    response.status(status).json({
      success: false,
      data: null,
      error: this.getError(exception, status),
    });
  }

  private getError(exception: unknown, status: number): ApiError {
    if (!(exception instanceof HttpException)) {
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
}
