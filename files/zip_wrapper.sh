#!/usr/bin/expect

spawn zip -e -r client.zip aws-vpnclient.crt ca.crt openvpn-shutdown ta.key aws-vpnclient.key.nopass client.conf openvpn-startup

expect "Enter password: "
send "password\n"
expect "Verify password: "
send "password\n"

interact

