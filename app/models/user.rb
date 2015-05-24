class User 
  include Neo4j::ActiveNode
  property :email, type: String
  property :name, type: String

  has_many :out, :attends, rel_class: Attends, model_class: Meeting
  has_many :out, :organizes, model_class: 'Meeting'
end
