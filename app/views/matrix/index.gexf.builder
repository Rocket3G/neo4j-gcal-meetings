xml.instruct!
xml.gexf 'xmlns:viz' => 'http://www.gexf.net/1.1draft/viz', :xmlns => 'http://www.gexf.net/1.1draft', :version => '1.1' do
  xml.meta :lastmodifieddate => (Time.new).strftime("%Y-%m-%d") do |m|
    m.creator "Sander Verkuil"
    m.description "Users Graph"
  end


  xml.graph :mode => "dynamic", defaultedgetype: "directed" do |graph|
    graph.nodes do |nodes|
      @users.each do |user|
        nodes.node :id => user.email, :label => user.name
      end
    end
    graph.edges do |edges|
      @matrix.each do |key, value|
        value.each do |k, v|
          edges.edge :id => "edge_#{key}_#{k}", :source => key, :target => k, :weight => v
        end
      end
    end
  end
end
