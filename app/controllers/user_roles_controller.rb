class UserRolesController < ApplicationController
  include Hydra::RoleManagement::UserRolesBehavior

  # Fixes a bug in Sufia/hydra-roles. We must find the user fy the find_column, not id.
  def destroy
    authorize! :remove_user, @role
    @role.users.delete(::User.find_by_user_key(params[:id]))
    redirect_to role_management.role_path(@role)
  end
end
