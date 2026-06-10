# Monogatari Extension Library

Extension repository for the **Monogatari** app. It hosts Lua extensions
(novel sources), shared Lua libraries and icons, plus the `index.json` the
app reads to list, install and update extensions.

## Using this repository in the app

Add the following URL as a repository in the Monogatari app
(*More → Repositories → Add*):

```
https://raw.githubusercontent.com/LevelADude/Monogatari-Extension-Library/main
```

> **Note:** The GitHub repository must be **public**, otherwise the app
> receives `404` for every file.

## How it works

The app fetches files using these URL patterns:

| File | URL |
|---|---|
| Index | `{repoURL}/index.json` |
| Extension | `{repoURL}/src/{lang}/{fileName}.lua` |
| Library | `{repoURL}/lib/{name}.lua` |

`index.json` lists every extension (`scripts`) and shared library
(`libraries`). It is generated — **never edit it by hand**.

Every `.lua` file must start with a JSON metadata comment on line 1:

```lua
-- {"id":12345,"ver":"1.0.0","libVer":"1.0.0","author":"YourName"}
```

- `id` must be unique across all extensions and must never change.
- Bump `ver` whenever you change an extension, otherwise the app will not
  pick up the update.

## Development

1. Add or edit an extension under `src/{lang}/` (use an existing extension
   as a template, e.g. [AO3.lua](src/en/AO3.lua)). Optionally add an icon
   under `icons/{fileName}.png`.
2. Regenerate the index:

   ```
   py scripts/generate_index.py
   ```

3. Test locally against the app: run

   ```
   py scripts/serve.py
   ```

   and add the printed `http://<pc-ip>:8000` URL as a repository in the app
   (phone and PC must be on the same network).
4. Commit and push. CI validates the metadata and checks that `index.json`
   is up to date (`scripts/generate_index.py --check`).

### Optional: official Shosetsu tooling

The extensions use the Shosetsu Lua API (kotlin-lib). For API documentation
and a full extension test harness (requires Java 21 and Git Bash on
Windows):

- `./dev-setup.sh` — downloads `_doc.lua` (API documentation) and
  `bin/extension-tester.jar`
- `./test-server.sh` — runs the extension tester with index generation and
  a local HTTP server

## Credits

Most extensions originate from the community-maintained
[shosetsu extensions "Universe" repository](https://gitlab.com/shosetsuorg/extensions)
(GPL-3.0). See the `authors` section of [index.json](index.json) for the
original authors. License: [GPL-3.0](LICENSE).
