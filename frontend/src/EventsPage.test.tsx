import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, it, vi } from "vitest";
import { EventsPage } from "./EventsPage";
import { event, fakeClient, page } from "./test/fakes";

it("lists events and loads the next page", async () => {
  const listEvents = vi
    .fn()
    .mockResolvedValueOnce(page([event({ id: 2 })], 2))
    .mockResolvedValueOnce(page([event({ id: 1, event_type: "order.refunded" })]));
  render(<EventsPage client={fakeClient({ listEvents })} />);

  expect(await screen.findByText("order.paid")).toBeInTheDocument();
  await userEvent.click(screen.getByRole("button", { name: "Load more" }));

  expect(await screen.findByText("order.refunded")).toBeInTheDocument();
  expect(screen.getByText("order.paid")).toBeInTheDocument();
  expect(listEvents).toHaveBeenLastCalledWith({ event_type: "", before: 2 });
  expect(screen.queryByRole("button", { name: "Load more" })).not.toBeInTheDocument();
});

it("filters by event type from the first page", async () => {
  const listEvents = vi.fn().mockResolvedValue(page([]));
  render(<EventsPage client={fakeClient({ listEvents })} />);

  await userEvent.type(screen.getByLabelText("Event type"), "order.refunded");
  await userEvent.click(screen.getByRole("button", { name: "Filter" }));

  expect(listEvents).toHaveBeenLastCalledWith({ event_type: "order.refunded", before: undefined });
  expect(await screen.findByText("No events yet.")).toBeInTheDocument();
});

it("links each event to its detail", async () => {
  render(<EventsPage client={fakeClient({ listEvents: vi.fn().mockResolvedValue(page([event({ id: 7 })])) })} />);

  expect(await screen.findByRole("link", { name: "#7" })).toHaveAttribute("href", "#/events/7");
});

it("shows a load error", async () => {
  render(<EventsPage client={fakeClient({ listEvents: vi.fn().mockRejectedValue(new Error("Network down")) })} />);

  expect(await screen.findByRole("alert")).toHaveTextContent("Network down");
});
