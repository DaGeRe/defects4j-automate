file=$1

grep "^{" "$file" | jq -r '
  if .type == "tool_use" then
    "\(.type) (\(.part.tool)): \(.part.state.input | to_entries[0] | "\(.key)=\(.value)")"
  else
    .type
  end
'
