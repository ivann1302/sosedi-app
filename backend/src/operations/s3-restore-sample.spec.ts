import {
  GetObjectCommand,
  PutObjectCommand,
  type S3Client,
} from '@aws-sdk/client-s3';
import { createHash } from 'node:crypto';
import {
  requireDistinctRestoreIdentities,
  restoreS3Sample,
} from './s3-restore-sample';

const sample = Buffer.from('synthetic private evidence sample');
const checksum = createHash('sha256').update(sample).digest('hex');

function body(bytes: Buffer) {
  return {
    transformToByteArray: jest.fn().mockResolvedValue(Uint8Array.from(bytes)),
  };
}

describe('S3 restore sample', () => {
  it('requires separate scoped source and target identities', () => {
    expect(() =>
      requireDistinctRestoreIdentities('restore-reader', 'restore-writer'),
    ).not.toThrow();
    expect(() =>
      requireDistinctRestoreIdentities('shared-identity', 'shared-identity'),
    ).toThrow('must use distinct scoped identities');
  });

  it('restores one checksum-bound object into an explicitly confirmed isolated prefix', async () => {
    const sourceClient = {
      send: jest.fn().mockResolvedValue({
        Body: body(sample),
        ContentLength: sample.length,
        ContentType: 'image/webp',
      }),
    };
    const targetClient = {
      send: jest.fn((command: unknown) => {
        if (command instanceof PutObjectCommand) {
          return Promise.resolve({});
        }
        if (command instanceof GetObjectCommand) {
          return Promise.resolve({
            Body: body(sample),
            ContentLength: sample.length,
          });
        }
        throw new Error('Unexpected command');
      }),
    };

    const result = await restoreS3Sample(
      {
        sourceBucket: 'secondary-private-backup',
        sourceKey: 'objects/evidence-1.webp',
        sourceVersionId: 'version-42',
        expectedSha256: checksum,
        targetBucket: 'sosedi-restore-isolated',
        targetPrefix: 'sosedi-restore-sample/drill-42',
        targetConfirmation:
          'sosedi-restore-isolated/sosedi-restore-sample/drill-42',
      },
      sourceClient as unknown as S3Client,
      targetClient as unknown as S3Client,
    );

    expect(sourceClient.send).toHaveBeenCalledWith(
      expect.objectContaining({
        input: {
          Bucket: 'secondary-private-backup',
          Key: 'objects/evidence-1.webp',
          VersionId: 'version-42',
        },
      }),
    );
    const put = targetClient.send.mock.calls[0]?.[0];
    expect(put).toBeInstanceOf(PutObjectCommand);
    if (!(put instanceof PutObjectCommand)) {
      throw new Error('Expected a restore PutObject command');
    }
    expect(put.input).toMatchObject({
      Bucket: 'sosedi-restore-isolated',
      Key: `sosedi-restore-sample/drill-42/${checksum.slice(0, 16)}.sample`,
      Body: sample,
      ContentType: 'image/webp',
      ServerSideEncryption: 'AES256',
      Metadata: {
        restoredsha256: checksum,
        sourcekeysha256: createHash('sha256')
          .update('objects/evidence-1.webp')
          .digest('hex'),
      },
    });
    expect(result).toEqual({
      sha256: checksum,
      sizeBytes: sample.length,
      sourceKeySha256: createHash('sha256')
        .update('objects/evidence-1.webp')
        .digest('hex'),
      targetKey: `sosedi-restore-sample/drill-42/${checksum.slice(0, 16)}.sample`,
    });
  });

  it('does not write a target object when the backup checksum mismatches', async () => {
    const sourceClient = {
      send: jest.fn().mockResolvedValue({
        Body: body(sample),
        ContentLength: sample.length,
      }),
    };
    const targetClient = { send: jest.fn() };

    await expect(
      restoreS3Sample(
        {
          sourceBucket: 'secondary-private-backup',
          sourceKey: 'objects/evidence-1.webp',
          expectedSha256: 'a'.repeat(64),
          targetBucket: 'sosedi-restore-isolated',
          targetPrefix: 'sosedi-restore-sample/drill-42',
          targetConfirmation:
            'sosedi-restore-isolated/sosedi-restore-sample/drill-42',
        },
        sourceClient as unknown as S3Client,
        targetClient as unknown as S3Client,
      ),
    ).rejects.toThrow('Source object checksum mismatch');
    expect(targetClient.send).not.toHaveBeenCalled();
  });

  it('fails when the isolated target does not return the same bytes', async () => {
    const sourceClient = {
      send: jest.fn().mockResolvedValue({
        Body: body(sample),
        ContentLength: sample.length,
      }),
    };
    const targetClient = {
      send: jest
        .fn()
        .mockResolvedValueOnce({})
        .mockResolvedValueOnce({
          Body: body(Buffer.from('corrupted')),
          ContentLength: Buffer.byteLength('corrupted'),
        }),
    };

    await expect(
      restoreS3Sample(
        {
          sourceBucket: 'secondary-private-backup',
          sourceKey: 'objects/evidence-1.webp',
          expectedSha256: checksum,
          targetBucket: 'sosedi-restore-isolated',
          targetPrefix: 'sosedi-restore-sample/drill-42',
          targetConfirmation:
            'sosedi-restore-isolated/sosedi-restore-sample/drill-42',
        },
        sourceClient as unknown as S3Client,
        targetClient as unknown as S3Client,
      ),
    ).rejects.toThrow('Restored object checksum mismatch');
  });

  it('rejects an object without bounded size metadata before reading its body', async () => {
    const sourceBody = body(sample);
    const sourceClient = {
      send: jest.fn().mockResolvedValue({ Body: sourceBody }),
    };
    const targetClient = { send: jest.fn() };

    await expect(
      restoreS3Sample(
        {
          sourceBucket: 'secondary-private-backup',
          sourceKey: 'objects/evidence-1.webp',
          expectedSha256: checksum,
          targetBucket: 'sosedi-restore-isolated',
          targetPrefix: 'sosedi-restore-sample/drill-42',
          targetConfirmation:
            'sosedi-restore-isolated/sosedi-restore-sample/drill-42',
        },
        sourceClient as unknown as S3Client,
        targetClient as unknown as S3Client,
      ),
    ).rejects.toThrow('bounded ContentLength');
    expect(sourceBody.transformToByteArray).not.toHaveBeenCalled();
    expect(targetClient.send).not.toHaveBeenCalled();
  });

  it('rejects a broad or unconfirmed target before S3 I/O', async () => {
    const sourceClient = { send: jest.fn() };
    const targetClient = { send: jest.fn() };

    await expect(
      restoreS3Sample(
        {
          sourceBucket: 'secondary-private-backup',
          sourceKey: 'objects/evidence-1.webp',
          expectedSha256: checksum,
          targetBucket: 'sosedi-restore-isolated',
          targetPrefix: 'sosedi-restore-sample',
          targetConfirmation: 'wrong-target',
        },
        sourceClient as unknown as S3Client,
        targetClient as unknown as S3Client,
      ),
    ).rejects.toThrow('isolated restore target');
    expect(sourceClient.send).not.toHaveBeenCalled();
    expect(targetClient.send).not.toHaveBeenCalled();
  });

  it('rejects restoring into the source bucket before S3 I/O', async () => {
    const sourceClient = { send: jest.fn() };
    const targetClient = { send: jest.fn() };

    await expect(
      restoreS3Sample(
        {
          sourceBucket: 'secondary-private-backup',
          sourceKey: 'objects/evidence-1.webp',
          expectedSha256: checksum,
          targetBucket: 'secondary-private-backup',
          targetPrefix: 'sosedi-restore-sample/drill-42',
          targetConfirmation:
            'secondary-private-backup/sosedi-restore-sample/drill-42',
        },
        sourceClient as unknown as S3Client,
        targetClient as unknown as S3Client,
      ),
    ).rejects.toThrow('distinct from the source bucket');
    expect(sourceClient.send).not.toHaveBeenCalled();
    expect(targetClient.send).not.toHaveBeenCalled();
  });
});
