// spec/e2e/accessibility.spec.js
// ==============================
//
// Axe-core accessibility audits. Tagged `@axe` so the GitHub Actions
// workflow can run them as their own CI status (see `.github/workflows/ci.yml`).
//
// All scans go through `spec/e2e/support/axe.js`, which automatically
// excludes any element carrying `data-axe-excluded="true"` — see
// spec/README.md#accessibility-exclusions for when to reach for that
// escape hatch.

const { test, expect } = require('@playwright/test');
const { runAxe } = require('./support/axe');
const { seedUser, seedProject, deleteUser } = require('./support/fixtures');

// Simple public pages that every release must stay accessible. Keep this
// list small and intentional; axe is slow, and we want failures to
// mean something.
const publicPages = [
    { path: '/',            label: 'homepage'     },
    { path: '/explore',     label: 'explore'      },
    { path: '/collections', label: 'collections'  },
    { path: '/login',       label: 'login form'   },
    { path: '/sign_up',     label: 'sign-up form' },
];

for (const { path, label } of publicPages) {
    test(`${label} has no serious axe violations @axe`, async ({ page }) => {
        await page.goto(path);
        const { seriousViolations } = await runAxe(page);
        expect.soft(
            seriousViolations,
            'axe reported serious/critical violations; see playwright-report/'
        ).toEqual([]);
    });
}

// -----------------------------------------------------------------------
// Project page accessibility.
//
// The project viewer page embeds the Snap! editor in an iframe. We can't
// scan inside that iframe (it's controlled by the upstream Snap! repo
// and is sandboxed), so it's tagged with `data-axe-excluded="true"` in
// views/project.etlua. Our helper drops it from the scan automatically;
// the assertion below guards the *surrounding* chrome only.
// -----------------------------------------------------------------------
test.describe('project page @axe', () => {
    const owner   = 'axe_project_owner';
    const project = 'axe-sample-project';

    test.beforeAll(async () => {
        await seedUser({ username: owner, role: 'standard' });
        await seedProject({
            username: owner,
            projectname: project,
            ispublic: true,
            ispublished: true,
        });
    });

    test.afterAll(async () => {
        await deleteUser(owner);
    });

    test('chrome has no serious axe violations @axe', async ({ page }) => {
        const qs = new URLSearchParams({
            username: owner, projectname: project
        }).toString();
        await page.goto(`/project?${qs}`);

        const { seriousViolations } = await runAxe(page);
        expect.soft(
            seriousViolations,
            'axe reported serious/critical violations on /project; ' +
            'remember the Snap! iframe is excluded via data-axe-excluded'
        ).toEqual([]);
    });
});
