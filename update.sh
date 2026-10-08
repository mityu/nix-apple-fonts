#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq git

set -euo pipefail

json_file="lock.json"

mapfile -t urls < <(jq -r '.srcs[].url' "$json_file")

hashes=()
for url in "${urls[@]}"; do
	sri_hash=$(nix hash convert --hash-algo sha256 "$(nix-prefetch-url "$url")")
	hashes+=("$sri_hash")
done

json_hashes_array=$(printf '%s\n' "${hashes[@]}" | jq -R . | jq -s -c .)

tmpfile=$(mktemp)
trap "rm $tmpfile" ERR
jq --argjson new_hashes "$json_hashes_array" \
	'reduce range(0; .srcs | length) as $i (.; .srcs[$i].hash = $new_hashes[$i])' \
	"$json_file" > "$tmpfile"
mv "$tmpfile" "$json_file"
