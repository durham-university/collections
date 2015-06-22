# Most of this copied from hydra-editor/app/inputs/multi_value_input.rb,
# with some modifications for the identifier field

class IdentifierInput < MultiValueInput
  def input(wrapper_options)
    @rendered_first_element = false
    input_html_classes.unshift("string")
    input_html_options[:name] ||= "#{object_name}[#{attribute_name}][]"

    outer_wrapper do
      buffer_each(collection) do |value, index|
        classes= if value.starts_with? "doi:#{DOI_CONFIG['doi_prefix']}/"
          'local_doi'
        else
          ''
        end

        inner_wrapper classes do
          build_field(value, index)
        end
      end
    end
  end

  def input_type
    'multi_value'.freeze
  end


  protected

    def inner_wrapper classes
      <<-HTML
        <li class="field-wrapper #{classes}">
          #{yield}
        </li>
      HTML
    end

  private

    def build_field_options(value, index)
      options = input_html_options.dup

      options[:value] = value
      if @rendered_first_element
        options[:id] = nil
        options[:required] = nil
      else
        options[:id] ||= input_dom_id
      end
      options[:class] ||= []
      options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      options[:'aria-labelledby'] = label_id

      if value.starts_with? "doi:#{DOI_CONFIG['doi_prefix']}/"
        options[:readonly]='readonly'
      end

      @rendered_first_element = true

      options
    end

    def build_field(value, index)
      options = build_field_options(value, index)

      if options.delete(:type) == 'textarea'.freeze
        @builder.text_area(attribute_name, options)
      else
        @builder.text_field(attribute_name, options)
      end
    end


end
