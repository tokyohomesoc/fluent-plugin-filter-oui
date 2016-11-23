require "csv"

module Fluent
  class OuiFilter < Filter
    Plugin.register_filter('oui', self)

    config_param :database_path, :string, :default => File.dirname(__FILE__) + '/../../../ouilist/ouilist.csv'
    config_param :mac_address,   :string, :default => 'mac_address'
    config_param :key_prefix,    :string, :default => 'vendor'
    config_param :remove_prefix, :string, :default => nil
    config_param :add_prefix,    :string, :default => nil

    def configure(conf)
      super
      @remove_prefix = Regexp.new("^#{Regexp.escape(remove_prefix)}\.?") unless conf['remove_prefix'].nil?
      @key_prefix    = @mac_address + "_" + @key_prefix
    end

    def filter(tag, es)
      new_es = MultiEventStream.new
      tag = tag.sub(@remove_prefix, '') if @remove_prefix
      tag = (@add_prefix + '.' + tag) if @add_prefix



      es.each do |time,record|
        record[@key_prefix] = getprotocolname(record[@mac_address])
        new_es.add(time, record)
      end
      return new_es
    end

    def getprotocolname(mac_address)
      mac = mac_address
      mac.gsub!(/[0-9a-fA-F:]{1,8}$/, '')
      mac.gsub!(/:/, '')
      mac = mac.upcase

      CSV.open(@database_path,"r") do |csv|
        csv.each do |row|
          if row[0] == mac
            return row[1]
          end
        end
      end
    end

  end
end