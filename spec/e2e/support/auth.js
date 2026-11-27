// spec/e2e/support/auth.js
// ========================
//
// Log a seeded user in by driving the real /api/v1/users/:username/login
// endpoint from Playwright's request context. The resulting session
// cookie is written onto the page's browser context, so subsequent
// navigation is authenticated as that user.
//
// Prefer this to UI-driven login whenever the test isn't actually
// checking the login form — it's faster and removes an unrelated
// failure mode from the spec under test.

const { clientHashedPassword } = require('./fixtures');

/**
 * Log `username` / `password` in and return the populated request context.
 * `password` is the plaintext; we hash it here the way the client JS would.
 *
 * @param {import('@playwright/test').BrowserContext} context
 * @param {string} username
 * @param {string} password
 */
async function loginAs(context, username, password) {
    const response = await context.request.post(
        `/api/v1/users/${encodeURIComponent(username)}/login?persist=false`,
        {
            // The Snap!Cloud login handler reads `self.params.body` and
            // treats it as the already-sha512-hashed password.
            data: clientHashedPassword(password),
            headers: { 'content-type': 'text/plain' },
        }
    );
    if (!response.ok()) {
        throw new Error(
            `loginAs('${username}') failed: ${response.status()} ${await response.text()}`
        );
    }
    return response;
}

/**
 * Clear the current session (logout) via the API so the next navigation
 * behaves as an anonymous user. Safe to call even if already logged out.
 */
async function logout(context) {
    await context.request.post('/api/v1/logout');
}

module.exports = { loginAs, logout };
