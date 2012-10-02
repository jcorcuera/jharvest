module JHarvest
  class Client
    def initialize(opts)
      @resource = Resource.new(opts)
    end

    def projects
      response = @resource.request('/daily', :get)
      hash = Hash.from_xml(response.body)
      hash['daily']['projects']['project']
    end

    def create_entry(project_id, task_id, notes=nil)
      request = <<-EOT
      <request>
        <notes>#{notes}</notes>
        <hours> </hours>
        <project_id type="integer">#{project_id}</project_id>
        <task_id type="integer">#{task_id}</task_id>
        <spent_at type="date">#{Date.today}</spent_at>
      </request>
      EOT
      response = @resource.request('/daily/add', :post, request)
      hash = Hash.from_xml(response.body)
      hash['add']
    end

    def toggle_entry(entry_id)
      response = @resource.request("/daily/timer/#{entry_id}", :get)
      hash = Hash.from_xml(response.body)
      hash['timer']
    end
  end
end
