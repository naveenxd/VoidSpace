#!/usr/bin/env python3
"""
gen_secrets.py — Regenerate the XOR-obfuscated token table for lib/app/secrets.dart

Usage:
  python3 scripts/gen_secrets.py <YOUR_TOKEN>

Example:
  python3 scripts/gen_secrets.py xdv_b4b2373d34277015a1eb5c663eb1b4b28178c8989cabc863

Then copy the printed _T list into lib/app/secrets.dart.
Do NOT commit the raw token anywhere.
"""

from __future__ import annotations

import sys
from typing import List

_USAGE: str = __doc__ or ""

KEY: List[int] = [
    0x56, 0x4F, 0x49, 0x44, 0x5F, 0x53, 0x50, 0x41,
    0x43, 0x45, 0x5F, 0x4B, 0x45, 0x59, 0x5F, 0x32,
    0x30, 0x32, 0x35, 0x5F, 0x58, 0x44, 0x56, 0x5F,
    0x53, 0x45, 0x43, 0x52, 0x45, 0x54, 0x21, 0x40,
]


def encode(token: str) -> List[int]:
    return [ord(c) ^ KEY[i % len(KEY)] for i, c in enumerate(token)]


def decode(obf: List[int]) -> str:
    return "".join(chr(b ^ KEY[i % len(KEY)]) for i, b in enumerate(obf))


def format_dart_list(obf: List[int]) -> str:
    rows: List[str] = []
    for i in range(0, len(obf), 8):
        chunk: List[int] = obf[i : i + 8]
        rows.append("  " + ", ".join(f"0x{b:02X}" for b in chunk) + ",")
    return "const List<int> _T = [\n" + "\n".join(rows) + "\n];"


def main() -> None:
    if len(sys.argv) < 2:
        print(_USAGE)
        sys.exit(1)

    token: str = sys.argv[1].strip()
    obf: List[int] = encode(token)

    # Verify round-trip before printing anything
    assert decode(obf) == token, "Round-trip verification failed!"

    print(f"Token length : {len(token)}")
    print("Round-trip   : OK\n")
    print("─── Paste this into lib/app/secrets.dart ───\n")
    print(format_dart_list(obf))


if __name__ == "__main__":
    main()
