// spec/e2e/homepage.spec.js
// =========================
//
// Smoke tests that exercise the Snap!Cloud homepage end-to-end. These
// require a running app server (see playwright.config.js `webServer`).

const { test, expect } = require('@playwright/test');

test.describe('homepage', () => {
    test('loads and responds 200', async ({ page }) => {
        const response = await page.goto('/');
        expect(response?.status()).toBe(200);
    });

    test('renders the primary Run Snap! call-to-action', async ({ page }) => {
        await page.goto('/');
        // The localized button text ends with "Run Snap!" but includes
        // HTML for the logo — match on the link target instead.
        const runLink = page.locator('a[href="/snap"]').first();
        await expect(runLink).toBeVisible();
    });

    test('serves the embedded editor page', async ({ page }) => {
        const response = await page.goto('/embed');
        // /embed redirects or renders; anything 2xx/3xx is fine, we're just
        // making sure it isn't 500.
        expect(response?.status()).toBeLessThan(500);
    });
});
