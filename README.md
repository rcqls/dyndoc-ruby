# dyndoc ruby

TODO: DESCRIPTION

## Requirements

* R, ruby
* Windows only:
  * Rtools, RStudio (pandoc is embedded)
  * rubyinstaller and devkit
  * ConEmu (optional)
  * add pandoc, R, ruby to the environment variable PATH
* git (for Windows: useable in cmd)
* R packages: devtools, base64
* ruby gems: asciidoctor (optional)

## Install

* `gem install dyndoc-ruby`

## Config

* open terminal (ConEmu)
* `dyn-init`
* edit `~/dyndoc/etc/dyndoc_library_path`

## Atom editor

* install it first!
* install packages `(atom-)dyndoc` and `(atom-)language-dyndoc`

## Ubuntu users

* R install (see http://sites.psu.edu/theubunturblog/installing-r-in-ubuntu/ for more details)
  * `sudo add-apt-repository ppa:marutter/rrutter`
  * `sudo apt-get update`
  * `sudo apt-get install r-base r-base-dev`
* ruby install (see https://www.brightbox.com/docs/ruby/ubuntu/ for more details)
  * `sudo apt-get install software-properties-common`
  * `sudo apt-add-repository ppa:brightbox/ruby-ng`
  * `sudo apt-get update`
  * `sudo apt-get install ruby2.2 ruby2.2-dev ruby-switch`
  * `ruby-switch --list`
