import { useState, type FormEvent } from "react";
import type { Client, Source, Subscription } from "./api";
import { formatTime, messageOf } from "./format";
import { usePagedList } from "./usePagedList";

export function SourcesPage({ client }: { client: Client }) {
  const sources = usePagedList((_filter: object, before) => client.listSources({ before }), {});
  const [name, setName] = useState("");
  const [secret, setSecret] = useState("");
  const [created, setCreated] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [openId, setOpenId] = useState<number | null>(null);

  async function create(e: FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      const source = await client.createSource(name, secret);
      setCreated(`${window.location.origin}${source.ingest_path}`);
      sources.setItems((items) => [source, ...items]);
      setName("");
      setSecret("");
    } catch (err) {
      setError(messageOf(err));
    }
  }

  return (
    <section>
      <h2>Sources</h2>
      <form className="card toolbar" onSubmit={create}>
        <label>
          Name
          <input value={name} onChange={(e) => setName(e.target.value)} />
        </label>
        <label>
          Signing secret
          <input type="password" autoComplete="off" value={secret} onChange={(e) => setSecret(e.target.value)} />
        </label>
        <button type="submit">Create source</button>
      </form>
      {error && <p role="alert" className="error">{error}</p>}
      {created && (
        <p role="status" className="notice">
          Ingest URL: <code>{created}</code>. Copy it now: it will not be shown again.
        </p>
      )}
      {sources.error && <p role="alert" className="error">{sources.error}</p>}
      {sources.items.map((source) => (
        <SourceRow
          key={source.id}
          client={client}
          source={source}
          open={openId === source.id}
          onToggle={() => setOpenId(openId === source.id ? null : source.id)}
        />
      ))}
      {sources.hasMore && (
        <button type="button" onClick={sources.loadMore} disabled={sources.loading}>
          Load more
        </button>
      )}
    </section>
  );
}

interface SourceRowProps {
  client: Client;
  source: Source;
  open: boolean;
  onToggle: () => void;
}

function SourceRow({ client, source, open, onToggle }: SourceRowProps) {
  return (
    <div className="card">
      <div className="row">
        <strong>{source.name}</strong>
        <span className="muted">
          #{source.id}, created {formatTime(source.created_at)}
        </span>
        <button type="button" aria-expanded={open} aria-label={`Subscriptions for ${source.name}`} onClick={onToggle}>
          Subscriptions
        </button>
      </div>
      {open && <Subscriptions client={client} sourceId={source.id} />}
    </div>
  );
}

function Subscriptions({ client, sourceId }: { client: Client; sourceId: number }) {
  const list = usePagedList((_filter: object, before) => client.listSubscriptions(sourceId, { before }), {});
  const [url, setUrl] = useState("");
  const [eventFilter, setEventFilter] = useState("");
  const [secret, setSecret] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function add(e: FormEvent) {
    e.preventDefault();
    setError(null);
    try {
      const subscription = await client.createSubscription(sourceId, {
        url: url.trim(),
        event_filter: eventFilter.trim() || null,
      });
      setSecret(subscription.signing_secret);
      list.setItems((items) => [subscription, ...items]);
      setUrl("");
      setEventFilter("");
    } catch (err) {
      setError(messageOf(err));
    }
  }

  async function toggle(subscription: Subscription) {
    setError(null);
    try {
      const updated = await client.updateSubscription(subscription.id, { active: !subscription.active });
      list.setItems((items) => items.map((s) => (s.id === updated.id ? updated : s)));
    } catch (err) {
      setError(messageOf(err));
    }
  }

  return (
    <div>
      {list.items.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>URL</th>
              <th>Events</th>
              <th>State</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {list.items.map((subscription) => (
              <tr key={subscription.id}>
                <td className="mono">{subscription.url}</td>
                <td>{subscription.event_filter ?? "All"}</td>
                <td>{subscription.active ? "Active" : "Paused"}</td>
                <td>
                  <button type="button" onClick={() => toggle(subscription)}>
                    {subscription.active ? "Pause" : "Resume"}
                  </button>
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
      <form className="toolbar" onSubmit={add}>
        <label>
          URL
          <input value={url} onChange={(e) => setUrl(e.target.value)} placeholder="https://" />
        </label>
        <label>
          Event type filter (optional)
          <input value={eventFilter} onChange={(e) => setEventFilter(e.target.value)} />
        </label>
        <button type="submit">Add subscription</button>
      </form>
      {(error ?? list.error) && <p role="alert" className="error">{error ?? list.error}</p>}
      {secret && (
        <p role="status" className="notice">
          Signing secret: <code>{secret}</code>. Copy it now: it will not be shown again.
        </p>
      )}
    </div>
  );
}
