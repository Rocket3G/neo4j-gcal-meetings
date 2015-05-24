class CalendarsController < ApplicationController
  def index
  	respond_to do |format|
  		format.html do

  		end

  		format.json do
  			@users = User.all
  			nodes = @users.map{|u| {:uuid => u.uuid, :name => u.name, :email => u.email, :model => "User"}}
  			@meetings = Meeting.all
  			@meetings.map{|m| {:uuid => m.uuid, :name => m.name, :description => m.description, :start => m.start, :end => m.end, :model => "Meeting"}}.each do |meeting|
  				nodes << meeting
  			end
  			links = []

  			@users.each do |user|
  				links += user.attends.map { |other| {:source => nodes.find_index{|n| n[:uuid] == user.uuid}, :target => nodes.find_index{|n| n[:uuid] == other.uuid}, :type => "attends"}}
  				links += user.organizes.map { |other| {:source => nodes.find_index{|n| n[:uuid] == user.uuid}, :target => nodes.find_index{|n| n[:uuid] == other.uuid}, :type => "organizes"}}
  			end
	  		render :json => {:nodes => nodes, :links => links}
  		end
  	end
  end

  def show
  	client = Google::APIClient.new
    client.authorization.access_token = session[:token]
    service = client.discovered_api('calendar', 'v3')
    @result = client.execute(
      :api_method => service.calendar_list.list,
      :parameters => {},
      :headers => {'Content-Type' => 'application/json'})

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
end
