class UtilityController < ApplicationController

  include AspaceUtilities
  include NcsuCatalogUtilities

  def uuid
    render text: SecureRandom.uuid
  end


  def aspace_get
    if params[:uri]
      @uri = params[:uri]
      @params = params[:params] || {}
      @headers = params[:headers] || {}
      @params[:resolve] = ['resource']
      response = aspace_api_get(@uri, @params, @headers)
      if response
        render text: response
      end
    end
  end


  def catalog_get

    if params[:catalog_record_id]
      # catalog_id_from_url() will handle either full url or just the id
      id = catalog_id_from_url(params[:catalog_record_id])
      catalog_connection = NcsuCatalogApiClient::Connection.new
      data = catalog_connection.get_record_by_id(id)
      record = { data: data }

      if !data
        raise CircaExceptions::BadRequest("No catalog record found matching the id or url provided.")
      else
        render json: record
      end
    end
  end


  def archivesspace_data
    case params[:request]
    when 'resources_per_accession'
      return_data = params[:identifier] ? archivesspace_resources_per_accession(params[:identifier]) : {}
    end
    render json: return_data
  end


  def user_data
    if !:user_signed_in?
      redirect_to '/users/sign_in'
    else
      @user = current_user
      # @user = current_user.clone
      render json:  @user
    end
  end


  def archivesspace_redirect
    url_protocol = ENV['archivesspace_https'] ? 'https://' : 'http://'
    redirect_url = url_protocol + ENV['archivesspace_url_host'] + ':' + ENV['archivesspace_frontend_port'] + '/'
    redirect_url += params[:archivesspace_path] ? params[:archivesspace_path] : ''
    redirect_to redirect_url
  end


  def archivesspace_resolver
    url_protocol = ENV['archivesspace_https'] ? 'https://' : 'http://'
    redirect_url = url_protocol + ENV['archivesspace_host'] + ':' + ENV['archivesspace_frontend_port']
    redirect_url += '/resolve/readonly?uri=/'
    redirect_url += params[:archivesspace_uri]
    redirect_to redirect_url
  end


  def user_typeahead
    params[:q] ||= ''
    solr_params = { lucene: true, filters: { 'record_type' => 'user'} }
    if params[:q].length > 0
      q = URI.unescape(params[:q])
      solr_params[:q] = "first_name:#{q}* last_name:#{q}* first_name_t:#{q}* last_name_t:#{q}* email:#{q}* email_t:#{q}*"
      s = Search.new(solr_params)
      solr_response = s.execute
      @api_response = {
        users: solr_response['response']['docs'].map { |d| JSON.parse(d['data']) },
      }
    else
      @api_response = { users: [] }
    end
    render json: @api_response
  end


  def enumeration_values
    if params[:enumeration_name]
      e = Enumeration.find_by_name(params[:enumeration_name])
    elsif params[:enumeration_id]
      e = Enumeration.find_by_id(params[:enumeration_id])
    else
      e = nil
    end

    all_enumeration_values = lambda do
      all_values = {}
      Enumeration.find_each do |enumeration|
        values = EnumerationValue.where(enumeration_id: enumeration.id)
        all_values[enumeration.name] = values.map { |ev| {
          id: ev.id, value: ev.value, value_short: ev.value_short
        } }
      end
      return all_values
    end

    @values = e ? EnumerationValue.where(emueration_id: e.id).map { |ev| ev.attributes } : all_enumeration_values.call
    render json: @values
  end


  # Provides the following values to the front end:
  #  * order_types
  #  * order_sub_types
  #  * patron_type (from enumeration_values)
  def controlled_values
    @values = { order_type: [], order_sub_type: [], patron_type: [] }

    #order_type
    OrderType.find_each do |ot|
      @values[:order_type] << { id: ot.id, name: ot.name, label: ot.label }
    end

    #order_sub_type
    OrderSubType.find_each do |ost|
      @values[:order_sub_type] << { id: ost.id, name: ost.name, label: ost.label, order_type_id: ost.order_type_id }
    end

    #patron_type
    patron_type_enumeration = Enumeration.where(name: 'patron_type').first
    EnumerationValue.where(enumeration_id: patron_type_enumeration.id).find_each do |ev|
      @values[:patron_type] << { id: ev.id, value: ev.value, value_short: ev.value_short }
    end
    render json: { controlled_values: @values }
  end


  def circa_locations
    @locations = Location.where(source_id: Location.circa_location_source_id)
    render json: @locations
  end


  def states_events
    api_response = {
      order_states_events: Order.states_events,
      item_states_events: Item.states_events
    }
    render json: api_response
  end


  def options
    @options = YAML.load_file('config/options.yml')
    render json: { options: @options }
  end

end
