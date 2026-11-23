#!/usr/bin/env bash
# Source from any checkout; no dependency on the primary worktree's location.
_dx_here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for _dx_p in "$_dx_here/portable.sh" "$_dx_here/dx-portable.sh"; do
  if [[ -f "$_dx_p" ]]; then source "$_dx_p"; break; fi
done
unset _dx_here _dx_p
export MGOS_DX_HOME="${MGOS_DX_HOME:-$HOME/.mgos-dx}"
export GITNEXUS_EMBEDDING_MODEL="${GITNEXUS_EMBEDDING_MODEL:-voyage-code-4}"
export GITNEXUS_EMBEDDING_URL="${GITNEXUS_EMBEDDING_URL:-https://api.voyageai.com/v1}"
export GITNEXUS_EMBEDDING_DIMS="${GITNEXUS_EMBEDDING_DIMS:-1024}"
export GITNEXUS_EMBEDDING_BATCH_SIZE="${GITNEXUS_EMBEDDING_BATCH_SIZE:-512}"
export GITNEXUS_EMBEDDING_SUB_BATCH_SIZE="${GITNEXUS_EMBEDDING_SUB_BATCH_SIZE:-64}"
export GITNEXUS_EMBEDDING_REQUEST_DIMS="${GITNEXUS_EMBEDDING_REQUEST_DIMS:-omit}"
