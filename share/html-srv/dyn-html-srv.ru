require "roda"
require "pathname"
##TODO: require 'rack-livereload'
## read config file
require 'dyndoc/init/home'
dyndoc_home = Dyndoc.home
cfg_yml = File.join(dyndoc_home,"etc","dyn-html.yml")
cfg={}
cfg.merge! YAML::load_file(cfg_yml) if File.exist? cfg_yml
root = cfg["root"] || File.join(ENV["HOME"],"RCqls","RodaServer")
$public_root = cfg["public_root"] || File.join(root ,"public")
##p [:public_root,$public_root]

require 'dyndoc-world'
DyndocWorld.root(cfg["dynworld_root"] || File.join(ENV["HOME"],".dyndoc-world"))
DyndocWorld.public_root($public_root)

class App < Roda
  use Rack::Session::Cookie, :secret => (secret="Thanks like!")
  ##TODO: use Rack::LiveReload
  plugin :static, ["/pages","/private","/tools","/users"], :root => $public_root
  #opts[:root]=File.expand_path("..",__FILE__),
  #plugin :static, ["/pages","/private"]
  plugin :multi_route
  ###Dir[File.expand_path("../routes/*.rb",__FILE__)].each{|f| require f}
  plugin :header_matchers
  plugin :json
  plugin :json_parser
  plugin :render,
    :views => File.join($public_root,"views"),
    :escape=>true,
    :check_paths=>true,
    :allowed_paths=>[File.join($public_root,"views"),$public_root]
  plugin :route_csrf
  route do |r|

    # GET / request
    r.root do
      r.redirect "/hello"
    end

    r.on "dynworld" do

      r.post "file-save" do
        puts "file-save"
        prj,yml,@content=r['prj'].strip,r['yml'].strip,r['content']
        p [prj,yml,@content]
        success=false
        unless yml.empty?
          yml="---\n" + yml unless yml[0,4] == "---\n"
          yml=YAML::load(yml)
          p [:yml, yml]
          require 'fileutils'
          if DyndocWorld.yml?(prj,yml)
            success=DyndocWorld.prj_file(yml,@content)
          end
        end
        p [:success, "{success: " + success.to_s + "}"]
        "{success: " + success.to_s + "}"
      end

      r.post "file-upload" do
        uploaded_io = r[:file]
        ##
        p [:uploaded_io, uploaded_io]
        @upload_dir=r["upload_dir"]
        p [:file_upload_dir,@upload_dir]
        # FileUtils.mkdir_p File.join(@upload_dir_root,@upload_dir)
        # uploaded_io[:filename].gsub("'","_") if uploaded_io[:filename].include? "'"
        # File.open(File.join(@upload_dir_root,@upload_dir, uploaded_io[:filename]), 'wb') do |file|
        #   file.write(uploaded_io[:tempfile].read)
        # end
        "{success: true}"
      end
  
      r.post "file-delete" do
        @upload_dir=r["upload_dir"]
        p @upload_dir
        # deleted_file=File.join(@upload_dir_root,@upload_dir,r[:file_name])
        # ##p deleted_file
        # FileUtils.rm(deleted_file)
        "{success: true}"
      end

    end

    #r.multi_route

    # /hello branch
    r.on "hello" do
      # Set variable for all routes in /hello branch
      @greeting = 'Hello'

      # GET /hello/world request
      r.get "world" do
        "#{@greeting} world!"
      end

      # /hello request
      r.is do
        # GET /hello request
        r.get do
          "#{@greeting}!"
        end

        # POST /hello request
        r.post do
          puts "Someone said #{@greeting}!"
          r.redirect
        end
      end
    end

=begin
    r.on "get" do ## useless because of static above???
      rsrc=r.remaining_path
      #p [:get,rsrc]
      static_root=File.join($public_root,"tools")
      if (rsrc=~/[^\.]*\.(?:css|js|rb|red|r|R|RData|rdata|rds|csv|txt|xls|xlsx|jpeg|jpg|png|gif)/)
        rsrc_files=Dir[File.join(static_root,"**",rsrc)]
        ##p rsrc_files
        unless rsrc_files.empty?
          rsrc_file="/tools/"+Pathname(rsrc_files[0]).relative_path_from(Pathname(static_root)).to_s
          r.redirect rsrc_file
        end
      end
      "No resource #{rsrc} to serve!"
    end
=end

    r.get do
      check_csrf!
      page=r.remaining_path
      p [:captures,r.remaining_path,r.captures,r.scope,r.params]
      static_root=File.join($public_root,"pages")
  
      ## Added for erb 
      is_erb = (page[0...4] == "/erb")
      if is_erb
        page=page[4..-1] 
        @params=r.params
      end

      ## Added to protect page
      @protect = "no"
      if (page[0...8] == "/protect")
        page=page[8..-1]
        if page =~ /^\/([^\/]*)\/(.*)$/
          @protect, page = $1, '/' + $2
        end
        p [:protect, @protect, page]
      end
      
      ##p [:page,File.join(static_root,"**",page+".html")]
      
      pattern=(page=~/[^\.]*\.(?:R|Rmd|css|js|htm|html|rb|red|r|jpeg|jpg|png|gif|pdf)/) ? page : page+(is_erb ? ".erb" : ".html")
      
      html_files=Dir[File.join(static_root,"**",pattern)]
      html_files=Dir[File.join(static_root,"*","**",pattern)] if html_files.empty?

      ## try index.html in directory
      html_files=Dir[File.join(static_root,"**",page,"index.html")] if html_files.empty?
      html_files=Dir[File.join(static_root,"*","**",page,"index.html")] if html_files.empty?

      ##DEBUG:
      # a=File.join(static_root,"**",page,"index.html")
      # p [a,Dir[a]]
      # a=File.join(static_root,"*","**",page,"index.html")
      # p [a,Dir[a]]

      ##DEBUG: p html_files

      unless html_files.empty?
        html_file="pages/"+Pathname(html_files[0]).relative_path_from(Pathname(static_root)).to_s
        if [".html",".erb"].include? (html_file_ext=File.extname(html_file))
          html_file=File.join(File.dirname(html_file),File.basename(html_file,html_file_ext))
          p html_file
          if is_erb
            erb_yml=File.join($public_root,html_file+"_erb.yml")
            @cfg_erb=(File.exists? erb_yml) ? YAML::load_file(erb_yml) : {}
          end
          render html_file, :engine=> (is_erb ? "erb" : 'html'), :views=>$public_root
        else
          r.redirect html_file
        end
      else
        "no #{page} to serve!"
      end
    end

  end
end

run App.freeze.app
