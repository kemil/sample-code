class AgenciesController < InheritedResources::Base
  before_action :authorize
  before_action :set_info


  def index
    @agency = Agency.new
    @agencies = Agency.all
    @users = @agency.users.new
  end

  def create
    @agency = Agency.new(agency_params)
    respond_to do |format|
      if @agency.save
        @agency.users.first.add_role :admin, @agency
        format.html { redirect_to agencies_path, notice: 'Agency was successfully created.' }
        format.json { head :no_content }
      else
        format.html { render action: 'new' }
        format.json { render json: @agency.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def authorize
      unless current_user.has_role? :super_admin
        redirect_to '/', :notice => "You don't have permission"
      end
    end

    def set_info
      @page_header = 'Agency'
      @page_secondary = ''
      @page_title = 'LeadAccount | Agency'
      @page_icon = 'cogs'
    end

    def agency_params
    params.require(:agency).permit(:name, :slug,
                                   users_attributes: [:first_name, :last_name,
                                                       :email, :password, :password_confirmation])
  end
end
