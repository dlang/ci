#!/bin/sh
# Query https://www.passwordstore.org/ for GPG encrypted
# vault password to leverage keyring/gpg-agent caching.
exec pass show dlangci/ansible_vault
