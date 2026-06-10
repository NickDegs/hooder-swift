#!/usr/bin/env python3
"""Sets up internal TestFlight group with auto-distribution and adds tester."""
import os, time, json
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
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())

def post(path, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(f"{BASE}{path}", data=body, headers=HEADERS, method="POST")
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"  POST {e.code}: {body}")
        return None

def patch(path, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(f"{BASE}{path}", data=body, headers=HEADERS, method="PATCH")
    try:
        with urllib.request.urlopen(req) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        print(f"  PATCH {e.code}: {e.read().decode('utf-8', errors='replace')}")
        return None

# 1. List existing beta groups
print(f"App ID: {app_id}")
print("Listing beta groups...")
resp = get(f"/v1/apps/{app_id}/betaGroups")
groups = resp.get("data", [])
for g in groups:
    attrs = g["attributes"]
    print(f"  {g['id']} — {attrs.get('name')} internal={attrs.get('isInternalGroup')} autoDist={attrs.get('hasAccessToAllBuilds')}")

# 2. Find or create internal group
internal_group = next((g for g in groups if g["attributes"].get("isInternalGroup")), None)

if not internal_group:
    print("No internal group found — creating...")
    resp = post("/v1/betaGroups", {"data": {
        "type": "betaGroups",
        "attributes": {
            "name": "Internal Testers",
            "isInternalGroup": True,
            "hasAccessToAllBuilds": True,
            "publicLinkEnabled": False,
        },
        "relationships": {
            "app": {"data": {"type": "apps", "id": app_id}}
        }
    }})
    if resp:
        internal_group = resp["data"]
        print(f"  Created: {internal_group['id']}")
else:
    print(f"Found internal group: {internal_group['id']} — {internal_group['attributes'].get('name')}")
    # Ensure auto-distribution is on
    if not internal_group["attributes"].get("hasAccessToAllBuilds"):
        print("  Enabling auto-distribution for all builds...")
        patch(f"/v1/betaGroups/{internal_group['id']}", {"data": {
            "type": "betaGroups",
            "id": internal_group["id"],
            "attributes": {"hasAccessToAllBuilds": True}
        }})

group_id = internal_group["id"]

# 3. Check if tester already in group
print(f"Checking testers in group {group_id}...")
resp = get(f"/v1/betaGroups/{group_id}/betaTesters?limit=50")
testers = resp.get("data", [])
existing_emails = [t["attributes"].get("email","") for t in testers]
print(f"  Current testers: {existing_emails}")

if tester_email in existing_emails:
    print(f"  {tester_email} already in group")
else:
    # Find tester by email
    print(f"Looking up {tester_email}...")
    import urllib.parse
    resp = get(f"/v1/betaTesters?filter[email]={urllib.parse.quote(tester_email)}&limit=1")
    testers_found = resp.get("data", [])
    if testers_found:
        tester_id = testers_found[0]["id"]
        print(f"  Found tester ID: {tester_id}")
        # Add to group
        resp = post(f"/v1/betaGroups/{group_id}/relationships/betaTesters", {
            "data": [{"type": "betaTesters", "id": tester_id}]
        })
        print(f"  Added {tester_email} to group")
    else:
        # Create/invite tester
        print(f"  Tester not found — inviting {tester_email}...")
        resp = post("/v1/betaTesters", {"data": {
            "type": "betaTesters",
            "attributes": {"email": tester_email, "firstName": "Baris", "lastName": "Daclen"},
            "relationships": {"betaGroups": {"data": [{"type": "betaGroups", "id": group_id}]}}
        }})
        if resp:
            print(f"  Invited: {resp['data']['id']}")

# 4. Distribute latest build to internal group
print("Finding latest processed build...")
resp = get(f"/v1/builds?filter[app]={app_id}&filter[processingState]=VALID&sort=-uploadedDate&limit=1")
builds = resp.get("data", [])
if builds:
    build = builds[0]
    build_id = build["id"]
    attrs = build["attributes"]
    print(f"  Build: {attrs.get('version')} — {attrs.get('uploadedDate')}")
    # Add build to internal group
    resp = post(f"/v1/betaGroups/{group_id}/relationships/builds", {
        "data": [{"type": "builds", "id": build_id}]
    })
    print(f"  Build added to internal group")

print("Done.")
