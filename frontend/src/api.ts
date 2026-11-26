export type DeliveryStatus = "pending" | "delivering" | "delivered" | "dead";

export interface Page<T> {
  data: T[];
  next_cursor: number | null;
}

export interface Source {
  id: number;
  name: string;
  created_at: string;
}

export interface CreatedSource extends Source {
  token: string;
  ingest_path: string;
}

export interface Subscription {
  id: number;
  source_id: number;
  url: string;
  event_filter: string | null;
  active: boolean;
  created_at: string;
}

export interface CreatedSubscription extends Subscription {
  signing_secret: string;
}

export interface EventSummary {
  id: number;
  source_id: number;
  event_type: string;
  idempotency_key: string;
  received_at: string;
}

export interface Delivery {
  id: number;
  event_id: number;
  subscription_id: number;
  status: DeliveryStatus;
  attempts_count: number;
  attempt_limit: number;
  next_attempt_at: string;
  updated_at: string;
}

export interface Attempt {
  number: number;
  response_code: number | null;
  error: string | null;
  duration_ms: number;
  created_at: string;
}

export interface EventDetail extends EventSummary {
  payload: unknown;
  deliveries: (Delivery & { attempts: Attempt[] })[];
}

export interface Client {
  listSources(params?: { before?: number }): Promise<Page<Source>>;
  createSource(name: string, signingSecret: string): Promise<CreatedSource>;
  listSubscriptions(sourceId: number, params?: { before?: number }): Promise<Page<Subscription>>;
  createSubscription(
    sourceId: number,
    input: { url: string; event_filter: string | null },
  ): Promise<CreatedSubscription>;
  updateSubscription(
    id: number,
    changes: Partial<Pick<Subscription, "url" | "event_filter" | "active">>,
  ): Promise<Subscription>;
  listEvents(params?: { event_type?: string; source_id?: number; before?: number }): Promise<Page<EventSummary>>;
  getEvent(id: number): Promise<EventDetail>;
  listDeliveries(params?: {
    status?: DeliveryStatus;
    subscription_id?: number;
    before?: number;
  }): Promise<Page<Delivery>>;
  replay(id: number): Promise<Delivery>;
}

export class ApiError extends Error {
  readonly status: number;

  constructor(status: number, message: string) {
    super(message);
    this.name = "ApiError";
    this.status = status;
  }
}

type Fetch = (input: string, init: RequestInit) => Promise<Response>;
type Query = Record<string, string | number | undefined | null>;

function withQuery(path: string, query: Query = {}): string {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined && value !== null && value !== "") params.set(key, String(value));
  }
  const search = params.toString();
  return search ? `${path}?${search}` : path;
}

function errorMessage(status: number, body: unknown): string {
  if (body && typeof body === "object") {
    const { error, errors } = body as { error?: unknown; errors?: unknown };
    if (typeof error === "string") return error;
    if (Array.isArray(errors)) return errors.join(", ");
  }
  return `Request failed (${status})`;
}

export function createClient(token: string, fetchImpl: Fetch = (input, init) => fetch(input, init)): Client {
  async function request<T>(path: string, init: { method?: string; body?: unknown } = {}): Promise<T> {
    const headers: Record<string, string> = { Authorization: `Bearer ${token}`, Accept: "application/json" };
    if (init.body !== undefined) headers["Content-Type"] = "application/json";

    const response = await fetchImpl(path, {
      method: init.method ?? "GET",
      headers,
      body: init.body === undefined ? undefined : JSON.stringify(init.body),
    });
    const body: unknown = await response.json().catch(() => null);
    if (!response.ok) throw new ApiError(response.status, errorMessage(response.status, body));
    return body as T;
  }

  return {
    listSources: (params = {}) => request(withQuery("/api/sources", params)),
    createSource: (name, signingSecret) =>
      request("/api/sources", { method: "POST", body: { name, signing_secret: signingSecret } }),
    listSubscriptions: (sourceId, params = {}) =>
      request(withQuery(`/api/sources/${sourceId}/subscriptions`, params)),
    createSubscription: (sourceId, input) =>
      request(`/api/sources/${sourceId}/subscriptions`, { method: "POST", body: input }),
    updateSubscription: (id, changes) => request(`/api/subscriptions/${id}`, { method: "PATCH", body: changes }),
    listEvents: (params = {}) => request(withQuery("/api/events", params)),
    getEvent: (id) => request(`/api/events/${id}`),
    listDeliveries: (params = {}) => request(withQuery("/api/deliveries", params)),
    replay: (id) => request(`/api/deliveries/${id}/replay`, { method: "POST" }),
  };
}
