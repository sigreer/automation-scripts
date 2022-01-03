#!/bin/bash

source distrocheck.sh

if [[ $DISTRO != *debian* ]]
then
  exit 0
fi

chmod 400 ./certificates/*
cp $tiltbasedir/certificates/CAs/* /usr/local/share/ca-certificates/
update-ca-certificates
