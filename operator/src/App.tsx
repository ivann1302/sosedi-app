import { FormEvent, useEffect, useState } from 'react';
import {
  api,
  ApiError,
  Item,
  OperatorSession,
  Report,
  ReportedReviewContext,
  SupportMessage,
  SupportTicket,
  User,
} from './api';

type AuthStep = 'loading' | 'phone' | 'otp' | 'mfa' | 'ready';
type Page = 'support' | 'users' | 'moderation' | 'reports';
const IDLE_TIMEOUT_MS = 5 * 60 * 1000;

export function App() {
  const [step, setStep] = useState<AuthStep>('loading');
  const [page, setPage] = useState<Page>();
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const [accessToken, setAccessToken] = useState<string>();
  const [users, setUsers] = useState<User[]>([]);
  const [items, setItems] = useState<Item[]>([]);
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [openTicketId, setOpenTicketId] = useState<string>();
  const [supportMessages, setSupportMessages] = useState<
    Record<string, SupportMessage[]>
  >({});
  const [supportFiles, setSupportFiles] = useState<Record<string, File[]>>({});
  const [reports, setReports] = useState<Report[]>([]);
  const [reviewContexts, setReviewContexts] = useState<
    Record<string, ReportedReviewContext>
  >({});
  const [error, setError] = useState('');
  const [session, setSession] = useState<OperatorSession>();

  useEffect(() => {
    void api
      .session()
      .then((value) => {
        setSession(value);
        setPage(initialPage(value));
        setStep('ready');
      })
      .catch(() => setStep('phone'));
  }, []);

  useEffect(() => {
    if (step !== 'ready' || !page) return;
    void load(page);
  }, [page, step]);

  useEffect(() => {
    if (step !== 'ready' || !session) return;
    let idleTimer = window.setTimeout(() => void logout(), IDLE_TIMEOUT_MS);
    const sessionTimer = window.setTimeout(
      () => void logout(),
      session.expiresInSeconds * 1000,
    );
    const resetIdle = () => {
      window.clearTimeout(idleTimer);
      idleTimer = window.setTimeout(() => void logout(), IDLE_TIMEOUT_MS);
    };
    window.addEventListener('pointerdown', resetIdle);
    window.addEventListener('keydown', resetIdle);
    return () => {
      window.clearTimeout(idleTimer);
      window.clearTimeout(sessionTimer);
      window.removeEventListener('pointerdown', resetIdle);
      window.removeEventListener('keydown', resetIdle);
    };
  }, [session, step]);

  async function load(target: Page) {
    try {
      setError('');
      if (target === 'support') {
        setTickets(await api.supportTickets());
      } else if (target === 'users') {
        setUsers(await api.users());
      } else if (target === 'reports') {
        setReports(await api.reports());
        setReviewContexts({});
      } else {
        setItems(await api.items());
      }
    } catch (caught) {
      if (caught instanceof ApiError && caught.status === 401) {
        resetToLogin();
      } else {
        setError(message(caught));
      }
    }
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    try {
      setError('');
      if (step === 'phone') {
        await api.requestOtp(phone);
        setStep('otp');
      } else if (step === 'otp') {
        const result = await api.verifyOtp(phone, code);
        setAccessToken(result.accessToken);
        setCode('');
        setStep('mfa');
      } else if (step === 'mfa' && accessToken) {
        await api.stepUp(accessToken, code);
        const activeSession = await api.session();
        setSession(activeSession);
        setPage(initialPage(activeSession));
        setAccessToken(undefined);
        setCode('');
        setStep('ready');
      }
    } catch (caught) {
      setError(message(caught));
    }
  }

  async function logout() {
    try {
      await api.logout();
    } finally {
      resetToLogin();
    }
  }

  function resetToLogin() {
    api.cancelPendingRequests();
    setAccessToken(undefined);
    setSession(undefined);
    setPage(undefined);
    setUsers([]);
    setItems([]);
    setTickets([]);
    setOpenTicketId(undefined);
    setSupportMessages({});
    setSupportFiles({});
    setReports([]);
    setReviewContexts({});
    setPhone('');
    setCode('');
    setError('');
    setStep('phone');
  }

  if (step === 'loading') {
    return <main className="auth"><span className="brand">СОСЕДИ · OPERATOR</span></main>;
  }

  if (step !== 'ready') {
    const labels = {
      phone: ['Вход оператора', 'Телефон', 'Получить код'],
      otp: ['Код из SMS', '6 цифр', 'Продолжить'],
      mfa: ['Подтверждение MFA', 'TOTP или recovery code', 'Войти'],
    } as const;
    const current = labels[step];
    return (
      <main className="auth">
        <form className="panel" onSubmit={submit}>
          <span className="brand">СОСЕДИ · OPERATOR</span>
          <h1>{current[0]}</h1>
          <p>Доступ только для назначенных сотрудников.</p>
          <label>{current[1]}</label>
          <input
            autoFocus
            value={step === 'phone' ? phone : code}
            onChange={(event) =>
              step === 'phone'
                ? setPhone(event.target.value)
                : setCode(event.target.value)
            }
            required
          />
          {error && <div className="error">{error}</div>}
          <button>{current[2]}</button>
        </form>
      </main>
    );
  }

  return (
    <div className="shell">
      <aside>
        <span className="brand">СОСЕДИ</span>
        <nav>
          {session?.capabilities.includes('SUPPORT') && (
            <button onClick={() => setPage('support')}>Поддержка</button>
          )}
          {session?.capabilities.includes('MODERATION') && (
            <>
              <button onClick={() => setPage('users')}>Пользователи</button>
              <button onClick={() => setPage('moderation')}>Модерация</button>
              <button onClick={() => setPage('reports')}>Жалобы</button>
            </>
          )}
        </nav>
        <button className="quiet" onClick={logout}>Выйти</button>
      </aside>
      <main>
        <header>
          <h1>{pageTitle(page)}</h1>
          {page === 'support' && (
            <p>Обычные обращения. Финансовые споры появятся после утверждения ADR.</p>
          )}
        </header>
        {error && <div className="error">{error}</div>}
        <section className="list">
          {!page ? (
            <article>Обратитесь к администратору для назначения capability.</article>
          ) : page === 'support'
            ? sortTickets(tickets).map((ticket) => (
                <article key={ticket.id}>
                  <div className="ticket-head">
                    <strong>{ticket.subject}</strong>
                    <span className={`sla ${ticketPriority(ticket).className}`}>
                      {ticketPriority(ticket).label}
                    </span>
                  </div>
                  <span>
                    {ticket.user.name ?? 'Без имени'} · пользователь{' '}
                    {shortId(ticket.user.id)} · {formatAge(ticket.createdAt)}
                  </span>
                  <span>
                    Исполнитель: {ticket.assignee?.name ?? (ticket.assignee ? 'Без имени' : 'не назначен')}
                  </span>
                  {ticket.bookingId && (
                    <span className="context">
                      Бронь {shortId(ticket.bookingId)} ·{' '}
                      {bookingIssueLabel(ticket.bookingIssueReason)}
                    </span>
                  )}
                  <p>{ticket.message}</p>
                  <div className="actions">
                    <button
                      className="secondary"
                      onClick={() => void toggleSupportThread(ticket.id)}
                    >
                      {openTicketId === ticket.id
                        ? 'Скрыть переписку'
                        : 'Переписка'}
                    </button>
                    {!ticket.assignee && ticket.status !== 'CLOSED' && (
                      <button
                        className="secondary"
                        onClick={() =>
                          void act(
                            () => api.assignSupportTicket(ticket.id),
                            'support',
                          )
                        }
                      >
                        Взять в работу
                      </button>
                    )}
                    {ticket.status !== 'CLOSED' &&
                      canCurrentOperatorAct(ticket, session) && (
                      <button onClick={() => void replyToSupport(ticket)}>
                        Ответить
                      </button>
                    )}
                    {ticket.status !== 'CLOSED' &&
                      canCurrentOperatorAct(ticket, session) && (
                      <button
                        className="secondary"
                        onClick={() =>
                          void closeSupportTicket(ticket)
                        }
                      >
                        Закрыть
                      </button>
                    )}
                    {ticket.status !== 'CLOSED' &&
                      canCurrentOperatorAct(ticket, session) && (
                      <label className="file-button">
                        Фото
                        <input
                          accept="image/jpeg,image/png,image/webp"
                          multiple
                          onChange={(event) =>
                            selectSupportFiles(
                              ticket.id,
                              Array.from(event.target.files ?? []),
                            )
                          }
                          type="file"
                        />
                      </label>
                    )}
                  </div>
                  {ticket.status !== 'CLOSED' &&
                    !canCurrentOperatorAct(ticket, session) && (
                      <span>Только назначенный оператор может отвечать и закрывать.</span>
                    )}
                  {(supportFiles[ticket.id]?.length ?? 0) > 0 && (
                    <span>
                      Выбрано вложений: {supportFiles[ticket.id].length}
                    </span>
                  )}
                  {openTicketId === ticket.id && (
                    <div className="thread">
                      {(supportMessages[ticket.id] ?? []).map((message) => (
                        <div
                          className={`message ${message.authorRole.toLowerCase()}`}
                          key={message.id}
                        >
                          <strong>
                            {message.authorRole === 'SUPPORT'
                              ? 'Поддержка'
                              : 'Пользователь'}
                          </strong>
                          <span>{message.body}</span>
                          {message.attachments.map((attachment) => (
                            <button
                              className="attachment"
                              key={attachment.id}
                              onClick={() =>
                                void openSupportAttachment(
                                  ticket.id,
                                  attachment.id,
                                )
                              }
                            >
                              Открыть вложение
                            </button>
                          ))}
                          <time>{formatDateTime(message.createdAt)}</time>
                        </div>
                      ))}
                      {!supportMessages[ticket.id] && (
                        <span>Загружаем переписку…</span>
                      )}
                    </div>
                  )}
                </article>
              ))
            : page === 'users'
            ? users.map((user) => (
                <article key={user.id}>
                  <strong>{user.name ?? 'Без имени'}</strong>
                  <span>{user.phone} · {user.city ?? 'Город не указан'}</span>
                  <i>{user.isBlocked ? 'Заблокирован' : user.role}</i>
                  {!user.isBlocked &&
                    session?.capabilities.includes('MODERATION') && (
                      <div className="actions">
                        <button
                          className="danger"
                          onClick={() => void blockUser(user)}
                        >
                          Заблокировать
                        </button>
                      </div>
                    )}
                </article>
              ))
            : page === 'moderation'
            ? items.map((item) => (
                <article key={item.id}>
                  <div className="moderation-photos">
                    {item.photos.map((photo, index) => {
                      const src =
                        photo.previewUrl ??
                        photo.thumbnailUrl ??
                        photo.originalUrl;
                      return src ? (
                        <img
                          alt={`Фото объявления ${index + 1}`}
                          key={photo.id}
                          src={src}
                        />
                      ) : (
                        <span key={photo.id}>Фото обрабатывается</span>
                      );
                    })}
                    {item.photos.length === 0 && (
                      <span>Фото не добавлены или ещё обрабатываются</span>
                    )}
                  </div>
                  <strong>{item.title}</strong>
                  <span>
                    {item.owner.name ?? `Владелец ${shortId(item.owner.id)}`} ·{' '}
                    {item.publicArea}
                  </span>
                  <span>
                    {item.category.name} · {conditionLabel(item.condition)} ·{' '}
                    {_money(item.pricePerDay)} ₽ / день
                  </span>
                  <p>{item.description}</p>
                  <div className="moderation-details">
                    <strong>Комплектация</strong>
                    <span>{item.completeness}</span>
                    <strong>Передача и безопасность</strong>
                    <span>{item.handoverTerms}</span>
                  </div>
                  <div className="actions">
                    <button onClick={() => void act(() => api.approve(item.id))}>Одобрить</button>
                    <button className="danger" onClick={() => {
                      const reason = window.prompt('Причина отклонения');
                      if (reason) void act(() => api.reject(item.id, reason));
                    }}>Отклонить</button>
                  </div>
                </article>
              ))
            : reports.map((report) => (
                <article key={report.id}>
                  <div className="ticket-head">
                    <strong>{report.reason}</strong>
                    <span className="sla new">{report.targetType}</span>
                  </div>
                  <span>
                    {reportTargetLabel(report)} · {formatAge(report.createdAt)}
                  </span>
                  <p>{report.description}</p>
                  {report.targetType === 'REVIEW' &&
                    (reviewContexts[report.id] ? (
                      <div className="moderation-details">
                        <strong>Оценка</strong>
                        <span>{'★'.repeat(reviewContexts[report.id].rating)}</span>
                        <strong>Текст отзыва</strong>
                        <span>
                          {reviewContexts[report.id].text ?? 'Текст не добавлен'}
                        </span>
                      </div>
                    ) : (
                      <button
                        className="secondary"
                        onClick={() => void loadReviewContext(report.id)}
                      >
                        Показать текст отзыва
                      </button>
                    ))}
                  <div className="actions">
                    <button
                      className="secondary"
                      onClick={() => void decideReport(report, 'DISMISS')}
                    >
                      Отклонить жалобу
                    </button>
                    {report.targetType === 'ITEM' && (
                      <button
                        className="danger"
                        onClick={() =>
                          void decideReport(report, 'HIDE_LISTING')
                        }
                      >
                        Скрыть объявление
                      </button>
                    )}
                    {report.targetType === 'REVIEW' && (
                      <button
                        className="danger"
                        onClick={() => void decideReport(report, 'HIDE_REVIEW')}
                      >
                        Скрыть отзыв
                      </button>
                    )}
                    {(report.targetType === 'USER' ||
                      report.targetType === 'MESSAGE') && (
                      <button
                        className="danger"
                        onClick={() => void decideReport(report, 'BLOCK_USER')}
                      >
                        Заблокировать
                      </button>
                    )}
                  </div>
                </article>
              ))}
        </section>
      </main>
    </div>
  );

  async function act(action: () => Promise<unknown>, reloadPage: Page = 'moderation') {
    try {
      setError('');
      await action();
      await load(reloadPage);
    } catch (caught) {
      if (caught instanceof ApiError && caught.status === 401) {
        resetToLogin();
      } else {
        setError(message(caught));
      }
    }
  }

  async function decideReport(
    report: Report,
    decision: 'DISMISS' | 'HIDE_LISTING' | 'HIDE_REVIEW' | 'BLOCK_USER',
  ) {
    const reason = window.prompt('Основание решения (не менее 10 символов)');
    if (!reason) return;
    await act(
      () => api.decideReport(report.id, decision, reason),
      'reports',
    );
  }

  async function loadReviewContext(reportId: string) {
    try {
      setError('');
      const context = await api.reportedReviewContext(reportId);
      setReviewContexts((current) => ({ ...current, [reportId]: context }));
    } catch (caught) {
      if (caught instanceof ApiError && caught.status === 401) {
        resetToLogin();
      } else {
        setError(message(caught));
      }
    }
  }

  async function blockUser(user: User) {
    const reason = window.prompt(
      `Основание блокировки ${user.name ?? user.phone} (5–500 символов)`,
    );
    if (!reason) return;
    const normalized = reason.trim();
    if (normalized.length < 5 || normalized.length > 500) {
      setError('Основание блокировки должно содержать от 5 до 500 символов');
      return;
    }
    await act(() => api.blockUser(user.id, normalized), 'users');
  }

  async function toggleSupportThread(ticketId: string) {
    if (openTicketId === ticketId) {
      setOpenTicketId(undefined);
      return;
    }
    setOpenTicketId(ticketId);
    if (supportMessages[ticketId]) return;
    try {
      setError('');
      const messages = await api.supportMessages(ticketId);
      setSupportMessages((current) => ({
        ...current,
        [ticketId]: messages,
      }));
    } catch (caught) {
      setOpenTicketId(undefined);
      if (caught instanceof ApiError && caught.status === 401) {
        resetToLogin();
      } else {
        setError(message(caught));
      }
    }
  }

  async function replyToSupport(ticket: SupportTicket) {
    const reply = window.prompt('Ответ пользователю');
    if (!reply) return;
    await act(async () => {
      const files = supportFiles[ticket.id] ?? [];
      const intentIds = await api.uploadSupportAttachments(ticket.id, files);
      await api.createSupportMessage(ticket.id, reply, intentIds);
      setSupportFiles((current) => ({ ...current, [ticket.id]: [] }));
      const messages = await api.supportMessages(ticket.id);
      setSupportMessages((current) => ({
        ...current,
        [ticket.id]: messages,
      }));
      setOpenTicketId(ticket.id);
    }, 'support');
  }

  async function closeSupportTicket(ticket: SupportTicket) {
    if (!window.confirm('Закрыть обращение? Новые сообщения будут запрещены.')) {
      return;
    }
    await act(() => api.closeSupportTicket(ticket.id), 'support');
    setOpenTicketId(undefined);
  }

  function selectSupportFiles(ticketId: string, files: File[]) {
    const allowed = files
      .filter(
        (file) =>
          ['image/jpeg', 'image/png', 'image/webp'].includes(file.type) &&
          file.size > 0 &&
          file.size <= 10 * 1024 * 1024,
      )
      .slice(0, 3);
    setSupportFiles((current) => ({ ...current, [ticketId]: allowed }));
    if (allowed.length !== files.length) {
      setError('Можно выбрать до 3 JPEG, PNG или WebP не больше 10 МБ');
    } else {
      setError('');
    }
  }

  async function openSupportAttachment(
    ticketId: string,
    attachmentId: string,
  ) {
    try {
      setError('');
      const result = await api.supportAttachmentUrl(ticketId, attachmentId);
      const url = new URL(result.downloadUrl);
      if (url.protocol !== 'https:') {
        throw new Error('Небезопасная ссылка вложения');
      }
      window.open(url.toString(), '_blank', 'noopener,noreferrer');
    } catch (caught) {
      if (caught instanceof ApiError && caught.status === 401) {
        resetToLogin();
      } else {
        setError(message(caught));
      }
    }
  }
}

function message(error: unknown): string {
  if (error instanceof DOMException && error.name === 'AbortError') return '';
  return error instanceof Error ? error.message : 'Неизвестная ошибка';
}

function initialPage(session: OperatorSession): Page | undefined {
  if (session.capabilities.includes('SUPPORT')) return 'support';
  if (session.capabilities.includes('MODERATION')) return 'moderation';
  return undefined;
}

function canCurrentOperatorAct(
  ticket: SupportTicket,
  session: OperatorSession | undefined,
): boolean {
  return !ticket.assignee || ticket.assignee.id === session?.userId;
}

function pageTitle(page: Page | undefined): string {
  if (page === 'support') return 'Очередь поддержки';
  if (page === 'users') return 'Пользователи';
  if (page === 'moderation') return 'Очередь модерации';
  if (page === 'reports') return 'Жалобы';
  return 'Нет доступных разделов';
}

function formatAge(createdAt: string): string {
  const hours = Math.max(
    0,
    Math.floor((Date.now() - new Date(createdAt).getTime()) / 3_600_000),
  );
  return hours < 1 ? 'меньше часа' : `${hours} ч в очереди`;
}

function formatDateTime(value: string): string {
  return new Intl.DateTimeFormat('ru-RU', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value));
}

function ticketPriority(ticket: SupportTicket): {
  label: string;
  className: string;
  rank: number;
} {
  if (ticket.status === 'CLOSED') {
    return { label: 'Закрыто', className: 'closed', rank: 0 };
  }
  if (ticket.status === 'IN_PROGRESS') {
    return { label: 'В работе', className: 'progress', rank: 1 };
  }
  const ageHours =
    (Date.now() - new Date(ticket.createdAt).getTime()) / 3_600_000;
  const highPriority = [
    'OWNER_NO_SHOW',
    'BORROWER_NO_SHOW',
    'ITEM_FAULTY',
    'ITEM_DAMAGED',
    'ITEM_LOST',
  ].includes(ticket.bookingIssueReason ?? '');
  const slaHours = highPriority ? 4 : 24;
  if (ageHours >= slaHours) {
    return {
      label: `SLA > ${slaHours} ч`,
      className: 'overdue',
      rank: 3,
    };
  }
  return highPriority
    ? { label: 'Высокий · SLA 4 ч', className: 'high', rank: 2 }
    : { label: 'Обычный · SLA 24 ч', className: 'new', rank: 1 };
}

function sortTickets(tickets: SupportTicket[]): SupportTicket[] {
  return [...tickets].sort((left, right) => {
    const rankDifference =
      ticketPriority(right).rank - ticketPriority(left).rank;
    if (rankDifference !== 0) return rankDifference;
    return (
      new Date(left.createdAt).getTime() -
      new Date(right.createdAt).getTime()
    );
  });
}

function shortId(id: string): string {
  return id.slice(0, 8);
}

function bookingIssueLabel(reason: SupportTicket['bookingIssueReason']): string {
  const labels: Record<NonNullable<SupportTicket['bookingIssueReason']>, string> = {
    OWNER_NO_SHOW: 'владелец не пришёл',
    BORROWER_NO_SHOW: 'арендатор не пришёл',
    ITEM_FAULTY: 'вещь неисправна',
    EARLY_RETURN: 'досрочный возврат',
    LATE_RETURN: 'просроченный возврат',
    ITEM_DAMAGED: 'повреждение',
    ITEM_LOST: 'потеря',
  };
  return reason ? labels[reason] : 'контекст бронирования';
}

function reportTargetLabel(report: Report): string {
  const title =
    typeof report.target.title === 'string'
      ? report.target.title
      : typeof report.target.name === 'string'
        ? report.target.name
        : typeof report.target.itemTitle === 'string'
          ? report.target.itemTitle
          : report.targetId;
  return `${report.targetType}: ${title}`;
}

function conditionLabel(condition: Item['condition']): string {
  return {
    NEW: 'Новое',
    LIKE_NEW: 'Как новое',
    GOOD: 'Хорошее',
    FAIR: 'Удовлетворительное',
  }[condition];
}

function _money(value: number): string {
  return Number.isInteger(value) ? String(value) : value.toFixed(2);
}
