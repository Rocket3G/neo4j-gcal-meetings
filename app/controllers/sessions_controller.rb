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
      meeting = Meeting.find_by(calendarId: e.id)

      if (e.start)
        start = e.start.date_time
        if (start.nil?)
          start = e.start.date
        end
      end
      if (e.end)
        enddate = e.end.date_time
        if (enddate.nil?)
          enddate = e.end.date
        end
      end

      if (meeting.nil?)
        meeting = Meeting.create({
          :calendarId => e.id,
          :name => e.summary,
          :description => e.description,
          :start => start,
          :end => enddate
        })
      else
        meeting.update({
          :name => e.summary,
          :description => e.description,
          :start => start,
          :end => enddate
        })
      end

      e.attendees.each do |attendee|
        user = User.find_by(email: attendee.email)
        if (user.nil?)
          user = User.create(email: attendee.email, name: attendee.display_name)
        end
        if (!user.attends.include?(meeting))
          link = Attends.create(from_node: user, to_node: meeting, status: attendee.responseStatus)
        end

        if (!user.organizes.include?(meeting) && attendee.organizer)
          user.organizes << meeting
        end
      end

      @meetings << meeting

    end


  end

  def destroy
  	session[:user_id] = nil
  	redirect_to root_path
  end
end
