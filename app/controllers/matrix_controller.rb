class MatrixController < ApplicationController
  def index
    @users = User.all

    @m = Hash.new

    @users.each do |user|

      if (user.email =~ /@hollandstartup\.com/)
        @m[user.email] = Hash.new

        user.attends.each do |meeting|
          meeting.attendees.each do |attendee|
            if (attendee.email =~ /@hollandstartup\.com/)
              if @m[user.email][attendee.email].nil?
                @m[user.email][attendee.email] = 0
              end
              @m[user.email][attendee.email] += 1
            end
          end
        end
      end
    end

    @matrix = Hash.new


    respond_to do |format|
      format.html do
        @users.each do |row|
          if (row.email =~ /@hollandstartup\.com/)
            @matrix[row.email] = Hash.new
            @users.each do |column|
              if (column.email =~ /@hollandstartup\.com/)
                @matrix[row.email][column.email] = 0
                if (!@m[row.email][column.email].nil?)
                  @matrix[row.email][column.email] = @m[row.email][column.email]
                end
              end
            end
          end
        end
      end
      format.json do
        render :json => @matrix
      end
      format.txt do
      end

      format.gexf do
        @users.each do |row|
          if (row.email =~ /@hollandstartup\.com/)
            @matrix[row.email] = Hash.new
            @users.each do |column|
              if (column.email =~ /@hollandstartup\.com/)
                @matrix[row.email][column.email] = @m[row.email][column.email] unless @m[row.email][column.email].nil?
              end
            end
          end
        end
      end
    end
  end
end
