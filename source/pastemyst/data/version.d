module pastemyst.data.versioning;

private string _version;

public string getVersion()
{
    return _version;
}

static this()
{
    _version = getGitVersion();
}

private string getGitVersion()
{
    import std.process : executeShell;
    import std.string : strip;

    auto res = executeShell("git describe --tags");
    
    // If git command failed, return a fallback version
    if (res.status != 0)
    {
        // Try to get just the commit hash as fallback
        auto hashRes = executeShell("git rev-parse --short HEAD");
        if (hashRes.status == 0)
        {
            return "dev-" ~ hashRes.output.strip;
        }
        
        // If even that fails, return a default version
        return "dev-unknown";
    }

    return res.output.strip;
}
