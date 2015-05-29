class Calendar
  include Neo4j::ActiveNode

  id_property :personal_id, on: :idHash

  property :calendarId, type: String
  property :idHash, type: String
  property :description, type: String
  property :background, type: String
  property :lastUpdate, type: DateTime

  has_many :in, :meetings, type: "BELONGS", model_class: Meeting

end
