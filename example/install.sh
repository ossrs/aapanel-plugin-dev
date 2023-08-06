#!/bin/bash

install_path=/www/server/panel/plugin/example

Install() {
  echo 'Installing'; sleep 2;
  echo 'Install OK'; sleep 2;
}

Uninstall() {
 rm -rf $install_path
}

if [ "${1}" == 'install' ];then
 Install
elif [ "${1}" == 'uninstall' ];then
 Uninstall
else
 echo 'Error!'; exit 1;
fi
