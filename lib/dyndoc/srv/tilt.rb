require 'tilt' #this allows the use of any other template
require 'tilt/template' #for creating the dyndoc one
require 'redcloth'

## This version relies on dyn-srv!


module Tilt

  class DynCliTemplate < Template

    attr_reader :content

		@@end_token="__[[END_TOKEN]]__"

    def DynCliTemplate.init(libs=nil)
    end


		## reinit is an array
		def send_dyndoc(code)

      addr,port="127.0.0.1",7777


#p [:addr,@addr]
			Socket.tcp(addr, port) {|sock|
					msg='__send_cmd__[['+@dyndoc_cmd+']]__' + code + @@end_token
					#p msg
  				sock.print msg
					#sleep 1
  				sock.close_write
  				@result=sock.read
			}

			data=@result.split(@@end_token,-1)
			last=data.pop
			resCmd=decode_cmd(data.join(""))
			##p [:resCmd,resCmd]
			if resCmd and resCmd[:cmd] != "windows_platform"
				@content=resCmd[:content]
			end
		end

		def decode_cmd(res)
		  if res =~ /^__send_cmd__\[\[([a-zA-Z0-9_]*)\]\]__([\s\S]*)/m
		  	return {cmd: $1, content: $2}
		  end
		end

    def self.engine_initialized?
      defined? ::DynDoc
    end

    def initialize_engine
    	DynCliTemplate.init
    end

    def prepare; end


    def prepare_output
      send_dyndoc(data)
		  return @content
    end

    def evaluate(scope, locals, &block)
      if locals.keys.include? :reinit and locals[:reinit]
        ## The layout needs to be reintailized for new dyndoc file but not for the layout (of course)!
        @dyndoc_cmd="dyndoc"
        @dyndoc_cmd += "_with_tag_tmpl" if locals[:reinit].include? :dyndoc_tag_tmpl
        @dyndoc_cmd += "_with_libs_reinit" if locals[:reinit].include? :dyndoc_libs
        @dyndoc_cmd += "_with_layout_reinit" if locals[:reinit].include? :dyndoc_layout
        locals.delete :reinit
      end

    	@output=prepare_output
    	#puts @output
    	#@output
    end

  end

end


Tilt.register Tilt::DynCliTemplate,   '_html.dyn'
#puts "dyn registered in tilt!"
