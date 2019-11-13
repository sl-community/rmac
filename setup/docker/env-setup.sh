#!/bin/bash

ENV_FILE=~/.sql-ledger.env
LINK=.env


if [ -r $ENV_FILE ]; then
    echo "Environment file exists: $ENV_FILE" 1>&2
else
    cat >$ENV_FILE <<EOF
###############################
# You may want to adjust these:
###############################

LEDGER_PORT=4293
LEDGERSETUP_CONFIG_PATH=/tmp/ledgersetup/config
LEDGERSETUP_DUMPS_PATH=/tmp/ledgersetup/dumps


####################
# These shoud be ok:
####################

LEDGER_POSTGRES_USER=sql-ledger

LEDGER_UID=$(id -u)
LEDGER_GID=$(id -g)
EOF
    echo "Environment file created: $ENV_FILE" 1>&2
    echo "Please adjust it to your needs." 1>&2
fi
    
if [ -L $LINK ]; then
    echo "Symbolic link exists: $LINK" 1>&2
else
    ln -s $ENV_FILE $LINK
    echo "Symbolic link created: $LINK -> $(readlink -- "$LINK")" 1>&2
fi
