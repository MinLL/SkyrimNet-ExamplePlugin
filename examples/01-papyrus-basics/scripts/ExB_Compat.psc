Scriptname ExB_Compat Hidden
{SkyrimNet version checks. Global functions only: call them from any script, attach this to nothing.}

; The oldest SkyrimNet this mod works with. Raise it when you start calling an API function that
; a newer SkyrimNet added. Keep it in step with min_skyrimnet_version in the layer's manifest.json.
string Function MinimumVersion() global
    return "0.25.0"
EndFunction

; True when SkyrimNet's DLL is loaded. Check this before calling any SkyrimNetApi function: when
; the DLL is missing, a native call only logs an error and returns a default, which looks like a
; silent failure to whoever is debugging it.
bool Function IsSkyrimNetLoaded() global
    return SKSE.GetPluginVersion("SkyrimNet") != -1
EndFunction

; True when SkyrimNet is loaded and at least MinimumVersion().
bool Function IsSkyrimNetCompatible() global
    if !IsSkyrimNetLoaded()
        return false
    endif
    return CompareVersions(SkyrimNetApi.GetBuildVersion(), MinimumVersion()) >= 0
EndFunction

; Compares dotted versions number by number, so "0.10.0" is newer than "0.9.0".
; Returns -1 if a is older, 0 if equal, 1 if newer. Missing parts count as 0: "0.28" equals "0.28.0".
int Function CompareVersions(string a, string b) global
    int i = 0
    while i < 4
        int partA = VersionPart(a, i)
        int partB = VersionPart(b, i)
        if partA < partB
            return -1
        elseif partA > partB
            return 1
        endif
        i += 1
    endwhile
    return 0
EndFunction

; The index-th dot-separated number of a version string, or 0 if it has no such part.
int Function VersionPart(string version, int index) global
    int start = 0
    int skipped = 0
    while skipped < index
        int nextDot = StringUtil.Find(version, ".", start)
        if nextDot < 0
            return 0
        endif
        start = nextDot + 1
        skipped += 1
    endwhile

    int endDot = StringUtil.Find(version, ".", start)
    if endDot < 0
        return StringUtil.Substring(version, start) as int
    endif
    return StringUtil.Substring(version, start, endDot - start) as int
EndFunction
