module SufiaHelper
  include ::BlacklightHelper
  include Sufia::BlacklightOverride
  include Sufia::SufiaHelperBehavior

  # Given a model and a term, gets the html class names as a list of
  # strings which will determine what kind of autocomplete to use for
  # the field. Typically this list is just ['autocomplete'] or an
  # empty list if no autocomplete is to be used. It could however in
  # the future contain other classes used to mark special autocomplete
  # behaviour.
  #
  # There is special handling for some terms these will always just return
  # ['autocomplete'] regardless of the model or anything else. These cases
  # match the special cases in authorities_controller.
  #
  # Otherwise, If the database contains a DomainTerm with the given model
  # and term names and a local authority for the DomainTerm, then returns
  # ["autocomplete"]. Otherwise no autocomplete should be used and returns [].
  #
  # Other relevant files to edit when modifying this are authorities_controller
  # and edit_metadata.js.
  def get_field_autocomplete_class(model,term)
    if (not model.is_a? String) and (not model.is_a? Symbol)
      model=ActiveSupport::Inflector.tableize(model.class.to_s)
    end

    if term
      if term.to_s=='based_near' || term.to_s=='subject' || term.to_s=='contributor'
        return ['autocomplete']
      end
    end

    dt=DomainTerm.find_by(model: model, term: term)
    if not dt or dt.local_authorities.empty?
      return []
    else
      return ['autocomplete']
    end
  end


  def render_visibility_label document
    if (document.respond_to? :open_access_pending?) && document.open_access_pending?
      content_tag :span, t('sufia.visibility.open_pending'), class: "label label-success", title: t('sufia.visibility.open_pending')
    elsif document.public?
      content_tag :span, t('sufia.visibility.open'), class: "label label-success", title: t('sufia.visibility.open_title_attr')
    elsif document.registered?
      content_tag :span, t('sufia.institution_name'), class: "label label-info", title: t('sufia.institution_name')
    else
      content_tag :span, t('sufia.visibility.private'), class: "label label-danger", title: t('sufia.visibility.private_title_attr')
    end
  end

  def link_to_profile(login)
    user = ::User.find_by_user_key(login)
    return login if user.nil?

    text =
      if user.respond_to? :name
        user.name
      else
        login
      end

    text
  end

  # Fixes a bug in Sufia. PR sent upstream. See https://github.com/projecthydra/sufia/issues/1546
  def iconify_auto_link(text, show_link = true)
    # this block is only executed when a link is inserted;
    # if we pass text containing no links, it just returns text.
   auto_link(html_escape(text)) do |value|
      "<i class='glyphicon glyphicon-new-window'></i>#{('&nbsp;' + value) if show_link}<br />"
    end
  end

  # Override default sufia link_to_facet, adding the possibility to specify
  # label separately from facet value
  def link_to_facet(field, field_string, label=nil)
    label ||= field
    link_to(label, add_facet_params(field_string, field).merge!(controller: "catalog", action: "index"))
  end

end
