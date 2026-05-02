// spec/e2e/auth.spec.js
// =====================
//
// Sign-up and login flows end-to-end. We exercise both the UI paths
// (to catch broken forms / wiring) and the JSON API endpoints
// (to catch controller-level regressions in isolation).

const { test, expect } = require('@playwright/test');
const {
    seedUser,
    deleteUser,
    clientHashedPassword,
} = require('./support/fixtures');
const { logout } = require('./support/auth');

// Usernames are deliberately timestamped so reruns don't collide with
// leftover state, even if afterAll is skipped due to a crash.
const run = Date.now();
const newUsername    = `signup_e2e_${run}`;
const existingUser   = `login_e2e_${run}`;
const existingPass   = 'super-secret-pw-1';

test.describe('sign up', () => {

    test.afterAll(async () => {
        await deleteUser(newUsername);
    });

    test('renders the sign-up form', async ({ page }) => {
        await page.goto('/sign_up');
        // The page also has a site-wide search form, so target the
        // signup form by id (views/users/sign_up.etlua, #js-signup).
        await expect(page.locator('#js-signup')).toBeVisible();
        await expect(page.locator('#username')).toBeVisible();
        await expect(page.locator('#email')).toBeVisible();
    });

    test('rejects a too-short raw password', async ({ request }) => {
        // The controller runs `min_length = MIN_PASSWORD_LENGTH` against
        // whatever `password` param it receives. The real client always
        // sha512-hashes first (so it's 128 chars), but a bad/attacker
        // client that posts plaintext must still be rejected.
        const response = await request.post('/api/v1/signup', {
            form: {
                username: `${newUsername}_short`,
                password: 'abc',
                password_repeat: 'abc',
                email: `${newUsername}_short@example.invalid`,
            },
        });
        expect(response.ok()).toBe(false);
    });

    test('creates an account via the API and then allows login', async ({ request }) => {
        const signup = await request.post('/api/v1/signup', {
            form: {
                username: newUsername,
                // Mimic what the client JS sends over the wire.
                password: clientHashedPassword(existingPass),
                password_repeat: clientHashedPassword(existingPass),
                email: `${newUsername}@example.invalid`,
            },
        });
        expect(signup.ok(), await signup.text()).toBe(true);

        // New accounts are unverified. The login handler has a special
        // code path that returns a 200 JSON body with a `title` + verify
        // message for unverified users — we accept either outcome here.
        const login = await request.post(
            `/api/v1/users/${encodeURIComponent(newUsername)}/login?persist=false`,
            {
                data: clientHashedPassword(existingPass),
                headers: { 'content-type': 'text/plain' },
            }
        );
        // Unverified -> HTTP 200 with verification message, verified ->
        // plain ok. Either way it shouldn't be an auth error (4xx).
        expect(login.status()).toBeLessThan(400);
    });

    test('rejects duplicate usernames', async ({ request }) => {
        const retry = await request.post('/api/v1/signup', {
            form: {
                username: newUsername,
                password: clientHashedPassword(existingPass),
                password_repeat: clientHashedPassword(existingPass),
                email: `${newUsername}-dup@example.invalid`,
            },
        });
        expect(retry.ok()).toBe(false);
        const body = await retry.text();
        expect(body.toLowerCase()).toContain('already exists');
    });
});

test.describe('login', () => {

    test.beforeAll(async () => {
        await seedUser({
            username: existingUser,
            password: existingPass,
            role: 'standard',
            verified: true,
        });
    });

    test.afterAll(async () => {
        await deleteUser(existingUser);
    });

    test.beforeEach(async ({ context }) => { await logout(context); });

    test('renders the login form with username + password fields', async ({ page }) => {
        await page.goto('/login');
        await expect(page.locator('#username')).toBeVisible();
        await expect(page.locator('#password')).toBeVisible();
    });

    test('correct credentials succeed', async ({ request }) => {
        const response = await request.post(
            `/api/v1/users/${encodeURIComponent(existingUser)}/login?persist=false`,
            {
                data: clientHashedPassword(existingPass),
                headers: { 'content-type': 'text/plain' },
            }
        );
        expect(response.ok(), await response.text()).toBe(true);
    });

    test('wrong password is rejected', async ({ request }) => {
        const response = await request.post(
            `/api/v1/users/${encodeURIComponent(existingUser)}/login?persist=false`,
            {
                data: clientHashedPassword('not-the-password'),
                headers: { 'content-type': 'text/plain' },
            }
        );
        expect(response.status()).toBe(403);
    });

    test('unknown username is rejected with the same error', async ({ request }) => {
        // Snap!Cloud reuses err.wrong_password for unknown-user logins so
        // attackers can't enumerate accounts. Verify the status stays 403.
        const response = await request.post(
            `/api/v1/users/nobody_${run}/login?persist=false`,
            {
                data: clientHashedPassword('anything'),
                headers: { 'content-type': 'text/plain' },
            }
        );
        expect(response.status()).toBe(403);
    });

    test('logout clears the session', async ({ request }) => {
        // Log in first.
        const login = await request.post(
            `/api/v1/users/${encodeURIComponent(existingUser)}/login?persist=false`,
            {
                data: clientHashedPassword(existingPass),
                headers: { 'content-type': 'text/plain' },
            }
        );
        expect(login.ok()).toBe(true);

        const logoutResponse = await request.post('/api/v1/logout');
        expect(logoutResponse.ok()).toBe(true);

        // After logout, /profile should bounce the (now-anonymous) user to /.
        const profile = await request.get('/profile', { maxRedirects: 0 });
        expect([301, 302, 303, 307, 308]).toContain(profile.status());
    });
});
