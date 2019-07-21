#!/bin/bash

source $(basename $0)/lib.sh

(
	if [[ "$UID" != "0" ]]
	then
		echo "Not running as root"
		exit 1
	fi
	[[ "${FLOCKER}" != "x$0x" ]] && echo "Acquiring lock"
	[[ "${FLOCKER}" != "x$0x" ]] && exec env FLOCKER="x$0x" flock "$LOCKFILE" "$0" "$@"
	[[ "${FLOCKER}" == "x$0x" ]] && echo "Lock acquired"

	# Check backup.d/ excludes*
	BASE="/var/lib/safekeep"
	SOURCE="$(mktemp -d ${BASE}/source.XXXXXXXX)"
	DESTURL="{{ backup_archive_bucket_uri }}"  # /$NAME appended
	PASSPHRASEFILE="/var/lib/safekeep/archive_passphrase"
	TMPDIR="$(mktemp -d ${BASE}/tmpdir.XXXXXXXX)"
	PRUNETIME="3M"
	export AWS_CREDENTIAL_FILE=/var/lib/safekeep/boto

	cleanup() {
	    echo "Cleaning up temporary files"
	    rm -rf "$TMPDIR"
	    rm -rf "$SOURCE"
	}
	trap cleanup EXIT

	if ! [[ -r "$PASSPHRASEFILE" ]]
	then
	    echo "Error: Can't read passphrase from $PASSPHRASEFILE"
	    exit 2
	fi

	cd "$BASE"
	for NAME in *.{{ emailclient_mydomain }}
	do
	    echo "=================================================="
	    echo "Extracting $NAME"
	    mkdir -vp "${SOURCE}/${NAME}"
	    cd "$BASE"
	    rdiff-backup --restore-as-of now --tempdir "$TMPDIR" \
			 "${NAME}" "$SOURCE/${NAME}"
	    if [[ "$?" -ne "0" ]]
	    then
		echo "Error unpacking latest backup for $NAME"
		exit 3
	    fi

	    cd "$SOURCE/$NAME"
	    echo "Dumping recursive file listing to $BASE/listings/$NAME"
	    ls -laR > "$BASE/listings/$NAME"

	    echo "Archiving backup for $NAME"
	    PASSPHRASE=$(cat $PASSPHRASEFILE) /usr/bin/duplicity incr \
		      --full-if-older-than "$PRUNETIME" \
		      --archive-dir "$BASE/duplicity_cache" --name "$NAME" \
		      --volsize 1024 --verbosity warning --progress \
		      --s3-unencrypted-connection --s3-use-new-style \
		      --tempdir "$TMPDIR" ./ "$DESTURL/$NAME"
	    RET=$?
	    echo "Duplicity archive for $NAME exited: $RET"

	    echo "Cleaning up archive source"
	    cd "$BASE"
	    rm -rf "$SOURCE/$NAME"

	    if [[ "$RET" -ne "0" ]]
	    then
		echo "WARNING: Not pruning $NAME archive."
		continue
	    fi

	    echo "Pruning $NAME duplicity sets older than $PRUNETIME"
	    PASSPHRASE=$(cat $PASSPHRASEFILE) /usr/bin/duplicity \
		remove-older-than "$PRUNETIME" --archive-dir "$BASE/duplicity_cache" \
		--verbosity warning --tempdir "$TMPDIR" --force --name "$NAME" \
		--s3-unencrypted-connection --s3-use-new-style "$DESTURL/$NAME"
	    echo "Duplicity pruning exited: $?"

	    echo "Pruning $NAME rdiff-backup sets older than $PRUNETIME"
	    rdiff-backup --force --remove-older-than $PRUNETIME $NAME
	    echo "rdiff-backup exited: $?"
	done
	echo "Lock released"
) &> /var/lib/safekeep/archive.log
