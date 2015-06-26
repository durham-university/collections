class SingleSelectWithModalHelpInput < MultiValueWithHelpInput
  def link_to_help
    template.link_to "##{attribute_name}Modal", id: "#{input_class}_help_modal", rel: 'button',
            data: { toggle: 'modal' }, :'aria-label' => aria_label do
      help_icon
    end
  end

  def input_type
    'single_value'.freeze
  end

  private
    def select_options
      @select_options ||= begin
        collection = options.delete(:collection) || self.class.boolean_collection
        collection.respond_to?(:call) ? collection.call : collection.to_a
      end
    end

    def build_field(value, index)
      html_options = input_html_options.dup

      if @rendered_first_element
        html_options[:id] = nil
        html_options[:required] = nil
      else
        html_options[:id] ||= input_dom_id
      end
      html_options[:class] ||= []
      html_options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      html_options[:'aria-labelledby'] = label_id
      html_options.delete(:multiple)
      @rendered_first_element = true

      html_options.merge!(options.slice(:include_blank))
      template.select_tag(attribute_name, template.options_for_select(select_options, value), html_options)
    end

    def collection
      return @collection if @collection
      @collection = Array.wrap(object[attribute_name]).reject { |value| value.to_s.strip.blank? }
      # Add an empty value if empty, otherwise the selector won't show up at all
      @collection << '' if @collection.empty?
      @collection
    end

    def multiple?
      false
    end

end
