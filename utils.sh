#!/usr/bin/env bash

function log {
  local cyan="\033[0;36m"
  local nocolor="\033[0m"
  echo -e "${cyan}$(tput bold)=> ${nocolor}$(tput bold)$*$(tput sgr0)"
}
