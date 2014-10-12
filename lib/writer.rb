module ConfigConsumer
  class Writer
    SENSU_CONF_DIR = "/etc/sensu/conf.d"
    def initialize(type, name, payload)
      @type = type
      @name = name
      @payload = payload
    end

    def save
      #verify json and write to disk
      #default directory should be /etc/sensu/conf.d/handlers
      File.open("#{SENSU_CONF_DIR}/#{@name}_config.json", "w") { |f|
        f.write JSON.generate(@payload)
      }
      File.exists?("#{SENSU_CONF_DIR}/#{@name}_config.json")
    end
  end
  
end
