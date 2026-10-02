# Repro: an interrupted `dn pub get` leaves `example/pubspec.yaml` stripped

Issue: https://github.com/DartNative/dartnative/issues/72

`dn pub get` in a package's `example/` app rewrites `example/pubspec.yaml` in
place while it resolves: the `dartnative*` dependencies are removed and
`dependency_overrides` pointing at `.dart_tool/dartnative_sdk/` are added.
Ctrl-C (SIGINT) and SIGTERM now restore the file. A SIGHUP (closing the
terminal or the IDE's terminal tab) or SIGKILL leaves it rewritten, and the
next `dn pub get` succeeds on the rewritten file without repairing it.

## Run

```sh
./repro.sh
```

It starts `dn pub get` in `example/`, waits until the pubspec has been
rewritten, sends SIGHUP, prints `git diff example/pubspec.yaml`, then runs
`dn pub get` again. Restore afterwards with `git checkout example/pubspec.yaml`.

## What you'll see

```console
--- example/pubspec.yaml after the interrupted run (git diff):
diff --git a/example/pubspec.yaml b/example/pubspec.yaml
index a9a254d..f44c17d 100644
--- a/example/pubspec.yaml
+++ b/example/pubspec.yaml
@@ -9,9 +9,8 @@ environment:
 # Plain version deps: `dn pub get` resolves DartNative packages from your
 # installed SDK (closed resolution) — no registry setup, works offline.
 dependencies:
-  dartnative: ^1.0.0
-  dartnative_ios: ^1.0.0
-  dartnative_android: ^1.0.0
+  ffi: ^2.1.4
+  meta: ^1.17.0
   dn_example_repro:
     path: ..
   # Skia GPU canvas: SkSL runtime shaders and rich shaped text. Adds about
@@ -49,3 +48,13 @@ dartnative:
 
 # Branded launch splash + app icon: add the dartnative_splash plugin from
 # dartpub.dev, then see tool/generate_app_assets.dart.
+
+dependency_overrides:
+  dartnative_android:
+    path: .dart_tool/dartnative_sdk/dartnative_android
+  dartnative:
+    path: .dart_tool/dartnative_sdk/dartnative
+  dartnative_ios:
+    path: .dart_tool/dartnative_sdk/dartnative_ios
+  dartnative_path_provider:
+    path: .dart_tool/dartnative_sdk/dartnative_path_provider
\ No newline at end of file

--- dn pub get again:
! dartnative_ios 1.0.0 from path .dart_tool/dartnative_sdk/dartnative_ios (overridden)
! dartnative_path_provider 1.0.0 from path .dart_tool/dartnative_sdk/dartnative_path_provider (overridden)
Got dependencies!

--- example/pubspec.yaml after the second run (git diff --stat):
 example/pubspec.yaml | 15 ++++++++++++---
 1 file changed, 12 insertions(+), 3 deletions(-)
```

## Expected

The user's `pubspec.yaml` is never left modified: resolve against a copy, or
restore the original on every exit path (SIGHUP included) and repair it on the
next run.

## Environment

- DartNative 1.0.0 (SDK `113c27aacb2`, framework edition `7ae29132`), Dart 3.12.0
- macOS 26.7.1
