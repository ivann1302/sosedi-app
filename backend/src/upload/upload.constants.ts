export const ALLOWED_UPLOAD_CONTENT_TYPES = [
  'image/jpeg',
  'image/png',
  'image/webp',
] as const;

export const MAX_UPLOAD_SIZE_BYTES = 10 * 1024 * 1024;
export const PRESIGNED_UPLOAD_EXPIRES_SECONDS = 15 * 60;

export const TOOL_PHOTO_THUMBNAIL_SIZE = 200;
export const TOOL_PHOTO_PREVIEW_WIDTH = 800;
export const TOOL_PHOTO_PREVIEW_HEIGHT = 600;
