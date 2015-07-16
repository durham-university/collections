class Ability
  include Hydra::Ability
  include Sufia::Ability


  # Define any customized permissions here.
  def custom_permissions
    can [:index, :show], :people_controller
    if current_user.admin?
      can [:create, :show, :add_user, :remove_user, :index], Role
      can [:edit, :create, :destroy], :people_controller
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

  def test_edit(id)
    (current_user.admin?) || super
  end

  def test_read(id)
    (current_user.admin?) || super
  end
end
