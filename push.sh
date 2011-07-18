#!/bin/sh

IP="127.0.0.1"
PORT="24488"

echo "$@" | nc -q 1 $IP $PORT
