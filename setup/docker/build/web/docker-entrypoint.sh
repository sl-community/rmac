#!/bin/bash

if [ -n "${LEDGER_UID}" -a -n "${LEDGER_GID}" ]; then
    usermod  -u ${LEDGER_UID} www-data
    groupmod -g ${LEDGER_GID} www-data
fi

exec "$@"
