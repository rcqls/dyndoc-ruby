#!/bin/bash

for cmd in "dyn-srv" "dyntask-server"
do
  conf="${cmd}.conf"
  echo "author \"rcqls\"" > "${conf}"
  echo "description \"start and stop dyn-srv for Ubuntu (upstart)\"" >> "${conf}"
  echo "version \"0.1\"" >> "${conf}"
  echo "" >> "${conf}"
  echo "start on started networking" >> "${conf}"
  echo "stop on runlevel [!2345]" >> "${conf}"
  echo "" >> "${conf}"
  echo "env APPUSER=\"${USER}\"" >> "${conf}"
  echo "env APPDIR=\"/home/${USER}/.gem/ruby/2.2.0/bin\"" >> "${conf}"
  echo "env APPBIN=\"${cmd}\"" >> "${conf}"
  echo "" >> "${conf}"
  echo "respawn" >> "${conf}"
  echo "" >> "${conf}"
  echo "script" >> "${conf}"
  echo "  exec su - $APPUSER -c \"$APPDIR/$APPBIN\"" >> "${conf}"
  echo "end script" >> "${conf}"
  sudo mv "${conf}" /etc/init/
done
