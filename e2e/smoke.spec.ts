import { expect, test } from "@playwright/test";

test("landing page states only source builds and has no binary links", async ({ page }) => {
  await page.goto("/");
  await expect(page).toHaveTitle("CERBERUS | Cross-Platform Security Toolkit");
  await expect(page.getByRole("heading", { level: 1, name: "CERBERUS" })).toBeVisible();
  await expect(page.getByRole("heading", { name: "WindowsGuardianWatchdog" }).first()).toBeVisible();
  await expect(page.getByRole("heading", { name: "LinuxGuardianWatchdog" }).first()).toBeVisible();
  await expect(page.getByRole("heading", { name: "MacGuardianWatchdog" }).first()).toBeVisible();

  const hrefs = await page.locator("a").evaluateAll((anchors) =>
    anchors.map((anchor) => anchor.getAttribute("href") ?? ""),
  );
  for (const href of hrefs) {
    if (/\.zip$/i.test(href)) {
      expect(href).toMatch(
        /^https:\/\/github\.com\/abelxmendoza\/(?:Linux|Mac)GuardianWatchdog\/archive\/[0-9a-f]{40}\.zip$/,
      );
    }
    expect(href).not.toMatch(/\.(exe|msi|msix|dmg|pkg|deb|rpm)$/i);
    if (href.startsWith("http")) {
      const rel = await page.locator(`a[href="${href}"]`).first().getAttribute("rel");
      expect(rel).toContain("noopener");
      expect(rel).toContain("noreferrer");
    }
  }

  const overflow = await page.evaluate(() => {
    return document.documentElement.scrollWidth - document.documentElement.clientWidth;
  });
  expect(overflow).toBeLessThanOrEqual(1);
});

test("mobile menu and linux tab work", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto("/");
  await page.getByRole("button", { name: "Open menu" }).click();
  await page.getByRole("link", { name: "Guardians", exact: true }).click();
  await expect(page.locator("#guardians")).toBeInViewport();
  await page.getByRole("tab", { name: "LINUX" }).click();
  await expect(page.getByRole("tab", { name: "LINUX" })).toHaveAttribute("aria-selected", "true");
});

test("reduced motion disables the wolf glow animation", async ({ page }) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("/");
  const name = await page.locator(".wolf-glow").first().evaluate((element) => {
    return getComputedStyle(element).animationName;
  });
  expect(name).toBe("none");
});
