require 'puppetlabs_spec_helper/rake_tasks'
# This is disabled by lib/puppetlabs_spec_helper/rake_tasks.rb
# https://github.com/tphoney/puppetlabs_spec_helper/blob/master/lib/puppetlabs_spec_helper/rake_tasks.rb#L160
# but its quite usefull so we re-enable it
PuppetLint.configuration.send('enable_single_quote_string_with_variables')
private_repo = 'https://gerrit.wikimedia.org/r/labs/private'
fixture_path = File.join(__dir__, '..', 'spec', 'fixtures')
private_modules_path = File.join(fixture_path, 'private')
# This stops the fixtures dir being configured which is
# something we do manually in rake_modules/spec_helper.rb
Rake::Task[:spec_prep].clear
unless ENV['SPEC_PREP_DONE'] == 'DONE'
  task :spec_prep do
    if File.exist?(File.join(private_modules_path, '.git'))
      system('git', '-C', private_modules_path, 'pull', out: File::NULL)
    else
      system('git', 'clone', private_repo, private_modules_path, out: File::NULL)
    end
  end
end
