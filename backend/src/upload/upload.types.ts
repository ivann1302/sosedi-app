export enum UploadPurpose {
  TOOL_PHOTO = 'TOOL_PHOTO',
  KYC_DOCUMENT = 'KYC_DOCUMENT',
}

export type PresignedUploadResponse = {
  uploadUrl: string;
  method: 'PUT';
  bucket: string;
  key: string;
  publicUrl: string | null;
  expiresInSeconds: number;
  headers: {
    contentType: string;
  };
};

export type ToolPhotoUploadResponse = {
  id: string;
  toolId: string;
  originalUrl: string;
  thumbnailUrl: string | null;
  previewUrl: string | null;
  sortOrder: number;
  isCover: boolean;
  createdAt: Date;
};

export type PhotoProcessingJob = {
  toolPhotoId: string;
  toolId: string;
  originalKey: string;
};
