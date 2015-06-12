class Meeting
  include Neo4j::ActiveNode

  property :calendarId, type: String
  property :name, type: String
  property :description, type: String
  property :start, type: DateTime
  property :end, type: DateTime

  has_many :in, :attendees, type: "ATTENDS", rel_clas: 'Attends', model_class: User
  has_many :in, :organizers, type: "ORGANIZES", model_class: User
  has_one :out, :calendar, type: "BELONGS", model_class: Calendar
end
