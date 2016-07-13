source 'https://rubygems.org'

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

gem 'metadata-json-lint'
gem 'puppetlabs_spec_helper', '>= 0.1.0'
gem 'puppet-lint', '>= 1.0.0'
gem 'facter', '>= 1.7.0'
gem 'rspec-puppet'

# rspec must be v2 for ruby 1.8.7
if RUBY_VERSION >= '1.8.7' and RUBY_VERSION < '1.9'
  gem 'rspec', '~> 2.0'
  # rake >= 11 does not support ruby 1.8.7
  gem 'rake', '~> 10.0'
end

if RUBY_VERSION < '2.0'
  # json 2.x requires ruby 2.0. Lock to 1.8
  gem 'json', '~> 1.8'
end
