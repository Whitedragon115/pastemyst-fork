#!/usr/bin/env rdmd
// Test script to verify version generation fix

import std.stdio;
import std.process;
import std.string;

string getGitVersion()
{
    import std.process : executeShell;
    import std.string : strip;

    auto res = executeShell("git describe --tags");
    
    // If git command failed, return a fallback version
    if (res.status != 0)
    {
        writeln("Git describe failed with status: ", res.status);
        writeln("Error output: ", res.output);
        
        // Try to get just the commit hash as fallback
        auto hashRes = executeShell("git rev-parse --short HEAD");
        if (hashRes.status == 0)
        {
            writeln("Using commit hash fallback");
            return "dev-" ~ hashRes.output.strip;
        }
        
        // If even that fails, return a default version
        writeln("Using default version fallback");
        return "dev-unknown";
    }

    return res.output.strip;
}

void main()
{
    writeln("Testing version generation...");
    string version_ = getGitVersion();
    writeln("Generated version: '", version_, "'");
    
    // Test URL encoding (simulate what would happen in CSS loading)
    import std.uri : encodeComponent;
    string urlEncoded = encodeComponent(version_);
    writeln("URL encoded version: '", urlEncoded, "'");
    
    // Check if it looks like the problematic version
    if (version_.indexOf("fatal:") != -1 || version_.indexOf("No names found") != -1)
    {
        writeln("❌ Version still contains error message!");
    }
    else
    {
        writeln("✅ Version looks good!");
    }
}
