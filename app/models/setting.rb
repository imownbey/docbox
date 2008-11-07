class Setting
  def self.[](arg)
    @settings = YAML.load(File.open("#{RAILS_ROOT}/config/docbox.yml"))
    @settings[arg.to_s]
  end
end