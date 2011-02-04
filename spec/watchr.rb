watch('spec/.*spec\.rb') { |md| system("bundle exec rspec --color #{md[0]}") }
watch('lib/km\.rb') { |md| system("bundle exec rake spec") }
watch('lib/km/saas\.rb') { |md| system("bundle exec rspec --color spec/km_saas_spec.rb") }
