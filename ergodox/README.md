# Keymap for ErgoDox
This directory includes a ErgoDox keymap for me.

## Installation
Run the shellscript, it will build the keymap and create hex file:
```
./build_keymap.sh
```

After, write the hex file to your ErgoDox with the [Teensy Loader](https://www.pjrc.com/teensy/loader.html).
If you use the command line version, please run the following command:
```
teensy_loader_cli -mmcu=atmega32u4 -w -v <path of the hex file>
```
