require 'dyndoc/init/home'
require 'pathname'
require 'yaml'

module Dyndoc
  module HtmlServers

    @@cfg=nil

    def HtmlServers.cfg
      unless @@cfg
        dyndoc_home = Dyndoc.home
        cfg_yml = File.join(dyndoc_home,"etc","dyn-html.yml")
        @@cfg=(File.exist? cfg_yml) ? ::YAML::load_file(cfg_yml) : {}
        @@cfg["dyndoc_home"]=dyndoc_home
      end
      @@cfg
    end

    def HtmlServers.dyn_http_server(host=nil,port=nil)
      require 'thin'
      dyn_html_srv_ru=File.expand_path("../../share/html-srv/dyn-html-srv.ru",__FILE__)
      arg=["-R",dyn_html_srv_ru]
      if HtmlServers.cfg["html-srv-port"]
        arg += ["-p",HtmlServers.cfg["html-srv-port"].to_s]
      else
        arg += ["-p",port || "9294"]
      end
      if host
        arg += ["-a",host]
      elsif HtmlServers.cfg["html-srv-host"]
        arg += ["-a",HtmlServers.cfg["html-srv-host"].to_s]
      end
      arg << "start"
      ##p [:arg,arg]
      Thin::Runner.new(arg).run!
    end

    def HtmlServers.dyn_html_filewatcher(cfg={}) #cfg
      require 'dyndoc-convert'
      require 'dyndoc-edit'
      require 'filewatcher'
      require 'dyndoc-linter'

      $VERBOSE = nil
      options={first: true}
      ## To put inside yaml config file!
      root ||= cfg["root"] || HtmlServers.cfg["root"] || File.join(ENV["HOME"],"RCqls","RodaServer")
      dyn_root = cfg["dyn_root"] || HtmlServers.cfg["dyn_root"] || File.join(root ,"edit")
      public_root = cfg["public_root"] || HtmlServers.cfg["public_root"] || File.join(root ,"public")
      pages_root = File.join(public_root ,"pages")
      current_email = cfg["email"] || HtmlServers.cfg["email"] || "rdrouilh@gmail.com" #default email user can be overriden by -u option
      host=(cfg["html-srv-host"] || HtmlServers.cfg["html-srv-host"] || "http://localhost").to_s
      port=(cfg["html-srv-port"] || HtmlServers.cfg["html-srv-port"] || "9294").to_s
      base_url= host+":"+port

      opts = {
        dyn_root: dyn_root,
        html_root: pages_root,
        user: nil #current_email
      }

      puts "watching "+ dyn_root
      old_html_file=""
      ::FileWatcher.new(dyn_root).watch() do |filename, event|
        ##p [:filename,filename]
        if [:changed,:new].include? event and File.extname(filename) == ".dyn"
          ##p [:filename_event,event,filename]
          if (lint_error=Dyndoc::Linter.check_file(filename)).empty?
            ## do not process preload, postload, lib and layout files
            unless filename =~ /(?:_pre|_post|_lib|_layout)\.dyn$/
              ## find dyn_file (relative path from root)
              dyn_file="/"+Pathname(filename).relative_path_from(Pathname(dyn_root)).to_s
              opts_doc=Dyndoc::FileWatcher.get_dyn_html_info(filename,dyn_file,opts[:user])
              opts.merge! opts_doc
              ##p [:html_files,html_files]

              html_file=opts[:html_files][opts[:current_doc_tag]] # No more default # || html_files[""]
              ##p [:opts,opts,:current_doc_tag,opts[:current_doc_tag]]
              Dyndoc.cli_convert_from_file(dyn_file[1..-1],html_file, opts)
              ## fix html_file for _rmd, _adoc and _ttm
              if html_file =~ /^(.*)_(rmd|adoc|ttm)\.html$/
                html_file = $1+".html"
              end
              puts dyn_file[1..-1]+" processed => "+html_file+" created!"
              if RUBY_PLATFORM =~ /darwin/
                options[:first] = html_file != old_html_file
                if html_file != old_html_file
                  old_html_file = html_file
                  url=File.join(base_url,html_file)
                  cmd_to_open='tell application "Safari" to set URL of current tab of front window to "'+url+'"'
                  `osascript -e '#{cmd_to_open}'`
                else
%x{osascript<<ENDREFRESH
tell app "Safari" to activate
tell application "System Events"
  keystroke "r" using {command down}
end tell
ENDREFRESH
}
                end
              end
            end
          else
            if RUBY_PLATFORM =~ /darwin/
              ##p lint_error
              cmd_to_display='display notification "' +lint_error.map{|e| e[0].to_s+") "+e[1].to_s}.join('" & "')+ '" with title "Lint Error:'+filename+'"'
              p [:cmd_display,cmd_to_display]
              `osascript -e '#{cmd_to_display}'`
            else
              puts "Lint Error: "+filename+" with "+lint_error.inspect
            end
          end
        end
      end

    end

  end
end
