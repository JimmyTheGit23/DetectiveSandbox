#!/usr/bin/env python3
"""Download Noto Serif SC (思源宋体) multi-weight fonts from GitHub."""
import urllib.request
import json
import os
import zipfile
import glob

FONTS_DIR = r"e:\godot\DetectiveSandbox\detective\assets\fonts"

# Try multiple possible URLs for Noto Serif SC
# Source: https://github.com/googlefonts/noto-cjk/releases
DOWNLOAD_URLS = [
    # Serif2.002 release - SC individual
    "https://github.com/notofonts/noto-cjk/releases/download/Serif2.002/09_NotoSerifSC.zip",
    # Alternative: Google Fonts API direct download (single weight)
    "https://fonts.google.com/download?family=Noto+Serif+SC",
    # Source Han Serif from Adobe GitHub
    "https://github.com/adobe-fonts/source-han-serif/releases/latest",
]

def try_github_api():
    """Check GitHub releases for the correct download URL."""
    url = "https://api.github.com/repos/notofonts/noto-cjk/releases?per_page=5"
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        resp = urllib.request.urlopen(req, timeout=15)
        data = json.loads(resp.read())
        for release in data:
            tag = release.get("tag_name", "")
            print(f"Release: {tag}")
            for asset in release.get("assets", []):
                name = asset["name"].lower()
                if "serif" in name and "sc" in name:
                    print(f"  Found: {asset['name']}")
                    return asset["browser_download_url"]
            # Also list all assets for debugging
            for asset in release.get("assets", [])[:5]:
                print(f"  Asset: {asset['name']}")
    except Exception as e:
        print(f"GitHub API failed: {e}")
    return None

def try_download(url, dest):
    """Try downloading a URL."""
    print(f"Trying: {url}")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        resp = urllib.request.urlopen(req, timeout=30)
        data = resp.read()
        with open(dest, "wb") as f:
            f.write(data)
        size = os.path.getsize(dest)
        print(f"  Downloaded: {size} bytes -> {dest}")
        return True
    except Exception as e:
        print(f"  Failed: {e}")
        return False

def extract_fonts(zip_path, fonts_dir):
    """Extract TTF/OTF files from zip to fonts directory."""
    try:
        with zipfile.ZipFile(zip_path, "r") as zf:
            ttf_files = [f for f in zf.namelist() if f.endswith((".ttf", ".otf"))]
            print(f"Found {len(ttf_files)} font files in archive:")
            for tf in ttf_files:
                print(f"  {tf}")
            # Extract only the Regular and Bold weights for now
            for tf in ttf_files:
                basename = os.path.basename(tf)
                # Extract key weights
                if any(w in basename.lower() for w in ["regular", "bold", "medium", "semibold", "light"]):
                    print(f"  Extracting: {basename}")
                    with zf.open(tf) as src, open(os.path.join(fonts_dir, basename), "wb") as dst:
                        dst.write(src.read())
            # If no specific weights found, extract all
            if not any(any(w in os.path.basename(tf).lower() for w in ["regular", "bold"]) for tf in ttf_files):
                print("  No specific weight matches, extracting all...")
                for tf in ttf_files:
                    basename = os.path.basename(tf)
                    print(f"  Extracting: {basename}")
                    with zf.open(tf) as src, open(os.path.join(fonts_dir, basename), "wb") as dst:
                        dst.write(src.read())
        return True
    except Exception as e:
        print(f"Extraction failed: {e}")
        return False

def main():
    os.makedirs(FONTS_DIR, exist_ok=True)
    
    # Step 1: Try to find the right URL via GitHub API
    api_url = try_github_api()
    
    # Step 2: Try downloading
    zip_dest = os.path.join(FONTS_DIR, "NotoSerifSC_full.zip")
    
    if api_url:
        if try_download(api_url, zip_dest):
            extract_fonts(zip_dest, FONTS_DIR)
            return
    
    # Step 3: Try direct Google Fonts download
    google_url = "https://fonts.google.com/download?family=Noto+Serif+SC"
    if try_download(google_url, zip_dest):
        extract_fonts(zip_dest, FONTS_DIR)
        return
    
    print("\nAll download attempts failed.")
    print("Please manually download Noto Serif SC from:")
    print("  https://fonts.google.com/noto/specimen/Noto+Serif+SC")
    print("Or from GitHub:")
    print("  https://github.com/notofonts/noto-cjk/releases")
    print(f"Place .ttf files in: {FONTS_DIR}")

if __name__ == "__main__":
    main()