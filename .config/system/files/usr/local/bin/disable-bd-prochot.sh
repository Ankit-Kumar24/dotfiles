#!/bin/bash

modprobe msr

for cpu in /dev/cpu/[0-9]*; do
    cpu_id="${cpu##*/cpu/}"

    reg=$(rdmsr -p "$cpu_id" 0x1FC)

    # Clear bit 0 (BD PROCHOT)
    new=$(printf '%x' $((16#$reg & ~1)))

    wrmsr -p "$cpu_id" 0x1FC "0x$new"
done
