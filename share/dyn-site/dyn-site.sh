#!/bin/bash


RootSrv=$HOME/RodaSrv

if [ "$1" = "--root" ];then
    shift
    RootSrv=$1
	if [ $RootSrv = "cfg" ]; then
		RootSrv=`ruby -e 'require "yaml";puts YAML::load_file(File.join(ENV["HOME"],"dyndoc/etc/dyn-html.yml"))["root"]'`
	fi
    shift
fi

Cmd=$1

#echo "Command: $Cmd"

if [ "$Cmd" = "" ]; then
	Cmd="help"
fi


case $Cmd in
set-root)
    new-root=$2
	## Config file
	echo "---" > $HOME/dyndoc/etc/dyn-html.yml
	echo "root: $new-root" >> $HOME/dyndoc/etc/dyn-html.yml
;;
help)
	echo "Aide:"
	echo "----"
	echo "  dyn-site [--root <cfg|ROOT>] first (création de l'arborescence de base)"
	echo "  dyn-site [--root <cfg|ROOT>] init [zip|link <PATH>](installation de tools et system)"
	echo "  dyn-site [--root <cfg|ROOT>] add <User> (ajout d'un utilisateur <User>)"
	echo "  dyn-site [--root <cfg|ROOT>] rebase <Conf> (cas de workshop où <Conf>=<User>)" 
	echo "  dyn-site [--root <cfg|ROOT>] rebase-subdir <Subdir> <Prj> (Subdir=<User>/<PrjPath>)"
	echo "  dyn-site vscode [--update] (install vscode plugin for dyndoc)"
	## DANGEROUS!: echo "  dyn-site set-root <new-root>"
	;;
first)
	## Not necessary for docker
	mkdir -p $RootSrv/edit
	mkdir -p $RootSrv/public/users
	;;
init)
	installmode=$2
	case $installmode in
	zip)
		## Install Specfic stuff inside 
		mkdir -p $RootSrv/install/RodaSrvTools 
		cd ${RootSrv}/install
		if ! [ -d DynRodaSystem ]; then git clone https://toltex-gogs.dyndoc.fr/rcqls/DynRodaSystem.git; fi
		if ! [ -f RodaSrvTools.zip ]; then 
			wget https://toltex-seafile.dyndoc.fr/f/128ced4435/?raw=1 -O RodaSrvTools.zip
			cd RodaSrvTools
			unzip ../RodaSrvTools.zip
		fi
		## Create links
		cd ${RootSrv}
		ln -sf install/DynRodaSystem system
		cd public
		ln -sf ../install/RodaSrvTools tools
		;;
	link)
		rodatools_path=$2
		## Create links
		cd ${RootSrv}
		ln -sf $rodatools_path/system system
		cd public
		ln -sf $rodatools_path/tools tools
	esac
	;;
add)
	RodaWebUser=$2
	if [ "$RodaWebUser" != "" ]; then
		mkdir -p ${RootSrv}/edit/${RodaWebUser}
		mkdir -p ${RootSrv}/public/pages
		mkdir -p ${RootSrv}/public/users/${RodaWebUser}/.pages
		cd ${RootSrv}/public/pages
		ln -s ../users/${RodaWebUser}/.pages ${RodaWebUser}
	fi
	;;
rebase)
	Conf=$2
	if [ "${Conf}" = "" ]; then
		exit
	fi
	PUBLIC_ROOT="$HOME/RodaSrv/public/users/${Conf}"
	SITE_ROOT="$HOME/RodaSrv/.site/$Conf"
	PAGES_ROOT="$SITE_ROOT/pages"
	mkdir -p ${SITE_ROOT}
	cp -R  ${PUBLIC_ROOT}/* ${SITE_ROOT}/
	cd ${PAGES_ROOT}
	pages=$(ls *.html)
	echo "pages to process: $pages"
	for html in $pages
	do
		rebase_url --from /users/$Conf/ --to / $html
		rebase_url --from /$Conf/ --to / $html
		mv $html ..
	done
	cd $SITE_ROOT
	rm -fr pages
	;;
rebase-subdir)
	Subdir=$2
	if [ "${Subdir}" = "" ]; then
		echo "Subdir doit être non vide!"
		exit
	fi
	Prj=$3
	if [ "${Prj}" = "" ]; then
		echo "Prj doit être non vide!"
		exit
	fi
	PUBLIC_ASSETS="$HOME/RodaSrv/public/users/${Subdir}/${Prj}"
	PUBLIC_PAGES="$HOME/RodaSrv/public/pages/${Subdir}/${Prj}"
	SITE_ROOT="$HOME/RodaSrv/.site/$Prj"
	PAGES_ROOT="$SITE_ROOT/pages"
	if [ -d ${SITE_ROOT} ]; then
		rm -fr ${SITE_ROOT}
	fi
	mkdir -p ${PAGES_ROOT}
	cp -R ${PUBLIC_PAGES}/* ${PAGES_ROOT}/
	cp -R  ${PUBLIC_ASSETS}/* ${SITE_ROOT}/
	cd ${PAGES_ROOT}
	pages=$(find . -name  '*.html')
	echo "pages to process: $pages"
	for html in $pages
	do
		rebase_url --from /users/${Subdir}/${Prj}/ --to / $html
		rebase_url --from /${Subdir}/${Prj}/ --to / $html
	done
	cd $SITE_ROOT
	mv pages/* .
	rm -fr pages
	;;
vscode)
    if [ -d ~/.vscode/extensions ]; then
		cd ~/.vscode/extensions
		mkdir tmp
		cd tmp
		git clone https://github.com/rcqls/dyndoc-syntax
		cd ..
		if [ -d dyndoc ]; then
			if [ "$2" = "--update" ]; then
				rm -fr dyndoc
				mv tmp/dyndoc-syntax/vscode/dyndoc dyndoc
				rm -fr tmp
		  	fi
		else
			mv tmp/dyndoc-syntax/vscode/dyndoc dyndoc
			rm -fr tmp
		fi
	fi
	;;
# deploy)
# 	Conf=$2
# 	url="sfdsmqrk@ftp.sfds.asso.fr:$Conf/"
# 	if [ "$3" != "" ]; then
# 		url="$3"
# 	fi
# 	rsync -az $SITE_ROOT/* $url
# 	;;
esac