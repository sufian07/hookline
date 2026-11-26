import { vi } from "vitest";
import type { Attempt, Client, Delivery, EventSummary, Page, Source, Subscription } from "../api";

export function page<T>(data: T[], next_cursor: number | null = null): Page<T> {
  return { data, next_cursor };
}

export function fakeClient(overrides: Partial<Client> = {}): Client {
  const empty = () => Promise.resolve(page([]));
  return {
    session: vi.fn(() => Promise.resolve({ role: "admin" as const })),
    listSources: vi.fn(empty),
    createSource: vi.fn(),
    listSubscriptions: vi.fn(empty),
    createSubscription: vi.fn(),
    updateSubscription: vi.fn(),
    listEvents: vi.fn(empty),
    getEvent: vi.fn(),
    listDeliveries: vi.fn(empty),
    replay: vi.fn(),
    ...overrides,
  } as Client;
}

export function event(overrides: Partial<EventSummary> = {}): EventSummary {
  return {
    id: 1,
    source_id: 1,
    event_type: "order.paid",
    idempotency_key: "evt-1",
    received_at: "2026-11-26T08:30:00.000Z",
    ...overrides,
  };
}

export function delivery(overrides: Partial<Delivery> = {}): Delivery {
  return {
    id: 1,
    event_id: 1,
    subscription_id: 1,
    status: "pending",
    attempts_count: 0,
    attempt_limit: 8,
    next_attempt_at: "2026-11-26T08:31:00.000Z",
    updated_at: "2026-11-26T08:30:00.000Z",
    ...overrides,
  };
}

export function attempt(overrides: Partial<Attempt> = {}): Attempt {
  return {
    number: 1,
    response_code: 200,
    error: null,
    duration_ms: 120,
    created_at: "2026-11-26T08:30:01.000Z",
    ...overrides,
  };
}

export function source(overrides: Partial<Source> = {}): Source {
  return { id: 1, name: "Shop", created_at: "2026-11-26T08:00:00.000Z", ...overrides };
}

export function subscription(overrides: Partial<Subscription> = {}): Subscription {
  return {
    id: 3,
    source_id: 1,
    url: "https://receiver.example.com/hooks",
    event_filter: null,
    active: true,
    created_at: "2026-11-26T08:00:00.000Z",
    ...overrides,
  };
}
