import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, it, vi } from "vitest";
import { DeliveriesPage } from "./DeliveriesPage";
import { delivery, fakeClient, page } from "./test/fakes";

it("starts with dead deliveries, which are the ones that need attention", async () => {
  const listDeliveries = vi.fn().mockResolvedValue(page([delivery({ id: 4, status: "dead" })]));
  render(<DeliveriesPage client={fakeClient({ listDeliveries })} />);

  expect(await screen.findByText("dead")).toBeInTheDocument();
  expect(listDeliveries).toHaveBeenCalledWith({ status: "dead", before: undefined });
});

it("switches status", async () => {
  const listDeliveries = vi.fn().mockResolvedValue(page([]));
  render(<DeliveriesPage client={fakeClient({ listDeliveries })} />);

  await userEvent.selectOptions(screen.getByLabelText("Status"), "delivered");

  expect(listDeliveries).toHaveBeenLastCalledWith({ status: "delivered", before: undefined });
});

it("replays from the list", async () => {
  const listDeliveries = vi.fn().mockResolvedValue(page([delivery({ id: 4, status: "dead" })]));
  const replay = vi.fn().mockResolvedValue(delivery({ id: 4, status: "pending" }));
  render(<DeliveriesPage client={fakeClient({ listDeliveries, replay })} />);

  await userEvent.click(await screen.findByRole("button", { name: "Replay delivery 4" }));

  expect(await screen.findByText("pending")).toBeInTheDocument();
});

it("links each delivery to its event", async () => {
  const listDeliveries = vi.fn().mockResolvedValue(page([delivery({ id: 4, event_id: 12, status: "dead" })]));
  render(<DeliveriesPage client={fakeClient({ listDeliveries })} />);

  expect(await screen.findByRole("link", { name: "#12" })).toHaveAttribute("href", "#/events/12");
});
