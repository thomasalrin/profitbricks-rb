# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'rspec', :spec_paths => ["spec/profitbricks"], :exclude => "./spec/live/*" do
  watch(%r{^spec/profitbricks/.+_spec\.rb$})
  watch(%r{^lib/profitbricks/(.+)\.rb$})     { |m| "spec/profitbricks/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end