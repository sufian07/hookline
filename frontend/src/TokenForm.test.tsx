import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { expect, it, vi } from "vitest";
import { ApiError } from "./api";
import { TokenForm } from "./TokenForm";

it("hands over the token only after the API accepts it", async () => {
  const verify = vi.fn().mockResolvedValue(undefined);
  const onAccept = vi.fn();
  render(<TokenForm verify={verify} onAccept={onAccept} />);

  await userEvent.type(screen.getByLabelText("Admin token"), "good");
  await userEvent.click(screen.getByRole("button", { name: "Sign in" }));

  expect(verify).toHaveBeenCalledWith("good");
  expect(onAccept).toHaveBeenCalledWith("good");
});

it("explains a rejected token", async () => {
  const onAccept = vi.fn();
  render(<TokenForm verify={vi.fn().mockRejectedValue(new ApiError(401, "nope"))} onAccept={onAccept} />);

  await userEvent.type(screen.getByLabelText("Admin token"), "bad");
  await userEvent.click(screen.getByRole("button", { name: "Sign in" }));

  expect(await screen.findByRole("alert")).toHaveTextContent("That token was not accepted.");
  expect(onAccept).not.toHaveBeenCalled();
});
