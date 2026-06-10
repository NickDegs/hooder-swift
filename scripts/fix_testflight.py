#!/usr/bin/env python3
"""Adds tester + latest build to the internal TestFlight group."""
import os, time, json, urllib.parse
import urllib.request, urllib.error

try:
    import jwt
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyjwt", "cryptography", "-q"])
    import jwt

key_id    = os.environ["ASC_KEY_ID"]
issuer_id = os.environ["ASC_ISSUER_ID"]
key_pem   = os.environ["ASC_API_KEY"]
app_id    = "6776767786"
tester_email = "daclen100@gmail.com"

now = int(time.time())
token = jwt.encode(
    {"iss": issuer_id, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
    key_pem, algorithm="ES256", headers={"kid": key_id}
)
HEADERS = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
BASE = "https://api.appstoreconnect.apple.com"

def get(path):
    req = urllib.request.Request(f"{BASE}{path}", headers=HEADERS)
    try:
        with urllib.request.urlopen(req) as r:
            body = r.read()
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        print(f"  GET {e.code}: {e.read().decode('utf-8', errors='replace')[:200]}")
        return {}

def post(path, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(f"{BASE}{path}", data=body, headers=HEADERS, method="POST")
    try:
        with urllib.request.urlopen(req) as r:
            body = r.read()
            return json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        print(f"  POST {e.code}: {e.read().decode('utf-8', errors='replace')[:300]}")
        return None

# 1. Find internal group
print("Listing beta groups...")
resp = get(f"/v1/apps/{app_id}/betaGroups")
groups = resp.get("data", [])
for g in groups:
    a = g["attributes"]
    print(f"  {g['id']} — {a.get('name')} internal={a.get('isInternalGroup')} autoDist={a.get('hasAccessToAllBuilds')}")

internal_group = next((g for g in groups if g["attributes"].get("isInternalGroup")), None)
if not internal_group:
    print("ERROR: No internal group found")
    exit(1)

group_id = internal_group["id"]
print(f"Using group: {internal_group['attributes']['name']} ({group_id})")

# 2. Find tester
print(f"\nLooking up tester {tester_email}...")
resp = get(f"/v1/betaTesters?filter[email]={urllib.parse.quote(tester_email)}&limit=1")
testers_found = resp.get("data", [])

if testers_found:
    tester_id = testers_found[0]["id"]
    attrs = testers_found[0]["attributes"]
    print(f"  Found: {tester_id} — {attrs.get('firstName')} {attrs.get('lastName')}")
else:
    print(f"  Not found — creating tester...")
    resp = post("/v1/betaTesters", {"data": {
        "type": "betaTesters",
        "attributes": {"email": tester_email, "firstName": "Baris", "lastName": "Daclen"},
    }})
    if not resp:
        print("  Failed to create tester")
        exit(1)
    tester_id = resp["data"]["id"]
    print(f"  Created: {tester_id}")

# 3. Add tester to group
print(f"\nAdding {tester_email} to group...")
result = post(f"/v1/betaGroups/{group_id}/relationships/betaTesters", {
    "data": [{"type": "betaTesters", "id": tester_id}]
})
if result is not None:
    print("  Done (or already in group)")

# 4. Find latest valid builds and add to group
print("\nFinding latest processed builds...")
resp = get(f"/v1/builds?filter[app]={app_id}&filter[processingState]=VALID&sort=-uploadedDate&limit=3")
builds = resp.get("data", [])
if not builds:
    print("  No valid builds found")
    exit(0)

for b in builds:
    a = b["attributes"]
    print(f"  {b['id']} — v{a.get('version')} uploaded={a.get('uploadedDate')}")

build_id = builds[0]["id"]
print(f"\nAdding build {build_id} to group...")
result = post(f"/v1/betaGroups/{group_id}/relationships/builds", {
    "data": [{"type": "builds", "id": build_id}]
})
if result is not None:
    print("  Done")

print("\nSetup complete. Check TestFlight in a few minutes.")
