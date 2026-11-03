// spec/e2e/project-visibility.spec.js
// ===================================
//
// Exercises the visibility rules defined in validation.lua's
// `assert_can_view_project` (and the surrounding controller flow):
//
//   - published OR public       -> everyone sees it
//   - neither public nor public -> only the owner or an admin sees it
//   - soft-deleted              -> nobody sees it (404)
//   - nonexistent username      -> 404
//
// We seed users and projects directly via spec/e2e/support/fixtures.js
// so the assertions stay focused on the controller logic.

const { test, expect } = require('@playwright/test');
const { seedUser, seedProject, deleteUser } = require('./support/fixtures');
const { loginAs, logout } = require('./support/auth');

const owner  = 'visibility_owner';
const other  = 'visibility_other';
const admin  = 'visibility_admin';

const publicProject   = 'public-published';
const privateProject  = 'private-unpublished';
const deletedProject  = 'soft-deleted';

function projectUrl(username, projectname) {
    return `/project?${new URLSearchParams({ username, projectname })}`;
}

test.describe.serial('project visibility', () => {
    test.beforeAll(async () => {
        await seedUser({ username: owner, role: 'standard' });
        await seedUser({ username: other, role: 'standard' });
        await seedUser({ username: admin, role: 'admin' });
        await seedProject({
            username: owner, projectname: publicProject,
            ispublic: true, ispublished: true,
        });
        await seedProject({
            username: owner, projectname: privateProject,
            ispublic: false, ispublished: false,
        });
        await seedProject({
            username: owner, projectname: deletedProject,
            ispublic: true, ispublished: true, deleted: true,
        });
    });

    test.afterAll(async () => {
        await deleteUser(owner);
        await deleteUser(other);
        await deleteUser(admin);
    });

    test.beforeEach(async ({ context }) => {
        // Guarantee each test starts anonymous.
        await logout(context);
    });

    test('anonymous user can view a public, published project', async ({ page }) => {
        const response = await page.goto(projectUrl(owner, publicProject));
        expect(response?.status()).toBe(200);
        await expect(page.getByRole('heading', { name: publicProject })).toBeVisible();
    });

    test('anonymous user cannot view a private project', async ({ page }) => {
        const response = await page.goto(projectUrl(owner, privateProject));
        // Snap!Cloud yields err.nonexistent_project (404). We also accept
        // any 4xx to insulate the spec from an exact-status refactor.
        expect(response?.status()).toBeGreaterThanOrEqual(400);
        expect(response?.status()).toBeLessThan(500);
    });

    test('another non-admin user cannot view a private project', async ({ page, context }) => {
        await loginAs(context, other, 'test-password-1');
        const response = await page.goto(projectUrl(owner, privateProject));
        expect(response?.status()).toBeGreaterThanOrEqual(400);
        expect(response?.status()).toBeLessThan(500);
    });

    test('owner can view their own private project', async ({ page, context }) => {
        await loginAs(context, owner, 'test-password-1');
        const response = await page.goto(projectUrl(owner, privateProject));
        expect(response?.status()).toBe(200);
        await expect(page.getByRole('heading', { name: privateProject })).toBeVisible();
    });

    test('admin can view any user\'s private project', async ({ page, context }) => {
        await loginAs(context, admin, 'test-password-1');
        const response = await page.goto(projectUrl(owner, privateProject));
        expect(response?.status()).toBe(200);
    });

    test('soft-deleted projects are hidden even from the owner', async ({ page, context }) => {
        await loginAs(context, owner, 'test-password-1');
        const response = await page.goto(projectUrl(owner, deletedProject));
        expect(response?.status()).toBeGreaterThanOrEqual(400);
        expect(response?.status()).toBeLessThan(500);
    });

    test('a nonexistent project returns an error response', async ({ page }) => {
        const response = await page.goto(
            projectUrl(owner, 'does-not-exist-' + Date.now())
        );
        expect(response?.status()).toBeGreaterThanOrEqual(400);
        expect(response?.status()).toBeLessThan(500);
    });
});
