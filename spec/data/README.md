# Test data / fixtures

This directory holds static fixture data that individual specs can load
instead of hand-building records inline. Keep it small — factories in
`spec/support/factories.lua` are the right home for *constructing* rows;
`spec/data/` is the right home for *canonical example input*.

## Layout

- `projects/`
    Sample Snap! project XML files. Use these when testing the project
    upload/download pipeline, storage, or parsers. Keep each fixture
    minimal and give it a descriptive filename
    (e.g. `hello_world.xml`, `remix_chain.xml`).

- `users/`
    JSON blobs describing canonical user seeds (admins, students,
    banned users, etc). Specs can load them with `require`-style
    helpers or a plain `io.open` + `cjson.decode`.

## How to add a fixture

1. Drop the file into the appropriate subdirectory.
2. Prefer inputs that are the smallest possible reproduction — tests
   should document intent, not stress-test the parser.
3. If the fixture is platform-specific (e.g. a Snap! v8 XML that won't
   parse under v7), note it in a comment in the XML header.
4. Reference the fixture from a spec by filename:

    ```lua
    local path = 'spec/data/projects/hello_world.xml'
    local xml  = assert(io.open(path)):read('*a')
    ```

## Conventions

- No PII or copyrighted user content.
- Keep individual files under 10 KB. Large fixtures belong in an
  external storage location referenced by URL, not committed.
- When deleting a fixture, grep the `spec/` tree first to make sure
  nothing still references it.
