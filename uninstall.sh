#!/bin/bash

echo "Uninstalling pulseaudio"
cd pulseaudio
sudo make uninstall
cd ..

echo "Uninstalling ofono"
sudo apt remove -y ofono

echo "Uninstalling bluez-5.63"
cd bluez-5.63
sudo make uninstall
cd ..

echo "Removing aasdk"
cd aasdk/build
cat install_manifest.txt | xargs echo sudo rm | sh
cd ../..

echo "Uninstalling h264bitstream"
cd h264bitstream
sudo make uninstall
cd ..

echo "Uninstalling qt-gstreamer"
cd qt-gstreamer/build
sudo make uninstall
cd ../..

echo "Removing openauto"
cd openauto/build
cat install_manifest.txt | xargs echo sudo rm | sh
cd ../..