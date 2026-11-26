import { render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, it, vi } from "vitest";
import { ApiError, type EventDetail as Detail } from "./api";
import { EventDetail } from "./EventDetail";
import { attempt, delivery, event, fakeClient } from "./test/fakes";

function detail(status: "dead" | "pending" = "dead"): Detail {
  return {
    ...event({ id: 5 }),
    payload: { order: 42 },
    deliveries: [
      {
        ...delivery({ id: 9, status, attempts_count: 2 }),
        attempts: [
          attempt({ number: 1, response_code: 500 }),
          attempt({ number: 2, response_code: null, error: "Net::OpenTimeout" }),
        ],
      },
    ],
  };
}

it("shows the payload and every attempt", async () => {
  render(<EventDetail id={5} client={fakeClient({ getEvent: vi.fn().mockResolvedValue(detail()) })} />);

  expect(await screen.findByText(/"order": 42/)).toBeInTheDocument();
  const attempts = screen.getByRole("table", { name: "Attempts for delivery 9" });
  expect(within(attempts).getByText("500")).toBeInTheDocument();
  expect(within(attempts).getByText("Net::OpenTimeout")).toBeInTheDocument();
});

it("replays a dead delivery and shows its new status", async () => {
  const replay = vi.fn().mockResolvedValue(delivery({ id: 9, status: "pending", attempts_count: 2 }));
  render(<EventDetail id={5} client={fakeClient({ getEvent: vi.fn().mockResolvedValue(detail()), replay })} />);

  await userEvent.click(await screen.findByRole("button", { name: "Replay delivery 9" }));

  expect(replay).toHaveBeenCalledWith(9);
  expect(await screen.findByText("pending")).toBeInTheDocument();
  expect(screen.queryByRole("button", { name: "Replay delivery 9" })).not.toBeInTheDocument();
});

it("offers no replay while a delivery is still pending", async () => {
  render(<EventDetail id={5} client={fakeClient({ getEvent: vi.fn().mockResolvedValue(detail("pending")) })} />);

  expect(await screen.findByText("pending")).toBeInTheDocument();
  expect(screen.queryByRole("button", { name: /Replay/ })).not.toBeInTheDocument();
});

it("shows why a replay failed", async () => {
  const replay = vi.fn().mockRejectedValue(new ApiError(409, "only dead or delivered deliveries can be replayed"));
  render(<EventDetail id={5} client={fakeClient({ getEvent: vi.fn().mockResolvedValue(detail()), replay })} />);

  await userEvent.click(await screen.findByRole("button", { name: "Replay delivery 9" }));

  expect(await screen.findByRole("alert")).toHaveTextContent("only dead or delivered deliveries can be replayed");
});
