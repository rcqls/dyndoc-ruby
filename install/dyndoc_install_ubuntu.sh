#!/bin/bash


prevdir=$(pwd)

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

cd $prevdir

echo "check git in PATH"
if [ "$(which git)" = "" ]; then
	echo "Installing git ... "
	# git install
	sudo apt-get install -y git
fi

echo "check R or ruby to install"
if [ "$(which R)$(which ruby)" = "" ]; then
	echo "Installing software-properties-common ..."
	sudo apt-get install -y software-properties-common
fi

echo "check R in PATH"
if [ "$(which R)" = "" ]; then
	echo "Installing R ..."
	# R install
	sudo add-apt-repository -y ppa:marutter/rrutter
	sudo apt-get update -y
	sudo apt-get install -y r-base r-base-dev
fi

echo "check ruby in PATH"
if [ "$(which ruby)" = "" ]; then
	echo "Installing ruby ..."
	# ruby install
	sudo apt-add-repository -y ppa:brightbox/ruby-ng
	sudo apt-get update -y
	sudo apt-get install -y ruby2.2 ruby2.2-dev ruby-switch
fi

echo "check pandoc in PATH"
if [ "$(which pandoc)" = "" ]; then
	echo "pandoc is not installed or in the PATH!"
	url_latest=$(ruby -ropen-uri -e 'print /(jgm\/pandoc\/releases.*deb)/.match(open("https://github.com/jgm/pandoc/releases").read)[1]')
 	wget https://github.com/${url_latest}
	sudo dpkg -i pandoc*.deb
	rm pandoc*.deb
fi

echo "check if ~/.gemrc exists ..."
if ![ -e "$HOME/.gemrc" ]; then
	echo "~/.gemrc config ..."
	echo "gem: --user-install --no-ri --no-rdoc" >> ~/.gemrc
	echo "" >> ~/.bash_profile
	echo "if which ruby >/dev/null && which gem >/dev/null; then" >> ~/.bash_profile
  echo "PATH=\"$(ruby -rubygems -e 'puts Gem.user_dir')/bin:$PATH\"" >> ~/.bash_profile
	echo "fi" >> ~/.bash_profile
fi

echo "Installing dyndoc (ruby part) and its dependencies ..."
gem install dyndoc-ruby
gem install dyntask-ruby

echo "Installing dyndoc (R part) and its dependencies ..."
# devtools dependencies
sudo apt-get install -y libxml2-dev  libcurl4-openssl-dev libssl-dev
sudo R -e 'install.packages("devtools",repos="http://cran.rstudio.com/")'
# R package rb4R
sudo R -e 'devtools::install_github("rcqls/rb4R",args="--no-multiarch")'
# R package base64
sudo R -e 'install.packages("base64",repos="http://cran.rstudio.com/")'

echo "dyndoc init"
. ~/.bash_profile
dyn-init
dyntask-init

read -p "Do you want to install dyn-srv.conf and dyntask.conf upstart [Y/N]" -n 1 -r
echo
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
	for cmd in "dyn-srv" "dyntask-server"
	do
		conf = "/etc/init/${cmd}.conf"
		sudo echo "author \"rcqls\"" > ${conf}
		sudo echo "description \"start and stop dyn-srv for Ubuntu (upstart)\"" >> ${conf}
		sudo echo "version \"0.1\"" >> ${conf}
		sudo echo "" >> ${conf}
		sudo echo "start on started networking" >> ${conf}
		sudo echo "stop on runlevel [!2345]" >> ${conf}
		sudo echo "" >> ${conf}
		sudo echo "env APPUSER=\"${USER}\"" >> ${conf}
		sudo echo "env APPDIR=\"/home/${USER}/.gem/ruby/2.2.0/bin\"" >> ${conf}
		sudo echo "env APPBIN=\"${cmd}\"" >> ${conf}
		sudo echo "" >> ${conf}
		sudo echo "respawn" >> ${conf}
		sudo echo "" >> ${conf}
		sudo echo "script" >> ${conf}
		sudo echo "  exec su - $APPUSER -c \"$APPDIR/$APPBIN\"" >> ${conf}
		sudo echo "end script" >> ${conf}
	done
fi

echo "check pdflatex in PATH"
if [ "$(which pdflatex)" = "" ]; then
	echo "Installing pdflatex! Be patient, this is a long step but the last ..."
 	sudo apt-get install -y texlive-full
fi

cd ${prevdir}
