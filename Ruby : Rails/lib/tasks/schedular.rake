desc "This task is called by the Heroku scheduler add-on"
task :process_inbounds => :environment do
  beginning = Time.now

  inboundCount = Inbound.count

  if inboundCount > 0
    puts "Processing " + inboundCount.to_s + " leads.\n"
    inbounds_by_agency = {}

    Inbound.find_each do |inbound|
      # Let's check to see if the inbound matches a current agency
      agency = Agency.find_by_slug(inbound.agency_slug)
      if agency.present?

        inbounds_by_agency[agency.id] ||= {}
        inbounds_by_agency[agency.id]['piped'] ||= {}
        inbounds_by_agency[agency.id]['triaged'] ||= []

        # Let's check to see if the lead already exists, and if not, add it plus add the image processing to the cue
        if Lead.where(order_no: inbound.order_no, record_no: inbound.record_no).take.nil?
          puts "Processing #{inbound.order_no} #{inbound.record_no}"
          lead = Lead.create(order_no: inbound.order_no, record_no: inbound.record_no, first_name: inbound.first_name, last_name: inbound.last_name, address_one: inbound.address, city: inbound.city, state: inbound.state, zip_code: inbound.zip_code, zip_ext: inbound.zip_ext, returned_date: inbound.received, keycode: inbound.keycode, county: inbound.county, phone: inbound.phone, agency: agency)

          image_url = 'http://3et3jvbtupxhgt.hopto.me:9090/' + lead.order_no + '/' + lead.returned_date.strftime('%Y-%m-%d') + '/tiff/' + lead.order_no + '-' + lead.record_no + '.tif'
          pdf_url = 'http://3et3jvbtupxhgt.hopto.me:9090/' + lead.order_no + '/' + lead.returned_date.strftime('%Y-%m-%d') + '/pdf/' + lead.order_no + '-' + lead.record_no + '.pdf'
          Lead.find(lead.id).delay.image_from_url(image_url)
          Lead.find(lead.id).delay.pdf_from_url(pdf_url)

          if Pipe.where(agency: agency, filter_param: lead.keycode).take.present?
            pipe = Pipe.where(agency: agency, filter_param: lead.keycode).take
            puts "Piping this lead to #{User.find(pipe.pipeable_id).full_name}"

            user_target = User.find(pipe.pipeable_id)
            type_id = Prospect.pipe_type
            if Prospect.create!( lead: lead, prospectable: user_target, type_id: type_id, first_name: lead.first_name, last_name: lead.last_name, middle_name: lead.middle_name, salutation: lead.salutation )
              inbounds_by_agency[agency.id]['piped'][user_target.id] ||= []
              inbounds_by_agency[agency.id]['piped'][user_target.id] << inbound
            end
          else
            inbounds_by_agency[agency.id]['triaged'] << inbound
          end

        else
          puts "Record #{inbound.order_no} #{inbound.record_no} already processed."
        end
      end
      inbound.destroy
    end

    # Let's process some mail!
    inbounds_by_agency.each do |agency_inbounded|
      # Let's look up the agency
      agency = Agency.find(agency_inbounded[0])

      # Let's mail out the prospect notions to the piped users
      agency_inbounded[1]['piped'].each do |user_piped|
        p = user_piped[1].size
        u = User.find(user_piped[0])
        if p > 0
          if u.settings['notifications.new_prospect'] == "1"
            Notifier.new_prospect(u, p, 'info@lead.ac').deliver
          end
        end
      end

      # Let's go ahead and mail the admins the triaged notices
      admins = User.with_role :admin, agency
      admins.each do |admin|
        t = agency_inbounded[1]['triaged'].size
        if t > 0
          if admin.settings['notifications.new_lead'] == "1"
            Notifier.new_triage_lead(admin, t, 'info@lead.ac').deliver
          end
        end
      end

    end

  else
    puts "Nothing to Process.\n"
  end

  runtime = Time.now - beginning
  puts "Your request completed in  #{runtime} seconds."
end
