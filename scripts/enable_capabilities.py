#!/usr/bin/env python3
"""
Enables Sign in with Apple + iCloud capabilities, deletes stale profiles,
and creates a fresh App Store provisioning profile via ASC API.
"""
import os, time, json, base64, urllib.parse
import urllib.request, urllib.error
from pathlib import Path

try:
    import jwt
except ImportError:
    import subprocess, sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyjwt", "cryptography", "-q"])
    import jwt

key_id    = os.environ["ASC_KEY_ID"]
issuer_id = os.environ["ASC_ISSUER_ID"]
key_pem   = os.environ["ASC_API_KEY"]

now = int(time.time())
token = jwt.encode(
    {"iss": issuer_id, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
    key_pem, algorithm="ES256", headers={"kid": key_id}
)

HEADERS = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
BASE = "https://api.appstoreconnect.apple.com"
PROFILE_DIR = Path("/tmp/fl-certs")
PROFILE_DIR.mkdir(parents=True, exist_ok=True)
PROFILE_NAME = "app.realvirtuality.landlord AppStore CI"

def get(path):
    req = urllib.request.Request(f"{BASE}{path}", headers=HEADERS)
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())

def post(path, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(f"{BASE}{path}", data=body, headers=HEADERS, method="POST")
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        if e.code == 409:
            err_body = e.read().decode("utf-8", errors="replace")
            print(f"  409: {err_body}")
            return None
        raise

def patch(path, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(f"{BASE}{path}", data=body, headers=HEADERS, method="PATCH")
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        print(f"  PATCH {e.code}: {e.read().decode('utf-8', errors='replace')}")
        return None

def delete(path):
    req = urllib.request.Request(f"{BASE}{path}", headers=HEADERS, method="DELETE")
    try:
        urllib.request.urlopen(req)
        return True
    except urllib.error.HTTPError as e:
        print(f"  Delete failed {e.code}: {e.read().decode('utf-8', errors='replace')}")
        return False

# ── 1. Get bundle ID resource ──────────────────────────────────────────────
resp = get("/v1/bundleIds?filter[identifier]=app.realvirtuality.landlord&limit=1")
bundle_res_id = resp["data"][0]["id"]
print(f"Bundle ID resource: {bundle_res_id}")

# ── 2. List current capabilities ───────────────────────────────────────────
print("Current capabilities:")
try:
    cap_resp = get(f"/v1/bundleIds/{bundle_res_id}/bundleIdCapabilities")
    existing_types = {}
    for c in cap_resp.get("data", []):
        ct = c["attributes"]["capabilityType"]
        existing_types[ct] = c["id"]
        print(f"  {ct} → {c['id']}")
    print(f"  (total: {len(existing_types)})")
except Exception as e:
    print(f"  Error listing: {e}")
    existing_types = {}

# ── 3. Enable / update capabilities ─────────────────────────────────────────
def enable_capability(cap_type, settings):
    if cap_type in existing_types:
        cap_id = existing_types[cap_type]
        result = patch(f"/v1/bundleIdCapabilities/{cap_id}", {"data": {
            "type": "bundleIdCapabilities",
            "id": cap_id,
            "attributes": {"capabilityType": cap_type, "settings": settings},
        }})
        if result is not None:
            print(f"  PATCHed {cap_type}")
    else:
        result = post("/v1/bundleIdCapabilities", {"data": {
            "type": "bundleIdCapabilities",
            "attributes": {"capabilityType": cap_type, "settings": settings},
            "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_res_id}}}
        }})
        if result:
            print(f"  Enabled {cap_type}")

# Sign in with Apple requires PRIMARY_APP_CONSENT configuration
print("Enabling Sign in with Apple...")
enable_capability("APPLE_ID_AUTH", [
    {"key": "APPLE_ID_AUTH_APP_CONSENT", "options": [{"key": "PRIMARY_APP_CONSENT"}]}
])

print("Enabling iCloud...")
enable_capability("ICLOUD", [{"key": "ICLOUD_VERSION", "options": [{"key": "XCODE_6"}]}])

# Wait for ASC to propagate capability changes
print("Waiting 8s for ASC propagation...")
time.sleep(8)

# ── 4. Delete stale App Store profiles (filter by name) ───────────────────
print("Deleting stale profiles...")
try:
    encoded = urllib.parse.quote(PROFILE_NAME)
    resp = get(f"/v1/profiles?filter[profileType]=IOS_APP_STORE&filter[name]={encoded}&limit=50")
    deleted = 0
    for p in resp.get("data", []):
        pid   = p["id"]
        pname = p["attributes"].get("name", pid)
        if delete(f"/v1/profiles/{pid}"):
            print(f"  Deleted: {pname}")
            deleted += 1
    if deleted == 0:
        print("  No matching profiles found to delete")
except Exception as e:
    print(f"  Profile list/delete error (non-fatal): {e}")

# ── 5. Get distribution certificate(s) ────────────────────────────────────
print("Fetching distribution certificates...")
resp = get("/v1/certificates?filter[certificateType]=IOS_DISTRIBUTION&limit=10")
cert_ids = [c["id"] for c in resp.get("data", [])]
if not cert_ids:
    resp = get("/v1/certificates?filter[certificateType]=DISTRIBUTION&limit=10")
    cert_ids = [c["id"] for c in resp.get("data", [])]
if not cert_ids:
    print("  No distribution certificate found — skipping profile creation")
    print("Capability setup complete (profile not created).")
    exit(0)
print(f"  Found {len(cert_ids)} certificate(s)")

# ── 6. Create fresh App Store profile ─────────────────────────────────────
print("Creating fresh App Store profile...")
resp = post("/v1/profiles", {"data": {
    "type": "profiles",
    "attributes": {
        "name": PROFILE_NAME,
        "profileType": "IOS_APP_STORE"
    },
    "relationships": {
        "bundleId": {"data": {"type": "bundleIds", "id": bundle_res_id}},
        "certificates": {"data": [{"type": "certificates", "id": cid} for cid in cert_ids]},
        "devices": {"data": []}
    }
}})

if resp is None:
    print("  Profile creation failed (409 — duplicate name). Listing current profiles...")
    try:
        encoded = urllib.parse.quote(PROFILE_NAME)
        resp2 = get(f"/v1/profiles?filter[profileType]=IOS_APP_STORE&filter[name]={encoded}&limit=10")
        for p in resp2.get("data", []):
            print(f"  Existing: {p['id']} — {p['attributes'].get('name')}")
    except Exception as e2:
        print(f"  Listing failed: {e2}")
    print("Capability setup complete (profile not created — will use existing).")
    exit(1)

profile_content = resp["data"]["attributes"]["profileContent"]
profile_bytes   = base64.b64decode(profile_content)
profile_path    = PROFILE_DIR / "AppStore_app.realvirtuality.landlord.mobileprovision"
profile_path.write_bytes(profile_bytes)
print(f"  Profile saved: {profile_path}")

# Extract UUID from profile
import subprocess
result = subprocess.run(
    ["security", "cms", "-D", "-i", str(profile_path)],
    capture_output=True, text=True
)
if result.returncode == 0:
    import plistlib
    plist = plistlib.loads(result.stdout.encode())
    uuid = plist.get("UUID", "")
    entitlements = plist.get("Entitlements", {})
    has_apple_signin = "com.apple.developer.applesignin" in entitlements
    print(f"  Profile UUID: {uuid}")
    print(f"  Has Apple Sign In entitlement: {has_apple_signin}")
    print(f"  Entitlements: {list(entitlements.keys())}")
    with open(os.environ.get("GITHUB_ENV", "/dev/null"), "a") as f:
        f.write(f"PROFILE_UUID={uuid}\n")
        f.write(f"PROFILE_PATH={profile_path}\n")

print("Capability setup complete.")
