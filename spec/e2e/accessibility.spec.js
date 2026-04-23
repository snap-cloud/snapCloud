// spec/e2e/accessibility.spec.js
// ==============================
//
// Axe-core accessibility audits. Tagged `@axe` so the GitHub Actions
// workflow can run them as their own CI status (see `.github/workflows/ci.yml`).
//
// Adding a new page:
//   1. Add it to the `pages` array below.
//   2. Commit — the existing test will cover the new URL.
//   3. If you want to tighten the ruleset, pass `.withTags([...])` or
//      `.withRules([...])` to AxeBuilder.

const { test, expect } = require('@playwright/test');
const AxeBuilder = require('@axe-core/playwright').default;

// Pages that every release must stay accessible. Keep this list small and
// intentional; axe is slow, and we want failures to be meaningful.
const pages = [
    { path: '/',           label: 'homepage' },
    { path: '/explore',    label: 'explore'  },
    { path: '/collections', label: 'collections' },
];

for (const { path, label } of pages) {
    test(`${label} has no serious axe violations @axe`, async ({ page }) => {
        await page.goto(path);

        const results = await new AxeBuilder({ page })
            // WCAG 2.1 A + AA is the baseline Snap!Cloud aims for. Tighten
            // later by adding 'wcag21aaa' or additional best-practice rules.
            .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
            .analyze();

        // Only fail on serious/critical issues for now so an accidental
        // `role="presentation"` on a decorative image doesn't block a PR.
        // The full violation list is still reported in the HTML report.
        const serious = results.violations.filter(
            (v) => v.impact === 'serious' || v.impact === 'critical'
        );

        expect.soft(
            serious,
            'axe reported serious/critical violations: see playwright-report/'
        ).toEqual([]);
    });
}
