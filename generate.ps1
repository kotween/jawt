$RuntimeInformation = [System.Runtime.InteropServices.RuntimeInformation];
$OSPlatform = [System.Runtime.InteropServices.OSPlatform];
$BindgenPath = if ([System.Environment]::OSVersion.Platform -eq "Win32NT") {
    ".bindgen\bin\bindgen.exe"
}
else {
    ".bindgen/bin/bindgen"
};
$Platform = if ($RuntimeInformation::IsOSPlatform($OSPlatform::Windows)) {
    "Windows"
}
elseif ($RuntimeInformation::IsOSPlatform($OSPlatform::OSX)) {
    "MacOS"
}
else {
    "Unix"
};

# Install bindgen locally
if (-not (Test-Path $BindgenPath)) {
    & "cargo" "install" "--version" "^0.69" "--root" ".bindgen" "bindgen-cli";
}

# Update submodules
& "git" "submodule" "update" "--init" "--recursive";

$JniIncludeDir = "./jdk/src/java.base/share/native/include";
$JniPlatformIncludeDir = @{
    Windows = "./jdk/src/java.base/windows/native/include";
    MacOS   = "./jdk/src/java.base/unix/native/include";
    Unix    = "./jdk/src/java.base/unix/native/include";
}[$Platform];
$JawtIncludeDir = "./jdk/src/java.desktop/share/native/include";
$JawtPlatformIncludeDir = @{
    Windows = "./jdk/src/java.desktop/windows/native/include";
    MacOS   = "./jdk/src/java.desktop/macosx/native/include";
    Unix    = "./jdk/src/java.desktop/unix/native/include";
}[$Platform];
$InputHeader = "./bindings.h";
$OutputBindings = @{
    Windows = "./jawt-sys/src/bindings_windows.rs";
    MacOS   = "./jawt-sys/src/bindings_macos.rs";
    Unix    = "./jawt-sys/src/bindings_unix.rs";
}[$Platform];

& $BindgenPath                                              `
    $InputHeader "-o" $OutputBindings                       `
    "--no-recursive-allowlist"                              `
    "--raw-line" "#![allow(non_camel_case_types)]"          `
    "--raw-line" "#![allow(non_snake_case)]"                `
    "--raw-line" ""                                         `
    "--raw-line" "use jni_sys::*;"                          `
    "--blocklist-file" "$JniIncludeDir/jni.h"               `
    "--blocklist-file" "$JniPlatformIncludeDir/jni_md.h"    `
    "--allowlist-file" "$JawtIncludeDir/jawt.h"             `
    "--allowlist-file" "$JawtPlatformIncludeDir/jawt_md.h"  `
    "--rust-target" "1.73"                                  `
    "--"                                                    `
    "-I$JniIncludeDir"                                      `
    "-I$JniPlatformIncludeDir"                              `
    "-I$JawtIncludeDir"                                     `
    "-I$JawtPlatformIncludeDir";