require 'yaml'
module DyndocServers
	@@cfg=nil
	@@servers_cfg_file=File.join(ENV["HOME"],".dyndoc-servers.yml")
	def DyndocServers.cfg
      unless @@cfg
        @@cfg=(File.exist? @@servers_cfg_file) ? ::YAML::load_file(@@servers_cfg_file) : {}
      end
      @@cfg
	end

	def DyndocServers.dyn_cli_port?
		DyndocServers.cfg["ports"] ? @@cfg["ports"]["dyn-cli"] : nil
	end

	def DyndocServers.dyn_srv_port?
		DyndocServers.cfg["ports"] ? @@cfg["ports"]["dyn-srv"] : nil
	end

	def DyndocServers.dyn_http_port?
		DyndocServers.cfg["ports"] ? @@cfg["ports"]["dyn-http"] : nil
	end

end