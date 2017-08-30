## Install dyndoc services

* change user account prefixed to `conf` if necessary

* then install the services

```
sudo cp *.service /etc/systemd/system/
sudo systemctl enable dyn-srv
sudo systemctl enable dyn-html
sudo systemctl enable dyn-http
sudo systemctl start dyn-http
```