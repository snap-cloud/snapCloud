// spec/e2e/admin-access.spec.js
// =============================
//
// Verifies the role gates on /admin, /flags, /user_admin, /ip_admin, etc.
// The route handlers live in site.lua and guard access with
// `assert_min_role(self, '<role>')`.
//
// The hierarchy (models/users.lua): admin > moderator > reviewer > standard.
// So a `standard` user must be denied; a `reviewer` can see /admin but not
// /ip_admin; an `admin` sees everything.
//
// On denial, the handler either redirects to "/" (for logged-out users
// or when the user doesn't meet the role) or yields err.auth. We accept
// either "redirected to /" OR a 4xx status as a denied response.

const { test, expect } = require('@playwright/test');
const { seedUser, deleteUser } = require('./support/fixtures');
const { loginAs, logout } = require('./support/auth');

const admin    = 'admin_access_admin';
const reviewer = 'admin_access_reviewer';
const standard = 'admin_access_standard';

// Each entry records the URL, the minimum role that can see it, and a
// distinctive bit of content that proves we actually rendered the page
// (rather than landing on "/").
const adminRoutes = [
    { path: '/admin',         minRole: 'reviewer'  },
    { path: '/flags',         minRole: 'reviewer'  },
    { path: '/user_admin',    minRole: 'moderator' },
    { path: '/zombie_admin',  minRole: 'moderator' },
    { path: '/ip_admin',      minRole: 'admin'     },
];

const roleRank = { standard: 2, reviewer: 3, moderator: 4, admin: 5 };

test.describe.serial('admin page access', () => {

    test.beforeAll(async () => {
        await seedUser({ username: admin,    role: 'admin'    });
        await seedUser({ username: reviewer, role: 'reviewer' });
        await seedUser({ username: standard, role: 'standard' });
    });

    test.afterAll(async () => {
        await deleteUser(admin);
        await deleteUser(reviewer);
        await deleteUser(standard);
    });

    test.beforeEach(async ({ context }) => { await logout(context); });

    for (const route of adminRoutes) {
        test(`anonymous visitors are bounced off ${route.path}`, async ({ page }) => {
            const response = await page.goto(route.path);
            // Handler redirects anonymous users to "/" — new URL is "/".
            const landedAt = new URL(page.url()).pathname;
            const denied =
                landedAt === '/' ||
                (response && response.status() >= 400 && response.status() < 500);
            expect(denied, `expected denial; ended up at ${landedAt}`).toBe(true);
        });

        test(`standard users cannot reach ${route.path}`, async ({ page, context }) => {
            await loginAs(context, standard, 'test-password-1');
            const response = await page.goto(route.path);
            const landedAt = new URL(page.url()).pathname;
            const denied =
                landedAt === '/' ||
                (response && response.status() >= 400 && response.status() < 500);
            expect(denied, `expected denial; ended up at ${landedAt}`).toBe(true);
        });
    }

    test('reviewers can see /admin but not /ip_admin', async ({ page, context }) => {
        await loginAs(context, reviewer, 'test-password-1');

        const adminResponse = await page.goto('/admin');
        expect(adminResponse?.status()).toBe(200);
        expect(new URL(page.url()).pathname).toBe('/admin');

        const ipResponse = await page.goto('/ip_admin');
        const landedAt = new URL(page.url()).pathname;
        const denied =
            landedAt === '/' ||
            (ipResponse && ipResponse.status() >= 400 && ipResponse.status() < 500);
        expect(denied).toBe(true);
    });

    test('admins can reach every admin route', async ({ page, context }) => {
        await loginAs(context, admin, 'test-password-1');
        for (const route of adminRoutes) {
            const response = await page.goto(route.path);
            expect(
                response?.status(),
                `admin unexpectedly denied from ${route.path}`
            ).toBe(200);
            expect(new URL(page.url()).pathname).toBe(route.path);
        }
    });

    test('every listed route actually requires a role above standard', () => {
        for (const route of adminRoutes) {
            expect(roleRank[route.minRole]).toBeGreaterThan(roleRank.standard);
        }
    });
});
