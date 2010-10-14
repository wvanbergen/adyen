class ResponseAttrHandler < YARD::Handlers::Ruby::Legacy::Base
  handles 'response_attrs'
  namespace_only

  def process
    statement.tokens[1..-1].each do |token|
      next unless token.text =~ /^:?(\w+)/
      name = $1
      object = YARD::CodeObjects::MethodObject.new(namespace, name)
      register(object)
      object.dynamic = true
      object.docstring = "@return [String] Returns +:#{name}+ from the {#params}."
    end
  end
end

