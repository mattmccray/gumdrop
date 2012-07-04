#!/usr/bin/env rake

require 'rake/testtask'
require "bundler/gem_tasks"

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['specs/*_spec.rb']
  t.verbose = false
end

desc 'clears fixture output'
task :test_clear do
  require 'fileutils'
  here= File.dirname __FILE__
  FileUtils.rm_rf File.join( here, 'specs', 'fixtures', 'output' )
end

desc "test generated output"
task :test_output do
  sh "cd specs/fixtures/source && bundle exec gumdrop build && opendiff ../output ../expected"
end