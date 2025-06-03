#!/usr/bin/env python3
"""
Test script to simulate the D language version.d logic
Tests the version generation with fallback mechanisms
"""

import subprocess
import sys

def get_git_version():
    """Simulate the getGitVersion() function from version.d"""
    try:
        # Try git describe --tags first
        result = subprocess.run(['git', 'describe', '--tags'], 
                              capture_output=True, text=True, cwd='.')
        if result.returncode == 0:
            version = result.stdout.strip()
            print(f"✓ git describe --tags succeeded: '{version}'")
            return version
        else:
            print(f"✗ git describe --tags failed: {result.stderr.strip()}")
            
        # Fallback to git rev-parse --short HEAD
        result = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], 
                              capture_output=True, text=True, cwd='.')
        if result.returncode == 0:
            commit_hash = result.stdout.strip()
            version = f"dev-{commit_hash}"
            print(f"✓ Fallback to commit hash succeeded: '{version}'")
            return version
        else:
            print(f"✗ git rev-parse --short HEAD failed: {result.stderr.strip()}")
            
        # Final fallback
        version = "dev-unknown"
        print(f"✓ Using final fallback: '{version}'")
        return version
        
    except Exception as e:
        print(f"✗ Exception occurred: {e}")
        return "dev-unknown"

def test_url_generation(version):
    """Test how the version would appear in a CSS URL parameter"""
    url_param = f"?v={version}"
    print(f"CSS URL parameter would be: '{url_param}'")
    
    # Check if it contains problematic characters
    if "fatal:" in version or "No names found" in version:
        print("❌ ERROR: Version contains error message!")
        return False
    elif version and not any(char in version for char in [' ', '\n', '\r']):
        print("✅ SUCCESS: Version is clean and usable!")
        return True
    else:
        print("⚠️  WARNING: Version might have whitespace issues")
        return True

def main():
    print("Testing pastemyst version generation fix...")
    print("=" * 50)
    
    # Test normal case (with current repository)
    print("\n1. Testing with current repository (has tags):")
    version = get_git_version()
    test_url_generation(version)
    
    # Test simulated failure case
    print("\n2. Simulating repository without tags:")
    print("   (This would happen in a fresh clone with no tags)")
    
    # Simulate the old behavior (what would happen before the fix)
    old_bad_version = "fatal: No names found, cannot describe anything."
    print(f"   Old broken version would be: '{old_bad_version}'")
    test_url_generation(old_bad_version)
    
    # Show what our fix would do
    print("\n   With our fix, it would fallback to:")
    try:
        result = subprocess.run(['git', 'rev-parse', '--short', 'HEAD'], 
                              capture_output=True, text=True, cwd='.')
        if result.returncode == 0:
            fallback_version = f"dev-{result.stdout.strip()}"
            print(f"   Fixed version: '{fallback_version}'")
            test_url_generation(fallback_version)
    except:
        fallback_version = "dev-unknown"
        print(f"   Fixed version: '{fallback_version}'")
        test_url_generation(fallback_version)

if __name__ == "__main__":
    main()
