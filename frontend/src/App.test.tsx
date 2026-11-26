import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, it, vi } from "vitest";
import { App } from "./App";
import { fakeClient } from "./test/fakes";

it("asks for a token first, then remembers it for this browser tab", async () => {
  render(<App makeClient={vi.fn(() => fakeClient())} />);

  await userEvent.type(screen.getByLabelText("Admin token"), "good");
  await userEvent.click(screen.getByRole("button", { name: "Sign in" }));

  expect(await screen.findByRole("link", { name: "Events" })).toBeInTheDocument();
  expect(sessionStorage.getItem("hookline.token")).toBe("good");
});

it("signs out", async () => {
  sessionStorage.setItem("hookline.token", "good");
  render(<App makeClient={vi.fn(() => fakeClient())} />);

  await userEvent.click(await screen.findByRole("button", { name: "Sign out" }));

  expect(screen.getByLabelText("Admin token")).toBeInTheDocument();
  expect(sessionStorage.getItem("hookline.token")).toBeNull();
});

it("opens an event from its link", async () => {
  sessionStorage.setItem("hookline.token", "good");
  window.location.hash = "#/events/5";
  const getEvent = vi.fn().mockResolvedValue({
    id: 5,
    source_id: 1,
    event_type: "order.paid",
    idempotency_key: "evt-5",
    received_at: "2026-11-26T08:30:00.000Z",
    payload: {},
    deliveries: [],
  });
  render(<App makeClient={vi.fn(() => fakeClient({ getEvent }))} />);

  expect(await screen.findByRole("heading", { name: "Event #5" })).toBeInTheDocument();
  expect(getEvent).toHaveBeenCalledWith(5);
});
