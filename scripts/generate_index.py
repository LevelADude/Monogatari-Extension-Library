#!/usr/bin/env python3
"""Generate and validate index.json for the Monogatari Extension Library.

The Monogatari app (shosetsu kotlin-lib) fetches:
    {repoURL}/index.json
    {repoURL}/src/{lang}/{fileName}.lua   (extensions, "scripts" in the index)
    {repoURL}/lib/{name}.lua              (shared libraries)

Index schema consumed by the app (kotlin-lib RepoIndex, ignoreUnknownKeys=true):
    scripts[]:   id, name, fileName, imageURL, lang, ver, libVer, md5, type
    libraries[]: name, ver
    styles[]:    (unused, kept empty)

Every .lua file must start with a metadata comment on line 1:
    -- {"id":123,"ver":"1.0.0","libVer":"1.0.0", ...}   (extensions)
    -- {"ver":"1.0.0","author":"..."}                   (libraries: "ver" required)

Usage:
    py scripts/generate_index.py            # rewrite index.json
    py scripts/generate_index.py --check    # validate only, exit 1 on problems
"""

import hashlib
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
RAW_BASE = "https://raw.githubusercontent.com/LevelADude/Monogatari-Extension-Library/main"
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")
META_RE = re.compile(r"^--\s*(\{.*\})\s*$")
NAME_RE = re.compile(r'\bname\s*=\s*"([^"]+)"')

errors = []
warnings = []


def fail(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def read_meta(path: Path) -> dict | None:
    """Parse the first-line metadata comment of a .lua file."""
    rel = path.relative_to(REPO_ROOT).as_posix()
    try:
        first_line = path.read_text(encoding="utf-8").splitlines()[0]
    except (UnicodeDecodeError, IndexError):
        fail(f"{rel}: file is empty or not valid UTF-8")
        return None
    m = META_RE.match(first_line.lstrip("﻿"))
    if not m:
        fail(f"{rel}: line 1 is not a metadata comment (-- {{...}})")
        return None
    try:
        meta = json.loads(m.group(1))
    except json.JSONDecodeError as e:
        fail(f"{rel}: metadata JSON invalid: {e}")
        return None
    return meta


def check_semver(rel: str, key: str, value) -> bool:
    if not isinstance(value, str) or not SEMVER_RE.match(value):
        fail(f'{rel}: "{key}" must be "x.y.z", got {value!r}')
        return False
    return True


def load_previous_index() -> dict:
    index_path = REPO_ROOT / "index.json"
    if not index_path.exists():
        return {}
    try:
        return json.loads(index_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        warn("index.json: existing file is not valid JSON, regenerating from scratch")
        return {}


def build_scripts(previous: dict) -> list[dict]:
    prev_by_id = {s["id"]: s for s in previous.get("scripts", [])}
    scripts = []
    seen_ids: dict[int, str] = {}

    for path in sorted((REPO_ROOT / "src").glob("*/*.lua")):
        rel = path.relative_to(REPO_ROOT).as_posix()
        lang = path.parent.name
        file_name = path.stem
        meta = read_meta(path)
        if meta is None:
            continue

        ext_id = meta.get("id")
        if not isinstance(ext_id, int):
            fail(f'{rel}: metadata "id" must be an integer, got {ext_id!r}')
            continue
        if ext_id in seen_ids:
            fail(f"{rel}: duplicate id {ext_id} (also used by {seen_ids[ext_id]})")
            continue
        seen_ids[ext_id] = rel

        if not check_semver(rel, "ver", meta.get("ver")):
            continue
        if not check_semver(rel, "libVer", meta.get("libVer")):
            continue

        prev = prev_by_id.get(ext_id, {})
        content = path.read_text(encoding="utf-8")

        name = prev.get("name")
        if not name:
            m = NAME_RE.search(content)
            name = m.group(1) if m else file_name

        icon = REPO_ROOT / "icons" / f"{file_name}.png"
        if icon.exists():
            image_url = f"{RAW_BASE}/icons/{file_name}.png"
        else:
            image_url = prev.get("imageURL", "")
            if not image_url or "shosetsuorg" in image_url:
                m = re.search(r'\bimageURL\s*=\s*"([^"]+)"', content)
                image_url = m.group(1) if m else (image_url or "")
            if not image_url:
                warn(f"{rel}: no icon found (icons/{file_name}.png missing)")

        scripts.append({
            "id": ext_id,
            "name": name,
            "fileName": file_name,
            "imageURL": image_url,
            "lang": lang,
            "ver": meta["ver"],
            "libVer": meta["libVer"],
            "md5": hashlib.md5(path.read_bytes()).hexdigest(),
            "type": "LuaScript",
        })

    # Files referenced by the old index but no longer on disk are simply dropped;
    # report them so removals are always intentional.
    on_disk = {s["id"] for s in scripts}
    for ext_id, prev in prev_by_id.items():
        if ext_id not in on_disk:
            warn(f'index.json: dropping "{prev.get("fileName")}" (id {ext_id}), no source file')

    scripts.sort(key=lambda s: s["id"])
    return scripts


def build_libraries() -> list[dict]:
    libraries = []
    for path in sorted((REPO_ROOT / "lib").glob("*.lua")):
        rel = path.relative_to(REPO_ROOT).as_posix()
        meta = read_meta(path)
        if meta is None:
            continue
        if not check_semver(rel, "ver", meta.get("ver")):
            continue
        libraries.append({"name": path.stem, "ver": meta["ver"]})
    libraries.sort(key=lambda l: l["name"])
    return libraries


def build_index() -> dict:
    previous = load_previous_index()
    return {
        "authors": previous.get("authors", []),
        "libraries": build_libraries(),
        "scripts": build_scripts(previous),
        "styles": [],
    }


def render(index: dict) -> str:
    return json.dumps(index, indent="\t", ensure_ascii=False) + "\n"


def main() -> int:
    check_only = "--check" in sys.argv
    index_path = REPO_ROOT / "index.json"

    output = render(build_index())

    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    if errors:
        return 1

    current = index_path.read_text(encoding="utf-8") if index_path.exists() else ""
    if check_only:
        if current != output:
            print("ERROR index.json is out of date. Run: py scripts/generate_index.py")
            return 1
        print("OK    index.json is up to date")
        return 0

    if current == output:
        print("OK    index.json already up to date")
    else:
        index_path.write_text(output, encoding="utf-8", newline="\n")
        print(f"OK    wrote index.json ({len(json.loads(output)['scripts'])} extensions, "
              f"{len(json.loads(output)['libraries'])} libraries)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
