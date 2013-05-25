#!/usr/bin/env rake

require 'rake/testtask'
require "bundler/gem_tasks"

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['specs/*_spec.rb']
  t.verbose = false
end

task :default do
  puts `rake -T`
end

desc 'clears fixture generated output'
task :test_output_clear do
  require 'fileutils'
  here= File.dirname __FILE__
  FileUtils.rm_rf File.join( here, 'specs', 'fixtures', 'output' )
end

desc "generates fixture site then tests output against expected fixture data"
task :test_output => :test_output_clear do
  sh "cd specs/fixtures/source && bundle exec gumdrop build -q -f"
  diff_results= `diff -w -r -y -N -q -B -b --suppress-common-lines specs/fixtures/output specs/fixtures/expected`
  if diff_results.empty?
    puts "\n\nPASS: All files matched!"
    puts "#{ diff_results }"
    diff_results.split("\n")
  else
    puts "\n\nFAIL: Not all files matched:\n\n"
    puts "#{ diff_results }"
    matcher= Regexp.new('Files (.*) and', 'i')
    diff_results.scan(matcher).flatten.each do |fname|
      puts "\n\n"
      puts `diff -w -B -b -C 3 #{fname} #{fname.gsub('fixtures/output', 'fixtures/expected')}`
    end
  end
  puts ""
end

desc "test generated output > OpenDiff"
task :test_output_ui do
  sh "cd specs/fixtures/source && bundle exec gumdrop build -f -q && opendiff ../output ../expected"
end
