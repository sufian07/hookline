import { useEffect, useState } from "react";
import type { Client, EventDetail as Detail } from "./api";
import { canReplay, formatTime, messageOf } from "./format";
import { StatusBadge } from "./StatusBadge";

export function EventDetail({ client, id, canWrite = true }: { client: Client; id: number; canWrite?: boolean }) {
  const [event, setEvent] = useState<Detail | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setEvent(null);
    setError(null);
    client
      .getEvent(id)
      .then((loaded) => !cancelled && setEvent(loaded))
      .catch((e: unknown) => !cancelled && setError(messageOf(e)));
    return () => {
      cancelled = true;
    };
  }, [client, id]);

  async function replay(deliveryId: number) {
    setError(null);
    try {
      const updated = await client.replay(deliveryId);
      setEvent((current) =>
        current && {
          ...current,
          deliveries: current.deliveries.map((d) => (d.id === updated.id ? { ...d, ...updated } : d)),
        },
      );
    } catch (e) {
      setError(messageOf(e));
    }
  }

  return (
    <section>
      <p>
        <a href="#/events">← Events</a>
      </p>
      <h2>Event #{id}</h2>
      {error && <p role="alert" className="error">{error}</p>}
      {event && (
        <>
          <dl className="facts">
            <dt>Type</dt>
            <dd>{event.event_type}</dd>
            <dt>Source</dt>
            <dd>{event.source_id}</dd>
            <dt>Idempotency key</dt>
            <dd className="mono">{event.idempotency_key}</dd>
            <dt>Received</dt>
            <dd>{formatTime(event.received_at)}</dd>
          </dl>
          <h3>Payload</h3>
          <pre>{JSON.stringify(event.payload, null, 2)}</pre>
          <h3>Deliveries</h3>
          {event.deliveries.length === 0 && <p className="muted">No subscriptions matched this event.</p>}
          {event.deliveries.map((delivery) => (
            <div className="card" key={delivery.id}>
              <div className="row">
                <strong>
                  Delivery {delivery.id} to subscription {delivery.subscription_id}
                </strong>
                <StatusBadge status={delivery.status} />
                <span className="muted">
                  {delivery.attempts_count} of {delivery.attempt_limit} attempts
                </span>
                {canWrite && canReplay(delivery.status) && (
                  <button type="button" aria-label={`Replay delivery ${delivery.id}`} onClick={() => replay(delivery.id)}>
                    Replay
                  </button>
                )}
              </div>
              {delivery.attempts.length > 0 && (
                <table aria-label={`Attempts for delivery ${delivery.id}`}>
                  <thead>
                    <tr>
                      <th>#</th>
                      <th>Response</th>
                      <th>Error</th>
                      <th>Duration</th>
                      <th>At</th>
                    </tr>
                  </thead>
                  <tbody>
                    {delivery.attempts.map((attempt) => (
                      <tr key={attempt.number}>
                        <td>{attempt.number}</td>
                        <td>{attempt.response_code ?? "—"}</td>
                        <td className="mono">{attempt.error ?? "—"}</td>
                        <td>{attempt.duration_ms} ms</td>
                        <td>{formatTime(attempt.created_at)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          ))}
        </>
      )}
    </section>
  );
}
