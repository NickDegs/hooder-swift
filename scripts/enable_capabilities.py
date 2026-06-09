#!/usr/bin/env python3
"""Enables Sign in with Apple + iCloud KV capabilities via ASC API."""
import os, time, json
import urllib.request
import urllib.error

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
        content = e.read().decode()
        if e.code == 409:
            print(f"  Already enabled (409)")
            return None
        print(f"  HTTP {e.code}: {content}")
        raise

# Get bundle ID resource
resp = get("/v1/bundleIds?filter[identifier]=app.realvirtuality.landlord&limit=1")
bundle_id = resp["data"][0]["id"]
print(f"Bundle ID: {bundle_id}")

# Enable Sign in with Apple
print("Enabling Sign in with Apple...")
post("/v1/bundleIdCapabilities", {"data": {
    "type": "bundleIdCapabilities",
    "attributes": {"capabilityType": "APPLE_ID_AUTH", "settings": []},
    "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_id}}}
}})

# Enable iCloud (KV store)
print("Enabling iCloud...")
post("/v1/bundleIdCapabilities", {"data": {
    "type": "bundleIdCapabilities",
    "attributes": {
        "capabilityType": "ICLOUD",
        "settings": [{"key": "ICLOUD_VERSION", "options": [{"key": "XCODE_6"}]}]
    },
    "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bundle_id}}}
}})

print("Done.")

# Delete stale App Store profiles so fastlane creates a fresh one with current capabilities
print("Deleting stale App Store profiles...")
try:
    resp = get(f"/v1/profiles?filter[bundleId]={bundle_id}&filter[profileType]=IOS_APP_STORE&limit=10")
    for p in resp.get("data", []):
        pid = p["id"]
        pname = p["attributes"].get("name", pid)
        req = urllib.request.Request(f"{BASE}/v1/profiles/{pid}", headers=HEADERS, method="DELETE")
        try:
            urllib.request.urlopen(req)
            print(f"  Deleted: {pname}")
        except urllib.error.HTTPError as e:
            print(f"  Skip {pname}: {e.code}")
except Exception as e:
    print(f"  Profile list error (non-fatal): {e}")

print("Capability setup complete.")
