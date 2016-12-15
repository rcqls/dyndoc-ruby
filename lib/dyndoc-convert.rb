require "dyndoc-core"
require 'dyndoc/cli/interactive-client.rb'
require 'yaml'


module Dyndoc

  @@dyndoc_tmpl_mngr=nil

  def Dyndoc.process_html_file_from_dyn_file(code,html_file,dyn_file,dyn_layout,addr,dyndoc_start)
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

  ## does not work when called twice!!!! (ex: jekyll-dyndoc in mode dyndoc)
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
  ## NOTE: Mode multipage works as follows:
  ## 1) "only:" can have a list of tags from "docs:" which is put inside opts[:doc_tag]
  ## 2) In order to process files properly for this list of tags inside opts[:doc_tag]
  ##    cfg[:tag] and dyn_tags are replace with "__ALL_DOC_TAG__" instead of opts[:doc_tag]
  ##    Since are __ALL_DOC_TAG__ is replaced by the current tag for each file to be processed, everything goes well!

  def Dyndoc.cli_convert_from_file(dyn_file,html_file,opts={}) #ex: opts={dyn_root: , html_root:, user: , doc_tag: }
    addr="127.0.0.1"

    return unless opts[:dyn_root]

    dyn_libs,dyn_tags,dyn_layout,dyn_pre_code,dyn_post_code=nil,nil,nil,nil,nil

    ## requirement: dyn_file is provided relatively to the opts[:dyn_root] (for security reason too)

    dyn_path=dyn_file.split(File::Separator)

    ## Complete info related to the related dyn file
    html_files=opts[:html_files]
    if opts[:user]
      html_urls={}
      html_files.each{|tag,html_file| html_urls[tag]=(html_file =~ /^\/users\/#{opts[:user]}(.*)/ ? $1 : html_file)}
      html_files=html_urls
    end

    cfg_files={
      fullname: dyn_file,
      basename: File.basename(dyn_file,".*"),
      long_url: html_file,
      url: File.basename(html_file,".*"),
      tag:  opts[:doc_tag],
      urls: html_files
    }

    dyn_file=File.join(opts[:dyn_root],dyn_file) unless dyn_file[0]=="/"


    if i=(dyn_file =~ /\_?(?:html)?\.dyn$/)

      cfg={}

      ## find the previous config.yml in the tree folder
      ## TODO: read all previous config.yml and merge them from root to current
      ## The merge could be also to join the content when the key is the same.
      ## Ex: semantic-ui (1st config.yml): css_message
      ##    semantic-ui (2nd config.yml): css_icon
      ##  becomes: semantic-ui: css_message, css_icon
      ## NEEDS TO DECLARE the fields that behave like this in some other config file (keys.yml)

      cfg_yml_files=dyn_path.inject([""]) {|res,e| res + [(res[-1,1]+[e]).flatten]}.map{|pa| File.join(opts[:dyn_root],pa,"config.yml")}.reverse
      cfg_yml_file=cfg_yml_files.select{|c| File.exists? c}[0]
      cfg=YAML::load_file(cfg_yml_file) if cfg_yml_file

      ## add info related to dyn file
      cfg.merge!(cfg_files)

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

      page={}

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

      cfg["layout"] = cfg["pre"] = cfg["post"] = cfg["model"] if cfg["model"]

      if cfg["layout"]
        if cfg["layout"][0] == "~" #user mode
          cfg_tmp=File.join(opts[:dyn_root],'users',cfg["layout"][1] == "/" ? File.join(opts[:user],cfg["layout"][1..-1]) : cfg["layout"][1..-1])
        else
          cfg_tmp=File.join(dyn_root,cfg["layout"][0] == "/" ? cfg["layout"][1..-1] : ["layout",cfg["layout"]])
        end
        cfg_tmp+= ".dyn" if File.extname(cfg_tmp).empty?
        ##Dyndoc.warn :layout,cfg_tmp
        dyn_layout=cfg_tmp if !dyn_layout and File.exist? cfg_tmp
      end
      if cfg["pre"]
        if cfg["pre"][0] == "~" #user mode
          cfg_tmp=File.join(opts[:dyn_root],'users',cfg["pre"][0] == "/" ? cfg["pre"][1..-1] : ["pre",cfg["pre"]])
        else
          #cfg_tmp=File.join(dyn_root,cfg["pre"])
          cfg_tmp=File.join(dyn_root,cfg["pre"][0] == "/" ? cfg["pre"][1..-1] : ["preload",cfg["pre"]])
        end
        cfg_tmp+= ".dyn" if File.extname(cfg_tmp).empty?
        dyn_pre_code=File.read(cfg_tmp) if !dyn_pre_code and File.exist? cfg_tmp
      end

      if cfg["post"]
        if cfg["post"][0] == "~" #user mode
          cfg_tmp=File.join(opts[:dyn_root],'users',cfg["post"][0] == "/" ? cfg["post"][1..-1] : ["post",cfg["post"]])
        else
          #cfg_tmp=File.join(dyn_root,cfg["post"])
          cfg_tmp=File.join(dyn_root,cfg["post"][0] == "/" ? cfg["post"][1..-1] : ["postload",cfg["post"]])
        end
        cfg_tmp+= ".dyn" if File.extname(cfg_tmp).empty?
        dyn_post_code=File.read(cfg_tmp) if !dyn_post_code and File.exist? cfg_tmp
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
      ## since opts[:doc_tag] can have more than one tag it is replaced with __ALL_DOC_TAG__ that is replaced before processing with the proper tag
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
      ##
      Dyndoc.warn :cfg,cfg
      ##Dyndoc.warn :page,page
      code = "[#rb<]require 'ostruct';cfg = OpenStruct.new(" + cfg.inspect + ");page = OpenStruct.new(" + page.inspect + ")[#>]" +code
      code = dyn_tags + code if dyn_tags

      ## add path for user
      code_path = "[#path]"+File.join(opts[:dyn_root],'users',opts[:user],"dynlib")
      code_path << "\n" << File.join(opts[:dyn_root],'users',opts[:user])
      code_path << "\n" << File.join(opts[:dyn_root],'dynlib')
      code_path << "\n" << opts[:dyn_root] << "\n"
      code_path << "[#main][#<]\n"
      code = code_path + code

      ### Dyndoc.warn :code,code

      dyndoc_start=[:dyndoc_libs,:dyndoc_layout]

      unless opts[:doc_tag] == "__ALL_DOC_TAG__"
        Dyndoc.process_html_file_from_dyn_file(code,html_file,dyn_file,dyn_layout,addr,dyndoc_start)
      else
        (opts[:current_tags] || html_files.keys[1..-1]).each do |doc_tag|
          html_file=File.join(html_root,["users",opts[:user]] || [],cfg_files[:urls][doc_tag])
          p [:html_multi,doc_tag,html_file] #,code.gsub(/__ALL_DOC_TAG__/,doc_tag)]
          Dyndoc.process_html_file_from_dyn_file(code.gsub(/__ALL_DOC_TAG__/,doc_tag),html_file,dyn_file,dyn_layout,addr,dyndoc_start)
        end
      end
    end
  end


  ## Very similar to Dyndoc.process_html_file_from_dyn_file
  def Dyndoc.auto_dyn_file(code,output_file,dyn_file,dyn_layout,addr,dyndoc_start)
    cli=Dyndoc::InteractiveClient.new(code,dyn_file,addr,dyndoc_start)

    if dyn_layout
      cli=Dyndoc::InteractiveClient.new(File.read(dyn_layout),"",addr) #File.expand_path(dyn_layout),addr)
    end

    if output_file and Dir.exist? File.dirname(output_file)
      File.open(output_file,"w") do |f|
        f << cli.content
      end
    else
      puts cli.content
    end
  end

  ###################################
  ## Dyndoc.auto_convert_from_file ##
  ###########################################################################
  ## Very similar to Dyndoc.cli_convert_from_file which is (badly) devoted to html file!
  ## This version tries to autoconvert a dyn_file of the form *_<format>.dyn to *.<format>
  ## Multi-documents is not considered here! The goal is to provide autoconversion for simple file (even though we can use template)
  ## :format_output => "html" is not a pb since it is mostly used for verbatim output and it is not the focus here!

  def Dyndoc.auto_convert_from_file(dyn_file,opts={}) #ex: opts={dyn_root: , doc_tag: } #opts=obtained by commandline
    ## opts[:dyn_root] ||= ENV["HOME"]

    dyn_libs,dyn_tags,dyn_layout,dyn_pre_code,dyn_post_code=nil,nil,nil,nil,nil

    dyn_path=dyn_file.split(File::Separator)


    if i=(dyn_file =~ /\_([a-z,A-Z,0-9]*)\.dyn$/)
      dyn_extname = $1
      dyn_dirname = File.dirname(dyn_file[0...i])
      dyn_basename = dyn_file[0...i]

      cfg_files={
        fullname: dyn_file,
        basename: File.basename(dyn_file,".*"),
        tag:  opts[:doc_tag],
        dyn_extname: dyn_extname,
        dyn_dirname: dyn_dirname,
        dyn_basename: dyn_basename,
        output_basename: dyn_basename+"."+dyn_extname
      }

      cfg={}

      ## find the previous config.yml in the tree folder
      ## TODO: read all previous config.yml and merge them from root to current
      ## The merge could be also to join the content when the key is the same.
      ## Ex: semantic-ui (1st config.yml): css_message
      ##    semantic-ui (2nd config.yml): css_icon
      ##  becomes: semantic-ui: css_message, css_icon
      ## NEEDS TO DECLARE the fields that behave like this in some other config file (keys.yml)

      cfg_yml_files=dyn_path.inject([""]) {|res,e| res + [(res[-1,1]+[e]).flatten]}.map{|pa| File.join("",pa,"config.yml")}.reverse
      cfg_yml_file=cfg_yml_files.select{|c| File.exists? c}[0]
      cfg=YAML::load_file(cfg_yml_file) if cfg_yml_file

      ## add info related to dyn file
      cfg.merge!(cfg_files)

      ## Dyn layout
      dyn_layout=dyn_file[0...i]+"_#{dyn_extname}-layout.dyn" if File.exist? dyn_file[0...i]+"_#{dyn_extname}-layout.dyn"

      ## Dyn pre
      dyn_pre_code=File.read(dyn_file[0...i]+"_#{dyn_extname}-pre.dyn") if File.exist? dyn_file[0...i]+"_#{dyn_extname}-pre.dyn"

      ## Dyn post
      dyn_post_code=File.read(dyn_file[0...i]+"_#{dyn_extname}-post.dyn") if File.exist? dyn_file[0...i]+"_#{dyn_extname}-post.dyn"


      if File.exist? dyn_file[0...i]+"_#{dyn_extname}.dyn_cfg" and (yml=YAML::load_file(dyn_file[0...i]+"_#{dyn_extname}.dyn_cfg"))
        cfg.merge!(yml)
      else # try do find (in the Zope spirit) a config file in the nearest folder
      end

      ## code to evaluate
      code=File.read(dyn_file)

      page={}

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
      # defines the root of relative predefined dyn (pre, post, ...) files
      dyn_root= cfg["dyn_root"] || opts[:dyn_root] || File.expand_path("..",dyn_file)

      cfg["layout"] = cfg["pre"] = cfg["post"] = cfg["model"] if cfg["model"]

      if cfg["layout"]
        if cfg["layout"][0] == "/"
          cfg_tmp=cfg["layout"]
        else
          cfg_tmp=File.join(dyn_root, cfg["layout"])
        end
        cfg_tmp+= ".dyn" if File.extname(cfg_tmp).empty?
        ##Dyndoc.warn :layout,cfg_tmp
        dyn_layout=cfg_tmp if !dyn_layout and File.exist? cfg_tmp
      end
      if cfg["pre"]
        if cfg["pre"][0] == "/"
          cfg_tmp=cfg["pre"]
        else
          cfg_tmp=File.join(dyn_root,cfg["pre"])
        end
        cfg_tmp+= ".dyn" if File.extname(cfg_tmp).empty?
        dyn_pre_code=File.read(cfg_tmp) if !dyn_pre_code and File.exist? cfg_tmp
      end

      if cfg["post"]
        if cfg["post"][0] == "/"
          cfg_tmp=cfg["post"]
        else
          cfg_tmp=File.join(dyn_root,cfg["post"])
        end
        cfg_tmp+= ".dyn" if File.extname(cfg_tmp).empty?
        dyn_post_code=File.read(cfg_tmp) if !dyn_post_code and File.exist? cfg_tmp
      end


      ## deal with html_file
      output_file=File.join(opts[:where] || cfg["dyn_dirname"],cfg["output_basename"])
      unless File.exist? output_file
        dirname=File.dirname(output_file)
        require 'fileutils'
        FileUtils.mkdir_p dirname
      end

      dyn_libs=cfg["libs"].strip if cfg["libs"]

      ## mode multi-documents
      docs_tags=[]
      ## since opts[:doc_tag] can have more than one tag it is replaced with __ALL_DOC_TAG__ that is replaced before processing with the proper tag
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
      ##
      Dyndoc.warn :cfg,cfg
      ##Dyndoc.warn :page,page
      code = "[#rb<]require 'ostruct';cfg = OpenStruct.new(" + cfg.inspect + ");page = OpenStruct.new(" + page.inspect + ")[#>]" +code
      code = dyn_tags + code if dyn_tags

      ## add path for user
      code_path = "[#path]"
      code_path << "\n" << File.join(dyn_root,'dynlib')
      code_path << "\n" << opts[:dynlib_root] << "\n" if opts[:dynlib_root]
      code_path << "\n" << cfg[:dynlib_root] << "\n" if cfg[:dynlib_root]
      code_path << "[#main][#<]\n"
      code = code_path + code

      ### Dyndoc.warn :code,code

      dyndoc_start=[:dyndoc_libs,:dyndoc_layout]

      ##unless cfg[:doc_tags]
        Dyndoc.auto_dyn_file(code,output_file,dyn_file,dyn_layout,addr,dyndoc_start)
      # else
      #   (cfg[:doc_tags]).each do |doc_tag|
      #     output_file = cfg[:outputs][doc_tag] ? (cfg[:outputs][doc_tag][0] == "/" ? cfg[:outputs][doc_tag] :  File.join() ) : File.join(opts[:where] || cfg["dyn_dirname"],cfg["output_basename"])
      #     p [:html_multi,doc_tag,html_file] #,code.gsub(/__ALL_DOC_TAG__/,doc_tag)]
      #     Dyndoc.auto_dyn_file(code,html_file,dyn_file,dyn_layout,addr,dyndoc_start)
      #   end
      # end
    end
  end


end
