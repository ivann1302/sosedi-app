export const ALLOWED_UPLOAD_CONTENT_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
] as const;

export const MAX_UPLOAD_SIZE_BYTES = 10 * 1024 * 1024;
export const PRESIGNED_UPLOAD_EXPIRES_SECONDS = 15 * 60;
export const PRESIGNED_DOWNLOAD_EXPIRES_SECONDS = 60;
export const UPLOAD_CLEANUP_INTERVAL_MS = 15 * 60 * 1000;
export const UPLOAD_INTENT_CLEANUP_GRACE_MS = 24 * 60 * 60 * 1000;
export const REJECTED_UPLOAD_RETENTION_MS = 7 * 24 * 60 * 60 * 1000;

export const ITEM_PHOTO_THUMBNAIL_SIZE = 200;
export const ITEM_PHOTO_PREVIEW_WIDTH = 800;
export const ITEM_PHOTO_PREVIEW_HEIGHT = 600;
export const MAX_ITEM_PHOTO_COUNT = 5;
export const AVATAR_SIZE = 512;
