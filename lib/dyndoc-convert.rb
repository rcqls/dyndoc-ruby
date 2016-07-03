require "dyndoc-core"
require 'dyndoc/cli/interactive-client.rb'


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

  def Dyndoc.cli_convert_from_file(dyn_file,dyn_out_file)
    addr="127.0.0.1"

    dyn_libs,dyn_tags=nil,nil

    if i=(dyn_file =~ /\_?(?:html)?\.dyn$/)

      ## Dyn layout
      dyn_layout=dyn_file[0...i]+"_layout.dyn" if File.exist? dyn_file[0...i]+"_layout.dyn"

      ## Dyn pre
      dyn_pre_code=File.read(dyn_file[0...i]+"_pre.dyn") if File.exist? dyn_file[0...i]+"_pre.dyn"

      ## Dyn post
      dyn_post_code=File.read(dyn_file[0...i]+"_post.dyn") if File.exist? dyn_file[0...i]+"_post.dyn"

      if File.exist? dyn_file[0...i]+".dyn_cfg"
        require 'yaml'
        cfg=YAML::load_file(dyn_file[0...i]+".dyn_cfg")

        dyn_root= cfg["root"] || File.expand_path("..",dyn_file)

        if cfg["layout"]
          cfg_tmp=File.join(dyn_root,cfg["layout"])
          dyn_layout=File.read(cfg_tmp) if !dyn_layout and File.exist? cfg_tmp
        end
        if cfg["pre"]
          cfg_tmp=File.join(dyn_root,cfg["pre"])
          dyn_pre_code=File.read(cfg_tmp) unless dyn_pre_code and File.exist? cfg_tmp
        end

        if cfg["post"]
          cfg_tmp=File.join(dyn_root,cfg["post"])
          dyn_post_code=File.read(cfg_tmp) unless dyn_post_code and File.exist? cfg_tmp
        end

        dyn_libs=cfg["libs"].strip if cfg["libs"]

        dyn_tags="[#<]{#opt]"+cfg["tags"].strip+"[#opt}" if cfg["tags"]
      end

    end


    ## code to evaluate
    code=File.read(dyn_file)
  	if dyn_libs or dyn_pre_code
  		code_pre = ""
  		code_pre += dyn_pre_code + "\n" if dyn_pre_code
  		code_pre += '[#require]'+"\n"+dyn_libs if dyn_libs
  		code = code_pre + '[#main][#>]' + code
  	end
  	code += "\n" + dyn_post_code if dyn_post_code
  	code = dyn_tags + code if dyn_tags
  	dyndoc_start=[:dyndoc_libs,:dyndoc_layout]

    cli=Dyndoc::InteractiveClient.new(code,dyn_file,addr,dyndoc_start)

  	if dyn_layout
  	 	cli=Dyndoc::InteractiveClient.new(File.read(dyn_layout),"",addr) #File.expand_path(dyn_layout),addr)
  	end

  	if dyn_out_file and Dir.exist? File.dirname(dyn_out_file)
  		File.open(dyn_out_file,"w") do |f|
  			f << cli.content
  		end
  	else
  		puts cli.content
  	end
  end

end