class Attends
  include Neo4j::ActiveRel

  from_class 'User'
  to_class 'Meeting'
  type 'ATTENDS'

  property :status 
end