#!/usr/bin/env bash

function log_info() {
    local cyan="\033[0;36m"
    local nocolor="\033[0m"
    echo -e "${cyan}$(tput bold)[$(date)]: INFO => ${nocolor}$(tput bold)$*$(tput sgr0)"
}
