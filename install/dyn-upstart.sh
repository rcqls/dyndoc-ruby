#!/bin/bash

for cmd in "dyn-srv" "dyntask-server"
do
  conf = "/etc/init/${cmd}.conf"
  sudo echo "author \"rcqls\"" > "${conf}"
  sudo echo "description \"start and stop dyn-srv for Ubuntu (upstart)\"" >> "${conf}"
  sudo echo "version \"0.1\"" >> "${conf}"
  sudo echo "" >> "${conf}"
  sudo echo "start on started networking" >> "${conf}"
  sudo echo "stop on runlevel [!2345]" >> "${conf}"
  sudo echo "" >> "${conf}"
  sudo echo "env APPUSER=\"${USER}\"" >> "${conf}"
  sudo echo "env APPDIR=\"/home/${USER}/.gem/ruby/2.2.0/bin\"" >> "${conf}"
  sudo echo "env APPBIN=\"${cmd}\"" >> "${conf}"
  sudo echo "" >> "${conf}"
  sudo echo "respawn" >> "${conf}"
  sudo echo "" >> "${conf}"
  sudo echo "script" >> "${conf}"
  sudo echo "  exec su - $APPUSER -c \"$APPDIR/$APPBIN\"" >> "${conf}"
  sudo echo "end script" >> "${conf}"
done
