require 'pp'
require 'fileutils'
require 'minitest/spec'
require 'minitest/autorun'
require 'bundler/setup'

HERE= File.dirname(__FILE__)
$LOAD_PATH << File.expand_path(File.join(HERE, '..', 'lib'))

require 'gumdrop'

# Paths

def fixture_path(path)
  (HERE / 'fixtures' / path).expand_path
end

def fixture_src(path)
  fixture_path 'source' / path
end

def fixture_exp(path)
  fixture_path 'expected' / path
end

# Content Objects

def content_for_source(path, opts={})
  # content_for fixture_src(path), site_for_source, opts
  # site_for_source.scan.contents.get path
  if opts[:generated]
    site_for_source.scan
    generator= Gumdrop::Generator.new(nil) { }
    content= Gumdrop::Content.new(path, generator) { }
    content
  else
    site_for_source.scan.contents.get path
  end
end

# Site

def site_for_source()
  Gumdrop::Site.new fixture_src('Gumdrop'), mode:'test', env:'test'
end

# Custom Assertions

module MiniTest::Assertions
  WHITESPACE_RE= Regexp.new('[\s]*', 'im')
  def assert_sorta_like(expected, source)
    exp= expected.gsub(WHITESPACE_RE, '')
    src= source.gsub(WHITESPACE_RE, '')
    assert exp == src, "Expected source to match source (ignoring whitespace)\n#{ exp }\n<=>\n#{ src }"
  end
end

String.infect_an_assertion :assert_sorta_like, :must_be_sorta_like

