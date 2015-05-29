class AuthorInput < MultiValueWithHelpInput
  def input(wrapper_options)
    super
  end

  protected

    def collection
      @collection ||= Array.wrap(object[attribute_name]).reject do
        |value| value.to_s.strip.blank?
      end
    end

    def build_field(value, index)
      @html = ''
      options = build_options(input_html_options.dup)
      @rendered_first_element = true
      build_components(attribute_name, value, index, options)
      hidden_id_field(value, index) unless value.new_record?
      @html
    end

    def build_options(options)
      options[:required] = nil if @rendered_first_element
      options[:data] = { attribute: attribute_name }
      options[:class] ||= []
      options[:class] += ["#{input_dom_id} form-control multi-text-field"]
      options[:'aria-labelledby'] = label_id
      options
    end

    def build_components(attribute_name, value, index, options)
      @html << "<div class='row'>"

      # --- First Name
      field = :first_name

      field_value = value.send(field).first
      field_name = name_for(attribute_name, index, field)

      @html << "  <div class='col-md-2'>"
      @html << template.label_tag(field_name, field.to_s.humanize, required: true)
      @html << "  </div>"

      @html << "  <div class='col-md-3'>"
      @html << @builder.text_field(field_name, options.merge(value: field_value, name: field_name))
      @html << "  </div>"

      # --- Last Name
      field = :last_name

      field_value = value.send(field).first
      field_name = name_for(attribute_name, index, field)

      @html << "  <div class='col-md-2'>"
      @html << template.label_tag(field_name, field.to_s.humanize, required: false)
      @html << "  </div>"

      @html << "  <div class='col-md-3'>"
      @html << @builder.text_field(field_name, options.merge(value: field_value, name: field_name))
      @html << "  </div>"

      @html << "</div>" # row

      @html << "<div class='row'>"

      # delete checkbox
      @html << "  <div class='col-md-3'>"
      @html << destroy_widget(attribute_name, index)
      @html << "  </div>"

      @html << "</div>" # class=row

      @html
    end

    def destroy_widget(attribute_name, index)
      out = ''
      field_name = destroy_name_for(attribute_name, index)
      out << @builder.check_box(attribute_name,
                            name: field_name,
                            id: id_for(attribute_name, index, '_destroy'.freeze),
                            value: "true", data: { destroy: true })
      out << template.label_tag(field_name, "Remove", class: "remove_author")
      out
    end

    def hidden_id_field(value, index)
      name = id_name_for(attribute_name, index)
      id = id_for(attribute_name, index, 'id'.freeze)
      hidden_value = value.new_record? ? '' : value.id
      @html << @builder.hidden_field(attribute_name, name: name, id: id, value: hidden_value, data: { id: 'remote' })
    end

    def name_for(attribute_name, index, field)
      "#{@builder.object_name}[#{attribute_name}_attributes][#{index}][#{field}][]"
    end

    def id_name_for(attribute_name, index)
      singular_input_name_for(attribute_name, index, "id")
    end

    def singular_input_name_for(attribute_name, index, field)
      "#{@builder.object_name}[#{attribute_name}_attributes][#{index}][#{field}]"
    end

    def destroy_name_for(attribute_name, index)
      singular_input_name_for(attribute_name, index, "_destroy")
    end

    def id_for(attribute_name, index, field)
      [@builder.object_name, "#{attribute_name}_attributes", index, field].join('_'.freeze)
    end
end