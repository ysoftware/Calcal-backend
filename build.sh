#!/bin/sh -x
swift build -c release
cp .build/release/Calcal-backend ./backend.app
chmod +x backend.app
