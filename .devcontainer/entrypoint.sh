#!/bin/bash
if [ ! -f /first_run_done ]; then
    echo "Install Jlink..."
    sudo touch /first_run_done
fi

exec "$@"