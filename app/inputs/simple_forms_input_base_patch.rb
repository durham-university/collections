# Monkey patches simple-forms lib/simple_form/inputs/base.rb
# Actual patching is done in config/application.rb to_prepare callback
#
module SimpleFormsInputBasePatch

  def initialize(builder, attribute_name, column, input_type, options = {})
    # Set readonly automatically if the model object has the field as
    # readonly.
    if (builder.object.respond_to? :model) &&
        (builder.object.model.respond_to? :field_readonly?) &&
        (builder.object.model.field_readonly? attribute_name)
      options[:readonly] = true
    end
    super(builder, attribute_name, column, input_type, options)
  end

end
