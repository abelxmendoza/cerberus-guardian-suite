import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import { Cerberus } from "../pages/Cerberus";

describe("Cerberus page", () => {
  it("offers Linux and macOS downloads and keeps Windows in development", () => {
    render(<Cerberus />);
    expect(screen.getByRole("heading", { level: 1, name: "CERBERUS" })).toBeInTheDocument();
    expect(
      screen.getByRole("heading", {
        level: 2,
        name: /built by an engineer\. for people who value privacy, security, control\./i,
      }),
    ).toBeInTheDocument();
    expect(screen.getAllByRole("link", { name: "Download for Linux" }).length).toBeGreaterThan(0);
    expect(screen.getAllByRole("link", { name: "Download for macOS" }).length).toBeGreaterThan(0);
    expect(screen.getAllByText(/in development — no download yet/i).length).toBeGreaterThan(0);
    const binaries = screen.getAllByRole("link").map((link) => link.getAttribute("href") ?? "");
    expect(binaries.some((href) => /\.(exe|msi|msix|dmg|pkg|deb|rpm)$/i.test(href))).toBe(false);
    expect(binaries.every((href) => href.length > 0 && !href.endsWith("#"))).toBe(true);
  });

  it("switches the screenshot tab without claiming a real capture", async () => {
    const user = userEvent.setup();
    render(<Cerberus />);
    await user.click(screen.getByRole("tab", { name: "LINUX" }));
    expect(screen.getByRole("tab", { name: "LINUX" })).toHaveAttribute("aria-selected", "true");
    expect(screen.getAllByText(/no screenshot published/i).length).toBeGreaterThan(0);
  });

  it("opens the mobile navigation", async () => {
    const user = userEvent.setup();
    render(<Cerberus />);
    await user.click(screen.getByRole("button", { name: "Open menu" }));
    expect(screen.getByRole("button", { name: "Close menu" })).toHaveAttribute("aria-expanded", "true");
  });
});
