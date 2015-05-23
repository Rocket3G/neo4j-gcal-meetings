json.array!(@meetings) do |meeting|
  json.extract! meeting, :id, :id, :name, :description, :start, :end
  json.url meeting_url(meeting, format: :json)
end
