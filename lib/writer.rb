module ConfigConsumer
  class Writer
    SENSU_PLUGIN_DIR = "/etc/sensu/conf.d/handlers"
    def initialize(type, name, payload)
      @type = type
      @name = name
      @payload = payload
    end

    def save
      #verify json and write to disk
      #default directory should be /etc/sensu/conf.d/handlers
      File.open("SENSU_PLUGIN_DIR/#{name}_handler.json", "w") { |f|
        f.write payload
      }
      File.exists?("SENSU_PLUGIN_DIR/#{name}_handler.json")
    end
  end
  
end
