// Playwright configuration for Snap!Cloud end-to-end and accessibility tests.
// See https://playwright.dev/docs/test-configuration

// @ts-check
const { defineConfig, devices } = require('@playwright/test');

const BASE_URL = process.env.SNAPCLOUD_BASE_URL || 'http://localhost:8080';

module.exports = defineConfig({
    testDir: './spec/e2e',
    // Each spec is independent; avoid "flaky test passes on retry" lies in CI.
    retries: process.env.CI ? 1 : 0,
    // Force serial workers locally to make failures easier to reproduce.
    workers: process.env.CI ? 2 : 1,
    reporter: process.env.CI
        ? [['list'], ['html', { open: 'never' }]]
        : [['list']],

    use: {
        baseURL: BASE_URL,
        // Screenshots and traces only on failure keeps artifact size down.
        screenshot: 'only-on-failure',
        trace: 'retain-on-failure',
    },

    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
    ],

    // Local convenience: if the app server isn't already running, boot it.
    // In CI the workflow starts the server itself (so we can keep the axe
    // job and the e2e job sharing one setup), so we skip this branch there.
    webServer: process.env.CI
        ? undefined
        : {
            command: 'lapis server test',
            url: BASE_URL,
            reuseExistingServer: true,
            timeout: 60_000,
            env: {
                LAPIS_ENVIRONMENT: 'test',
                DATABASE_NAME: 'snapcloud_test',
            },
        },
});
