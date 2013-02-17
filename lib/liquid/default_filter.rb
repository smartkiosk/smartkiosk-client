module Liquid::DefaultFilter
  def default(input, default)
  	input.blank? ? default : input
  end
end

Liquid::Template.register_filter(Liquid::DefaultFilter)