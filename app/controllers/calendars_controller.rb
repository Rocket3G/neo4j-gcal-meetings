require 'Digest'

class CalendarsController < ApplicationController
  def index
    @calendars = Calendar.all

  	respond_to do |format|
      format.html do

      end
    	format.json do
        @users ||= Array.new
        @meetings ||= Array.new

        @calendars.each do |calendar|
          calendar.meetings.each do |meeting|
            @meetings << meeting unless @meetings.include?(meeting)
          end
        end

        @links ||= Array.new
        @nodes ||= Array.new

        @meetings.each do |meeting|
          @nodes << {:id => meeting.id, :name => meeting.name, :model => "meeting"}

          meeting.attendees.each do |user|
            @users << user unless @nodes.include?(user)
          end
        end

        @users.each do |user|
          @nodes << {:id => user.id, :name => user.name, :model => "user"}
          user.attends.each do |node|
            @links << {:source => @nodes.find_index{|n| n[:id] == node.id}, :target => @nodes.find_index{|n| n[:id] == user.id}, :type => "ATTENDS"}
          end
          user.organizes.each do |node|
            @links << {:source => @nodes.find_index{|n| n[:id] == node.id}, :target => @nodes.find_index{|n| n[:id] == user.id}, :type => "ORGANIZES"}
          end

        end

        render :json => {nodes: @nodes, links: @links}
  		end
      format.gexf do

        @users ||= Array.new

        @meetings ||= Array.new

        Calendar.all.each do |calendar|
          calendar.meetings.each do |meeting|
            @meetings << meeting unless @meetings.include?(meeting)
          end
        end

        @links ||= Array.new
        @nodes ||= Array.new

        @meetings.each do |meeting|
          @nodes << {:id => meeting.id, :name => meeting.name, :model => "meeting", :weight => meeting.attendees.length}

          meeting.attendees.each do |user|
            if (user.email =~ /@hollandstartup\.com/)
              @users << user unless @users.include?(user)
              @links << {:target => meeting.id, :source => user.id, :label => "ATTENDS", :weight => 1}
            end
          end
        end

        @users.each do |user|
          if (user.email =~ /@hollandstartup\.com/)
            @nodes << {:id => user.id, :name => user.name, :model => "user", :radius => user.attends.length}
          end
        end
      end

  	end
  end

  def import
    client = Google::APIClient.new
    client.authorization.access_token = session[:token]
    service = client.discovered_api('calendar', 'v3')
    @result = client.execute(
      :api_method => service.calendar_list.list,
      :headers => {'Content-Type' => 'application/json'})
    @calendars = Array.new

    @result.data.items.each do |calendar|
      hash = Digest::SHA256.hexdigest calendar.id
      cal = Calendar.new({
        :calendarId => calendar.id,
        :idHash => hash,
        :description => calendar.summary,
        :background => calendar.backgroundColor
      })
      @calendars << cal
    end

    if (params.has_key?(:import))
      @users ||= Array.new
      @imported ||= Array.new

      params[:import].each do |import|
        puts import
        if (import[1] == "1") then
          hash = Digest::SHA256.hexdigest import[0]
          index = @calendars.find_index {|item| item.idHash == hash}
          calendar = @calendars[index]
          calendar.save!() unless Calendar.exists?({idHash: hash})

          calendar = Calendar.find_by({idHash: hash})

          @imported << calendar

          @result = client.execute(
            :api_method => service.events.list,
            :parameters => {
              'calendarId' => import[0],
              'fields' => 'items(status,originalStartTime,privateCopy,transparency,locked,creator,guestsCanSeeOtherGuests,organizer,description,htmlLink,recurringEventId,etag,hangoutLink,sequence,kind,anyoneCanAddSelf,updated,attendeesOmitted,endTimeUnspecified,attendees,created,summary,location,gadget,colorId,iCalUID,visibility,start,extendedProperties,end,guestsCanModify,id,guestsCanInviteOthers)'
            },
            :headers => {'Content-Type' => 'application/json'})
          @meetings ||= Array.new

          @result.data.items.each do |event|
            if (event.start)
              start = event.start.date_time
              if (start.nil?)
                start = event.start.date
              end
            end
            if (event.end)
              enddate = event.end.date_time
              if (enddate.nil?)
                enddate = event.end.date
              end
            end

            meeting = Meeting.new({
              :calendarId => event.id,
              :name => event.summary,
              :description => event.description,
              :start => start,
              :end => enddate,
            })
            meeting.save!() unless Meeting.exists?(calendarId: meeting.calendarId)

            meeting = Meeting.find_by(calendarId: meeting.calendarId)

            meeting.calendar = calendar

            event.attendees.each do |attendee|
              name = attendee.display_name
              name = attendee.email[/(.*?)@/,1].gsub(/[^\w\s\d]/, ' ').split.map(&:capitalize).join(' ') if name.nil? || name.empty?
              user = User.new(email: attendee.email, name: name)
              user.save! unless User.exists?(email: attendee.email)
              user = User.find_by(email: attendee.email)
              @users << user unless @users.include?(user)

              meeting.attendees << user unless meeting.attendees.include?(user)

              if (!user.attends.include?(meeting))
                link = Attends.create(from_node: user, to_node: meeting, status: attendee.responseStatus)
              end

              if (!user.organizes.include?(meeting) && attendee.organizer)
                user.organizes << meeting
              end

              if (!meeting.organizers.include?(user) && attendee.organizer)
                meeting.organizers << user
              end
            end
            @meetings << meeting
          end
        end
      end
      return render "done"
    end
  end

  def test
    client = Google::APIClient.new
    client.authorization.access_token = session[:token]
    service = client.discovered_api('calendar', 'v3')
    @result = client.execute(
      :api_method => service.calendar_list.list,
      :parameters => {},
      :headers => {'Content-Type' => 'application/json'})

    render :json => @result.data
  end

  def new
    client = Google::APIClient.new
    client.authorization.access_token = session[:token]
    service = client.discovered_api('calendar', 'v3')
    @result = client.execute(
      :api_method => service.calendar_list.list,
      :parameters => {},
      :headers => {'Content-Type' => 'application/json'})

    @result.data.items.each do |calendar|
      c = Calendar.find_or_create({
        :calendarId => calendar.id,
        :description => calendar.summary,
        :background => calendar.backgroundColor
        }) unless Calendar.exists?({calendarId: calendar.id })
    end
  end

  def show
    min = 5
    max = 10
    @calendar = Calendar.find_by({idHash: params[:id]})

    users = User.all.length

    respond_to do |format|

      format.html do

      end
      format.json do
        @users ||= Array.new
        @meetings ||= @calendar.meetings

        @links ||= Array.new
        @nodes ||= Array.new

        @meetings.each do |meeting|
          @nodes << {:id => meeting.id, :name => meeting.name, :model => "meeting", :radius => min + (meeting.attendees.length / users) * (max - min)}

          meeting.attendees.each do |user|
            @users << user unless @users.include?(user) or user.email =~ /@hollandstartup\.com/
          end
        end

        @users.each do |user|
          @nodes << {:id => user.id, :name => user.name, :model => "user", :radius => min + (user.attends.length / @meetings.length) * (max - min)}
          user.attends.each do |node|
            @links << {:target => @nodes.find_index{|n| n[:id] == node.id}, :source => @nodes.find_index{|n| n[:id] == user.id}, :type => "ATTENDS"}
          end

        end

        render :json => {nodes: @nodes, links: @links}
      end

      format.gexf do
        @users ||= Array.new
        @meetings ||= @calendar.meetings

        @links ||= Array.new
        @nodes ||= Array.new

        @meetings.each do |meeting|
          @nodes << {:id => meeting.id, :name => meeting.name, :model => "meeting", :weight => meeting.attendees.length}

          meeting.attendees.each do |user|
            if (user.email =~ /@hollandstartup\.com/)
              @users << user unless @users.include?(user)
              @links << {:target => meeting.id, :source => user.id, :label => "ATTENDS", :weight => 1}
            end
          end
        end

        @users.each do |user|
          if (user.email =~ /@hollandstartup\.com/)
            @nodes << {:id => user.id, :name => user.name, :model => "user", :radius => user.attends.length}
          end
        end
      end

    end
  end
end
