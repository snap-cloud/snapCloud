// spec/e2e/support/axe.js
// =======================
//
// Thin wrapper around AxeBuilder that:
//   1. Applies the project's default WCAG tag set (2.1 A + AA).
//   2. Honors the project-wide `data-axe-excluded="true"` convention —
//      elements carrying that attribute are excluded from the scan.
//
// See spec/README.md#accessibility-exclusions for the full convention.
//
// Usage:
//   const { runAxe } = require('./support/axe');
//   const results = await runAxe(page);
//   expect(results.seriousViolations).toEqual([]);

const AxeBuilder = require('@axe-core/playwright').default;

// The one and only selector for the exclusion convention. Document changes
// here in spec/README.md as well — the convention is a cross-cutting
// contract, not a private detail of the tests.
const EXCLUDE_SELECTOR = '[data-axe-excluded="true"]';

const DEFAULT_TAGS = ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'];

/**
 * Run an axe scan against the given page.
 *
 * @param {import('@playwright/test').Page} page
 * @param {object}  [opts]
 * @param {string[]} [opts.tags]       - override the default WCAG tag list
 * @param {string[]} [opts.exclude]    - extra selectors to exclude (merged with the convention)
 * @param {string[]} [opts.include]    - limit the scan to these selectors
 * @returns {Promise<{raw: object, seriousViolations: object[]}>}
 */
async function runAxe(page, opts = {}) {
    let builder = new AxeBuilder({ page }).withTags(opts.tags || DEFAULT_TAGS);

    // Always exclude the data-attribute convention. Merge any caller-supplied
    // selectors on top.
    const excludes = [EXCLUDE_SELECTOR, ...(opts.exclude || [])];
    for (const selector of excludes) {
        builder = builder.exclude(selector);
    }

    if (opts.include) {
        for (const selector of opts.include) {
            builder = builder.include(selector);
        }
    }

    const raw = await builder.analyze();
    const seriousViolations = raw.violations.filter(
        (v) => v.impact === 'serious' || v.impact === 'critical'
    );
    return { raw, seriousViolations };
}

module.exports = {
    runAxe,
    EXCLUDE_SELECTOR,
    DEFAULT_TAGS,
};
