import { useState } from "react";
import type { Client, DeliveryStatus } from "./api";
import { canReplay, formatTime, messageOf } from "./format";
import { StatusBadge } from "./StatusBadge";
import { usePagedList } from "./usePagedList";

const STATUSES: { value: DeliveryStatus; label: string }[] = [
  { value: "dead", label: "Dead" },
  { value: "pending", label: "Pending" },
  { value: "delivering", label: "Delivering" },
  { value: "delivered", label: "Delivered" },
];

export function DeliveriesPage({ client }: { client: Client }) {
  const [status, setStatus] = useState<DeliveryStatus>("dead");
  const [actionError, setActionError] = useState<string | null>(null);
  const list = usePagedList((filter: { status: DeliveryStatus }, before) => client.listDeliveries({ ...filter, before }), {
    status,
  });

  async function replay(id: number) {
    setActionError(null);
    try {
      const updated = await client.replay(id);
      list.setItems((items) => items.map((d) => (d.id === id ? updated : d)));
    } catch (e) {
      setActionError(messageOf(e));
    }
  }

  const error = actionError ?? list.error;

  return (
    <section>
      <h2>Deliveries</h2>
      <div className="toolbar">
        <label>
          Status
          <select value={status} onChange={(e) => setStatus(e.target.value as DeliveryStatus)}>
            {STATUSES.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </label>
      </div>
      {error && <p role="alert" className="error">{error}</p>}
      {!list.loading && !list.error && list.items.length === 0 && <p className="muted">Nothing here.</p>}
      {list.items.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Delivery</th>
              <th>Event</th>
              <th>Subscription</th>
              <th>Status</th>
              <th>Attempts</th>
              <th>Next attempt</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {list.items.map((delivery) => (
              <tr key={delivery.id}>
                <td>{delivery.id}</td>
                <td>
                  <a href={`#/events/${delivery.event_id}`}>#{delivery.event_id}</a>
                </td>
                <td>{delivery.subscription_id}</td>
                <td>
                  <StatusBadge status={delivery.status} />
                </td>
                <td>
                  {delivery.attempts_count} / {delivery.attempt_limit}
                </td>
                <td>{delivery.status === "pending" ? formatTime(delivery.next_attempt_at) : "—"}</td>
                <td>
                  {canReplay(delivery.status) && (
                    <button type="button" aria-label={`Replay delivery ${delivery.id}`} onClick={() => replay(delivery.id)}>
                      Replay
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
      {list.hasMore && (
        <button type="button" onClick={list.loadMore} disabled={list.loading}>
          Load more
        </button>
      )}
    </section>
  );
}
