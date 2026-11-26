import { describe, expect, it, vi } from "vitest";
import { ApiError, createClient } from "./api";

function respond(status: number, body?: unknown) {
  return vi.fn().mockResolvedValue(
    new Response(body === undefined ? null : JSON.stringify(body), {
      status,
      headers: { "Content-Type": "application/json" },
    }),
  );
}

describe("api client", () => {
  it("sends the token and leaves blank filters out of the query", async () => {
    const fetch = respond(200, { data: [], next_cursor: null });

    await createClient("t0k", fetch).listEvents({ event_type: "order.paid", before: 41 });

    const [url, init] = fetch.mock.calls[0];
    expect(url).toBe("/api/events?event_type=order.paid&before=41");
    expect(new Headers(init.headers).get("Authorization")).toBe("Bearer t0k");
  });

  it("sends JSON bodies", async () => {
    const fetch = respond(201, { id: 1, name: "Shop", token: "x", ingest_path: "/in/x", created_at: "" });

    await createClient("t0k", fetch).createSource("Shop", "s3cret", "stripe");

    const [url, init] = fetch.mock.calls[0];
    expect(url).toBe("/api/sources");
    expect(init.method).toBe("POST");
    expect(new Headers(init.headers).get("Content-Type")).toBe("application/json");
    expect(JSON.parse(init.body)).toEqual({ name: "Shop", signing_secret: "s3cret", verification: "stripe" });
  });

  it("surfaces the server's error message and status", async () => {
    const client = createClient("t0k", respond(409, { error: "only dead or delivered deliveries can be replayed" }));

    const error = await client.replay(9).catch((e: unknown) => e);

    expect(error).toBeInstanceOf(ApiError);
    expect(error).toMatchObject({ status: 409, message: "only dead or delivered deliveries can be replayed" });
  });

  it("joins validation errors", async () => {
    const client = createClient("t0k", respond(422, { errors: ["Url must be https", "Url is too long"] }));

    await expect(client.createSubscription(1, { url: "http://x", event_filter: null })).rejects.toThrow(
      "Url must be https, Url is too long",
    );
  });

  it("asks the API which role the token has", async () => {
    const fetch = respond(200, { role: "viewer" });

    await expect(createClient("t0k", fetch).session()).resolves.toEqual({ role: "viewer" });
    expect(fetch.mock.calls[0][0]).toBe("/api/session");
  });
});
