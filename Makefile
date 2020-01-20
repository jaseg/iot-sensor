ESPTOOL = esptool.py
# TOOL can be 'mpfshell' or 'ampy'
TOOL = mpfshell
FIRMWARE = esp32-idf3-20191220-v1.12.bin
PORT = /dev/serial/by-id/usb-Silicon_Labs_CP2102_USB_to_UART_Bridge_Controller_0001-if00-port0
SHELL = /bin/sh
MPY := $(patsubst %.py,%.mpy,$(wildcard *.py))


.PHONY: erase flash all install clean repl help sanitize

all: $(MPY)

%.mpy: %.py  ## Compile all python files
	mpy-cross -march=xtensa -o $@ $<

install: $(MPY)  ## Copy all compiled python files to the ESP32
	if [ "${TOOL}" = "mpfshell" ]; then ${TOOL} -n -c "open ${PORT:/dev/%=%}; mput ${MPY}"; fi
	if [ "${TOOL}" = "ampy" ]; then ${TOOL} -p ${PORT} put *.mpy; fi

sanitize: main.py.example

%.py.example: %.py
	sed -n '/#### CONFIG ####/,/#### END ####/{/^#/p;d};p' $< > $@

clean:  ## Delete all compiled python files
	rm -f *.mpy

erase:  ## Erase the flash of the ESP32
	${ESPTOOL} --chip esp32 --port ${PORT} erase_flash

flash:  ## Download micropython firmware and flash to ESP32
	curl -sSLO https://micropython.org/resources/firmware/${FIRMWARE}
	${ESPTOOL} --chip esp32 --port ${PORT} --baud 460800 write_flash -z 0x1000 ${FIRMWARE}

repl: ## Start repl shell
	if [ "${TOOL}" = "mpfshell" ]; then ${TOOL} -n -o ${BOARD} -c repl; fi
	if [ "${TOOL}" != "mpfshell" ]; then screen /dev/${BOARD} ; fi

help:  ## Show this help
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
