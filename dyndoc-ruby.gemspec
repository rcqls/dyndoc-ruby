
require 'rubygems/package_task'

pkg_name='dyndoc-ruby'
pkg_version='0.3.3'

pkg_files=FileList[
    'bin/*',
    'share/**/*'
]

spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "R and Ruby in text document"
    s.name = pkg_name
    s.version = pkg_version
    s.licenses = ['MIT', 'GPL-2']
    s.requirements << 'none'
    s.add_dependency("R4rb",">=0.1.0")
    s.add_dependency("dyndoc-ruby-core",">=0.1.0")
    s.add_dependency("dyndoc-ruby-doc",">=0.1.0")
    s.add_dependency("dyndoc-ruby-exec",">=0.1.0")
    s.require_path = 'lib'
    s.bindir = 'bin'
    s.executables << 'dyn.rb' << 'dyn-cli.rb' << 'dyn-srv.rb' << 'dpm.rb' << 'dyn-init.rb'
    s.files = pkg_files.to_a
    s.description = <<-EOF
  Provide templating in text document.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end
