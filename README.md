# dyndoc ruby

TODO: DESCRIPTION

## Dyndoc Install

Dyndoc relies mainly in `ruby` and `R`. As a document maker, it is better to also install tools like `latex`, `pandoc` and optionally `asciidoctor` (but nice-to-have), `ttm`. Dyndoc depends also on `git` when installing additional `dyndoc` libraries.  

### for MacOSX user

* requirements
  * `ruby`: [Xcode](https://developer.apple.com/downloads/) provides one and [homebrew](http://brew.sh) is based on ruby.
  * Command-line tools for Xcode (to access ruby): inside Terminal, `xcode-select --install`
  (details is proposed in the [homebrew github](https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Installation.md#installation) website).
  * [homebrew](http://brew.sh) (optional but I love it as a linux user)
  * [homebrew-cask](http://caskroom.io) optional but nice-to-have if you are in love with command-line to install applications: `brew tap caskroom/cask`
  * [R](http://cran.r-project.org/bin/macosx/) or `brew cask install r`
  * [latex (MacTex)](http://www.tug.org/mactex/) or `brew cask install mactex`
  * `git`: `brew install git`
  * [pandoc](https://github.com/jgm/pandoc/releases) or `brew cask install pandoc`
  * optional but nice-to-have:
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
sudo add-apt-repository -y ppa:marutter/rrutter
sudo apt-get update -y
sudo apt-get install -y r-base r-base-dev

# ruby install
sudo apt-get install -y software-properties-common
sudo apt-add-repository -y ppa:brightbox/ruby-ng
sudo apt-get update -y
sudo apt-get install -y ruby2.2 ruby2.2-dev ruby-switch
ruby-switch --list

# git install
sudo apt-get install -y git

# ruby gems: dyndoc
sudo gem install dyndoc-ruby --no-ri --no-rdoc

# R package devtools
sudo apt-get install -y libxml2-dev  libcurl4-openssl-dev libssl-dev
R -e 'install.packages("devtools",repos="http://cran.rstudio.com/")'

# R package rb4R
sudo R -e 'devtools::install_github("rcqls/rb4R",args="--no-multiarch")'
# if something goes wrong in the previous instruction redo after: sudo apt-get install libgmp-dev

# R package base64
sudo R -e 'install.packages("base64",repos="http://cran.rstudio.com/")'
```
* pdflatex
  * `sudo apt-get install -y texlive-full`
* [pandoc](http://pandoc.org/installing.html)
* optional but nice-to-have:
  * `sudo gem install asciidoctor --no-ri --no-rdoc`
  * [Ttm](http://hutchinson.belmont.ma.us/tth/mml) from source

### for Windows user

Installation is proposed with basic installers and also with [scoop](http://scoop.sh) which allow us to install the equired tools in command-line mode.

#### Common pre-installations

* [ConEmu](https://conemu.github.io) (optional but almost required)
  Rmk: `conemu`can be installed also via `scoop` but in such case it is not in the Windows menu.
* [R](http://cran.r-project.org/bin/windows/base/),  [Rtools](https://cran.r-project.org/bin/windows/Rtools/) and  [RStudio](https://www.rstudio.com/products/rstudio/download/) (pandoc is embedded)
* add R and pandoc to the PATH.


#### Installation with [scoop](http://scoop.sh) (my preferred choice)

`scoop` requires powershell version >= 3 installed.

* open `powershell` and go the [scoop](http://scoop.sh) website to see how to install it.
* `scoop install git`
* `scoop install ruby` (ruby and devkit automatically installed)
* `scoop install latex`
* [scoop-extras](https://github.com/lukesampson/scoop-extras) (not required but allow to install Application like Atom): `scoop bucket add extras`

#### Basic with Windows installers

* ruby: [rubyinstaller](http://rubyinstaller.org) and [devkit](http://rubyinstaller.org/add-ons/devkit) (Advice: put them in the same directory `C:\tools` and follow the instructions for devkit: `ruby dk.rb init` and then `ruby dk.rb install`)
* [git](https://git-for-windows.github.io) (for Windows: useable in cmd)
* latex (with pdflatex in PATH) : [MikTex](http:/miktex.org)

#### Common post-installations

* Open `powershell` terminal (ConEmu is excellent) and then:
```{bash}
gem install dyndoc-ruby --no-ri --no-rdoc
R -e 'install.packages("devtools",repos="http://cran.rstudio.com/")'
R -e 'devtools::install_github("rcqls/rb4R",args="--no-multiarch")'
R -e 'install.packages("base64",repos="http://cran.rstudio.com/")'
```

* optional but nice-to-have:
  * `gem install asciidoctor --no-ri --no-rdoc`
  * If RStudio not installed: [pandoc](https://github.com/jgm/pandoc/releases) or `scoop install pandoc`
  * [Ttm](http://hutchinson.belmont.ma.us/tth/mml)



## Dyndoc Config

* open terminal (ConEmu for Windows user) and type: `dyn-init`
* edit `~/dyndoc/etc/dyndoc_library_path` (maybe later is better)

## Dyndoc inside Atom editor

* install it first (go to https://atom.io) (for MacOSX user, `brew cask install atom` and, for Windows user `scoop install atom`)
* install packages `(atom-)dyndoc` and `(atom-)language-dyndoc` via settings inside atom (via comamnd line: `apm install dyndoc language-dyndoc`)

## Dyndoc testing inside Atom editor

* dyndoc server: open console and type
```{bash}
dpm install rcqls/DyndocWebTools.dyn  # install DyndocWebTools.dyn (git is required)
dpm link rcqls/DyndocWebTools.dyn     # to be required in dyndoc
dyn-srv                               # launch the dyndoc server
```
* optional atom packages but nice-to-have or even almost required:
  * asciidoc-preview, language-asciidoc (made by asciidoctor team)
  * pdf-view
  * Command line: apm install asciidoc-preview language-asciidoc pdf-view
* open atom and select ~/dyndoc/demo folder, open first.dyn
* to open dyndoc viewer: `[Ctrl+Alt+x] [t]` (Windows and Linux) or `[Cmd+Alt+x] [t]` (MacOSX)
* to execute dyndoc code: `[Ctrl+Alt+d]` (Windows and Linux) or `[Cmd+Alt+x] [d]` (MacOSX)

## Dyndoc server started as a daemon

* on MacOSX, `launchctl` and `gem install lunchy`. Commercial alternative is `LaunchControl` (`brew cask install launchcontrol`)
* on Windows, `task scheduler` and `bat_to_exe converter`
* on linux, `upstart` ...
