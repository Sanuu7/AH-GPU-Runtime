#!/usr/bin/env python3
"""Package already-built libraries without putting generated binaries in Git."""
from pathlib import Path
import gzip
import hashlib
import json
import shutil

root = Path(__file__).resolve().parent.parent
out = root / "packages"
out.mkdir(exist_ok=True)
records = []
for abi in ("arm64-v8a", "x86_64"):
    library = root / "build" / "stripped" / abi / "libggml-vulkan.so"
    data = library.read_bytes()
    assert data[:5] == b"\x7fELF\x02", f"Not a 64-bit ELF library: {library}"
    digest = hashlib.sha256(data).hexdigest()
    name = f"gpu-{abi}-{digest}.so.gz"
    path = out / name
    with path.open("wb") as destination:
        with gzip.GzipFile(filename="", mode="wb", fileobj=destination, compresslevel=6, mtime=0) as compressed:
            compressed.write(data)
    records.append(dict(asset=name, library_sha256=digest, library_bytes=len(data), download_bytes=path.stat().st_size))
manifest = dict(schema=1, upstream="19cce6919992fdffd92e0ac152caaf1e2b8f254e", packages=records)
(out / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
(out / "SHA256SUMS").write_text("".join(hashlib.sha256((out / item["asset"]).read_bytes()).hexdigest() + "  " + item["asset"] + "\n" for item in records))
(out / "THIRD_PARTY_NOTICES.txt").write_text("\n\n".join(p.name + "\n\n" + p.read_text() for p in sorted((root / "LICENSES").glob("*.txt"))))
for item in records:
    print(out / item["asset"])
