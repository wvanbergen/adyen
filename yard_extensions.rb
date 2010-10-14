class ResponseAttrHandler < YARD::Handlers::Ruby::Legacy::Base
  handles 'response_attrs'
  namespace_only

  def process
    statement.tokens[1..-1].each do |token|
      name = token.text.strip
      next if name.empty? || name == ','
      name = name[1..-1] if name[0,1] == ':'
      object = YARD::CodeObjects::MethodObject.new(namespace, name)
      register(object)
      object.dynamic = true
      object.docstring = "@return [String] Returns +:#{name}+ from the {#params}."
    end
  end
end

