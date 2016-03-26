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
	echo "gem: --user-install --no-ri --no-rdoc"
fi

echo "Installing dyndoc (ruby part) and its dependencies ..."
gem install dyndoc-ruby

echo "Installing dyndoc (R part) and its dependencies ..."
# devtools dependencies
sudo apt-get install -y libxml2-dev  libcurl4-openssl-dev libssl-dev
sudo R -e 'install.packages("devtools",repos="http://cran.rstudio.com/")'

# R package rb4R
sudo R -e 'devtools::install_github("rcqls/rb4R",args="--no-multiarch")'
# if something goes wrong in the previous instruction redo after: sudo apt-get install libgmp-dev

# R package base64
sudo R -e 'install.packages("base64",repos="http://cran.rstudio.com/")'

echo "check pdflatex in PATH"
if [ "$(which pdflatex)" = "" ]; then
	echo "Installing pdflatex! Be patient, this is a long step but the last ..."
 	sudo apt-get install -y texlive-full
fi

# R package devtools

cd ${prevdir}
