

DOW=$(date +%w)
# Assume the servers being backed up have sequential IPs (both even and odd)
LAST_BYTE=$(ip -4 -oneline -brief address list | head -2 | tail -1 | awk '{print $3}' | cut -d '/' -f 1 | cut -d '.' -f 4)
EVERYOTHERDAY=$[(DOW+LAST_BYTE)%2]
LOCKFILE=/var/safekeep/lock
LOCKTIMEOUT="$[60 * 60]"

mklockfile() {
    local lockdir
    lockdir=$(dirname $LOCKFILE)
    mkdir -p $lockdir
    chown -R safekeep.safekeep $lockdir
}
