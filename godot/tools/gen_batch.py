#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Batch FLUX2 generation driver for pirate-cats-book art regeneration.

Reads assets/art/generated/manifest.json; for each entry posts a txt2img request
to the A1111-compatible FLUX2 API (192.168.0.224:8080), writes the PNG and the raw
JSON response, and skips entries already generated (resumable).

Usage:
    python3 tools/gen_batch.py [--only SCREEN/SLUG] [--all]
"""
import argparse
import base64
import json
import os
import subprocess
import sys
import time

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "assets", "art", "generated")
MANIFEST = os.path.join(OUT, "manifest.json")
API_HOST = os.environ.get("FLUX_HOST", "192.168.0.224")
API = f"http://{API_HOST}:8080/sdapi/v1/txt2img"

WIDTH, HEIGHT, STEPS, CFG = 1024, 1024, 28, 2.5
PER_IMAGE_TIMEOUT_S = 600
MAX_RETRIES = 3


def gen_one(entry, timeout=PER_IMAGE_TIMEOUT_S):
    payload = {
        "prompt": entry["prompt"],
        "negative_prompt": entry["negative"],
        "width": WIDTH,
        "height": HEIGHT,
        "steps": STEPS,
        "cfg_scale": CFG,
        "seed": entry["seed"],
    }
    req = json.dumps(payload).encode()
    curl = [
        "curl", "-s", "-m", str(timeout), "-X", "POST", API,
        "-H", "Content-Type: application/json",
        "-d", "@-", "-o", "-",
    ]
    proc = subprocess.run(curl, input=req, capture_output=True)
    return proc


def save_png(entry, body):
    os.makedirs(os.path.dirname(entry["out"]), exist_ok=True)
    try:
        data = json.loads(body)
        png = base64.b64decode(data["images"][0])
        with open(entry["out"], "wb") as f:
            f.write(png)
    except Exception as exc:  # noqa: BLE001
        raise RuntimeError(f"decode failed: {exc}") from exc
    with open(entry["out_json"], "w", encoding="utf-8") as f:
        f.write(body)


def done(entry):
    return os.path.exists(entry["out"]) and os.path.getsize(entry["out"]) > 1000


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", help="run single target 'SCREEN/SLUG'")
    ap.add_argument("--all", action="store_true", help="force re-run even if done")
    args = ap.parse_args()

    with open(MANIFEST, encoding="utf-8") as f:
        manifest = json.load(f)

    targets = manifest
    if args.only:
        screen, slug = args.only.split("/")
        targets = [e for e in manifest if e["screen"] == screen and e["slug"] == slug]
    if not targets:
        sys.exit("no targets matched")

    for entry in targets:
        if args.all or not done(entry):
            run_entry(entry)


def run_entry(entry):
    last = None
    for attempt in range(1, MAX_RETRIES + 1):
        proc = gen_one(entry)
        if proc.returncode == 0 and proc.stdout and not proc.stdout.startswith(b"{"):
            last = proc.stdout
            time.sleep(1)
            continue
        try:
            save_png(entry, (proc.stdout or b"").decode())
            print(f"OK   {entry['screen']}/{entry['slug']} -> {entry['out']}", flush=True)
            return
        except Exception as exc:  # noqa: BLE001
            last = exc
            print(f"retry {entry['screen']}/{entry['slug']} attempt {attempt}: {exc}", flush=True)
            time.sleep(3)
    print(f"FAIL {entry['screen']}/{entry['slug']}: {last}", flush=True)


if __name__ == "__main__":
    main()
