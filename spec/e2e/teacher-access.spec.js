// spec/e2e/teacher-access.spec.js
// ===============================
//
// Guards on /teacher, /bulk, /learners (site.lua). The handler requires
// a signed-in user AND either `is_teacher = true` OR the admin role
// (see `assert_admin` fallback in site.lua).
//
// Behaviors we pin down:
//   - anonymous visitors: denied
//   - standard (non-teacher) users: denied
//   - teacher users: allowed
//   - admins (even without the teacher flag): allowed

const { test, expect } = require('@playwright/test');
const { seedUser, deleteUser } = require('./support/fixtures');
const { loginAs, logout } = require('./support/auth');

const standard = 'teacher_access_standard';
const teacher  = 'teacher_access_teacher';
const admin    = 'teacher_access_admin';

const teacherRoutes = ['/teacher', '/bulk', '/learners'];

function denied(page, response) {
    const landedAt = new URL(page.url()).pathname;
    return (
        landedAt === '/' ||
        (response && response.status() >= 400 && response.status() < 500)
    );
}

test.describe.serial('teacher page access', () => {

    test.beforeAll(async () => {
        await seedUser({ username: standard, role: 'standard' });
        await seedUser({ username: teacher,  role: 'standard', is_teacher: true });
        // Admin without is_teacher — proves the fallback works.
        await seedUser({ username: admin,    role: 'admin', is_teacher: false });
    });

    test.afterAll(async () => {
        await deleteUser(standard);
        await deleteUser(teacher);
        await deleteUser(admin);
    });

    test.beforeEach(async ({ context }) => { await logout(context); });

    for (const path of teacherRoutes) {
        test(`anonymous users are denied ${path}`, async ({ page }) => {
            const response = await page.goto(path);
            expect(denied(page, response)).toBe(true);
        });

        test(`standard (non-teacher) users are denied ${path}`, async ({ page, context }) => {
            await loginAs(context, standard, 'test-password-1');
            const response = await page.goto(path);
            expect(denied(page, response)).toBe(true);
        });

        test(`teacher users can reach ${path}`, async ({ page, context }) => {
            await loginAs(context, teacher, 'test-password-1');
            const response = await page.goto(path);
            expect(response?.status()).toBe(200);
            expect(new URL(page.url()).pathname).toBe(path);
        });

        test(`admins without the teacher flag can reach ${path}`, async ({ page, context }) => {
            await loginAs(context, admin, 'test-password-1');
            const response = await page.goto(path);
            expect(response?.status()).toBe(200);
            expect(new URL(page.url()).pathname).toBe(path);
        });
    }
});
