import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, it, vi } from "vitest";
import { SourcesPage } from "./SourcesPage";
import { fakeClient, page, source, subscription } from "./test/fakes";

it("creates a source and shows its token once", async () => {
  const createSource = vi.fn().mockResolvedValue({ ...source({ id: 2 }), token: "tok123", ingest_path: "/in/tok123" });
  render(<SourcesPage client={fakeClient({ createSource })} />);

  await userEvent.type(screen.getByLabelText("Name"), "Shop");
  await userEvent.type(screen.getByLabelText("Signing secret"), "s3cret");
  await userEvent.click(screen.getByRole("button", { name: "Create source" }));

  expect(createSource).toHaveBeenCalledWith("Shop", "s3cret", "hookline");
  expect(await screen.findByRole("status")).toHaveTextContent("/in/tok123");
  expect(screen.getByRole("button", { name: "Subscriptions for Shop" })).toBeInTheDocument();
});

it("shows a validation error", async () => {
  const createSource = vi.fn().mockRejectedValue(new Error("Name can't be blank"));
  render(<SourcesPage client={fakeClient({ createSource })} />);

  await userEvent.click(screen.getByRole("button", { name: "Create source" }));

  expect(await screen.findByRole("alert")).toHaveTextContent("Name can't be blank");
});

it("adds a subscription and shows its signing secret once", async () => {
  const createSubscription = vi.fn().mockResolvedValue({ ...subscription({ id: 8 }), signing_secret: "whsec" });
  const client = fakeClient({ listSources: vi.fn().mockResolvedValue(page([source()])), createSubscription });
  render(<SourcesPage client={client} />);

  await userEvent.click(await screen.findByRole("button", { name: "Subscriptions for Shop" }));
  await userEvent.type(screen.getByLabelText("URL"), "https://r.example.com/hooks");
  await userEvent.click(screen.getByRole("button", { name: "Add subscription" }));

  expect(createSubscription).toHaveBeenCalledWith(1, { url: "https://r.example.com/hooks", event_filter: null });
  expect(await screen.findByRole("status")).toHaveTextContent("whsec");
});

it("pauses and resumes a subscription", async () => {
  const updateSubscription = vi.fn().mockResolvedValue(subscription({ active: false }));
  const client = fakeClient({
    listSources: vi.fn().mockResolvedValue(page([source()])),
    listSubscriptions: vi.fn().mockResolvedValue(page([subscription()])),
    updateSubscription,
  });
  render(<SourcesPage client={client} />);

  await userEvent.click(await screen.findByRole("button", { name: "Subscriptions for Shop" }));
  await userEvent.click(await screen.findByRole("button", { name: "Pause" }));

  expect(updateSubscription).toHaveBeenCalledWith(3, { active: false });
  expect(await screen.findByRole("button", { name: "Resume" })).toBeInTheDocument();
});

it("creates a Stripe-signed source and labels it", async () => {
  const createSource = vi
    .fn()
    .mockResolvedValue({ ...source({ id: 2, name: "Stripe", verification: "stripe" }), token: "t", ingest_path: "/in/t" });
  render(<SourcesPage client={fakeClient({ createSource })} />);

  await userEvent.type(screen.getByLabelText("Name"), "Stripe");
  await userEvent.type(screen.getByLabelText("Signing secret"), "whsec_x");
  await userEvent.selectOptions(screen.getByLabelText("Signature scheme"), "stripe");
  await userEvent.click(screen.getByRole("button", { name: "Create source" }));

  expect(createSource).toHaveBeenCalledWith("Stripe", "whsec_x", "stripe");
  expect(await screen.findByText("Stripe-signed")).toBeInTheDocument();
});
