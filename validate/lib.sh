
SCRIPT_FILENAME=${SCRIPT_FILENAME:-$(basename $(realpath "$0"))}
SCRIPT_DIRPATH=${SCRIPT_DIRPATH:-$(dirname $(realpath "$0"))}
SCRIPT_SUBDIR=${SCRIPT_SUBDIR:-$(basename "$SCRIPT_DIRPATH")}
SRC_DIR=${SRC_DIR:-$(realpath "$SCRIPT_DIRPATH/../")}

source "$SRC_DIR/bin/lib.sh"

indent(){
    [[ "$1" -gt "0" ]] || die "Expecting first parameter to be the number of indend spaces" 1
    [[ -n "$2" ]] || die "Expecting second parameter to be a single line message" 2
    for (( i=0 ; i < $1 ; i++ ))
    do
        echo -n "* "
    done
    echo -e "$2"
}

non_empty_file(){
    [[ "$1" -gt "0" ]] || die "Expecting first parameter to be the number of indend spaces" 1
    [[ -n "$2" ]] || die "Expecting second parameter to be path to file" 2
    _filepath=$(realpath "$2")
    indent $1 "Checking that file \"$_filepath\" exists"
    test -r "$_filepath"
    _size=$(stat --format '%s' "$_filepath")
    test "$_size" -gt "0"
    unset _filepath _size
}
