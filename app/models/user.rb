class User 
  include Neo4j::ActiveNode
  property :email, type: String
  property :name, type: String

  has_many :out, :attends, rel_class: "Attends"
  has_many :out, :organizes, type: :organizes, class_name: 'Meeting'
end
