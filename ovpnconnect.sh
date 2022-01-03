#!/bin/bash

cd /etc/openvpn/client
ovpnconnection=$(ls -l | grep ovpn | awk '{printf($9)}' | sed 'r\#\""\')
openvpn $ovpnconnection
