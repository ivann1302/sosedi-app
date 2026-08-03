import {
  ConsoleLogger,
  type LoggerService,
  type LogLevel,
} from '@nestjs/common';
import { redactSensitiveData } from './sensitive-data-redactor';

export class RedactingLogger implements LoggerService {
  constructor(private readonly delegate: LoggerService = new ConsoleLogger()) {}

  log(message: unknown, ...optionalParams: unknown[]): void {
    this.delegate.log(
      redactSensitiveData(message),
      ...this.redactParams(optionalParams),
    );
  }

  error(message: unknown, ...optionalParams: unknown[]): void {
    this.delegate.error(
      redactSensitiveData(message),
      ...this.redactParams(optionalParams),
    );
  }

  warn(message: unknown, ...optionalParams: unknown[]): void {
    this.delegate.warn(
      redactSensitiveData(message),
      ...this.redactParams(optionalParams),
    );
  }

  debug(message: unknown, ...optionalParams: unknown[]): void {
    this.delegate.debug?.(
      redactSensitiveData(message),
      ...this.redactParams(optionalParams),
    );
  }

  verbose(message: unknown, ...optionalParams: unknown[]): void {
    this.delegate.verbose?.(
      redactSensitiveData(message),
      ...this.redactParams(optionalParams),
    );
  }

  fatal(message: unknown, ...optionalParams: unknown[]): void {
    this.delegate.fatal?.(
      redactSensitiveData(message),
      ...this.redactParams(optionalParams),
    );
  }

  setLogLevels(levels: LogLevel[]): void {
    this.delegate.setLogLevels?.(levels);
  }

  private redactParams(params: unknown[]): unknown[] {
    return params.map((param) => redactSensitiveData(param));
  }
}
