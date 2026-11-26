import { useState, type FormEvent } from "react";
import type { Client } from "./api";
import { formatTime } from "./format";
import { usePagedList } from "./usePagedList";

export function EventsPage({ client }: { client: Client }) {
  const [draft, setDraft] = useState("");
  const [eventType, setEventType] = useState("");
  const list = usePagedList((filter: { event_type: string }, before) => client.listEvents({ ...filter, before }), {
    event_type: eventType,
  });

  function applyFilter(e: FormEvent) {
    e.preventDefault();
    setEventType(draft.trim());
  }

  return (
    <section>
      <h2>Events</h2>
      <form className="toolbar" onSubmit={applyFilter}>
        <label>
          Event type
          <input value={draft} onChange={(e) => setDraft(e.target.value)} placeholder="order.paid" />
        </label>
        <button type="submit">Filter</button>
      </form>
      {list.error && <p role="alert" className="error">{list.error}</p>}
      {!list.loading && !list.error && list.items.length === 0 && <p className="muted">No events yet.</p>}
      {list.items.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Event</th>
              <th>Type</th>
              <th>Source</th>
              <th>Idempotency key</th>
              <th>Received</th>
            </tr>
          </thead>
          <tbody>
            {list.items.map((event) => (
              <tr key={event.id}>
                <td>
                  <a href={`#/events/${event.id}`}>#{event.id}</a>
                </td>
                <td>{event.event_type}</td>
                <td>{event.source_id}</td>
                <td className="mono">{event.idempotency_key}</td>
                <td>{formatTime(event.received_at)}</td>
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
