require "socket"

module Dyndoc

	class InteractiveClient

		attr_reader :content

		@@end_token="__[[END_TOKEN]]__"

		## reinit is an array
		def initialize(cmd,tmpl_filename,addr="127.0.0.1",reinit=[],port=7777)

			@addr,@port,@cmd,@tmpl_filename=addr,port,cmd,tmpl_filename
			##p [:tmpl_filename,@tmpl_filename,@cmd]
			## The layout needs to be reintailized for new dyndoc file but not for the layout (of course)!
			dyndoc_cmd="dyndoc"
			dyndoc_cmd += "_with_tag_tmpl" if reinit.include? :dyndoc_tag_tmpl
			dyndoc_cmd += "_with_libs_reinit" if reinit.include? :dyndoc_libs
			dyndoc_cmd += "_with_layout_reinit" if reinit.include? :dyndoc_layout

#p [:addr,@addr]
			Socket.tcp(@addr, @port) {|sock|
					msg='__send_cmd__[['+dyndoc_cmd+'|'+@tmpl_filename+']]__' + @cmd + @@end_token
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

		# def listen
		# 	##@response = Thread.new do
		# 	result=""
		# 	@content=nil
		# 	msg=""
		# 	loop {
		# 		msg=@server.recv(1024)
		# 		##p msg
		# 		if msg
		# 			msg.chomp!
		# 			##puts "#{msg}"
		# 			data=msg.split(@@end_token,-1)
		# 			##p data
		# 			last=data.pop
		# 			result += data.join("")
		# 			#p "last:<<"+last+">>"
		# 			if last == ""
		# 				#console.log("<<"+result+">>")
		# 				resCmd = decode_cmd(result)
		# 				##p resCmd
		# 				if resCmd[:cmd] != "windows_platform"
		# 					#console.log("data: "+resCmd["content"])
		# 					@content=resCmd[:content]
		# 					@server.close
		# 					break
		# 				end
		# 			else
		# 				result += last if last
		# 			end
		# 		end
		# 	}
		# 	#end
		# end
	end
end
