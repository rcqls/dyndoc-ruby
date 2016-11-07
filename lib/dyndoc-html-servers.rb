require 'dyndoc/init/home'
require 'pathname'

module Dyndoc
  module HtmlServers

    @@cfg=nil

    def HtmlServers.cfg
      unless @@cfg
        dyndoc_home = Dyndoc.home
        cfg_yml = File.join(dyndoc_home,"etc","dyn-html.yml")
        @@cfg=(File.exist? cfg_yml) ? YAML::load_file(cfg_yml) : {}
        @@cfg["dyndoc_home"]=dyndoc_home
      end
      @@cfg
    end

    def HtmlServers.dyn_http_server(host=nil,port="9294")
      require 'thin'
      dyn_html_srv_ru=File.expand_path("../../share/html-srv/dyn-html-srv.ru",__FILE__)
      arg=["-R",dyn_html_srv_ru]
      if port
        arg += ["-p",port]
      elsif HtmlServers.cfg["html-srv-port"]
        arg += ["-p",HtmlServers.cfg["html-srv-port"].to_s]
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
      host=cfg["html-srv-host"] || HtmlServers.cfg["html-srv-host"] || "http://localhost"
      port=cfg["html-srv-port"] || HtmlServers.cfg["html-srv-port"] || "9292"
      base_url= host+":"+port

      opts = {
        dyn_root: dyn_root,
        html_root: pages_root,
        user: current_email
      }

      puts "watching "+ dyn_root
      old_html_file=""
      ::FileWatcher.new(dyn_root).watch() do |filename, event|
        ##p [:filename,filename]
        if [:changed,:new].include? event and File.extname(filename) == ".dyn"
          ##p [:filename_event,event,filename]
          if Dyndoc::Linter.check_file(filename).empty?
            ## find dyn_file (relative path from root)
            dyn_file="/"+Pathname(filename).relative_path_from(Pathname(dyn_root)).to_s
            opts_doc=Dyndoc::FileWatcher.get_dyn_html_info(filename,dyn_file,opts[:user])
            opts.merge! opts_doc
            ##p [:html_files,html_files]

            html_file=opts[:html_files][opts[:current_doc_tag]] # No more default # || html_files[""]
            ##p [:opts,opts,:current_doc_tag,opts[:current_doc_tag]]
            Dyndoc.cli_convert_from_file(dyn_file[1..-1],html_file, opts)
            puts dyn_file[1..-1]+" processed!"
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
          else
            puts dyn_file[1..-1]+" not well-formed!"
          end
        end
      end

    end

  end
end
