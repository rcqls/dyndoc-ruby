require 'socket'                # Get sockets from stdlib
require "dyndoc-core"
require 'dyndoc-converter'


module Dyndoc

  class InteractiveServer

    def initialize
      @tmpl_mngr=nil
      @tmpl_filename=nil
      init_dyndoc
      init_server
    end

    def init_dyndoc
      unless @tmpl_mngr
        Dyndoc.cfg_dyn['dyndoc_session']=:interactive
        @tmpl_mngr = Dyndoc::Ruby::TemplateManager.new({})
        ##is it really well-suited for interactive mode???
      end
      reinit_dyndoc
    end

    def reinit_dyndoc
      if @tmpl_mngr
        @tmpl_mngr.init_doc({:format_output=> "html"})
        @tmpl_mngr.require_dyndoc_libs("DyndocWebTools")
        puts "InteractiveServer (re)initialized!\n"
        @tmpl_mngr.as_default_tmpl_mngr! #=> Dyndoc.tmpl_mngr activated!
      end
    end

    def post_process_from_format(content,fmt)
      case fmt
      when :rmd
        ::Dyndoc::Converter.markdown(content)
      when :adoc
        ::Dyndoc::Converter.asciidoctor(content)
      when :ttm
        ::Dyndoc::Converter.ttm(content,"-e2 -r -y1 -L").gsub(/<mtable[^>]*>/,"<mtable>").gsub("\\ngtr","<mtext>&ngtr;</mtext>").gsub("\\nless","<mtext>&nless;</mtext>").gsub("&#232;","<mtext>&egrave;</mtext>")
      end
    end


    def process_dyndoc(content)
      ##Dyndoc.warn :process_dyndoc_content,content
      @content=@tmpl_mngr.parse(content)
      ##Dyndoc.warn :content, @content
      ## depending on extension
      if @tmpl_filename =~ /_(rmd|adoc|ttm)\.dyn$/
        @content=post_process_from_format(@content,$1.to_sym)
      end
      @tmpl_mngr.filterGlobal.envir["body.content"]=Dyndoc::Utils.protect_dyn_block_for_atom(@content)
      ##Dyndoc.warn :body_content,@tmpl_mngr.filterGlobal.envir["body.content"]
      if @tmpl_filename
        @tmpl_mngr.filterGlobal.envir["_FILENAME_CURRENT_"]=@tmpl_filename.dup
        @tmpl_mngr.filterGlobal.envir["_FILENAME_"]=@tmpl_filename.dup #register name of template!!!
        @tmpl_mngr.filterGlobal.envir["_FILENAME_ORIG_"]=@tmpl_filename.dup #register name of template!!!
        @tmpl_mngr.filterGlobal.envir["_PWD_"]=File.dirname(@tmpl_filename)
      end
      return Dyndoc::Utils.unprotect_dyn_block_for_atom(@content)
    end

    def init_server
      @server = TCPServer.new('0.0.0.0',7777)
    end

    def run
    	trap("SIGINT") { @server.close;exit! }
  		loop {
  			socket = @server.accept

        ## Rmk: I can't remember the whole story but I started with recv and then need read (but did not notice that the atom-plugin did not work anymore). gets() seems to be the solution.
        ## read and gets are blocking and recv is not
        b=socket.gets("__[[END_TOKEN]]__")
  			#b=socket.read
        #b=socket.recv(100000)

  			##p [:b,b]
  			data=b.to_s.strip
  			##p [:data,data]
  			if data =~ /^__send_cmd__\[\[([a-z,_]*)\|?([^\]]*)?\]\]__(.*)__\[\[END_TOKEN\]\]__$/m
          cmd,@tmpl_filename,content = $1,$2,$3
    			##p [:cmd,cmd,:content,content,:filename,@tmpl_filename]
    			#p [:tmpl_mngr,@tmpl_filename]
          unless @tmpl_filename.empty?
            Question.session_dir(File.dirname(@tmpl_filename))
          end
          if content.strip == "__EXIT__"
    				socket.close
    				@server.close
    				break
    			end

          if cmd =~ /(.*)_with_layout_reinit$/
              LayoutMngr.reinit
              cmd=$1
          end

          if cmd =~ /(.*)_with_libs_reinit$/
              reinit_dyndoc
              cmd=$1
          end

    			if cmd == "dyndoc"
    			  res = process_dyndoc(content)
    			  ##p [:dyndoc_server,content,res]
    			  socket.write "__send_cmd__[[dyndoc]]__"+res+"__[[END_TOKEN]]__"
          end
  			end
  			socket.close
  		}
    end

  end

end
