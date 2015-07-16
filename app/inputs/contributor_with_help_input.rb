class ContributorWithHelpInput < MultiValueWithHelpInput

  def input(wrapper_options)
    super
  end

  def input_type
    'contributors_multi_value'
  end

  protected

    def buffer_each(collection)
      collection.each_with_object('').with_index do |(value, buffer), index|
        buffer << yield(value, index)
      end
    end

    def collection
      @collection ||= (Array.wrap(object[attribute_name]).reject do
        |value| value.to_s.strip.blank?
      end).sort do |x,y|
        x.order.first.to_i <=> y.order.first.to_i
      end + [Contributor.new()]
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
      @html << "<div class='block' style='padding-bottom: 0.5em'>"

      # --- Contributor Name
      field = :contributor_name

      field_value = value.send(field).first
      field_name = name_for(attribute_name, index, field)

      @html << "<div class='row'>"
      @html << "  <div class='col-md-4'>"
      @html << template.label_tag(field_name, "Name", required: true)
      @html << "  </div>"

      @html << "  <div class='col-md-8'>"
      @html << @builder.text_field(field_name, options.merge(value: field_value, name: field_name))
      @html << "  </div>"
      @html << "</div>"

      # --- Affiliation
      field = :affiliation

      field_value = value.send(field).first
      field_name = name_for(attribute_name, index, field)

      @html << "<div class='row'>"
      @html << "  <div class='col-md-4'>"
      @html << template.label_tag(field_name, field.to_s.humanize, required: true)
      @html << "  </div>"

      @html << "  <div class='col-md-8'>"
      @html << @builder.text_field(field_name, options.merge(value: field_value, name: field_name))
      @html << "  </div>"
      @html << "</div>"

      # --- Role
      field = :role

      field_value = value.send(field).first
      field_name = name_for(attribute_name, index, field)

      @html << "<div class='row'>"
      @html << "  <div class='col-md-4'>"
      @html << template.label_tag(field_name, field.to_s.humanize, required: true)
      @html << "  </div>"

      @html << "  <div class='col-md-8'>"

      merged_input_options = merge_wrapper_options(input_html_options, options)

      @html << @builder.collection_select(
          attribute_name,
          Sufia.config.contributor_roles, :last, :first,
          input_options.merge(selected: field_value), merged_input_options.merge(name: field_name)
        )

      @html << "  </div>"
      @html << "</div>"

      # --- Order
      field = :order

      field_value = index
      field_name = name_for(attribute_name, index, field)

      @html << @builder.hidden_field(attribute_name,
                            name: field_name,
                            value: field_value)

      # delete checkbox
      @html << destroy_widget(attribute_name, index)

      @html << "</div>" # block

      @html
    end

    def destroy_widget(attribute_name, index)
      out = ''
      field_name = destroy_name_for(attribute_name, index)
      out << @builder.hidden_field(attribute_name,
                            name: field_name,
                            id: id_for(attribute_name, index, '_destroy'.freeze),
                            value: "0", data: { destroy: true })
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
