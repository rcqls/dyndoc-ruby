require 'dyndoc/init/home'
require 'pathname'
require 'yaml'
require 'filewatcher'
require 'dyndoc-servers-cfg'

#if RUBY_VERSION >= "2.4"
  class FileWatcher < Filewatcher
  end
#end

module Dyndoc
  module Browser
    @@browser_cfg_file= File.join(Dyndoc.home,"etc","browser.yml")

    @@cfg=nil

    @@default_browser=(RUBY_PLATFORM =~ /darwin/ ? "safari" : (RUBY_PLATFORM =~ /linux/ ? "midori" : "firefox"))

    def Browser.set(browser)
      Browser.cfg["browser"]=browser
      Browser.save_cfg
      FileUtils.rm(@@browser_load_osa) if File.exists? @@browser_load_osa
      FileUtils.rm(@@browser_reload_osa) if File.exists? @@browser_reload_osa
      Browser.set_browser_reload
      puts "Current browser is set to "+Browser.get+"!"
    end

    def Browser.get
      Browser.cfg["browser"] || @@default_browser
    end

    def Browser.cfg
      unless @@cfg
        @@cfg=(File.exist? @@browser_cfg_file) ? ::YAML::load_file(@@browser_cfg_file) : {}
      end
      @@cfg
    end

    def Browser.save_cfg
      File.open(@@browser_cfg_file,"w") do |f|
        f << Browser.cfg.to_yaml
      end
    end

    def Browser.name
      mode=Browser.get.to_sym
      if RUBY_PLATFORM =~ /darwin/
        case mode
          when :chrome
            "Google Chrome"
          when :canary
            "Google Chrome Canary"
          when :firefox
            "Firefox"
          when :firefox_nightly
            "FirefoxNightly"
          when :firefox_developer
            "FirefoxDeveloperEdition"
          when :safari
            "Safari"
        end
      elsif RUBY_PLATFORM =~ /linux/
        mode.to_s
      end
    end

    @@browser_reload_osa= File.join(Dyndoc.home,"etc","browser_reload.osa")
    def Browser.set_browser_reload
      activate=Browser.cfg["activate"] || false
      mode=Browser.get.to_sym
      code=case mode
        when :chrome
        %Q{
        tell application "Google Chrome"
          #{activate ? 'activate' : ''}
          "chrome"
          set winref to a reference to (first window whose title does not start with "Developer Tools - ")
          set winref's index to 1
          reload active tab of winref
        end tell
        }

        when :canary
        %Q{
        tell application "Google Chrome Canary"
          #{activate ? 'activate' : ''}
          "chrome canary"
          set winref to a reference to (first window whose title does not start with "Developer Tools - ")
          set winref's index to 1
          reload active tab of winref
        end tell
        }

        when :firefox
        %Q{
        tell application "Firefox"
        	activate
        	tell application "System Events" to keystroke "r" using command down
        end tell
        }

        when :firefox_nightly
        %Q{
        set a to path to frontmost application as text
        tell application "FirefoxNightly"
        	activate
        	tell application "System Events" to keystroke "r" using command down
        end tell
        #{activate ? '' : 'delay 0.2\nactivate application a'}
        }

        when :firefox_developer
        %Q{
        set a to path to frontmost application as text
        tell application "FirefoxDeveloperEdition"
        	activate
        	tell application "System Events" to keystroke "r" using command down
        end tell
        #{activate ? '' : 'delay 0.2\nactivate application a'}
        }

        when :safari
        %Q{
        tell application "Safari"
          #{activate ? 'activate' : ''}
          tell its first document
            set its URL to (get its URL)
          end tell
        end tell
        }
      end
      File.open(@@browser_reload_osa,"w") do |f|
        f << code.strip
      end
    end

    def Browser.reload
      if RUBY_PLATFORM =~ /darwin/
        Browser.set_browser_reload unless File.exists? @@browser_reload_osa
        `osascript #{@@browser_reload_osa}`
      elsif RUBY_PLATFORM =~ /linux/ and File.exists? "/usr/bin/xdotool"
        `export DISPLAY=':0.0';/usr/bin/xdotool search --sync --onlyvisible  #{Browser.name} key F5 windowactivate`
      end
    end

    @@browser_load_osa= File.join(Dyndoc.home,"etc","browser_load.osa")
    def Browser.load(url)
      if RUBY_PLATFORM =~ /darwin/
        mode=Browser.get.to_sym
        if mode==:safari
          code='tell application "'+Browser.name+'" to set URL of current tab of front window to "'+url+'"'
        elsif mode == :firefox
          code='tell application "Firefox" to open location "'+url+'"'
        elsif mode == :chrome
          code=%Q{
            tell application "Google Chrome"
              set frontIndex to active tab index of front window
              set URL of tab frontIndex of front window to "#{url}"
            end tell
          }
        end
        File.open(@@browser_load_osa,"w") do |f|
          f << code
        end
        `osascript #{@@browser_load_osa}`
      elsif RUBY_PLATFORM =~ /linux/
        system("xdg-open #{url} &")
      end
    end
  end
end

module Dyndoc
  module HtmlServers

    ## Deal with unwatched files!

    @@unwatch=[]
    @@unwatch_yml = File.join(Dyndoc.home,"etc","unwatch.yml")

    def HtmlServers.unwatch_cfg
      if @@unwatch.empty?
        @@unwatch=(File.exist? @@unwatch_yml) ? ::YAML::load_file(@@unwatch_yml) : []
      end
      @@unwatch
    end

    def HtmlServers.unwatch_ls
      res=HtmlServers.unwatch_cfg.empty? ? "Empty folders list" : (HtmlServers.unwatch_cfg.each_with_index.map {|e,i| (i+1).to_s+") "+e}.join("\n") + "\n")
      puts res
    end

    def HtmlServers.unwatch_save
      File.open(@@unwatch_yml,"w") do |f|
        f << @@unwatch.to_yaml
      end
    end

    def HtmlServers.unwatch_add(path)
      return unless path
      HtmlServers.unwatch_cfg.unshift path
      HtmlServers.unwatch_save
    end

    def HtmlServers.unwatch_rm(path)
      return unless path
      HtmlServers.unwatch_cfg
      @@unwatch -= [path]
      HtmlServers.unwatch_save
    end

    def HtmlServers.unwatched?(file)
      return "" if HtmlServers.unwatch_cfg.empty?
      return HtmlServers.unwatch_cfg.map{|e| file[0...e.length] == e ? e : ""}[0] || ""
    end

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
      dyn_html_srv_ru=File.join(ENV["HOME"],"RodaSrv","public","users",".dyn-html","srv.ru")
      dyn_html_srv_ru="/home/ubuntu/tools/dyn-html/srv.ru" unless File.exists? dyn_html_srv_ru # DyndocDockerSite guest-tools folder
      dyn_html_srv_ru=File.join(ENV["HOME"],"dyndoc","html-srv","dyn.ru") unless File.exists? dyn_html_srv_ru
      dyn_html_srv_ru=File.expand_path("../../share/html-srv/dyn-html-srv.ru",__FILE__) unless File.exists? dyn_html_srv_ru
      
      arg=["-R",dyn_html_srv_ru]
      if HtmlServers.cfg["html-srv-port"]
        arg += ["-p",HtmlServers.cfg["html-srv-port"].to_s]
      else
        arg += ["-p",(port || DyndocServers.dyn_http_port?  || 9294).to_s]
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

    def HtmlServers.create_html_page(dyn_file,html_file,opts,pages_root)

      Dyndoc.cli_convert_from_file(dyn_file[1..-1],html_file, opts)
      ## fix html_file for _rmd, _adoc and _ttm
      if html_file =~ /^(.*)_(rmd|adoc|ttm)\.html$/
        html_file = $1+".html"
      end
      if html_file =~ /^(.*)_erb\.html$/
        erb_page=File.join(pages_root,$1)
        if File.exists? erb_page+"_erb.html"
          FileUtils.mv erb_page+"_erb.html",erb_page+".erb"
        end
        html_file = "erb"+$1
      end
    
    end

    def HtmlServers.dyn_html_filewatcher(cfg={}) #cfg
      require 'dyndoc-convert'
      require 'dyndoc-edit'
      require 'filewatcher'
      require 'dyndoc-linter'

      $VERBOSE = nil
      options={first: true}
      ## To put inside yaml config file!
      root ||= cfg["root"] || HtmlServers.cfg["root"] || File.join(ENV["HOME"],"RodaSrv")
      dyn_root = cfg["dyn_root"] || HtmlServers.cfg["dyn_root"] || File.join(root ,"edit") 
      public_root = cfg["public_root"] || HtmlServers.cfg["public_root"] || File.join(root ,"public")
      dyn_public_edit_root = File.join(public_root,"users","*",".edit","**","*.dyn")
      pages_root = File.join(public_root ,"pages")
      current_email = cfg["email"] || HtmlServers.cfg["email"] || "rdrouilh@gmail.com" #default email user can be overriden by -u option
      host=(cfg["html-srv-host"] || HtmlServers.cfg["html-srv-host"] || "http://localhost").to_s
      port=(cfg["html-srv-port"] || HtmlServers.cfg["html-srv-port"] || DyndocServers.dyn_http_port? || "9294").to_s
      base_url= host+":"+port

      opts = {
        dyn_root: dyn_root,
        html_root: pages_root,
        user: nil #current_email
      }

      puts "watching "+ dyn_public_edit_root + " and " + dyn_root
      old_html_file=""
      ::FileWatcher.new([dyn_public_edit_root,dyn_root]).watch() do |filename, event|
        ##
        p [:filename,filename,event]
        if [:changed,:updated,:new].include? event and File.extname(filename) == ".dyn"
          ##p [:filename_event,event,filename]
          if (lint_error=Dyndoc::Linter.check_file(filename)).empty?
            ## do not process preload, postload, lib and layout files
            unless filename =~ /(?:_pre|_post|_lib|_layout)\.dyn$/
              ## find dyn_file (relative path from root)
              dyn_public_edit_file=""
              dyn_file=Pathname(filename).relative_path_from(Pathname(dyn_root)).to_s
              if dyn_file[0,2] == '..' # try the public_root
                dyn_public_edit_file=Pathname(filename).relative_path_from(Pathname(public_root)).to_s
                dyn_public_edit_file=dyn_public_edit_file.split("/")
                if dyn_public_edit_file[0]=="users" and dyn_public_edit_file[2]==".edit"
                  dyn_file="/"+File.join(dyn_public_edit_file[1],dyn_public_edit_file[3..-1])
                  dyn_public_edit_file=dyn_public_edit_file.join("/")
                end
              else
                dyn_file="/"+dyn_file
              end
              
              unless HtmlServers.unwatched?(dyn_file[1..-1]).empty?
                if RUBY_PLATFORM =~ /darwin/
                  `osascript -e 'display notification "Warning: #{dyn_file} unwatched by #{HtmlServers.unwatched?(dyn_file[1..-1])}!" with title "dyn-ctl unwatch"'`
                end
              else
                opts_doc=Dyndoc::FileWatcher.get_dyn_html_info(filename,dyn_file,opts[:user])
                opts.merge! opts_doc
                ##p [:html_files,html_files]

                html_file=opts[:html_files][opts[:current_doc_tag]] # No more default # || html_files[""]
                ##p [:opts,opts,:current_doc_tag,opts[:current_doc_tag]]
                state=""
                begin
                  HtmlServers.create_html_page(dyn_file,html_file,opts,pages_root)

                  puts dyn_file[1..-1]+(dyn_public_edit_file.empty? ? "" : "*")+" processed => "+html_file+" created!"
                  options[:first] = html_file != old_html_file
                  if html_file != old_html_file
                    old_html_file = html_file
                    url=File.join(base_url,html_file)
                    ## p [:url,url]
                    Dyndoc::Browser.load(url)
                  else
                    Dyndoc::Browser.reload
                  end
                rescue => e
                  state="error: #{e.message} =>"
                ensure
                  notify_file=filename.split("/")
                  if (ind=notify_file.index ".edit")
                    notify_file=notify_file[0..ind].join("/")
                    File.open(notify_file+"/notify.out","w") do |f|
                      f << state + filename
                    end
                  end
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
