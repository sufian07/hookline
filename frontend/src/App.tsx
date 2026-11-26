import { useEffect, useMemo, useState } from "react";
import { createClient, type Client } from "./api";
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
  const client = useMemo(() => (token ? makeClient(token) : null), [token, makeClient]);
  const route = useRoute();

  function signIn(accepted: string) {
    writeToken(accepted);
    setToken(accepted);
  }

  function signOut() {
    writeToken(null);
    setToken(null);
  }

  if (!client) {
    return (
      <main>
        <TokenForm verify={(candidate) => makeClient(candidate).listSources().then(() => undefined)} onAccept={signIn} />
      </main>
    );
  }

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
        {route.name === "events" && <EventsPage client={client} />}
        {route.name === "event" && <EventDetail client={client} id={route.id} />}
        {route.name === "deliveries" && <DeliveriesPage client={client} />}
        {route.name === "sources" && <SourcesPage client={client} />}
      </main>
    </>
  );
}
