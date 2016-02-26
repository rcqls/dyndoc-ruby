# dyndoc ruby

TODO: DESCRIPTION

## Dyndoc Install

Dyndoc relies mainly in `ruby` and `R`. As a document maker, it is better to also install tools like `latex`, `pandoc` and optionnally `asciidoctor`, `ttm`. Dyndoc depends also on `git` when installing additional `dyndoc` libraries.  

### for MacOSX user

* requirements
  * `ruby`: xcode provides one and homebrew is based on ruby.
  * [homebrew](http://brew.sh) (optional but I love it as a linux user)
  * [R](http://cran.r-project.org/bin/macosx/)
  * [latex (MacTex)](http://www.tug.org/mactex/)
  * `git`: `brew install git`
  * [pandoc](https://github.com/jgm/pandoc/releases)
  * optionnally:
    * `gem install asciidoctor --no-ri --no-rdoc`
    * [Ttm](http://hutchinson.belmont.ma.us/tth/mml) from source
* ruby gems
  * `gem install dyndoc-ruby --no-ri --no-rdoc`
* R packages
```{bash}
brew install libxml2
R -e 'install.packages("devtools",repos="http://cran.rstudio.com/")'
R -e 'devtools::install_github("rcqls/rb4R",args="--no-multiarch")'
```

### for Ubuntu (or linux Ubuntu-based distribution) user

Note that generally linux user from other distributions knows how to adapt the following steps.

* [R](http://sites.psu.edu/theubunturblog/installing-r-in-ubuntu/),  [ruby](https://www.brightbox.com/docs/ruby/ubuntu/), git and dyndoc install
```{bash}
# R install
sudo add-apt-repository ppa:marutter/rrutter
sudo apt-get update
sudo apt-get install r-base r-base-dev

# ruby install
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:brightbox/ruby-ng
sudo apt-get update
sudo apt-get install ruby2.2 ruby2.2-dev ruby-switch
ruby-switch --list

# git install
sudo apt-get install git

# ruby gems: dyndoc
gem install dyndoc-ruby --no-ri --no-rdoc

# R package devtools
sudo apt-get install -y libxml2-dev  libcurl4-openssl-dev libssl-dev
R -e 'install.packages("devtools",repos="http://cran.rstudio.com/")'

# R package rb4R
sudo apt-get install libgmp-dev
R -e 'devtools::install_github("rcqls/rb4R",args="--no-multiarch")'

# R package base64
R -e 'install.packages("base64",repos="http://cran.rstudio.com/")'
```
* pdflatex
  * `sudo apt-get install texlive-full`
* [pandoc](http://pandoc.org/installing.html)
* optionnally:
  * `gem install asciidoctor --no-ri --no-rdoc`
  * [Ttm](http://hutchinson.belmont.ma.us/tth/mml) from source

### for Windows user

* [ConEmu](https://conemu.github.io) (optional but I love it as a non Windows user)
* [R](http://cran.r-project.org/bin/windows/base/),  [Rtools](https://cran.r-project.org/bin/windows/Rtools/) and  [RStudio](https://www.rstudio.com/products/rstudio/download/) (pandoc is embedded)
* ruby: [rubyinstaller](http://rubyinstaller.org) and [devkit](http://rubyinstaller.org/add-ons/devkit) (Advice: put them in the same directory `C:\tools` and follow the instructions for devkit: `ruby dk.rb init` and then `ruby dk.rb install`)
* [git](https://git-for-windows.github.io) (for Windows: useable in cmd)
* Add pandoc, R, ruby to the environment variable PATH
* Open `cmd` terminal (ConEmu) and then:
```{bash}
gem install dyndoc-ruby --no-ri --no-rdoc
R -e 'install.packages("devtools",repos="http://cran.rstudio.com/")'
R -e 'devtools::install_github("rcqls/rb4R",args="--no-multiarch")'
R -e 'install.packages("base64",repos="http://cran.rstudio.com/")'
```
* latex (with pdflatex in PATH) : [MikTex](http:/miktex.org)
* optionnally:
  * [Ttm](http://hutchinson.belmont.ma.us/tth/mml)
  * `gem install asciidoctor --no-ri --no-rdoc`
  * If RStudio not installed: [pandoc](https://github.com/jgm/pandoc/releases)


## Dyndoc Config

* open terminal (ConEmu for Windows user) and type: `dyn-init`
* edit `~/dyndoc/etc/dyndoc_library_path`

## Dyndoc inside Atom editor

* install it first (go to https://atom.io)
* install packages `(atom-)dyndoc` and `(atom-)language-dyndoc` via settings inside atom
