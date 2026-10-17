Scriptname SKSE Hidden
{The SKSE functions these examples use. Declarations only: SKSE provides the implementation.}

; SKSE's own version
int Function GetVersion() global native
int Function GetVersionMinor() global native
int Function GetVersionBeta() global native
int Function GetVersionRelease() global native
int Function GetScriptVersionRelease() global native

; The version an SKSE plugin reported for itself, or -1 if no plugin of that name is loaded
int Function GetPluginVersion(string name) global native
