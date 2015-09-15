ActiveAdmin.register Agency do

  controller do
    def permitted_params
      params.permit agency: [:name, :slug]
    end
  end

end
