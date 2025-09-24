source "http://www.rubygems.org"

gemspec

group :development, :test do
  gem 'method_source' # for bin/test
#  gem 'pg', '~>1.5.0' # 1.6 requires GLIBC 2.29 which CentOS 8 Stream doesn't have
  gem 'rake'
  gem 'simplecov',  :require => false
  gem 'sqlite3', '~> 2.4.0' # 2.5+ requires GLIBC 2.29 which CentOS 8 Stream doesn't have
  gem 'test-unit'
end

group :vscode do
  gem 'debase',           :require => false
  gem 'debug',            :require => false
  gem 'rainbow',          :require => false
  gem 'rdbg',             :require => false
  gem 'ruby-debug-ide',   :require => false
  gem 'ruby-lsp',         :require => false
  gem 'solargraph',       :require => false
end
