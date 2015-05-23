class SessionsController < ApplicationController
  def create
  	#What data comes back from OmniAuth?     
    @auth = request.env["omniauth.auth"]
    #Use the token from the data to request a list of calendars
    @token = @auth["credentials"]["token"]
    client = Google::APIClient.new
    client.authorization.access_token = @token
    service = client.discovered_api('calendar', 'v3')
    @result = client.execute(
      :api_method => service.calendar_list.list,
      :parameters => {},
      :headers => {'Content-Type' => 'application/json'})

    owner = User.find_by(email: @auth["info"]["email"])
    if (owner.nil?)
      owner = User.create({
        email: @auth["info"]["email"],
        name: @auth["info"]["name"]
      })
    end

    @events ||= Array.new

    @result.data.items.each do |e| 
      calendarEvents = client.execute(
        :api_method => service.events.list,
        :parameters => {
          'calendarId' => e.id,
          'fields' => 'items(status,originalStartTime,privateCopy,transparency,locked,creator,guestsCanSeeOtherGuests,organizer,description,htmlLink,recurringEventId,etag,hangoutLink,sequence,kind,anyoneCanAddSelf,updated,attendeesOmitted,endTimeUnspecified,attendees,created,summary,location,gadget,colorId,iCalUID,visibility,start,extendedProperties,end,guestsCanModify,id,guestsCanInviteOthers)'
        },
        :headers => {'Content-Type' => 'application/json'}
      )
      calendarEvents.data.items.each do |ee|
        @events << ee
      end
    end

    @meetings = Array.new

    @events.each do |e|
      meeting = Meeting.find_by(id: e.id)

      puts e.start

      if (meeting.nil?)
        meeting = Meeting.create({
          :id => e.id,
          :name => e.summary,
          :description => e.description,
          :start => e.start,
          :end => e.end
        })
      end


      @meetings << meeting

    end


  end

  def destroy
  	session[:user_id] = nil
  	redirect_to root_path
  end
end
