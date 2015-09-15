ActiveAdmin.register Group do
  controller do
    def permitted_params
      params.permit group: [:ancestry, :name, :agency_id]
    end
  end
end
