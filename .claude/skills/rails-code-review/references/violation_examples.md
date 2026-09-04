# Violation Examples: Correct & Incorrect Patterns

Reference for sections 2.1–2.7 of the rails-code-review skill.

---

## 2.1 Modelos (`app/models/*.rb`)

```ruby
# ✅ CORRECTO
class User < ApplicationRecord
  include Discard::Model
  default_scope -> { kept }

  belongs_to :company
  has_many :orders

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Solo métodos sin parámetros externos
  def full_name
    "#{name} #{surname}".strip
  end
end

# ❌ VIOLACIONES COMUNES
class User < ApplicationRecord
  # ❌ FALTA include Discard::Model
  # ❌ FALTA default_scope -> { kept }

  # ❌ PROHIBIDO: scope personalizado
  scope :active, -> { where(status: 'active') }

  # ❌ PROHIBIDO: método con parámetros externos (debe ser servicio)
  def calculate_discount(percentage)
    total * (1 - percentage)
  end

  # ❌ PROHIBIDO: método privado
  private

  def internal_calculation
    # ...
  end
end
```

---

## 2.2 Servicios (`app/services/**/*.rb`)

```ruby
# ✅ CORRECTO (Create/Update - SIN bang)
module Users
  class Create < BaseService
    def initialize(name:, email:)
      @name = name
      @email = email
    end

    def service_execute
      User.create(name: @name, email: @email)
    end
  end
end

# ✅ CORRECTO (Operación que no debe fallar - CON bang)
module Users
  class Enable < BaseService
    def initialize(user:)
      @user = user
    end

    def service_execute
      @user.update!(enabled: true)
      @user
    end
  end
end

# ✅ CORRECTO (Search service)
module Users
  class Search < Base::Search
    def initialize(filters: nil, sort: nil, sort_order: nil, page: nil)
      super(klass: User, filters: filters, sort: sort, sort_order: sort_order, page: page)
    end

    def execute
      result = super
      result.includes(:company, :roles)
    end

    def apply_query_filter(filter_value)
      @value = @value.where("users.name LIKE ? OR users.email LIKE ?", "%#{filter_value}%", "%#{filter_value}%")
    end
  end
end

# ❌ VIOLACIONES COMUNES
module Users
  class Create < BaseService
    # ❌ NO hereda de BaseService
    # ❌ Usa métodos privados
    private

    def validate_params
      # ...
    end

    # ❌ Usa bang method en Create (espera validaciones)
    def service_execute
      User.create!(name: @name)
    end
  end
end
```

---

## 2.3 Controladores (`app/controllers/**/*.rb`)

```ruby
# ✅ CORRECTO
class Admin::UsersController < ApplicationController
  def index
    authorize User
    users = ::Users::Search.execute(filters: filter_params)
    @users = Users::UserTableDecorator.decorate_collection(users)
  end

  def show
    user = ::Base::Find.execute(klass: User, id: params[:id])
    authorize user
    @user = Users::UserShowDecorator.decorate(user)
  end

  def create
    authorize User
    user = ::Users::Create.execute(name: user_params[:name],
                                       email: user_params[:email],
                                       password: user_params[:password])

    if user.valid?
      redirect_to admin_user_path(user), notice: t('flash.actions.create.notice')
    else
      @flash_notification = user.errors.full_messages
      @user = Users::UserShowDecorator.decorate(user)
      render :new, status: :unprocessable_content
    end
  end
end

# ❌ VIOLACIONES COMUNES
class Admin::UsersController < ApplicationController
  def index
    # ❌ ActiveRecord directo
    @users = User.where(active: true).order(:name)
  end

  def show
    # ❌ ActiveRecord directo
    @user = User.find(params[:id])
  end

  def create
    # ❌ NO usa servicio
    @user = User.new(user_params)
    @user.save
  end

  # ❌ Lógica de negocio en controlador
  def calculate_total
    @order = Order.find(params[:id])
    @total = @order.items.sum(&:price) * 1.21
  end
end
```

---

## 2.4 Decorators (`app/decorators/**/*.rb`)

```ruby
# ✅ CORRECTO (ShowDecorator)
class Users::UserShowDecorator < Draper::Decorator
  delegate_all
  delegate :to_key, :to_param, :persisted?, :model_name, to: :object

  def formatted_created_at
    h.l(object.created_at, format: :short)
  end

  def status_badge
    color = object.active? ? 'success' : 'secondary'
    h.content_tag(:span, I18n.t("users.status.#{object.status}"), class: "badge bg-#{color}")
  end
end

# ✅ CORRECTO (TableDecorator)
class Users::UserTableDecorator < Draper::Decorator
  delegate_all
  delegate :to_key, :to_param, :persisted?, :model_name, to: :object

  def self.collection_decorator_class
    Common::PaginatingIndexCollectionDecorator
  end

  def self.table_config
    { columns: [
        { key: :name, label: User.human_attribute_name(:name), sortable: true, sort_column: "users.name" },
        { key: :actions, label: I18n.t('common.actions'), sortable: false, cell_class: "stop-propagation" }
      ],
      row_clickable: true,
      row_path: ->(user) { h.admin_user_path(user) },
      turbo_frame_id: "users_list" }
  end

  def table_cells
    { name: object.name,
      actions: actions_buttons }
  end

  def actions_buttons
    buttons = []
    buttons << edit_button if h.policy(object).update?
    h.content_tag(:div, h.safe_join(buttons), class: "d-inline-flex gap-1")
  end
end

# ❌ VIOLACIONES COMUNES
class Users::UserTableDecorator < Draper::Decorator
  # ❌ FALTA delegate_all
  # ❌ FALTA delegate :to_key, :to_param, :persisted?, :model_name

  # ❌ FALTA collection_decorator_class para TableDecorator
  # ❌ FALTA table_config para TableDecorator

  # ❌ Usa método privado
  private

  def format_date(date)
    date.strftime('%Y-%m-%d')
  end

  # ❌ Lógica de negocio en decorator
  def calculate_total
    object.items.sum(&:price) * 1.21
  end

  # ❌ Llama a ActiveRecord directamente
  def recent_orders
    Order.where(user_id: object.id).limit(5)
  end
end
```

---

## 2.5 Componentes (`app/components/**/*.rb`)

```ruby
# ✅ CORRECTO
class StateMachine::StateChangesCardComponent < ViewComponent::Base
  def initialize(decorated_object:)
    @decorated_object = decorated_object
  end

  def render?
    @decorated_object.respond_to?(:state_changes)
  end

  def available_events
    @decorated_object.available_events_with_metadata
  end
end

# ❌ VIOLACIONES COMUNES
class StateMachine::StateChangesCardComponent < ViewComponent::Base
  def initialize(object:)
    # ❌ Infiere que es un decorator (debería ser explícito)
    @object = object
  end

  # ❌ Llama a servicio desde componente
  def available_events
    StateService::GetEvents.execute(object: @object)
  end

  # ❌ Lógica de negocio compleja
  def calculate_next_state
    if @object.pending? && @object.items.all?(&:ready?)
      :ready
    else
      :waiting
    end
  end

  # ❌ Usa método privado
  private

  def format_date(date)
    date.strftime('%Y-%m-%d')
  end
end
```

---

## 2.6 State Machines (Modelos con AASM)

```ruby
# ✅ CORRECTO
class Order < ApplicationRecord
  include AASM
  include Discard::Model
  default_scope -> { kept }

  has_many :state_changes, as: :state_changeable

  aasm column: :state do
    state :draft, initial: true
    state :pending, :completed, :cancelled

    event :submit do
      transitions from: :draft, to: :pending
    end

    event :complete do
      transitions from: :pending, to: :completed
    end

    event :cancel do
      transitions from: [:draft, :pending], to: :cancelled
    end
  end

  # ✅ OBLIGATORIO: Define eventos visibles en UI
  def available_frontend_events
    [:submit, :complete, :cancel]
  end
end

# ❌ VIOLACIONES COMUNES
class Order < ApplicationRecord
  include AASM

  # ❌ FALTA has_many :state_changes
  # ❌ FALTA include Discard::Model
  # ❌ FALTA default_scope -> { kept }

  aasm column: :state do
    state :draft, initial: true
    state :pending

    event :submit do
      transitions from: :draft, to: :pending
    end
  end

  # ❌ FALTA método available_frontend_events
end
```

---

## 2.7 Vistas (`app/views/**/*.erb`)

```erb
<%# ✅ CORRECTO %>
<h1><%= I18n.t('activerecord.models.user.other') %></h1>

<%= form_with model: @user, url: admin_user_path(@user) do |f| %>
  <%= render Form::Fields::Text::TextFieldComponent.new(
        form: f,
        attribute: :name,
        label: User.human_attribute_name(:name),
        options: { required: true }) %>
<% end %>

<%= turbo_frame_tag "users_list" do %>
  <%= render Tables::IndexComponent.new(collection: @users) %>
<% end %>

<%= render Show::Fields::FieldComponent.new(
      object: @user,
      attribute: :email,
      type: :text,
      label: User.human_attribute_name(:email)) %>

<%# ❌ VIOLACIONES COMUNES %>
<h1>Usuarios</h1>  <%# ❌ String hardcoded, debe usar I18n %>

<%# ❌ HTML de formulario generado manualmente %>
<div class="mb-3">
  <%= f.label :name, "Nombre", class: "form-label" %>
  <%= f.text_field :name, class: "form-control" %>
</div>

<%# ❌ Tabla generada manualmente en lugar de usar TableComponent %>
<table class="table">
  <thead>
    <tr>
      <th>Name</th>
      <th>Email</th>
    </tr>
  </thead>
  <tbody>
    <% @users.each do |user| %>
      <tr>
        <td><%= user.name %></td>
        <td><%= user.email %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<%# ❌ Lógica de negocio en vista %>
<% if @user.orders.sum(&:total) > 1000 %>
  <span class="badge bg-success">VIP</span>
<% end %>
```
