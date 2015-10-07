class Ability
  include Hydra::Ability
  include Sufia::Ability


  # Define any customized permissions here.
  def custom_permissions
    can [:index, :show], :people_controller
    if current_user.admin?
      can [:create, :show, :add_user, :remove_user, :index], Role
      can [:edit, :create, :destroy], :people_controller
      can [:update], ContentBlock
    end

    if current_user.id
      can :show, :unpublished_doi
    end

    # Limits deleting objects to a the admin user
    #
    # if current_user.admin?
    #   can [:destroy], ActiveFedora::Base
    # end

    # Limits creating new objects to a specific group
    #
    # if user_groups.include? 'special_group'
    #   can [:create], ActiveFedora::Base
    # end
  end

  # This is just to pull a fix from a more recent hydra-access controls. Can
  # be removed when gem updated.
  def download_permissions
    can :download, ActiveFedora::File do |file|
      parent_uri = file.uri.to_s.sub(/\/[^\/]*$/, '')
      parent_id = ActiveFedora::Base.uri_to_id(parent_uri)
      can? :read, parent_id # i.e, can download if can read parent resource
    end
  end

  def test_edit(id)
    (current_user.admin?) || super
  end

  def test_read(id)
    (current_user.admin?) || super
  end
end
