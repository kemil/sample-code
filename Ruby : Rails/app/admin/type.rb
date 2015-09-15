ActiveAdmin.register Type do
	permit_params :typeable_type, :name, :order, :slug
end