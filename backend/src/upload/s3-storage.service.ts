import {
  DeleteObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from '@aws-sdk/client-s3';
import { createPresignedPost } from '@aws-sdk/s3-presigned-post';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { StoredObject, UploadedObjectInfo } from './upload.types';

@Injectable()
export class S3StorageService {
  private client: S3Client | null = null;

  constructor(private readonly config: ConfigService) {}

  async createPresignedPostUpload(
    bucket: string,
    key: string,
    contentType: string,
    sizeBytes: number,
    expiresInSeconds: number,
  ): Promise<{ uploadUrl: string; fields: Record<string, string> }> {
    const presignedPost = await createPresignedPost(this.getClient(), {
      Bucket: bucket,
      Key: key,
      Fields: {
        'Content-Type': contentType,
      },
      Conditions: [['content-length-range', sizeBytes, sizeBytes]],
      Expires: expiresInSeconds,
    });

    return {
      uploadUrl: presignedPost.url,
      fields: presignedPost.fields,
    };
  }

  async createPresignedDownloadUrl(
    bucket: string,
    key: string,
    expiresInSeconds: number,
  ): Promise<string> {
    return getSignedUrl(
      this.getClient(),
      new GetObjectCommand({
        Bucket: bucket,
        Key: key,
      }),
      { expiresIn: expiresInSeconds },
    );
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

  async inspectUploadedObject(
    bucket: string,
    key: string,
  ): Promise<UploadedObjectInfo | null> {
    try {
      const metadata = await this.getClient().send(
        new HeadObjectCommand({
          Bucket: bucket,
          Key: key,
        }),
      );
      let prefix = Buffer.alloc(0);
      if (metadata.ContentLength && metadata.ContentLength > 0) {
        const object = await this.getClient().send(
          new GetObjectCommand({
            Bucket: bucket,
            Key: key,
            Range: 'bytes=0-11',
          }),
        );
        prefix = object.Body
          ? Buffer.from(await object.Body.transformToByteArray())
          : Buffer.alloc(0);
      }

      return {
        sizeBytes: metadata.ContentLength ?? null,
        contentType: metadata.ContentType ?? null,
        prefix,
      };
    } catch (error) {
      if (this.isNotFound(error)) {
        return null;
      }
      throw error;
    }
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

  async deleteObject(bucket: string, key: string): Promise<void> {
    await this.getClient().send(
      new DeleteObjectCommand({
        Bucket: bucket,
        Key: key,
      }),
    );
  }

  async listObjects(bucket: string, prefix: string): Promise<StoredObject[]> {
    const objects: StoredObject[] = [];
    let continuationToken: string | undefined;

    do {
      const response = await this.getClient().send(
        new ListObjectsV2Command({
          Bucket: bucket,
          Prefix: prefix,
          ContinuationToken: continuationToken,
        }),
      );
      for (const object of response.Contents ?? []) {
        if (object.Key) {
          objects.push({
            key: object.Key,
            lastModified: object.LastModified ?? null,
          });
        }
      }
      continuationToken = response.IsTruncated
        ? response.NextContinuationToken
        : undefined;
    } while (continuationToken);

    return objects;
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

  private isNotFound(error: unknown): boolean {
    if (typeof error !== 'object' || error === null) {
      return false;
    }

    const candidate = error as {
      name?: string;
      $metadata?: { httpStatusCode?: number };
    };
    return (
      candidate.name === 'NotFound' ||
      candidate.name === 'NoSuchKey' ||
      candidate.$metadata?.httpStatusCode === 404
    );
  }

  private getRequiredConfig(key: string): string {
    const value = this.config.get<string>(key);

    if (!value) {
      throw new InternalServerErrorException(`Не настроен ${key}`);
    }

    return value;
  }
}
