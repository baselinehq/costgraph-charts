import re
import sys


def parse(version):
    match = re.fullmatch(
        r"v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?", version
    )
    if not match:
        raise SystemExit(f"not a semver version: {version}")
    major, minor, patch, prerelease = match.groups()
    return (int(major), int(minor), int(patch)), prerelease


def prerelease_rank(prerelease):
    if prerelease is None:
        return (1,)
    identifiers = []
    for identifier in prerelease.split("."):
        if identifier.isdigit():
            identifiers.append((0, int(identifier), ""))
        else:
            identifiers.append((1, 0, identifier))
    return (0, identifiers)


def key(version):
    core, prerelease = parse(version)
    return (core, prerelease_rank(prerelease))


base, head = sys.argv[1], sys.argv[2]
sys.exit(0 if key(head) > key(base) else 1)
