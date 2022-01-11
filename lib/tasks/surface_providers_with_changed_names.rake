namespace :surface_providers_with_changed_names do
  desc "surface providers that have had their names changed over recruitment cycles"
  task run: :environment do
    provider_codes = Provider.distinct.pluck(:provider_code)

    provider_codes_with_name_discrepancies = provider_codes.select do |provider_code|
      Provider.where(provider_code: provider_code).distinct.pluck(:provider_name).length > 1
    end

    File.write("providers_with_changed_names.csv", "provider_code,old_name,new_name,audit_information_available?\n", mode: "a")
    provider_codes_with_name_discrepancies.each do |provider_code|
      providers = Provider.where(provider_code: provider_code)
      names = providers.distinct.pluck(:provider_name)
      audit_information = providers.select { |p| p.audits.any? }.empty?
      File.write("providers_with_changed_names.csv", "#{provider_code},#{names.first},#{names.last},#{!audit_information}\n", mode: "a")
    end
  end
end
