#!/bin/sh
# Interrupts `dn pub get` in example/ the way closing the terminal does
# (SIGHUP), then shows example/pubspec.yaml and runs `dn pub get` again.
cd "$(dirname "$0")/example" || exit 1
git diff --quiet -- pubspec.yaml || { echo "example/pubspec.yaml is already modified; git checkout it first"; exit 1; }
dn pub get > /tmp/dn-pub-get-repro.log 2>&1 &
pid=$!
# Wait until dn has rewritten the pubspec for its temporary resolution.
i=0
until grep -q '^dependency_overrides:' pubspec.yaml; do
  i=$((i+1)); [ $i -gt 600 ] && { echo "pubspec never rewritten"; exit 1; }
  sleep 0.1
done
pkill -HUP -P $pid 2>/dev/null; kill -HUP $pid 2>/dev/null
wait $pid 2>/dev/null
sleep 1
echo "--- example/pubspec.yaml after the interrupted run (git diff):"
git --no-pager diff -- pubspec.yaml
echo
echo "--- dn pub get again:"
dn pub get 2>&1 | tail -3
echo
echo "--- example/pubspec.yaml after the second run (git diff --stat):"
git --no-pager diff --stat -- pubspec.yaml
