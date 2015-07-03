module My
  class CollectionsController < MyController

    self.search_params_logic += [
      # This is fixed in sufia github. Temporarily copied solution until we
      # upgrade to new Sufia.
      :show_only_files_deposited_by_current_user,
      
      :show_only_collections
    ]

    def index
      super
      @selected_tab = :collections
    end

    protected

    def search_action_url *args
      sufia.dashboard_collections_url *args
    end
  end
end
