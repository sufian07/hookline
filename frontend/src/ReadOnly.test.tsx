import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, it, vi } from "vitest";
import { ApiError } from "./api";
import { App } from "./App";
import { DeliveriesPage } from "./DeliveriesPage";
import { EventDetail } from "./EventDetail";
import { SourcesPage } from "./SourcesPage";
import { attempt, delivery, event, fakeClient, page, source, subscription } from "./test/fakes";

it("signs in with a read-only token and says so", async () => {
  const client = fakeClient({ session: vi.fn().mockResolvedValue({ role: "viewer" }) });
  render(<App makeClient={vi.fn(() => client)} />);

  await userEvent.type(screen.getByLabelText("Access token"), "demo");
  await userEvent.click(screen.getByRole("button", { name: "Sign in" }));

  expect(await screen.findByText(/Read-only demo/)).toBeInTheDocument();
});

it("forgets a stored token that is no longer accepted", async () => {
  sessionStorage.setItem("hookline.token", "old");
  const client = fakeClient({ session: vi.fn().mockRejectedValue(new ApiError(401, "nope")) });
  render(<App makeClient={vi.fn(() => client)} />);

  expect(await screen.findByLabelText("Access token")).toBeInTheDocument();
  expect(sessionStorage.getItem("hookline.token")).toBeNull();
});

it("hides replay on an event for a viewer", async () => {
  const getEvent = vi.fn().mockResolvedValue({
    ...event({ id: 5 }),
    payload: {},
    deliveries: [{ ...delivery({ id: 9, status: "dead" }), attempts: [attempt({ response_code: 500 })] }],
  });
  render(<EventDetail id={5} canWrite={false} client={fakeClient({ getEvent })} />);

  expect(await screen.findByText("dead")).toBeInTheDocument();
  expect(screen.queryByRole("button", { name: /Replay/ })).not.toBeInTheDocument();
});

it("hides replay in the deliveries list for a viewer", async () => {
  const listDeliveries = vi.fn().mockResolvedValue(page([delivery({ id: 4, status: "dead" })]));
  render(<DeliveriesPage canWrite={false} client={fakeClient({ listDeliveries })} />);

  expect(await screen.findByText("dead")).toBeInTheDocument();
  expect(screen.queryByRole("button", { name: /Replay/ })).not.toBeInTheDocument();
});

it("shows sources and subscriptions to a viewer without any way to change them", async () => {
  const client = fakeClient({
    listSources: vi.fn().mockResolvedValue(page([source()])),
    listSubscriptions: vi.fn().mockResolvedValue(page([subscription()])),
  });
  render(<SourcesPage canWrite={false} client={client} />);

  await userEvent.click(await screen.findByRole("button", { name: "Subscriptions for Shop" }));

  expect(await screen.findByText("https://receiver.example.com/hooks")).toBeInTheDocument();
  expect(screen.queryByRole("button", { name: "Create source" })).not.toBeInTheDocument();
  expect(screen.queryByRole("button", { name: "Pause" })).not.toBeInTheDocument();
  expect(screen.queryByRole("button", { name: "Add subscription" })).not.toBeInTheDocument();
});
