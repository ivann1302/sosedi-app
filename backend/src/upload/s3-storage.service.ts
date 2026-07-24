import {
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class S3StorageService {
  private client: S3Client | null = null;

  constructor(private readonly config: ConfigService) {}

  async createPresignedPutUrl(
    bucket: string,
    key: string,
    contentType: string,
    expiresInSeconds: number,
  ): Promise<string> {
    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      ContentType: contentType,
    });

    return getSignedUrl(this.getClient(), command, {
      expiresIn: expiresInSeconds,
    });
  }

  async getObjectBuffer(bucket: string, key: string): Promise<Buffer> {
    const response = await this.getClient().send(
      new GetObjectCommand({
        Bucket: bucket,
        Key: key,
      }),
    );

    if (!response.Body) {
      throw new InternalServerErrorException('Файл не найден в S3');
    }

    const bytes = await response.Body.transformToByteArray();
    return Buffer.from(bytes);
  }

  async putObject(
    bucket: string,
    key: string,
    body: Buffer,
    contentType: string,
  ): Promise<void> {
    await this.getClient().send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
      }),
    );
  }

  getPublicBucket(): string {
    return this.getRequiredConfig('S3_BUCKET_PUBLIC');
  }

  getPrivateBucket(): string {
    return this.getRequiredConfig('S3_BUCKET_PRIVATE');
  }

  getPublicUrl(bucket: string, key: string): string {
    const publicBaseUrl = this.config.get<string>('S3_PUBLIC_BASE_URL');

    if (publicBaseUrl) {
      return `${publicBaseUrl.replace(/\/$/, '')}/${key}`;
    }

    const endpoint = this.getRequiredConfig('S3_ENDPOINT').replace(/\/$/, '');
    return `${endpoint}/${bucket}/${key}`;
  }

  private getClient(): S3Client {
    if (!this.client) {
      this.client = new S3Client({
        endpoint: this.getRequiredConfig('S3_ENDPOINT'),
        region: this.getRequiredConfig('S3_REGION'),
        credentials: {
          accessKeyId: this.getRequiredConfig('S3_ACCESS_KEY'),
          secretAccessKey: this.getRequiredConfig('S3_SECRET_KEY'),
        },
        forcePathStyle:
          this.config.get<string>('S3_FORCE_PATH_STYLE') !== 'false',
      });
    }

    return this.client;
  }

  private getRequiredConfig(key: string): string {
    const value = this.config.get<string>(key);

    if (!value) {
      throw new InternalServerErrorException(`Не настроен ${key}`);
    }

    return value;
  }
}
