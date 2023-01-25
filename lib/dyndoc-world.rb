require 'yaml'

module DyndocWorld

	@@root=nil
	@@public=nil

	def DyndocWorld.root(root=nil)
		@@root=root if root
		return @@root
	end

	def DyndocWorld.public_root(public_root=nil)
		@@public=public_root if public_root
		return @@public
	end

	def DyndocWorld.cfg(admin=nil)
		cfg={}
		secret = File.join(DyndocWorld.root,admin ? ".admin.yml" : ".secret.yml")
		cfg = YAML::load_file(secret) if DyndocWorld.root and File.exist? secret
		return cfg
	end

	## access ##
	## prj is to give access for a user or a group of users
	## if prj or prj/secret is undefined it is accessible
	def DyndocWorld.prj_file?(yml)
		prj=yml["prj"] || yml["project"] || "default" 
		admin=(prj=="admin")
		cfg=DyndocWorld.cfg(admin)
		cfg=cfg[prj] unless admin
		return nil unless cfg and yml["file"]
		parts=yml["file"].split("/")
		p [:parts,parts]
		root=parts.shift
		p [:root,root]
		user=parts.shift
		##DEBUG: p [:"yml?", cfg, yml, (cfg and yml and ((cfg["secret"] || "none") == (yml["secret"] || "none")) and yml["file"] and !(yml["file"].include? "../"))]
		if (cfg and yml and ((cfg["secret"] || "none") == (yml["secret"] || "none")) and yml["file"] and !(yml["file"].include? "../")) and ((cfg["users"] || []).include? user)
			prj_file=nil
			if ["public","edit","dynworld"].include? root
				prj_subdir=cfg["subdir"] || ""
				case root
				when "public"
					prj_file=File.join(DyndocWorld.public_root,"users",user)
					prj_file=(Dir.exist? prj_file) ? File.join(prj_file,prj_subdir,parts) : ""
				when "edit"
					prj_file=File.join(DyndocWorld.public_root,"users",user,".edit")
					prj_file=(Dir.exist? prj_file) ? File.join(prj_file,prj_subdir,parts) : ""
				when "dynworld"
					prj_file=File.join(DyndocWorld.root,user,prj_subdir,parts)
				end
			end
		end
		p [:prj_file,prj_file]
		return prj_file
		
	end

	## file ##
	## from yml
	## ex: public/<user>/<pathname>
	##     edit/<user>/<pathname>
	##     dynworld/<user>/<pathname>
	def DyndocWorld.save_prj_file(prj_file,content)
		FileUtils.mkdir_p File.dirname prj_file
		File.open(prj_file,"w") {|f|
			f << content.strip
		}
	end

	def DyndocWorld.open_prj_file(prj_file)
		res={success: false}
		if File.exist? prj_file
			res[:content]=File.read(prj_file)
			res[:success]=true
		end
		return res
	end
end