// spec/e2e/support/fixtures.js
// ============================
//
// Seed the `snapcloud_test` database directly so Playwright tests have
// known-good users and projects to work with.
//
// Why bypass the sign-up API? Several e2e scenarios need users with
// elevated roles (admin, moderator) or with `is_teacher = true`. Those
// roles can't be set through the public sign-up endpoint. Seeding via
// SQL keeps the fixtures explicit and makes cleanup obvious.
//
// Safety: every query re-asserts the DATABASE_NAME is `snapcloud_test`
// before running. If someone points this at dev/prod by accident the
// helper refuses to proceed.

const crypto = require('crypto');
const { Client } = require('pg');

const EXPECTED_DB = 'snapcloud_test';

// Connection settings come straight from the CI env. Defaults match the
// ones used by the workflow in .github/workflows/ci.yml.
function clientConfig() {
    const database = process.env.DATABASE_NAME || EXPECTED_DB;
    if (database !== EXPECTED_DB) {
        throw new Error(
            `[fixtures] Refusing to connect: DATABASE_NAME=${database}, ` +
            `expected ${EXPECTED_DB}.`
        );
    }
    return {
        host: process.env.DATABASE_HOST || '127.0.0.1',
        port: Number(process.env.DATABASE_PORT || 5432),
        user: process.env.DATABASE_USERNAME || 'cloud',
        password: process.env.DATABASE_PASSWORD || 'snap-cloud-password',
        database,
    };
}

async function withClient(fn) {
    const client = new Client(clientConfig());
    await client.connect();
    try {
        return await fn(client);
    } finally {
        await client.end();
    }
}

// Snap!Cloud's password pipeline (see controllers/user.lua and
// static/js/cloud.js):
//   1. The client hashes the plaintext to sha512 hex.
//   2. The server hashes (sha512_hex + salt) again with sha512.
// Tests that log in via the HTTP API send the client-side hash; fixtures
// that insert users directly skip step 1 and precompute the final hash.
function hexSha512(input) {
    return crypto.createHash('sha512').update(input).digest('hex');
}

function serverHash(plaintext, salt) {
    return hexSha512(hexSha512(plaintext) + salt);
}

// The password the client JS *sends* over the wire — after its own
// sha512 pass. Use this when calling /api/v1/users/:username/login.
function clientHashedPassword(plaintext) {
    return hexSha512(plaintext);
}

/**
 * Create (or replace) a user with a known password.
 *
 * @param {object} attrs
 * @param {string} attrs.username
 * @param {string} [attrs.password]   - plaintext; defaults to 'test-password-1'
 * @param {string} [attrs.email]
 * @param {string} [attrs.role]       - 'admin' | 'moderator' | 'reviewer' |
 *                                      'standard' | 'student' | 'banned'
 * @param {boolean} [attrs.verified]
 * @param {boolean} [attrs.is_teacher]
 * @returns {Promise<{username: string, password: string, role: string}>}
 */
async function seedUser(attrs) {
    const password  = attrs.password  ?? 'test-password-1';
    const email     = attrs.email     ?? `${attrs.username}@example.invalid`;
    const role      = attrs.role      ?? 'standard';
    const verified  = attrs.verified  ?? true;
    const isTeacher = attrs.is_teacher ?? false;
    const salt      = crypto.randomBytes(16).toString('hex');
    const hashed    = serverHash(password, salt);

    await withClient(async (client) => {
        // Clean up any prior run's user record so tests are idempotent.
        await client.query('DELETE FROM users WHERE username = $1', [attrs.username]);
        await client.query(
            `INSERT INTO users
                (username, email, salt, password, verified, role,
                 is_teacher, created, session_count, bad_flags)
             VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), 0, 0)`,
            [attrs.username, email, salt, hashed, verified, role, isTeacher]
        );
    });

    return { username: attrs.username, password, role };
}

/**
 * Create a project owned by the given user. Defaults to a private
 * (neither public nor published) project; override via the flags.
 *
 * @param {object} attrs
 * @param {string} attrs.username       - owning user
 * @param {string} [attrs.projectname]
 * @param {boolean} [attrs.ispublic]
 * @param {boolean} [attrs.ispublished]
 * @param {boolean} [attrs.deleted]     - soft-delete marker
 */
async function seedProject(attrs) {
    const projectname  = attrs.projectname  ?? `test-project-${Date.now()}`;
    const ispublic     = attrs.ispublic     ?? false;
    const ispublished  = attrs.ispublished  ?? false;
    const deleted      = attrs.deleted      ?? false;
    await withClient(async (client) => {
        await client.query(
            `DELETE FROM projects WHERE username = $1 AND projectname = $2`,
            [attrs.username, projectname]
        );
        await client.query(
            `INSERT INTO projects
                (username, projectname, ispublic, ispublished,
                 created, lastupdated, deleted)
             VALUES ($1, $2, $3, $4, NOW(), NOW(), $5)`,
            [
                attrs.username,
                projectname,
                ispublic,
                ispublished,
                deleted ? new Date() : null,
            ]
        );
    });
    return { username: attrs.username, projectname };
}

/**
 * Delete a user and the rows that hold a foreign key on their username.
 * Useful in afterAll hooks. The signup flow inserts a verify_user row
 * into `tokens`, and `tokens.username` has an FK to `users.username`
 * with no ON DELETE clause (see db/schema.sql) — so the users row can't
 * go before the token row.
 */
async function deleteUser(username) {
    await withClient(async (client) => {
        await client.query('DELETE FROM tokens   WHERE username = $1', [username]);
        await client.query('DELETE FROM projects WHERE username = $1', [username]);
        await client.query('DELETE FROM users    WHERE username = $1', [username]);
    });
}

module.exports = {
    seedUser,
    seedProject,
    deleteUser,
    clientHashedPassword,
    serverHash,
    hexSha512,
};
