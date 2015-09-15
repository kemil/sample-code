ActiveAdmin.register User do
  index do
    column :id
    column :email
    column :sign_in_count
    column :first_name
    column :last_name
    column :agency
    actions
  end

  form do |f|
    f.inputs "User Details" do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :password
      f.input :password_confirmation
      f.input :agency
    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit user: [:email, :password, :password_confirmation, :agency_id, :first_name, :last_name]
    end
  end
end
