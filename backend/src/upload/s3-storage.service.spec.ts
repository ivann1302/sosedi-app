import { GetObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';
import { ConfigService } from '@nestjs/config';
import { S3StorageService } from './s3-storage.service';

type PostPolicy = {
  expiration: string;
  conditions: unknown[];
};

describe('S3StorageService', () => {
  afterEach(() => {
    jest.useRealTimers();
  });

  it('signs an exact short-lived POST policy for bucket, key, MIME and size', async () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-07-28T12:00:00.000Z'));
    const service = new S3StorageService(
      new ConfigService({
        S3_ENDPOINT: 'https://storage.yandexcloud.net',
        S3_REGION: 'ru-central1',
        S3_ACCESS_KEY: 'test-access-key',
        S3_SECRET_KEY: 'test-secret-key',
      }),
    );

    const result = await service.createPresignedPostUpload(
      'sosedi-public',
      'items/item-1/original/photo.png',
      'image/png',
      1024,
      900,
    );
    const policy = JSON.parse(
      Buffer.from(result.fields.Policy, 'base64').toString('utf8'),
    ) as PostPolicy;

    expect(result.fields).toMatchObject({
      bucket: 'sosedi-public',
      key: 'items/item-1/original/photo.png',
      'Content-Type': 'image/png',
    });
    expect(policy.expiration).toBe('2026-07-28T12:15:00Z');
    expect(policy.conditions).toEqual(
      expect.arrayContaining([
        { bucket: 'sosedi-public' },
        { key: 'items/item-1/original/photo.png' },
        { 'Content-Type': 'image/png' },
        ['content-length-range', 1024, 1024],
      ]),
    );
  });

  it('reads object metadata and only the bytes needed for signature validation', async () => {
    const service = new S3StorageService(new ConfigService());
    const send = jest
      .fn()
      .mockResolvedValueOnce({
        ContentLength: 1024,
        ContentType: 'image/png',
      })
      .mockResolvedValueOnce({
        Body: {
          transformToByteArray: () =>
            Promise.resolve(
              Uint8Array.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
            ),
        },
      });
    (
      service as unknown as {
        client: { send: typeof send };
      }
    ).client = { send };

    await expect(
      service.inspectUploadedObject(
        'public-bucket',
        'items/item-1/original/photo.png',
      ),
    ).resolves.toEqual({
      sizeBytes: 1024,
      contentType: 'image/png',
      prefix: Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    });
    expect(send).toHaveBeenNthCalledWith(1, expect.any(HeadObjectCommand));
    expect(send).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        input: {
          Bucket: 'public-bucket',
          Key: 'items/item-1/original/photo.png',
          Range: 'bytes=0-11',
        },
      }) as GetObjectCommand,
    );
  });

  it('reports a missing object without hiding other storage failures', async () => {
    const service = new S3StorageService(new ConfigService());
    const outage = new Error('S3 unavailable');
    const send = jest
      .fn()
      .mockRejectedValueOnce({ $metadata: { httpStatusCode: 404 } })
      .mockRejectedValueOnce(outage);
    (
      service as unknown as {
        client: { send: typeof send };
      }
    ).client = { send };

    await expect(
      service.inspectUploadedObject('public-bucket', 'missing.jpg'),
    ).resolves.toBeNull();
    await expect(
      service.inspectUploadedObject('public-bucket', 'pending.jpg'),
    ).rejects.toBe(outage);
  });
});
