#!/bin/sh

haxe build-cpp.hxml

sudo cp bin/cpp/airflair /usr/local/bin/
