#!/usr/bin/env python3
"""Fingerprint the repository state reviewed by build-review."""

import hashlib
import json
import os
import stat
import subprocess
import sys
from pathlib import Path


EXCLUDED_DIRS = (b".review/", b"graphify-out/")


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args], stderr=subprocess.PIPE)


def add(hasher: "hashlib._Hash", value: bytes) -> None:
    hasher.update(len(value).to_bytes(8, "big"))
    hasher.update(value)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: build-review-snapshot.py <base-ref>", file=sys.stderr)
        return 2

    try:
        root = Path(os.fsdecode(git("rev-parse", "--show-toplevel").strip()))
        base = git("rev-parse", "--verify", f"{sys.argv[1]}^{{commit}}").strip()
        head = git("rev-parse", "--verify", "HEAD^{commit}").strip()
        paths = set(git("ls-files", "-z", "--cached", "--others", "--exclude-standard").split(b"\0"))
    except subprocess.CalledProcessError as error:
        print(error.stderr.decode(errors="replace").strip(), file=sys.stderr)
        return 1

    hasher = hashlib.sha256()
    add(hasher, b"build-review-snapshot-v1")
    add(hasher, base)
    add(hasher, head)
    count = 0

    for raw_path in sorted(paths):
        if not raw_path or raw_path.startswith(EXCLUDED_DIRS):
            continue
        path = root / os.fsdecode(raw_path)
        add(hasher, raw_path)
        count += 1
        try:
            info = path.lstat()
        except FileNotFoundError:
            add(hasher, b"deleted")
            continue

        add(hasher, str(stat.S_IMODE(info.st_mode)).encode())
        if stat.S_ISLNK(info.st_mode):
            add(hasher, b"symlink")
            add(hasher, os.fsencode(os.readlink(path)))
        elif stat.S_ISREG(info.st_mode):
            add(hasher, b"file")
            add(hasher, str(info.st_size).encode())
            with path.open("rb") as stream:
                while chunk := stream.read(1024 * 1024):
                    hasher.update(chunk)
        elif stat.S_ISDIR(info.st_mode):
            add(hasher, b"directory-or-submodule")
        else:
            add(hasher, b"special-file")

    print(json.dumps({"snapshot_id": hasher.hexdigest(), "base": base.decode(),
                      "head": head.decode(), "path_count": count}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
