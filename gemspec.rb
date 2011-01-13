GEM_NAME = 'baker'
GEM_FILES = FileList['**/*'] - FileList['coverage', 'coverage/**/*', 'pkg', 'pkg/**/*']
GEM_SPEC = Gem::Specification.new do |s|
  # == CONFIGURE ==
  s.author = "Tung Nguyen"
  s.email = "tongueroo@gmail.com"
  s.homepage = "http://github.com/tongueroo/#{GEM_NAME}"
  s.summary = "A simple way to run chef recipes"
  # == CONFIGURE ==
  s.executables += ["bake"]
  s.extra_rdoc_files = [ "README.markdown" ]
  s.files = GEM_FILES.to_a
  s.has_rdoc = false
  s.name = GEM_NAME
  s.platform = Gem::Platform::RUBY
  s.require_path = "lib"
  s.version = "0.1.0"
end
