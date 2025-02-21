source 'https://rubygems.org'

gem 'sync'
gem 'puppet', ENV['PUPPET_GEM_VERSION'] || '5.5.10'
gem 'xmlrpc' if RUBY_VERSION >= '2.4.0'
gem 'puppet-strings', '~> 1.0.0'
gem 'rspec-puppet', '~> 2.9.0'
gem 'rspec-puppet-facts', '~> 2.0', require: false
gem 'puppetlabs_spec_helper', '< 4.0.0'
gem 'safe_yaml', '~> 1.0.5'
gem 'parallel_tests'
# required by lvm spec_helper
gem 'puppet-blacksmith', '~> 4.1.2'
# required by puppetdbquery
gem 'chronic', '~> 0.10.2'

gem 'rake', '~> 12.0.0'
gem 'git', '1.3.0'
gem 'puppet-lint', '2.4.2'
gem 'rubocop', '~> 0.49.1', require: false
gem 'puppet-lint-wmf_styleguide-check', '1.1.0'

# last versions supporting ruby 2.3 (Stretch)
gem 'byebug', '~> 11.0.1'
gem 'pry-byebug', '~> 3.7.0'

# pry 0.13.0 is a breaking change release incompatible with pry-byebug 3.7.0
# defined above.
gem 'pry', '~> 0.12.2', :require => false

# Theses are required for running beaker acceptance test
# you can forgo installing them using `bundle install --without system_tests`
group :system_tests do
  gem 'serverspec',                         :require => false
  gem 'beaker-rspec',                       :require => false
  gem 'beaker-hostgenerator', '>= 1.1.22',  :require => false
  gem 'beaker-docker',                      :require => false
  gem 'beaker-puppet',                      :require => false
  gem 'beaker-puppet_install_helper',       :require => false
  gem 'beaker-module_install_helper',       :require => false
  gem 'rbnacl', '< 5',                      :require => false
  # better to install libsodium natively
  # gem 'rbnacl-libsodium',                   :require => false
  gem 'bcrypt_pbkdf',                       :require => false
  gem 'ed25519'
end
