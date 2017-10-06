class CustomWizard::AdminController < ::ApplicationController
  before_action :ensure_logged_in
  before_action :ensure_admin

  def index
    render nothing: true
  end

  def field_types
    render json: { types: CustomWizard::FieldTypes.all }
  end

  def save
    params.require(:wizard)

    wizard = ::JSON.parse(params[:wizard])

    saved = false
    if wizard["existing_id"] && rows = PluginStoreRow.where(plugin_name: 'custom_wizard').order(:id)
      rows.each do |r, i|
        wizard = CustomWizard::Wizard.new(r.value)
        if wizard.id = wizard["existing_id"]
          r.update_all(key: wizard['id'], value: wizard)
          saved = true
        end
      end
    end

    unless saved
      PluginStore.set('custom_wizard', wizard["id"], wizard)
    end

    render json: success_json
  end

  def remove
    params.require(:id)

    PluginStore.remove('custom_wizard', params[:id])

    render json: success_json
  end

  def find_wizard
    params.require(:wizard_id)

    wizard = PluginStore.get('custom_wizard', params[:wizard_id])

    render json: success_json.merge(wizard: wizard)
  end

  def custom_wizards
    rows = PluginStoreRow.where(plugin_name: 'custom_wizard').order(:id)

    wizards = [*rows].map { |r| CustomWizard::Wizard.new(r.value) }

    render json: success_json.merge(wizards: wizards)
  end

  def find_submissions
    params.require(:wizard_id)

    wizard = PluginStore.get('custom_wizard_submissions', params[:wizard_id])

    render json: success_json.merge(submissions: submissions)
  end

  def submissions
    rows = PluginStoreRow.where(plugin_name: 'custom_wizard_submissions').order(:id)

    all = [*rows].map do |r|
      wizard = PluginStore.get('custom_wizard', r.key)
      name = wizard ? wizard['name'] : r.key
      {
        id: r.key,
        name: name,
        submissions: ::JSON.parse(r.value)
      }
    end

    render json: success_json.merge(submissions: all)
  end
end