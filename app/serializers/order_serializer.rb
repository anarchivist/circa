class OrderSerializer < ActiveModel::Serializer

  attributes :id, :access_date_start, :access_date_end, :order_type_id, :order_sub_type_id, :confirmed, :open, :created_at, :updated_at,
    :archivesspace_records, :catalog_records, :catalog_items,
    :current_state, :permitted_events, :available_events, :states_events,
    :default_location, :num_items, :primary_user_id, :primary_user_id, :num_items_ready, :created_by_user, :deletable, :item_ids_in_use

  belongs_to :order_type
  belongs_to :order_sub_type
  belongs_to :temporary_location
  has_many :items, serializer: OrderItemsSerializer
  has_many :item_orders, serializer: ItemOrderSerializer
  has_many :users, serializer: OrderUserSerializer
  has_many :assignees, serializer: OrderUserSerializer
  has_many :notes
  has_one :course_reserve


  def created_at
    object.created_at.strftime('%FT%T%:z')
  end


  def updated_at
    object.created_at.strftime('%FT%T%:z')
  end


  def default_location
    if object.temporary_location
      object.temporary_location.default
    end
  end


  def num_items
    object.items.length
  end


  def primary_user_id
    primary_user = object.primary_user
    primary_user ? primary_user.user.id : nil
  end


  def deletable
    object.deletable? ? true : nil
  end


  def item_ids_in_use
    object.access_sessions.active.map { |a| a.item_id }
  end


end
