
require 'rubygems/package_task'

pkg_name='dyndoc-ruby'
pkg_version='0.9.3'

pkg_files=FileList[
    'bin/*',
    'lib/**/*.rb',
    'share/**/*',
    'install/**/*'
]

spec = Gem::Specification.new do |s|
    s.platform = Gem::Platform::RUBY
    s.summary = "R and Ruby in text document"
    s.name = pkg_name
    s.version = pkg_version
    s.licenses = ['MIT', 'GPL-2']
    s.requirements << 'none'
    s.add_runtime_dependency 'R4rb','>= 1.0.0'
    s.add_runtime_dependency "dyndoc-ruby-core",">=1.0.0"
    s.add_runtime_dependency "dyndoc-ruby-doc",">=1.0.0"
    s.add_runtime_dependency "dyndoc-ruby-exec",">=0.1.0"
    #s.add_dependency("R4rb","~>1.0",">=1.0.0")
    #s.add_dependency("dyndoc-ruby-core","~>1.0",">=1.0.0")
    #s.add_dependency("dyndoc-ruby-doc","~>1.0",">=1.0.0")
    #s.add_dependency("dyndoc-ruby-exec","~>0.1",">=0.1.0")
    #s.add_dependency("dyntask-ruby","~>0.3",">=0.3.3")
    #if RUBY_PLATFORM =~ /darwin/
    #  s.add_dependency("dyn-ruby-launchctl","~>0.1",">=0.1.0")
    #elsif RUBY_PLATFORM =~ /mswin|mingw/i
    #  s.add_dependency("dyn-ruby-win32daemon","~>0.1",">=0.1.0")
    #end
    s.add_runtime_dependency "asciidoctor",">=1.5.3"
    s.add_runtime_dependency "redcarpet",">=3.3.4"
    s.require_path = 'lib'
    s.bindir = 'bin'
    s.executables << 'dyn' << 'dyn-cli' << 'dyn-srv' << 'dpm' << 'dyn-html' << 'dyn-html-srv' << 'dyn-init' << 'dyn-scan' << 'dyn-lint'
    s.files = pkg_files.to_a
    s.description = <<-EOF
  Provide templating in text document.
  EOF
    s.author = "CQLS"
    s.email= "rdrouilh@gmail.com"
    s.homepage = "http://cqls.upmf-grenoble.fr"
    s.rubyforge_project = nil
end
