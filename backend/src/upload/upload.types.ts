export enum UploadPurpose {
  ITEM_PHOTO = 'ITEM_PHOTO',
  AVATAR = 'AVATAR',
  BOOKING_EVIDENCE = 'BOOKING_EVIDENCE',
  DISPUTE_EVIDENCE = 'DISPUTE_EVIDENCE',
  SUPPORT_ATTACHMENT = 'SUPPORT_ATTACHMENT',
  KYC_DOCUMENT = 'KYC_DOCUMENT',
}

export type PresignedUploadResponse = {
  intentId: string;
  uploadUrl: string;
  method: 'POST';
  bucket: string;
  key: string;
  publicUrl: string | null;
  expiresInSeconds: number;
  fields: Record<string, string>;
  constraints: {
    contentType: string;
    sizeBytes: number;
  };
};

export type ItemPhotoUploadResponse = {
  id: string;
  itemId: string;
  originalUrl: string | null;
  thumbnailUrl: string | null;
  previewUrl: string | null;
  sortOrder: number;
  isCover: boolean;
  createdAt: Date;
};

export type AvatarUploadResponse = {
  avatarUrl: string;
};

export type PrivateFileDownloadResponse = {
  downloadUrl: string;
  expiresInSeconds: number;
};

export type VerifiedBookingEvidence = {
  intentId: string;
  bucket: string;
  objectKey: string;
  sha256: string;
};

export type VerifiedDisputeEvidence = VerifiedBookingEvidence;

export type VerifiedSupportAttachment = {
  intentId: string;
  bucket: string;
  objectKey: string;
  sha256: string;
};

export type UploadedObjectInfo = {
  sizeBytes: number | null;
  contentType: string | null;
  prefix: Buffer;
};

export type StoredObject = {
  key: string;
  lastModified: Date | null;
};

export type PhotoProcessingJob = {
  itemPhotoId: string;
  itemId: string;
  sourceBucket: string;
  sourceKey: string;
};
