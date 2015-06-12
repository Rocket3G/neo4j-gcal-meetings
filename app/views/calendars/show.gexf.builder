xml.instruct!
xml.gexf 'xmlns:viz' => 'http://www.gexf.net/1.2draft/viz', :xmlns => 'http://www.gexf.net/1.2draft', :version => '1.2' do
  xml.meta :lastmodifieddate => (Time.new).strftime("%Y-%m-%d") do |m|
    m.creator "Sander Verkuil"
    m.description "Calendar Graph"
  end


  xml.graph :mode => "dynamic", defaultedgetype: "directed" do |graph|
    graph.nodes do |nodes|
      @nodes.each do |n|
        if (n[:model] == "user")
            nn.viz :color, :r => "255", :g => "128", b: "0", a: "1"
            nn.viz :shape, :value => "disc"
          elsif (n[:model] == "meeting")
            nn.viz :color, :r => "0", :g => "128", b: "255", a: "1"
            nn.viz :shape, :value => "square"
          else
            nn.viz :color, :r => "0", :g => "0", b: "0", a: "1"
            nn.viz :shape, :value => "triangle"
          end
      end
    end
    graph.edges do |edges|
      @links.each do |link|
        edges.edge :id => "edge_#{link[:source]}_#{link[:target]}", :source => link[:source], :target => link[:target], :label => link[:label], :weight => link[:weight]
      end
    end
  end
end
