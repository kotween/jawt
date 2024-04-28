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

function Normalize-Path {
    param ([string] $Path);
    return (Resolve-Path $Path).Path;
}

$JniIncludeDir = Normalize-Path "./jdk/src/java.base/share/native/include";
$JniHeader = Normalize-Path "$JniIncludeDir/jni.h";

$JniPlatformIncludeDir = Normalize-Path @{
    Windows = ".\jdk\src\java.base\windows\native\include";
    MacOS   = "./jdk/src/java.base/unix/native/include";
    Unix    = "./jdk/src/java.base/unix/native/include";
}[$Platform];
$JniPlatformHeader = Normalize-Path "$JniPlatformIncludeDir/jni_md.h";

$JawtIncludeDir = Normalize-Path "./jdk/src/java.desktop/share/native/include";
$JawtHeader = Normalize-Path "$JawtIncludeDir/jawt.h";

$JawtPlatformIncludeDir = Normalize-Path @{
    Windows = ".\jdk\src\java.desktop\windows\native\include";
    MacOS   = "./jdk/src/java.desktop/macosx/native/include";
    Unix    = "./jdk/src/java.desktop/unix/native/include";
}[$Platform];
$JawtPlatformHeader = Normalize-Path "$JawtPlatformIncludeDir/jawt_md.h";

$InputHeader = Normalize-Path "./bindings.h";
$OutputBindings = Normalize-Path @{
    Windows = ".\jawt-sys\src\bindings_windows.rs";
    MacOS   = "./jawt-sys/src/bindings_macos.rs";
    Unix    = "./jawt-sys/src/bindings_unix.rs";
}[$Platform];
$AdditionalParams = @{
    Windows = @(
        "--raw-line", "use windows_sys::Win32::Foundation::HWND;",
        "--raw-line", "use windows_sys::Win32::Graphics::Gdi::{HBITMAP, HDC, HPALETTE};",
        # To avoid jawt_Win32DrawingSurfaceInfo__bindgen_ty_1 being generated as
        # a bindgen-generated wrapper struct
        "--allowlist-item", "HWND",
        "--allowlist-item", "HBITMAP",
        "--allowlist-item", "HDC",
        "--allowlist-item", "HPALETTE"
    );
    MacOS   = @();
    Unix    = @(
        "--raw-line", "use use x11_dl::xlib::{Colormap, Display, Drawable, VisualID};"
    );
}[$Platform];

# .Replace("\", "\\") is to escape \ in regex
& $BindgenPath                                                  `
    $InputHeader "-o" $OutputBindings                           `
    "--no-recursive-allowlist"                                  `
    "--raw-line" "#![allow(non_camel_case_types)]"              `
    "--raw-line" "#![allow(non_snake_case)]"                    `
    "--raw-line" ""                                             `
    "--raw-line" "use jni_sys::*;"                              `
    $AdditionalParams                                           `
    "--blocklist-file" $JniHeader.Replace("\", "\\")            `
    "--blocklist-file" $JniPlatformHeader.Replace("\", "\\")    `
    "--allowlist-file" $JawtHeader.Replace("\", "\\")           `
    "--allowlist-file" $JawtPlatformHeader.Replace("\", "\\")   `
    "--rust-target" "1.73"                                      `
    "--"                                                        `
    "-I$JniIncludeDir"                                          `
    "-I$JniPlatformIncludeDir"                                  `
    "-I$JawtIncludeDir"                                         `
    "-I$JawtPlatformIncludeDir";

# Postprocessing
if ($Platform -eq "Windows") {
    $Content = Get-Content $OutputBindings;
    $Content = $Content -replace "pub type (HWND|HBITMAP|HDC|HPALETTE) = .*;", "";
    Set-Content -Path $OutputBindings -Value $Content;
}