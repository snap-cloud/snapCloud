# OAuth2 / OpenID Connect Provider

Snap!Cloud acts as an OAuth2/OIDC **identity provider**, allowing downstream
applications (LMS platforms, forums, third-party tools, etc.) to authenticate
users with their Snap! accounts.

## Overview

The implementation follows the **Authorization Code** flow (the most secure
server-side flow) with OpenID Connect on top for identity claims.

### Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/.well-known/openid-configuration` | GET | OIDC Discovery document |
| `/oauth2/authorize` | GET/POST | Authorization & consent screen |
| `/oauth2/token` | POST | Exchange code for tokens |
| `/oauth2/userinfo` | GET/POST | Fetch user profile claims |
| `/oauth2/introspect` | POST | Token introspection (RFC 7662) |
| `/oauth2/revoke` | POST | Token revocation (RFC 7009) |
| `/oauth2/clients` | GET/POST | Admin: list / register clients |
| `/oauth2/clients/:id` | DELETE | Admin: delete a client |

### Supported Scopes

| Scope | Claims |
|---|---|
| `openid` | `sub` (user ID) |
| `profile` | `preferred_username`, `name`, `role`, `about`, `locale` |
| `email` | `email`, `email_verified` |

### Token Types

- **Authorization code** -- short-lived (10 min), single-use, exchanged at the token endpoint.
- **Access token** -- JWT (HS256), 1 hour TTL. Used as a Bearer token for `/oauth2/userinfo` and `/oauth2/introspect`.
- **Refresh token** -- opaque, 30 day TTL, rotated on each use. Exchanged at the token endpoint for a fresh access/refresh pair.
- **ID token** -- JWT (HS256), 1 hour TTL. Returned alongside the access token when the `openid` scope is requested.

### Authorization Code Flow

```
 Client App                    Snap!Cloud                      User
 ----------                    ----------                      ----
     |                              |                            |
     |  1. redirect to              |                            |
     |  /oauth2/authorize?          |                            |
     |  client_id=...&              |                            |
     |  redirect_uri=...&           |                            |
     |  response_type=code&         |                            |
     |  scope=openid+profile&       |                            |
     |  state=xyz                   |                            |
     |----------------------------->|                            |
     |                              |  2. show login (if needed) |
     |                              |--------------------------->|
     |                              |  3. show consent screen    |
     |                              |--------------------------->|
     |                              |  4. user approves          |
     |                              |<---------------------------|
     |  5. redirect to              |                            |
     |  redirect_uri?code=...&      |                            |
     |  state=xyz                   |                            |
     |<-----------------------------|                            |
     |                              |                            |
     |  6. POST /oauth2/token       |                            |
     |  grant_type=authorization_code                            |
     |  code=...                    |                            |
     |  client_id + client_secret   |                            |
     |----------------------------->|                            |
     |                              |                            |
     |  7. { access_token,          |                            |
     |       refresh_token,         |                            |
     |       id_token }             |                            |
     |<-----------------------------|                            |
     |                              |                            |
     |  8. GET /oauth2/userinfo     |                            |
     |  Authorization: Bearer ...   |                            |
     |----------------------------->|                            |
     |  9. { sub, username, ... }   |                            |
     |<-----------------------------|                            |
```

## Configuration

### Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OAUTH_JWT_SECRET` | Recommended | Signing secret for JWT access tokens and ID tokens. Falls back to `SESSION_SECRET_BASE` if not set. Use a long random string in production. |

For production, always set `OAUTH_JWT_SECRET` to a dedicated secret that is
different from your session secret.

## Client Registration

Only **admin** users can register OAuth clients.

### Register a client (API)

```bash
curl -X POST http://localhost:8080/oauth2/clients \
  -H 'Content-Type: application/json' \
  -b 'snapsession_development=<your-admin-session-cookie>' \
  -d '{
    "name": "My App",
    "redirect_uri": "http://localhost:3000/callback",
    "client_icon": "/static/img/my-app-logo.png"
  }'
```

The response includes the generated `client_id` and `client_secret`. **Save the
`client_secret` immediately** -- it is not retrievable after creation.

### `client_icon` field

When registering a client you can provide a `client_icon` URL that is displayed
on the authorization consent screen next to the application name. This can be:

- A path on the Snap!Cloud server, e.g. `/static/img/partner-logo.png`
- An absolute external URL, e.g. `https://example.com/logo.png`

### List clients

```bash
curl http://localhost:8080/oauth2/clients \
  -b 'snapsession_development=<your-admin-session-cookie>'
```

### Delete a client

```bash
curl -X DELETE http://localhost:8080/oauth2/clients/<client_id> \
  -b 'snapsession_development=<your-admin-session-cookie>'
```

This also cleans up any authorization codes and refresh tokens associated with
the client.

## Client Authentication

The token, introspection, and revocation endpoints accept client credentials via
either method:

- **`client_secret_basic`** -- HTTP Basic auth header with `client_id:client_secret` (base64).
- **`client_secret_post`** -- `client_id` and `client_secret` as POST body parameters.

## Local Testing

### Prerequisites

A running Snap!Cloud development instance with a database. See the main README
for general setup. The key steps are:

```bash
make install        # install Lua and npm dependencies
make db             # initialize the database
make migrate        # run migrations (creates oauth_* tables)
```

Start the services using the Procfile (e.g. with `foreman start` or `overmind start`):

```bash
# Or run them individually:
lapis server                    # app on http://localhost:8080
npx maildev --incoming-user cloud --incoming-pass cloudemail  # email at http://localhost:1080
```

### Step-by-step walkthrough

#### 1. Create an admin user and log in

Sign up at `http://localhost:8080/sign_up`, then verify the account (check
maildev at `http://localhost:1080`). Promote yourself to admin in psql:

```sql
UPDATE users SET role = 'admin', verified = true WHERE username = 'youruser';
```

Log in at `http://localhost:8080/login`.

#### 2. Register an OAuth client

Grab your session cookie from the browser (DevTools > Application > Cookies >
`snapsession_development`).

```bash
# Register a test client that redirects to a local callback
curl -s -X POST http://localhost:8080/oauth2/clients \
  -H 'Content-Type: application/json' \
  -b 'snapsession_development=<COOKIE>' \
  -d '{
    "name": "Test App",
    "redirect_uri": "http://localhost:9999/callback",
    "client_icon": "https://picsum.photos/96"
  }' | python3 -m json.tool
```

Save the `client_id` and `client_secret` from the response.

#### 3. Start the authorization flow

Open the following URL in your browser (replace `CLIENT_ID`):

```
http://localhost:8080/oauth2/authorize?client_id=CLIENT_ID&redirect_uri=http://localhost:9999/callback&response_type=code&scope=openid%20profile%20email&state=test123
```

If you are logged in you will see the consent screen with the application name
and icon. Click **Authorize**. The browser will redirect to:

```
http://localhost:9999/callback?code=AUTHORIZATION_CODE&state=test123
```

Since there is nothing running on port 9999 you will see a connection error --
that is expected. Copy the `code` value from the URL bar.

#### 4. Exchange the code for tokens

```bash
curl -s -X POST http://localhost:8080/oauth2/token \
  -d 'grant_type=authorization_code' \
  -d 'code=AUTHORIZATION_CODE' \
  -d 'redirect_uri=http://localhost:9999/callback' \
  -d 'client_id=CLIENT_ID' \
  -d 'client_secret=CLIENT_SECRET' | python3 -m json.tool
```

You should receive a JSON response with `access_token`, `refresh_token`,
`id_token`, and `expires_in`.

#### 5. Fetch user info

```bash
curl -s http://localhost:8080/oauth2/userinfo \
  -H 'Authorization: Bearer ACCESS_TOKEN' | python3 -m json.tool
```

Returns the user's `sub`, `preferred_username`, `email`, `email_verified`,
`role`, etc. depending on which scopes were granted.

#### 6. Inspect the ID token

The `id_token` is a JWT. You can decode it to see the claims:

```bash
echo 'ID_TOKEN' | cut -d. -f2 | base64 -d 2>/dev/null | python3 -m json.tool
```

#### 7. Refresh tokens

```bash
curl -s -X POST http://localhost:8080/oauth2/token \
  -d 'grant_type=refresh_token' \
  -d 'refresh_token=REFRESH_TOKEN' \
  -d 'client_id=CLIENT_ID' \
  -d 'client_secret=CLIENT_SECRET' | python3 -m json.tool
```

This returns a new access token and a rotated refresh token. The old refresh
token is invalidated.

#### 8. Introspect a token

```bash
curl -s -X POST http://localhost:8080/oauth2/introspect \
  -d 'token=ACCESS_TOKEN' \
  -d 'client_id=CLIENT_ID' \
  -d 'client_secret=CLIENT_SECRET' | python3 -m json.tool
```

Returns `{ "active": true, "sub": "...", "username": "...", ... }` for valid
tokens.

#### 9. Revoke a token

```bash
curl -s -X POST http://localhost:8080/oauth2/revoke \
  -d 'token=REFRESH_TOKEN' \
  -d 'client_id=CLIENT_ID' \
  -d 'client_secret=CLIENT_SECRET'
```

### Using a real OAuth client library

For a more realistic test, point any standard OAuth2/OIDC client library at:

- Discovery URL: `http://localhost:8080/.well-known/openid-configuration`

Most libraries (e.g. `passport-openidconnect` for Node, `authlib` for Python,
`omniauth-openid_connect` for Ruby) can auto-configure from the discovery
document.

### Quick test with the OIDC Discovery endpoint

```bash
curl -s http://localhost:8080/.well-known/openid-configuration | python3 -m json.tool
```

This should return a JSON document listing all endpoints, supported scopes,
grant types, and signing algorithms.

---

## Sign In with Google (Social Login)

Snap!Cloud can also act as an OAuth2 **consumer**, allowing users to sign in
with their Google accounts (or other external identity providers in the future).

### How It Works

1. User clicks "Sign in with Google" on the login page.
2. Snap!Cloud redirects to Google's OAuth2 consent screen.
3. Google redirects back to `/auth/google/callback` with an authorization code.
4. Snap!Cloud exchanges the code for tokens and fetches the user's Google profile.
5. If the Google identity is already linked to a Snap! account, the user is
   logged in immediately.
6. If no link exists but a Snap! account with the same email is found, the user
   is shown a **link account** page where they must enter their Snap! password
   to prove account ownership. This prevents unauthorized account takeover.
7. If no matching account is found at all, the user is directed to either link
   an existing account (different email) or sign up for a new one.

### Identities Table

The `identities` table stores external provider associations:

| Column | Type | Description |
|---|---|---|
| `id` | serial PK | Auto-increment ID |
| `user_id` | integer FK | References `users.id` |
| `provider` | text | Provider name (e.g. `google`, `github`) |
| `external_id` | text | The user's unique ID at the provider (e.g. Google `sub`) |
| `verified` | boolean | Whether the link has been verified (password confirmation) |
| `display_name` | text | Name from the provider profile |
| `email` | text | Email from the provider profile |
| `avatar_url` | text | Profile picture URL from the provider |
| `created_at` | timestamp | When the link was created |
| `updated_at` | timestamp | When the link was last modified |
| `last_used_at` | timestamp | When the identity was last used to sign in |

A user can have multiple identities (e.g. Google + GitHub). Each
`(provider, external_id)` pair is unique.

### Configuration

| Variable | Required | Description |
|---|---|---|
| `GOOGLE_CLIENT_ID` | Yes (to enable) | OAuth2 client ID from Google Cloud Console |
| `GOOGLE_CLIENT_SECRET` | Yes (to enable) | OAuth2 client secret from Google Cloud Console |

If these variables are not set, the "Sign in with Google" button is hidden
and the `/auth/google` endpoint returns a 503 error.

### Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project (or use an existing one)
3. Go to **APIs & Services > Credentials**
4. Click **Create Credentials > OAuth client ID**
5. Application type: **Web application**
6. Add authorized redirect URIs:
   - Development: `http://localhost:8080/auth/google/callback`
   - Production: `https://snap.berkeley.edu/auth/google/callback`
7. Copy the Client ID and Client Secret

### Local Testing (Google Sign-In)

#### 1. Set up Google credentials

```bash
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-client-secret"
```

Add these to your `.env` file or export them before starting the server.

#### 2. Start the server

```bash
lapis server
```

#### 3. Test the flow

1. Open `http://localhost:8080/login`
2. You should see a "Sign in with Google" button below the login form
3. Click it -- you'll be redirected to Google's consent screen
4. After signing in with Google, you'll be redirected back to Snap!Cloud
5. If your Google email matches an existing Snap! account, you'll see the
   **link account** page asking for your Snap! password
6. Enter your password to link the accounts
7. On subsequent sign-ins, clicking "Sign in with Google" will log you in
   directly without needing your Snap! password

#### 4. Testing without real Google credentials

For unit testing or local development without network access, you can:

- Test the `/auth/link_account` flow directly by manually setting
  `session.pending_link` in a test
- The identity-linking logic is independent of the Google-specific HTTP calls

### Account Linking Security

- **Existing accounts**: When a Google identity's email matches an existing
  Snap! account, the user MUST enter their Snap! password to complete the link.
  This prevents an attacker with access to a victim's email from hijacking
  their Snap! account.
- **Already logged in**: If a user is already authenticated (via session), they
  can link a Google identity without re-entering their password, since session
  ownership already proves identity.
- **Verified flag**: Identities are marked `verified = true` only after the
  password confirmation step (or if the user was already logged in).
- **No auto-registration**: Google Sign-In does NOT automatically create new
  Snap! accounts. Users must first sign up through the normal flow, then link
  their Google identity.

### Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/auth/google` | GET | Initiates Google Sign-In (redirects to Google) |
| `/auth/google/callback` | GET | Handles Google's OAuth2 callback |
| `/auth/link_account` | GET | Shows the account-linking form |
| `/auth/link_account` | POST | Verifies password and creates the identity link |

---

## Security Notes

- Authorization codes are single-use and expire after 10 minutes.
- Refresh tokens are rotated on every use (the old token is deleted).
- Access tokens (JWTs) cannot be revoked before expiry since they are stateless.
  Keep the TTL short (default: 1 hour).
- Client secrets are stored in plaintext in the database. Treat them like
  passwords -- only admins can register clients, and secrets are redacted in
  the list endpoint.
- For production, always set a dedicated `OAUTH_JWT_SECRET` environment variable.
- The consent screen requires the user to be logged in and explicitly approve
  each authorization request.
- Google Sign-In requires password verification before linking to an existing
  account, preventing email-based account takeover.
