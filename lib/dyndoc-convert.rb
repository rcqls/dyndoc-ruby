require "dyndoc-core"
require 'dyndoc/cli/interactive-client.rb'
require 'yaml'


module Dyndoc

  @@dyndoc_tmpl_mngr=nil

  ## does notwork when called twice!!!! (ex: jekyll-dyndoc in mode dyndoc)
  def Dyndoc.convert(input,config={})
    unless @@dyndoc_tmpl_mngr
      Dyndoc.cfg_dyn['dyndoc_session']=:interactive
      @@dyndoc_tmpl_mngr = Dyndoc::Ruby::TemplateManager.new({})
      ##is it really well-suited for interactive mode???
      @@dyndoc_tmpl_mngr.init_doc({:format_output=> "html"})
      @@dyndoc_tmpl_mngr.require_dyndoc_libs("DyndocWebTools")
      puts "InteractiveServer (re)initialized!\n"
      @@dyndoc_tmpl_mngr.as_default_tmpl_mngr! #=> Dyndoc.tmpl_mngr activated!
    end
    Dyndoc.warn :input, input
    output=@@dyndoc_tmpl_mngr.parse(input)
    ##
    Dyndoc.warn :output, output
    @@dyndoc_tmpl_mngr.filterGlobal.envir["body.content"]=output
    if config['tmpl_filename']
      @@dyndoc_tmpl_mngr.filterGlobal.envir["_FILENAME_CURRENT_"]=config['tmpl_filename'].dup
      @@dyndoc_tmpl_mngr.filterGlobal.envir["_FILENAME_"]=config['tmpl_filename'].dup #register name of template!!!
      @@dyndoc_tmpl_mngr.filterGlobal.envir["_FILENAME_ORIG_"]=config['tmpl_filename'].dup #register name of template!!!
      @@dyndoc_tmpl_mngr.filterGlobal.envir["_PWD_"]=File.dirname(config['tmpl_filename'])
    end
    return output
  end

  def Dyndoc.cli_convert(input,config={})
    addr="127.0.0.1"
    dyndoc_start=[:dyndoc_libs]
    cli=Dyndoc::InteractiveClient.new(input,"",addr,dyndoc_start)
    return cli.content
  end

  ## TODO: a config.yml file for the site
  def Dyndoc.cli_convert_from_file(dyn_file,html_file,opts={}) #ex: opts={dyn_root: , html_root:, user: , doc_tag: }
    addr="127.0.0.1"

    return unless opts[:dyn_root]

    dyn_libs,dyn_tags=nil,nil

    ## requirement: dyn_file is provided relatively to the opts[:dyn_root] (for security reason too)

    dyn_path=dyn_file.split(File::Separator)

    dyn_file=File.join(opts[:dyn_root],dyn_file) unless dyn_file[0]=="/"

    if i=(dyn_file =~ /\_?(?:html)?\.dyn$/)

      cfg={}
      ## find the previous config.yml in the tree folder
      ## TODO: read all previous config.yml and merge them from root to current
      cfg_yml_files=dyn_path.inject([""]) {|res,e| res + [(res[-1,1]+[e]).flatten]}.map{|pa| File.join(opts[:dyn_root],pa,"config.yml")}.reverse
      cfg_yml_file=cfg_yml_files.select{|c| File.exists? c}[0]
      cfg=YAML::load_file(cfg_yml_file) if cfg_yml_file

      ## Dyn layout
      dyn_layout=dyn_file[0...i]+"_layout.dyn" if File.exist? dyn_file[0...i]+"_layout.dyn"

      ## Dyn pre
      dyn_pre_code=File.read(dyn_file[0...i]+"_pre.dyn") if File.exist? dyn_file[0...i]+"_pre.dyn"

      ## Dyn post
      dyn_post_code=File.read(dyn_file[0...i]+"_post.dyn") if File.exist? dyn_file[0...i]+"_post.dyn"


      if File.exist? dyn_file[0...i]+".dyn_cfg" and (yml=YAML::load_file(dyn_file[0...i]+".dyn_cfg"))
        cfg.merge!(yml)
      else # try do find (in the Zope spirit) a config file in the nearest folder
      end

      ## code to evaluate
      code=File.read(dyn_file)

      page=nil

      if code =~ /^\-{3}/
        b=code.split(/^(\-{3,})/,-1)
        if b[0].empty? and b.length>4
          require 'yaml'
          page=YAML.load(b[2])
          cfg.merge!(page)
          code=b[4..-1].join("")
        end
      end

      # dyn_root can be overwritten by cfg
      dyn_root= cfg["dyn_root"] || opts[:dyn_root] || File.expand_path("..",dyn_file)
      html_root= cfg["html_root"] || opts[:html_root] || File.expand_path("..",dyn_file)

      if cfg["layout"]
        if cfg["layout"][0] == "%" #user mode
          cfg_tmp=File.join(opts[:dyn_root],'users',opts[:user],cfg["layout"][1..-1])
        else
          cfg_tmp=File.join(dyn_root,cfg["layout"][0] == "/" ? cfg["layout"][1..-1] : ["layout",cfg["layout"]])
        end
        dyn_layout=cfg_tmp if !dyn_layout and File.exist? cfg_tmp
      end
      if cfg["pre"]
        if cfg["pre"][0] == "%" #user mode
          cfg_tmp=File.join(opts[:dyn_root],'users',opts[:user],cfg["pre"][1..-1])
        else
          #cfg_tmp=File.join(dyn_root,cfg["pre"])
          cfg_tmp=File.join(dyn_root,cfg["pre"][0] == "/" ? cfg["pre"][1..-1] : ["preload",cfg["pre"]])
        end
        dyn_pre_code=File.read(cfg_tmp) unless dyn_pre_code and File.exist? cfg_tmp
      end

      if cfg["post"]
        if cfg["post"][0] == "%" #user mode
          cfg_tmp=File.join(opts[:dyn_root],'users',opts[:user],cfg["post"][1..-1])
        else
          #cfg_tmp=File.join(dyn_root,cfg["post"])
          cfg_tmp=File.join(dyn_root,cfg["post"][0] == "/" ? cfg["post"][1..-1] : ["postload",cfg["post"]])
        end
        dyn_post_code=File.read(cfg_tmp) unless dyn_post_code and File.exist? cfg_tmp
      end

      ## deal with html_file
      html_file=File.join(html_root,cfg["html_file"] || html_file)
      unless File.exist? html_file
        dirname=File.dirname(html_file)
        require 'fileutils'
        FileUtils.mkdir_p dirname
      end

      dyn_libs=cfg["libs"].strip if cfg["libs"]

      ## mode multi-documents
      docs_tags=[]
      docs_tags << opts[:doc_tag] if opts[:doc_tag]
      ## complete docs_tags with cfg["tags"]
      docs_tags += (cfg["tags"]||"").split(",").map{|e| e.strip}
      dyn_tags="[#<]{#opt]"+docs_tags.join(",")+"[#opt}[#>]" unless docs_tags.empty?

      ### Dyndoc.warn  :dyn_tags,[docs_tags,dyn_tags]

    	if dyn_libs or dyn_pre_code
    		code_pre = ""
    		code_pre += dyn_pre_code + "\n" if dyn_pre_code
    		code_pre += '[#require]'+"\n"+dyn_libs if dyn_libs
    		code = code_pre + '[#main][#>]' + code
    	end
    	code += "\n" + dyn_post_code if dyn_post_code
      ## TO TEST!!!
      code = "[#rb<]require 'ostruct';cfg = OpenStruct.new(" + cfg.inspect + ")[#>]" +code
      code = "[#rb<]page = " + page.inspect + "[#>]" +code if page
      code = dyn_tags + code if dyn_tags

      ## add path for user
      code_path = "[#path]"+File.join(opts[:dyn_root],'users',opts[:user],"dynlib")
      code_path << "\n" << File.join(opts[:dyn_root],'users',opts[:user])
      code_path << "\n" << opts[:dyn_root] << "\n"
      code_path << "[#main][#<]\n"
      code = code_path + code

      ### Dyndoc.warn :code,code

      dyndoc_start=[:dyndoc_libs,:dyndoc_layout]

      cli=Dyndoc::InteractiveClient.new(code,dyn_file,addr,dyndoc_start)

    	if dyn_layout
    	 	cli=Dyndoc::InteractiveClient.new(File.read(dyn_layout),"",addr) #File.expand_path(dyn_layout),addr)
    	end

    	if html_file and Dir.exist? File.dirname(html_file)
    		File.open(html_file,"w") do |f|
    			f << cli.content
    		end
    	else
    		puts cli.content
    	end
    end
  end

end
