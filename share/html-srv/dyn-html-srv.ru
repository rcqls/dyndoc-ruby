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
  plugin :static, ["/pages","/private","/tools"], :root => $public_root
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
  # plugin :csrf,
  #   :skip => [
  #     "POST:/edit/dyn",
  #     "POST:/edit/save",
  #     "POST:/edit/change-all-dyn-files",
  #     "POST:/edit/add_delete_dyn_file",
  #     "POST:/edit/add_delete_user",
  #     "POST:/edit/add_user_dyn_file",
  #     "POST:/edit/delete_user_dyn_file",
  #     "POST:/edit/update_doc_tags_info"
  #   ],
  #   :skip_if => lambda{|req| req.env['CONTENT_TYPE'] =~ /application\/json/}

  # plugin :rodauth, :name=>:editor, :json=>true do
  #   db DB
  #   enable :login, :logout
  #   account_password_hash_column :ph
  #   session_key :user_id
  #   login_label 'Email'
  #   password_label 'Mot de passe'
  #   login_redirect "/editor"
  # end

  # plugin :rodauth, :name=>:compte,  :json=>true do
  #   db DB
  #   enable :change_login, :change_password, :close_account, :create_account,
  #          :lockout, :login, :logout #, :remember, :reset_password,
  #          #:verify_account,
  #          #:otp, :recovery_codes, :sms_codes,
  #          :password_complexity #,
  #          #:disallow_password_reuse, :password_expiration, :password_grace_period,
  #          #:account_expiration,
  #          #:single_session,
  #          #:jwt, :session_expiration,
  #          #:verify_account_grace_period, :verify_change_login
  #   create_account_link  do
  #    "<p><a href=\"/compte/create-account\">Créer un nouveau compte</a></p>"
  #   end
  #   login_redirect "/editor"
  #   after_login do
  #     puts session[:user_id]
  #   end
  #   logout_redirect "/editor"
  #   create_account_redirect "/compte"
  #   session_key :user_id
  #   login_label "Email"
  #   password_label "Mot de passe"
  #   login_confirm_label "Confirme Email"
  #   password_confirm_label "Confirme Mot de passe"
  #   create_account_button "Création compte"
  #   max_invalid_logins 2
  #   #allow_password_change_after 60
  #   #verify_account_grace_period 300
  #   account_password_hash_column :ph
  #   title_instance_variable :@page_title
  #   delete_account_on_close? true
  #   #only_json? false
  #   #jwt_secret secret
  #   # sms_send do |phone_number, message|
  #   #   MUTEX.synchronize{SMS[session_value] = "Would have sent the following SMS to #{phone_number}: #{message}"}
  #   # end
  # end


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

    r.on "get" do
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

    r.get do
      page=r.remaining_path
      static_root=File.join($public_root,"pages")
      ##p [:page,File.join(static_root,"**",page+".html")]
      pattern=(page=~/[^\.]*\.(?:R|Rmd|css|js|html|html|rb|red|r|jpeg|jpg|png|gif)/) ? page : page+".html"
      html_files=Dir[File.join(static_root,"**",pattern)]
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
