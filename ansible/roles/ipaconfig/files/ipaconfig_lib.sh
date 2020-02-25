
die() { echo "Error ${1:-No Error Message Specified}" &> /dev/stderr; exit 1; }

dbg() { [[ "$DEBUG" != "true" ]] || echo "${1:-No debug message given}" &> /dev/stderr; }

ipacmditem() {
    local cmd
    local item="$1"
    local rx="^\s+$item:\s+"
    shift 1
    cmd="$@"
    dbg "ipacmditem($item) $cmd"
    [[ -n "$item" ]] || die "No item given"
    [[ -n "$cmd" ]] || die "No cmd given"
    OUTPUT=$("$@")
    echo "$OUTPUT" | egrep "$rx" | sed -r -e "s/($rx)(.*)/\2/"
}
