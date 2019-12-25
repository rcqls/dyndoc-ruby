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
		cfg = YAML::load_file(secret) if DyndocWorld.root and File.exists? secret
		return cfg
	end

	## access ##
	## prj is to give access for a user or a group of users
	## if prj or prj/secret is undefined it is accessible
	def DyndocWorld.yml?(prj,yml)
		admin=(prj=="admin")
		cfg=DyndocWorld.cfg(admin)
		cfg=cfg[prj] unless admin
		return true unless cfg
		##DEBUG: p [:"yml?", cfg, yml, (cfg and yml and ((cfg["secret"] || "none") == (yml["secret"] || "none")) and yml["file"] and !(yml["file"].include? "../"))]
		return (cfg and yml and ((cfg["secret"] || "none") == (yml["secret"] || "none")) and yml["file"] and !(yml["file"].include? "../"))
	end

	## file ##
	## from yml
	## ex: public/<user>/<pathname>
	##     edit/<user>/<pathname>
	##     dynworld/<user>/<pathname>
	def DyndocWorld.prj_file(yml,content)
		success,prj_file=false,""
		parts=yml["file"].split("/")
		p [:parts,parts]
		root=parts.shift
		p [:root,root]
		if ["public","edit","dynworld"].include? root
			user=parts.shift
			case root
			when "public"
				prj_file=File.join(DyndocWorld.public_root,"users",user)
				prj_file=(Dir.exists? prj_file) ? File.join(prj_file,parts) : ""
			when "edit"
				prj_file=File.join(DyndocWorld.public_root,"users",user,".edit")
				prj_file=(Dir.exists? prj_file) ? File.join(prj_file,parts) : ""
			when "dynworld"
				prj_file=File.join(DyndocWorld.root,user,parts)
			end
		end
		p [:prj_file,prj_file]
		unless prj_file.empty? 
			FileUtils.mkdir_p File.dirname prj_file
			File.open(prj_file,"w") {|f|
				if root == "edit"
					f << yml.to_yaml
					f << "---\n"
				end
				f << content.strip
			}
			success=true
		end
		return success
	end
end