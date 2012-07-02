module Gumdrop::Util

  class Pager
    attr_reader :all, :pages, :base_url, :current_page, :page_sets

    def initialize(articles, base_path="/page", page_size=5)
      @all= articles
      @page_size= page_size
      @base_path= base_path
      @page_sets= @all.in_groups_of(page_size, false)
      @pages= []
      @current_page=1
      @page_sets.each do |art_ary|
        @pages << HashObject.from({
          items: art_ary,
          page: @current_page,
          uri: "#{base_path}/#{current_page}",
          pager: self
        })
        @current_page += 1
      end
      @current_page= nil
    end

    def length
      @pages.length
    end

    def first
      @pages.first
    end

    def last
      @pages.last
    end

    def each
      @current_page=1
      @pages.each do |page_set|
        yield page_set
        @current_page += 1
      end
      @current_page= nil
    end

    def [](key)
      @pages[key]
    end
  end

end