class Calendar 
  include Neo4j::ActiveNode

  id_property :personal_id, on: :calendarId

  property :calendarId, type: String
  property :description, type: String
  property :background, type: String

end
