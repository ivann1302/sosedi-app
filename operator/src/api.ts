const API = '/api/v1';
let pendingRequests = new AbortController();

type Envelope<T> = {
  success: boolean;
  data: T | null;
  error: { code: string; message: string } | null;
};

export class ApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message);
  }
}

export type User = {
  id: string;
  phone: string;
  name: string | null;
  city: string | null;
  role: string;
  isBlocked: boolean;
};

export type Item = {
  id: string;
  title: string;
  description: string;
  condition: 'NEW' | 'LIKE_NEW' | 'GOOD' | 'FAIR';
  completeness: string;
  handoverTerms: string;
  pricePerDay: number;
  depositAmount: number | null;
  status: string;
  publicArea: string;
  category: {
    id: string;
    name: string;
    slug: string;
    iconName: string | null;
  };
  owner: {
    id: string;
    name: string | null;
    isBlocked: boolean;
    deletedAt: string | null;
  };
  photos: {
    id: string;
    originalUrl: string | null;
    thumbnailUrl: string | null;
    previewUrl: string | null;
    sortOrder: number;
    isCover: boolean;
    createdAt: string;
  }[];
};

export type OperatorSession = {
  userId: string;
  capabilities: string[];
  expiresInSeconds: number;
};

export type SupportTicket = {
  id: string;
  type: 'GENERAL';
  bookingId: string | null;
  bookingIssueReason:
    | 'OWNER_NO_SHOW'
    | 'BORROWER_NO_SHOW'
    | 'ITEM_FAULTY'
    | 'EARLY_RETURN'
    | 'LATE_RETURN'
    | 'ITEM_DAMAGED'
    | 'ITEM_LOST'
    | null;
  subject: string;
  message: string;
  status: 'OPEN' | 'IN_PROGRESS' | 'CLOSED';
  adminResponse: string | null;
  respondedAt: string | null;
  createdAt: string;
  updatedAt: string;
  user: {
    id: string;
    name: string | null;
  };
  assignee: {
    id: string;
    name: string | null;
  } | null;
};

export type SupportMessage = {
  id: string;
  authorRole: 'USER' | 'SUPPORT';
  body: string;
  attachments: {
    id: string;
    sha256: string;
    createdAt: string;
  }[];
  createdAt: string;
};

type PresignedUpload = {
  intentId: string;
  uploadUrl: string;
  fields: Record<string, string>;
};

export type Report = {
  id: string;
  targetType: 'ITEM' | 'USER' | 'BOOKING' | 'MESSAGE' | 'REVIEW';
  targetId: string;
  reason: string;
  description: string;
  status: 'OPEN' | 'DISMISSED' | 'ACTIONED';
  decision: string | null;
  reporter: { id: string; name: string | null };
  target: Record<string, string | boolean | null>;
  createdAt: string;
  updatedAt: string;
};

export type ReportedReviewContext = {
  id: string;
  authorRole: 'BORROWER' | 'LENDER';
  rating: number;
  text: string | null;
  publishedAt: string;
  createdAt: string;
};

export type FinancialDisputeReason =
  | 'ITEM_DAMAGED'
  | 'ITEM_LOST'
  | 'OTHER';

export type DisputeStatus = 'OPEN' | 'UNDER_REVIEW' | 'RESOLVED';

export type DepositStatus =
  | 'PENDING'
  | 'HELD'
  | 'DISPUTED'
  | 'RESOLVING'
  | 'RESOLVED'
  | 'CANCELLED';

export type DepositOperationKind =
  | 'HOLD'
  | 'CANCEL'
  | 'REFUND'
  | 'RELEASE_TO_LENDER';

export type DepositOperationStatus = 'PENDING' | 'SUCCEEDED' | 'FAILED';

export type DisputeEvidence = {
  id: string;
  sha256: string;
  createdAt: string;
};

export type FailedDepositOperation = {
  id: string;
  kind: DepositOperationKind;
  amountMinor: number;
  status: 'FAILED';
  errorCode: string | null;
  attempts: number;
  retryOfId: string | null;
  retryId: string | null;
  createdAt: string;
  completedAt: string | null;
};

export type AdminDispute = {
  id: string;
  bookingId: string;
  reason: FinancialDisputeReason;
  description: string | null;
  status: DisputeStatus;
  refundToBorrowerMinor: number;
  releaseToLenderMinor: number;
  depositAmountMinor: number;
  depositStatus: DepositStatus;
  disputeWindowEndsAt: string | null;
  openedAt: string;
  resolvedAt: string | null;
  evidence: DisputeEvidence[];
  failedOperations: FailedDepositOperation[];
};

export type DisputeCommandResponse = {
  id: string;
  bookingId: string;
  openedById: string;
  reason: FinancialDisputeReason;
  description: string | null;
  status: DisputeStatus;
  openedAt: string;
  resolvedAt: string | null;
  evidence: DisputeEvidence[];
};

export type DepositOperationCommandResponse = {
  id: string;
  depositId: string;
  kind: DepositOperationKind;
  amountMinor: number;
  status: DepositOperationStatus;
  retryOfId: string | null;
};

async function call<T>(
  path: string,
  init: RequestInit = {},
  accessToken?: string,
): Promise<T> {
  const headers = new Headers(init.headers);
  if (init.body) headers.set('Content-Type', 'application/json');
  if (accessToken) headers.set('Authorization', `Bearer ${accessToken}`);
  const csrf = readCookie('__Host-sosedi_admin_csrf');
  if (csrf && !['GET', 'HEAD'].includes(init.method ?? 'GET')) {
    headers.set('X-CSRF-Token', csrf);
  }
  headers.set('X-Request-Id', crypto.randomUUID());

  const response = await fetch(`${API}${path}`, {
    ...init,
    headers,
    credentials: 'include',
    signal: init.signal ?? pendingRequests.signal,
  });
  const payload = (await response.json()) as Envelope<T>;
  if (!response.ok || !payload.success || payload.data === null) {
    throw new ApiError(payload.error?.message ?? 'Ошибка запроса', response.status);
  }
  return payload.data;
}

function installationId(): string {
  const key = 'sosedi_operator_installation';
  const existing = localStorage.getItem(key);
  if (existing) return existing;
  const created = crypto.randomUUID();
  localStorage.setItem(key, created);
  return created;
}

function readCookie(name: string): string | null {
  const prefix = `${name}=`;
  const value = document.cookie
    .split(';')
    .map((part) => part.trim())
    .find((part) => part.startsWith(prefix));
  return value ? value.slice(prefix.length) : null;
}

export const api = {
  requestOtp: (phone: string) =>
    call('/auth/otp/request', {
      method: 'POST',
      headers: { 'X-Installation-Id': installationId() },
      body: JSON.stringify({ phone }),
    }),
  verifyOtp: (phone: string, code: string) =>
    call<{ accessToken: string }>('/auth/otp/verify', {
      method: 'POST',
      body: JSON.stringify({ phone, code }),
    }),
  stepUp: (accessToken: string, code: string) =>
    call('/admin/session/step-up', {
      method: 'POST',
      body: JSON.stringify({ code }),
    }, accessToken),
  session: () => call<OperatorSession>('/admin/session'),
  logout: () => call('/admin/session', { method: 'DELETE' }),
  users: () => call<User[]>('/admin/users'),
  blockUser: (id: string, reason: string) =>
    call<User>(`/admin/users/${id}/block`, {
      method: 'PATCH',
      body: JSON.stringify({ reason }),
    }),
  supportTickets: () =>
    call<SupportTicket[]>('/admin/support/tickets'),
  supportMessages: (id: string) =>
    call<SupportMessage[]>(`/admin/support/tickets/${id}/messages`),
  createSupportMessage: (
    id: string,
    body: string,
    attachmentIntentIds: string[] = [],
  ) =>
    call<SupportMessage>(`/admin/support/tickets/${id}/messages`, {
      method: 'POST',
      body: JSON.stringify({ body, attachmentIntentIds }),
    }),
  uploadSupportAttachments: async (ticketId: string, files: File[]) => {
    const intentIds: string[] = [];
    for (const file of files) {
      const upload = await call<PresignedUpload>(
        `/admin/support/tickets/${ticketId}/attachments/presigned-url`,
        {
          method: 'POST',
          body: JSON.stringify({
            fileName: file.name,
            contentType: file.type,
            sizeBytes: file.size,
          }),
        },
      );
      const form = new FormData();
      Object.entries(upload.fields).forEach(([key, value]) =>
        form.append(key, value),
      );
      form.append('file', file, file.name);
      const response = await fetch(upload.uploadUrl, {
        method: 'POST',
        body: form,
        credentials: 'omit',
        signal: pendingRequests.signal,
      });
      if (!response.ok) {
        throw new ApiError('Не удалось загрузить вложение', response.status);
      }
      intentIds.push(upload.intentId);
    }
    return intentIds;
  },
  supportAttachmentUrl: (ticketId: string, attachmentId: string) =>
    call<{ downloadUrl: string; expiresInSeconds: number }>(
      `/admin/support/tickets/${ticketId}/attachments/${attachmentId}/download-url`,
    ),
  assignSupportTicket: (id: string) =>
    call<SupportTicket>(`/admin/support/tickets/${id}/assign-self`, {
      method: 'PATCH',
    }),
  replyToSupportTicket: (id: string, message: string) =>
    call<SupportTicket>(`/admin/support/tickets/${id}/reply`, {
      method: 'PATCH',
      body: JSON.stringify({ message }),
    }),
  closeSupportTicket: (id: string) =>
    call<SupportTicket>(`/admin/support/tickets/${id}/close`, {
      method: 'PATCH',
    }),
  items: () => call<Item[]>('/admin/items/pending'),
  approve: (id: string) =>
    call(`/admin/items/${id}/approve`, { method: 'PATCH' }),
  reject: (id: string, reason: string) =>
    call(`/admin/items/${id}/reject`, {
      method: 'PATCH',
      body: JSON.stringify({ reason }),
    }),
  reports: () => call<Report[]>('/admin/reports'),
  reportedReviewContext: (id: string) =>
    call<ReportedReviewContext>(`/admin/reports/${id}/review-context`),
  decideReport: (
    id: string,
    decision: 'DISMISS' | 'HIDE_LISTING' | 'HIDE_REVIEW' | 'BLOCK_USER',
    reason: string,
  ) =>
    call<Report>(`/admin/reports/${id}/decision`, {
      method: 'PATCH',
      body: JSON.stringify({ decision, reason }),
    }),
  disputes: () => call<AdminDispute[]>('/admin/disputes'),
  disputeEvidenceUrl: (disputeId: string, evidenceId: string) =>
    call<{ downloadUrl: string; expiresInSeconds: number }>(
      `/admin/disputes/${disputeId}/evidence/${evidenceId}/download-url`,
    ),
  resolveDispute: (
    disputeId: string,
    refundToBorrowerMinor: number,
    releaseToLenderMinor: number,
    reason: string,
  ) =>
    call<DisputeCommandResponse>(`/admin/disputes/${disputeId}/resolve`, {
      method: 'POST',
      headers: { 'Idempotency-Key': crypto.randomUUID() },
      body: JSON.stringify({
        refundToBorrowerMinor,
        releaseToLenderMinor,
        reason,
      }),
    }),
  retryDepositOperation: (operationId: string) =>
    call<DepositOperationCommandResponse>(
      `/admin/deposit-operations/${operationId}/retry`,
      {
        method: 'POST',
        headers: { 'Idempotency-Key': crypto.randomUUID() },
      },
    ),
  cancelPendingRequests: () => {
    pendingRequests.abort();
    pendingRequests = new AbortController();
  },
};
