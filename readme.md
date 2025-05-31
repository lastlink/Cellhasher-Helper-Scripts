# Cellhasher Helper Scripts
* for windows

## Setup
* usb debug
    * turn phone on > settings > about touch build until developer mode on then settings developer and set following settings
        * enable usb (plug into computer and select always for that device)
        * disable auto updates
        * disable adb timeout
        * disable any usb app verifications
* for phone breakdown watch a video on specific devices
    * basically open case > remove battery cable cover and detach > remove battery (if you forgot to detach cable you could tear it) > unwrap battery adapter tape and cut with razer > solder cables white stripped cable is b+
* connect with cellhasher then run optimization script to reboot, run debloater to remove specific apks or create a custom app deletion
* if using ethernet model you can run gnirehtet to have internet access while in direct usb mode (ethernet mode turns off usb)
* apps recommened to download
    * verus miner
    * xmrig monero
    * Package Name Viewer
    * App Inspector
    * gnirehtet - reverse adb internet
    * termux-app
* recommded to set battery to a fixed 
* brightness
    * if screen too bright you can go to settings and decrease brightness, sometimes adb doesn't do anything. 0 is not recommended, but you can go as low as you can.

## Scripts
* print_devices_information - gets specific device information and saves to .csv file. You can update usb # with correct # to make troubleshooting easier
* enable_adb_wireless - in usb adb turn on adb wireless for all devices, resets on device reboot
* scan_adb_debug_port - scan ports to connect to devices that have adb wireless mode enabled and have network access
* install_bulk_apk - bulk install apks in a specific folder