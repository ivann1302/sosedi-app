export const BOOKING_STATUSES = [
  'PENDING',
  'CONFIRMED',
  'ACTIVE',
  'RETURNED',
  'COMPLETED',
  'CANCELLED',
] as const;

export const PAYMENT_STATUSES = [
  'PENDING',
  'SUCCEEDED',
  'FAILED',
  'CANCELLED',
] as const;

export const PAYOUT_STATUSES = [
  'PENDING',
  'PROCESSING',
  'SUCCEEDED',
  'FAILED',
  'CANCELLED',
] as const;

export const DISPUTE_STATUSES = ['OPEN', 'UNDER_REVIEW', 'RESOLVED'] as const;

type WorkflowContract = {
  statuses: readonly string[];
  transitions: readonly {
    command: string;
    from: string;
    to: string;
    actors: readonly string[];
    preconditions: readonly string[];
  }[];
};

export const WORKFLOW_CONTRACTS = {
  booking: {
    statuses: BOOKING_STATUSES,
    transitions: [
      {
        command: 'confirm',
        from: 'PENDING',
        to: 'CONFIRMED',
        actors: ['LENDER'],
        preconditions: ['notExpired', 'periodAvailable', 'versionMatches'],
      },
      {
        command: 'cancel',
        from: 'PENDING',
        to: 'CANCELLED',
        actors: ['BORROWER', 'LENDER'],
        preconditions: ['participant', 'versionMatches'],
      },
      {
        command: 'expire',
        from: 'PENDING',
        to: 'CANCELLED',
        actors: ['SYSTEM'],
        preconditions: ['expiresAtReached', 'reasonIsPendingTimeout'],
      },
      {
        command: 'cancel',
        from: 'CONFIRMED',
        to: 'CANCELLED',
        actors: ['BORROWER', 'LENDER'],
        preconditions: ['participant', 'cancellationPolicyAllows'],
      },
      {
        command: 'activate',
        from: 'CONFIRMED',
        to: 'ACTIVE',
        actors: ['BORROWER', 'LENDER'],
        preconditions: ['participant', 'handoverConfirmedByBoth'],
      },
      {
        command: 'return',
        from: 'ACTIVE',
        to: 'RETURNED',
        actors: ['BORROWER', 'LENDER'],
        preconditions: ['participant', 'returnConfirmedByBoth'],
      },
      {
        command: 'complete',
        from: 'RETURNED',
        to: 'COMPLETED',
        actors: ['SYSTEM'],
        preconditions: ['disputeWindowClosed', 'noOpenDispute'],
      },
    ],
  },
  payment: {
    statuses: PAYMENT_STATUSES,
    transitions: [
      {
        command: 'succeed',
        from: 'PENDING',
        to: 'SUCCEEDED',
        actors: ['PAYMENT_PROVIDER'],
        preconditions: ['providerEventVerified', 'amountAndCurrencyMatch'],
      },
      {
        command: 'fail',
        from: 'PENDING',
        to: 'FAILED',
        actors: ['PAYMENT_PROVIDER'],
        preconditions: ['providerEventVerified'],
      },
      {
        command: 'cancel',
        from: 'PENDING',
        to: 'CANCELLED',
        actors: ['SYSTEM', 'PAYMENT_PROVIDER'],
        preconditions: ['bookingCancelledOrProviderCancelled'],
      },
    ],
  },
  payout: {
    statuses: PAYOUT_STATUSES,
    transitions: [
      {
        command: 'start',
        from: 'PENDING',
        to: 'PROCESSING',
        actors: ['SYSTEM'],
        preconditions: [
          'bookingReturned',
          'disputeWindowClosed',
          'noOpenDispute',
          'recipientEligible',
        ],
      },
      {
        command: 'cancel',
        from: 'PENDING',
        to: 'CANCELLED',
        actors: ['SYSTEM'],
        preconditions: ['disputeOpenedBeforeDispatch'],
      },
      {
        command: 'succeed',
        from: 'PROCESSING',
        to: 'SUCCEEDED',
        actors: ['PAYMENT_PROVIDER'],
        preconditions: ['providerEventVerified'],
      },
      {
        command: 'fail',
        from: 'PROCESSING',
        to: 'FAILED',
        actors: ['PAYMENT_PROVIDER'],
        preconditions: ['providerEventVerified'],
      },
      {
        command: 'retry',
        from: 'FAILED',
        to: 'PROCESSING',
        actors: ['SYSTEM'],
        preconditions: ['newAttemptCreated', 'noOpenDispute'],
      },
    ],
  },
  dispute: {
    statuses: DISPUTE_STATUSES,
    transitions: [
      {
        command: 'review',
        from: 'OPEN',
        to: 'UNDER_REVIEW',
        actors: ['ADMIN_DISPUTE'],
        preconditions: ['stepUpValid', 'capabilityPresent', 'auditEnabled'],
      },
      {
        command: 'resolve',
        from: 'OPEN',
        to: 'RESOLVED',
        actors: ['ADMIN_DISPUTE'],
        preconditions: ['stepUpValid', 'resolutionAllowed', 'auditEnabled'],
      },
      {
        command: 'resolve',
        from: 'UNDER_REVIEW',
        to: 'RESOLVED',
        actors: ['ADMIN_DISPUTE'],
        preconditions: ['stepUpValid', 'resolutionAllowed', 'auditEnabled'],
      },
    ],
  },
} as const satisfies Record<string, WorkflowContract>;
