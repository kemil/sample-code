ActiveAdmin.register Lead do

  filter :order_no
  filter :record_no
  filter :first_name
  filter :last_name
  filter :address_one
  filter :city
  filter :county
  filter :returned_date
  filter :keycode

  index do
    column :order_no
    column :record_no
    column :first_name
    column :last_name
    column :address_one
    column :city
    column :state
    column :county
    column :returned_date
    column :keycode
    actions
  end

  form do |f|
    f.inputs "Leads Details" do
      f.input :order_no
      f.input :record_no
      f.input :agency
      f.input :first_name
      f.input :middle_name
      f.input :last_name
      f.input :salutation
      f.input :address_one
      f.input :address_two
      f.input :city
      f.input :county
      f.input :state
      f.input :zip_code
      f.input :zip_ext
      f.input :dob, as: :datepicker
      f.input :keycode
      f.input :returned_date, as: :datepicker
      f.input :suffix
      f.input :uid
      f.input :latitude
      f.input :longitude

    end
    f.actions
  end

  controller do
    def permitted_params
      params.permit lead: [:order_no, :record_no, :first_name, :middle_name, :last_name, :salutation, :address_one, :address_two, :city, :county, :state, :zip_code, :zip_ext, :dob, :keycode, :returned_date, :suffix, :uid, :latitude, :longitude]
    end
  end
end


#   Dob
#   Created At  Updated At  County  Salutation  Middle Name
#   Suffix  Uid
#   Image File Name
#   Image Content Type  Image File Size
#   Image Updated At  Pdf File Name
#   Pdf Content Type  Pdf File Size
#   Pdf Updated At  Latitude  Longitude
