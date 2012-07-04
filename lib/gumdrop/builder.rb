require 'fileutils'
require 'digest/md5'

module Gumdrop

  class Builder
    include Util::SiteAccess

    attr_reader :renderer, :checksums, :options

    def initialize(opts={})
      site.active_builder= self
      opts= opts.to_symbolized_hash
      @renderer= opts[:renderer] || Renderer.new
      @copy_files=[]
      @write_files=[]
      @checksums={}
      @options= opts
      @use_checksum= if opts.has_key?(:checksums)
          opts[:checksums]
        else
          site.config.file_change_test == :checksum
        end
    end

    def build_checksums
      event_block :checksum do
        log.debug "(Creating Checksums)"
        scanner= Util::Scanner.new(site.output_path) { false }
        scanner.each do |path, rel|
          digest= _checksum_for_file path
          @checksums[rel]= digest
          log.debug "  checksum: #{ rel } -> #{ digest }"
        end
      end
    end

    def execute
      fire :start
      event_block :build do
        log.debug "[Building Site]"
        log.debug "(Rendering)"
        event_block :render do
          site.contents.each do |uri, content|
            log.debug "  blackout: #{ uri }" and next if site.in_blacklist? uri
            output_path= site.output_path / content.uri
            if content.binary?
              @copy_files << { content.source_path => output_path }
            else
              rendered_content= renderer.draw content
              @write_files << { rendered_content => output_path }
            end
          end
        end
        build_checksums if @use_checksum
        # All files rendered without exception, write them to disc
        log.info "(Writing to #{ site.output_path })"
        event_block :write do
          @write_files.each {|files| _write files }
          @copy_files.each  {|files| _copy files }
        end
      end
      fire :end
    rescue => ex
      log.error _exception_message ex
      $stderr.puts _exception_message ex, true
      exit 1 unless site.options[:resume]
    end

  private

    def _copy(files)
      files.each do |from,to|
        event_block :copy_file do
          if _file_changed? from, to
            log.info "   copying: #{ _rel_path to }"
            _ensure_path to
            FileUtils.cp_r from, to
          else
            log.info " unchanged: #{ _rel_path to }"
          end
        end
      end
    end

    def _write(files)
      files.each do |rendered_content, to|
        event_block :write_file do
          if _file_changed? rendered_content, to, true
            log.info "   writing: #{ _rel_path to }"
            _ensure_path to
            File.open to, 'w' do |f|
              f.write rendered_content
            end
          else
            log.info " unchanged: #{ _rel_path to }"
          end
        end
      end
    end

    def _file_changed?(from, to, from_is_string=false)
      if @use_checksum
        digest= from_is_string ? _checksum_for(from) : _checksum_for_file(from)
        digest_to = @checksums[_rel_path to]
        # puts "CHECKSUM #{digest_to} == #{digest} #{digest_to == digest}"
        digest_to != digest
      else
        return true if from_is_string
        return true if !File.exists? to
        !FileUtils.identical? from, to
      end
    end

    def _ensure_path(to)
      FileUtils.mkdir_p File.dirname(to)
    end

    def _checksum_for(string)
      Digest::MD5.hexdigest( string )
    end

    def _checksum_for_file(path)
      _checksum_for File.read( path )
    end

    def _rel_path(path)
      path.gsub( site.output_path, '' )[1..-1]
    end

    def _exception_message(ex, short=false)
      class_name= ex.class.to_s
      backtrace= short ? ex.backtrace[0] : ex.backtrace
      "{Exception: #{class_name}}\n#{[ex.to_s, backtrace].flatten.join("\n")}"
    end

  end

  class << self
    
    def build(opts={})
      opts= opts.to_symbolized_hash
      site.scan
      Builder.new(opts).execute
    end

    def rebuild
      site.scan true
      Builder.new.execute
    end

    # Kicks off the build process!
    def run(opts={})
      opts= opts.to_symbolized_hash
      site.options= opts
      Gumdrop.build opts
    end


  end

end