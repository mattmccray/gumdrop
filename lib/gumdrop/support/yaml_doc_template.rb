require 'yaml'

module Tilt
  class YamlDocTemplate < Template

    def render(scope=Object.new, locals={}, &block)
      yamldoc= Gumdrop::Util::YamlDoc.new(@data)
      scope.set yamldoc.data if scope.respond_to? :set
      yamldoc.body
    end

  protected

    def prepare

    end

    def evaluate(scope, locals, &block)
      method = compiled_method(locals.keys)
      method.bind(scope).call(locals, &block)
    end
  end
end

 
 Tilt.register Tilt::YamlDocTemplate, 'yamldoc'
 Tilt.register Tilt::YamlDocTemplate, 'yamdoc'
 Tilt.register Tilt::YamlDocTemplate, 'yd'

