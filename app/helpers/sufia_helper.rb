module SufiaHelper
  include ::BlacklightHelper
  include Sufia::BlacklightOverride
  include Sufia::SufiaHelperBehavior

  # Given a model and a term, gets the html class name which will
  # determine what kind of autocomplete to use for the field. If no
  # autocomplete is to be used, returns an empty string.
  #
  # If the database contains a DomainTerm with the given model and
  # term names and a local authority for the DomainTerm, then returns
  # "autocomplete_la".
  #
  # As a special case, for term "based_near" returns "autocomplete_geo".
  def get_field_autocomplete_class(model,term)
    if (not model.is_a? String) and (not model.is_a? Symbol)
      model=ActiveSupport::Inflector.tableize(model.class.to_s)
    end

    if term and term.to_s=='based_near'
      return 'autocomplete_geo'
    end

    dt=DomainTerm.find_by(model: model, term: term)
    if not dt or dt.local_authorities.empty?
      return ''
    else
      return 'autocomplete_la'
    end
  end
end
