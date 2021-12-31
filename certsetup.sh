#!/bin/bash
chmod 400 ./certificates/*
cp /tilt/certificates/CAs/* /usr/local/share/ca-certificates/
update-ca-certificates
