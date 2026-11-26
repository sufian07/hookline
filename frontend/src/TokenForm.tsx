import { useState, type FormEvent } from "react";
import { ApiError } from "./api";
import { messageOf } from "./format";

interface Props {
  verify: (token: string) => Promise<void>;
  onAccept: (token: string) => void;
}

export function TokenForm({ verify, onAccept }: Props) {
  const [token, setToken] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await verify(token);
      onAccept(token);
    } catch (err) {
      setError(err instanceof ApiError && err.status === 401 ? "That token was not accepted." : messageOf(err));
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="card narrow" onSubmit={submit}>
      <h1>Hookline</h1>
      <label>
        Admin token
        <input type="password" autoComplete="off" value={token} onChange={(e) => setToken(e.target.value)} />
      </label>
      {error && <p role="alert" className="error">{error}</p>}
      <button type="submit" disabled={busy || token === ""}>
        Sign in
      </button>
    </form>
  );
}
