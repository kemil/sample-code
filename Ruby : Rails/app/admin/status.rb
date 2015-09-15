ActiveAdmin.register Status do
	permit_params :statusable_type, :name, :order, :slug
end