class DealsController < InheritedResources::Base
	def build_resource_params
  	[params.fetch(:deal, {}).permit(:status_id)]
	end
	load_and_authorize_resource
	before_action :set_return_to, only: [:destroy]
	before_action :set_info

	def ajax
    @deal = Deal.new(deal_params)
    @deal.save

    render :partial => 'widgets/modules/deals/cards', content_type: 'text/html', locals: { dealable: @deal.prospect }
	end

	def magic_load
		# Let's create a new deal for the prospect
		deal = Deal.new(deal_params)
		deal.save

		# # Let's create a default location for the contact
		# location = Location.new()
		# location.primary = true
		# location.type_id = 35
		# location.locatable = contact
		# location.address_one = prospect.lead.address_one
		# location.address_two = prospect.lead.address_two
		# location.city = prospect.lead.city
		# location.state = prospect.lead.state
		# location.zip_code = prospect.lead.zip_code
		# location.zip_ext = prospect.lead.zip_ext
		# location.county = prospect.lead.county
		# location.save

		render :partial => 'widgets/modules/deals/cards', content_type: 'text/html', locals: { dealable: deal.prospect, header: false, cardspan: 6 }
	end

	# DELETE /deals/1
  # DELETE /deals/1.json
  def destroy
  	deal = Deal.find(params[:id])
    deal.destroy
    respond_to do |format|
      format.html { redirect_to request.referer, notice: 'Deal was successfully removed.'  }
      format.json { head :no_content }
    end
  end

  def update
    @deal = Deal.find(params[:id])
    respond_to do |format|
      if @deal.update(deal_params)

        format.html { redirect_to deal_url(@deal), notice: 'Deal was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @deal.errors, status: :unprocessable_entity }
      end
    end
  end

	private
    def set_return_to
      session[:return_to] ||= request.referer
    end

    def deal_params
      params.require(:deal).permit(:status_id, :type_id, :prospect_id, :policy_number, :carrier_id, :application_date, :application_outcome, :outcome_note)
    end

    def set_info
	    @page_header = 'Deal Worksheet'
	    @page_secondary = 'Your deal worksheet. Everything goes here.'
	    @page_title = 'LeadAccount | Deal Worksheet'
	    @page_class = 'Deal'
  	end
end
