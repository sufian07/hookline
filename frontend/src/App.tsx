import { useEffect, useMemo, useState } from "react";
import { createClient, type Client, type Role } from "./api";
import { DeliveriesPage } from "./DeliveriesPage";
import { EventDetail } from "./EventDetail";
import { EventsPage } from "./EventsPage";
import { SourcesPage } from "./SourcesPage";
import { TokenForm } from "./TokenForm";

const TOKEN_KEY = "hookline.token";

type Route = { name: "events" } | { name: "event"; id: number } | { name: "deliveries" } | { name: "sources" };

function parseRoute(hash: string): Route {
  const event = hash.match(/^#\/events\/(\d+)$/);
  if (event) return { name: "event", id: Number(event[1]) };
  if (hash === "#/deliveries") return { name: "deliveries" };
  if (hash === "#/sources") return { name: "sources" };
  return { name: "events" };
}

function useRoute(): Route {
  const [hash, setHash] = useState(window.location.hash);
  useEffect(() => {
    const update = () => setHash(window.location.hash);
    window.addEventListener("hashchange", update);
    return () => window.removeEventListener("hashchange", update);
  }, []);
  return parseRoute(hash);
}

// Session storage: the token lasts for this tab only and is never written to disk long-term.
function readToken(): string | null {
  try {
    return sessionStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

function writeToken(token: string | null) {
  try {
    if (token) sessionStorage.setItem(TOKEN_KEY, token);
    else sessionStorage.removeItem(TOKEN_KEY);
  } catch {
    // Storage can be unavailable (private mode); the session then lasts until reload.
  }
}

export function App({ makeClient = createClient }: { makeClient?: (token: string) => Client }) {
  const [token, setToken] = useState<string | null>(readToken);
  const [role, setRole] = useState<Role | null>(null);
  const client = useMemo(() => (token ? makeClient(token) : null), [token, makeClient]);
  const route = useRoute();

  function signIn(accepted: string, acceptedRole: Role) {
    writeToken(accepted);
    setToken(accepted);
    setRole(acceptedRole);
  }

  function signOut() {
    writeToken(null);
    setToken(null);
    setRole(null);
  }

  // A token remembered from earlier in this tab is checked again, since it may have been rotated.
  useEffect(() => {
    if (!client || role) return;
    let cancelled = false;
    client
      .session()
      .then((session) => !cancelled && setRole(session.role))
      .catch(() => !cancelled && signOut());
    return () => {
      cancelled = true;
    };
  }, [client, role]);

  if (!client) {
    return (
      <main>
        <TokenForm
          verify={(candidate) => makeClient(candidate).session().then((session) => session.role)}
          onAccept={signIn}
        />
      </main>
    );
  }

  if (!role) {
    return (
      <main>
        <p className="muted">Checking access…</p>
      </main>
    );
  }

  const canWrite = role === "admin";

  return (
    <>
      <header>
        <strong>Hookline</strong>
        <nav>
          <a href="#/events" aria-current={route.name.startsWith("event") ? "page" : undefined}>
            Events
          </a>
          <a href="#/deliveries" aria-current={route.name === "deliveries" ? "page" : undefined}>
            Deliveries
          </a>
          <a href="#/sources" aria-current={route.name === "sources" ? "page" : undefined}>
            Sources
          </a>
        </nav>
        <button type="button" onClick={signOut}>
          Sign out
        </button>
      </header>
      <main>
        {!canWrite && (
          <p className="notice">Read-only demo: you can browse everything here, but changes are turned off.</p>
        )}
        {route.name === "events" && <EventsPage client={client} />}
        {route.name === "event" && <EventDetail client={client} id={route.id} canWrite={canWrite} />}
        {route.name === "deliveries" && <DeliveriesPage client={client} canWrite={canWrite} />}
        {route.name === "sources" && <SourcesPage client={client} canWrite={canWrite} />}
      </main>
    </>
  );
}
