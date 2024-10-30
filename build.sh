#!/bin/sh -x
swift build -c release
cp .build/release/Calcal-backend ./Calcal-backend
