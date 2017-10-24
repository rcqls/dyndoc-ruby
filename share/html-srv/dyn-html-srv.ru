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

class App < Roda
  use Rack::Session::Cookie, :secret => (secret="Thanks like!")
  ##TODO: use Rack::LiveReload
  plugin :static, ["/pages","/private","/tools","/users"], :root => $public_root
  #opts[:root]=File.expand_path("..",__FILE__),
  #plugin :static, ["/pages","/private"]
  plugin :multi_route
  ###Dir[File.expand_path("../routes/*.rb",__FILE__)].each{|f| require f}
  plugin :header_matchers
  plugin :render,
    :views => File.expand_path("../views",__FILE__),
    :escape=>true,
    :check_paths=>true,
    :allowed_paths=>[File.expand_path("../views",__FILE__),$public_root]

  route do |r|

    # GET / request
    r.root do
      r.redirect "/hello"
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
      page=r.remaining_path
      static_root=File.join($public_root,"pages")
      ##p [:page,File.join(static_root,"**",page+".html")]
      pattern=(page=~/[^\.]*\.(?:R|Rmd|css|js|htm|html|rb|red|r|jpeg|jpg|png|gif|pdf)/) ? page : page+".html"
      
      html_files=Dir[File.join(static_root,"**",pattern)]
      html_files=Dir[File.join(static_root,"*","**",pattern)] if html_files.empty?

      ## try index.html in directory
      html_files=Dir[File.join(static_root,"**",page,"index.html")] if html_files.empty?
      html_files=Dir[File.join(static_root,"*","**",page,"index.html")] if html_files.empty?

      ##p html_files
      unless html_files.empty?
        html_file="pages/"+Pathname(html_files[0]).relative_path_from(Pathname(static_root)).to_s
        if File.extname(html_file) == ".html"
          html_file=File.join(File.dirname(html_file),File.basename(html_file,".html"))
          p html_file
          render html_file, :engine=>'html', :views=>$public_root
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
