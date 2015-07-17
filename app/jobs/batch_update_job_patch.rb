# Monkey patches sufia-models app/jobs/batch_update_job.rb
# Actual patching is done in config/application.rb to_prepare callback
#
module BatchUpdateJobPatch

  include HydraDurham::VisibilityParams

  def update_file(gf, user)
    # Make sure the user is allowed to change visibility.
    # super will do a generic permissions check later as well.

    # Backup original attributes and visibility, we'll modify these
    # and then restore for subsequent files. This keeps the patch
    # minimal, though ideally we'd pass these as parameters to super instead.
    original_attributes=file_attributes.deep_dup
    original_visibility=visibility

    # handle_pending_visibility_params needs all parameters in a single hash
    params={
      visibility: visibility,
      generic_file: file_attributes
    }

    # Check if the user isn't allowed to change the visibility of this file
    if visibility && (gf.respond_to? :can_change_visibility?) && (!gf.can_change_visibility? visibility, user)
      params[:visibility] = gf.visibility # Not allowed to change visibility. Just keep old value.
    end
    handle_pending_visibility_params params, gf, :generic_file

    self.visibility=params[:visibility]

    old_request_value=gf.request_for_visibility_change

    super

    new_request_value=gf.request_for_visibility_change
    if new_request_value=='open' && new_request_value!=old_request_value && saved.last==gf
      send_open_pending_notifications gf, user
    end

    # restore the stored params for next file
    self.file_attributes=original_attributes
    self.visibility=original_visibility
  end

end
