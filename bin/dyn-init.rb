#!/usr/bin/env ruby
require 'fileutils'

share_path=File.expand_path("../../share", __FILE__)
dyndoc_path=File.join(ENV["HOME"],"dyndoc")
unless File.exist? dyndoc_path
	FileUtils.mkdir_p dyndoc_path
	FileUtils.cp_r File.join(share_path,"."),dyndoc_path
end
