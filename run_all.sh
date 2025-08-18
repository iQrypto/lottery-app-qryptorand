#! /bin/bash

trap 'killall anvil || true' EXIT
cd ./contracts/lib/QryptoRand
just start-anvil &
sleep 1
just deploy-backend 
just "start-${1}" &
cd ../..
just deploy-lottery  
cd ../app 
npm run dev
