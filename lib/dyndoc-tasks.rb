require 'filewatcher'
#if RUBY_VERSION >= "2.4"
class FileWatcher < Filewatcher
end
#end


module DyndocTasks

def DyndocTasks.dyn_yml(doc)

	require 'yaml'
	require 'fileutils'

	doc =~ /^(.*)_dyn\.yml$/
	docname=$1

	cfg_lines=File.readlines(doc)
	i=0
	i += 1 if cfg_lines[i][0,3] == "---"

	if cfg_lines[i][0,9] == "dyntask: "
		## regular _dyn.yml file
		cfg_yml=YAML::load(cfg_lines.join(""))
	else
		cfg_txt =  cfg_lines[0..i].join("\n")
		## deal with possible common params
		cfg_common=""
		while cfg_lines[i+1][0,2] == "  "
			i += 1
			cfg_common << cfg_lines[i]
		end
		unless cfg_common.empty?
			cfg_txt << "common:\n" << cfg_common
		end
		## deal with tasks
		cfg_lines[(i+1)..-1].each do |line|
			if line[0,2] == "  "
			cfg_txt << line
			else
			tn,td=line.split(":")
			cfg_txt << tn.strip << ": |\n"
			cfg_txt << "  " << td.strip << "\n"
			end
		end
		##DEBUG: puts cfg_txt.strip
		cfg_yml=YAML::load(cfg_txt.strip)
	end


	unless cfg_yml["dyntask"]
		#attempt to know if format is the simplified one for workflow
		ks=cfg_yml.keys
		cfg2={"dyntask" => "workflow", "params" => {"id" => ks[0], "workdir" => cfg_yml[ks[0]]}}
		tasks={}
		i=1
		if ks[1] == "common"
			i+=1
			cfg2["params"]["params"]=cfg_yml["common"] # common params for tasks
		end
		ks[i..-1].each do |t|
			kt,*pt=cfg_yml[t].strip.split("\n")
			wt,tn=kt.strip.split("->").map{|e| e.strip if e}
			if tn
			tasks[t]={"dyntask" => tn}
			wt="init" if wt.empty?
			tasks[t]["wait"]=wt
			pt=YAML::load(pt.join("\n"))  
			tasks[t]["params"]=pt
			else
				puts "Warning: task "+ t + " not considered because malformed"
			end
		end
		cfg2["params"]["tasks"]=tasks
		cfg_yml=cfg2
	end

	dyntaskname=cfg_yml["dyntask"]

	if dyntaskname
		puts dyntaskname
		##DEBUG: p [:cfg_yml,cfg_yml]
		dyntaskname += "_task.dyn" unless dyntaskname=~/_task.dyn$/
		dyntaskpath=dyntaskname
		is_dyntask=File.exists? dyntaskpath
		unless is_dyntask
			dyntaskpath=File.join(ENV["HOME"],".dyndoc-world","tasks",dyntaskname)
			is_dyntask=File.exists? dyntaskpath
		end
		unless is_dyntask
			dyntaskpath=File.join(ENV["HOME"],"dyndoc","tasks",dyntaskname)
			is_dyntask=File.exists? dyntaskpath
		end
		unless is_dyntask
			share_path=File.expand_path("../../share", __FILE__)
			dyntaskpath=File.join(share_path,"dyntasks",dyntaskname)
			is_dyntask=File.exists? dyntaskpath
		end
		if is_dyntask
			dynfile=docname+".dyn"
			FileUtils.cp dyntaskpath, dynfile
			$params=cfg_yml["params"]
			$dyntask=dyntaskname
			cfg_yml["params"].each do |key,val|
				Settings["cfg_dyn.user_input"] << [key,val]
			end

			d=Dyndoc::TemplateDocument.new(dynfile)
			d.make_all
		end
	end
end

def DyndocTasks.filewatcher(cfg={}) #cfg
	require 'dyndoc/document'

	Settings['cfg_dyn.ruby_only']=true
	Settings["cfg_dyn.model_doc"] = "Content"
	Settings["cfg_dyn.exec_mode"] = "yes"

	require 'dyndoc-linter'

	dyntasks_root=cfg["dyntasks_root"] || File.join(ENV["HOME"],".dyndoc-world","reactzone")

	puts "watching tasks inside "+ dyntasks_root
	::FileWatcher.new(dyntasks_root).watch() do |filename, event|
	  ##DEBUG: 
	  puts filename + "->" + event.to_s+"\n"
	  if [:changed,:updated,:new].include? event 
		case File.extname(filename)
		when ".yml"
			DyndocTasks.dyn_yml filename
		when ".rb"
			system("/usr/bin/env ruby "+filename)
		when ".sh"
			system("/usr/bin/env bash "+filename)
		end

	  end
	end
end
end