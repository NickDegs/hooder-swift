#!/usr/bin/env python3
"""
Enables Sign in with Apple + iCloud capabilities, deletes stale profiles,
and creates a fresh App Store provisioning profile via ASC API.
"""
import os, time, json, base64
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
            print("  Already enabled (409)")
            return None
        raise

def delete(path):
    req = urllib.request.Request(f"{BASE}{path}", headers=HEADERS, method="DELETE")
    try:
        urllib.request.urlopen(req)
        return True
    except urllib.error.HTTPError as e:
        print(f"  Delete failed {e.code}")
        return False

# ── 1. Get bundle ID resource ──────────────────────────────────────────────
resp = get("/v1/bundleIds?filter[identifier]=app.realvirtuality.landlord&limit=1")
bundle_res_id = resp["data"][0]["id"]
print(f"Bundle ID resource: {bundle_res_id}")

# ── 2. List current capabilities ───────────────────────────────────────────
print("Current capabilities:")
try:
    cap_resp = get(f"/v1/bundleIds/{bundle_res_id}/bundleIdCapabilities")
    existing_types = {c["attributes"]["capabilityType"]: c["id"] for c in cap_resp.get("data", [])}
    for ct in existing_types:
        print(f"  {ct}")
except Exception as e:
    print(f"  Error listing: {e}")
    existing_types = {}

# ── 3. Enable / update capabilities ─────────────────────────────────────────
def enable_or_update(cap_type, settings):
    if cap_type in existing_types:
        # PATCH existing capability
        cap_id = existing_types[cap_type]
        req = urllib.request.Request(
            f"{BASE}/v1/bundleIdCapabilities/{cap_id}",
            data=json.dumps({"data": {
                "type": "bundleIdCapabilities",
                "id": cap_id,
                "attributes": {"capabilityType": cap_type, "settings": settings},
            }}).encode(),
            headers={**HEADERS, "Content-Type": "application/json"},
            method="PATCH"
        )
        try:
            urllib.request.urlopen(req)
            print(f"  Updated {cap_type}")
        except urllib.error.HTTPError as e:
            print(f"  Patch {cap_type} {e.code}")
    else:
        result = post("/v1/bundleIdCapabilities", {"data": {
            "type": "bundleIdCapabilities",
            "attributes": {"capabilityType": cap_type, "settings": settings},
            "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_res_id}}}
        }})
        if result:
            print(f"  Enabled {cap_type}")

print("Enabling Sign in with Apple...")
enable_or_update("APPLE_ID_AUTH", [])

print("Enabling iCloud...")
enable_or_update("ICLOUD", [{"key": "ICLOUD_VERSION", "options": [{"key": "XCODE_6"}]}])

# ASC'ye capability değişikliklerini yansıtması için bekle
print("Waiting for ASC to propagate capability changes...")
time.sleep(5)

# ── 3. Delete stale App Store profiles ────────────────────────────────────
print("Deleting stale App Store profiles...")
try:
    resp = get("/v1/profiles?filter[profileType]=IOS_APP_STORE&limit=50")
    for p in resp.get("data", []):
        rel_bid = p.get("relationships", {}).get("bundleId", {}).get("data", {}).get("id", "")
        if rel_bid == bundle_res_id:
            pid   = p["id"]
            pname = p["attributes"].get("name", pid)
            if delete(f"/v1/profiles/{pid}"):
                print(f"  Deleted: {pname}")
except Exception as e:
    print(f"  Profile list/delete error (non-fatal): {e}")

# ── 4. Get distribution certificate(s) ────────────────────────────────────
print("Fetching distribution certificates...")
resp = get("/v1/certificates?filter[certificateType]=IOS_DISTRIBUTION&limit=10")
cert_ids = [c["id"] for c in resp.get("data", [])]
if not cert_ids:
    # Try DISTRIBUTION type as well (some accounts use this)
    resp = get("/v1/certificates?filter[certificateType]=DISTRIBUTION&limit=10")
    cert_ids = [c["id"] for c in resp.get("data", [])]
if not cert_ids:
    print("  No distribution certificate found — skipping profile creation")
    print("Capability setup complete (profile not created, fastlane will handle).")
    exit(0)
print(f"  Found {len(cert_ids)} certificate(s)")

# ── 5. Create fresh App Store profile ─────────────────────────────────────
print("Creating fresh App Store profile...")
resp = post("/v1/profiles", {"data": {
    "type": "profiles",
    "attributes": {
        "name": "app.realvirtuality.landlord AppStore CI",
        "profileType": "IOS_APP_STORE"
    },
    "relationships": {
        "bundleId": {"data": {"type": "bundleIds", "id": bundle_res_id}},
        "certificates": {"data": [{"type": "certificates", "id": cid} for cid in cert_ids]},
        "devices": {"data": []}
    }
}})

if resp is None:
    print("  Profile creation returned None — capability already handled")
    print("Capability setup complete.")
    exit(0)

profile_content = resp["data"]["attributes"]["profileContent"]
profile_bytes   = base64.b64decode(profile_content)
profile_path    = PROFILE_DIR / "AppStore_app.realvirtuality.landlord.mobileprovision"
profile_path.write_bytes(profile_bytes)
print(f"  Profile saved: {profile_path}")

# Extract UUID from profile using security cms
import subprocess
result = subprocess.run(
    ["security", "cms", "-D", "-i", str(profile_path)],
    capture_output=True, text=True
)
if result.returncode == 0:
    import plistlib
    plist = plistlib.loads(result.stdout.encode())
    uuid = plist.get("UUID", "")
    print(f"  Profile UUID: {uuid}")
    # Write UUID to env for fastlane
    with open(os.environ.get("GITHUB_ENV", "/dev/null"), "a") as f:
        f.write(f"PROFILE_UUID={uuid}\n")
        f.write(f"PROFILE_PATH={profile_path}\n")

print("Capability setup complete.")
