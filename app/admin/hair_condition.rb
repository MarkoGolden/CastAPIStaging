ActiveAdmin.register HairCondition do
  menu parent: 'Notifications'
  config.comments = false

  permit_params :minimum_temperature, :maximum_temperature, :minimum_humidity, :maximum_humidity, :time_of_a_day,
                :amazon_tags, :hair_type, push_texts_attributes: [:id, :text, :_destroy]

  index do
    selectable_column
    id_column
    column :hair_type
    column :minimum_temperature
    column :maximum_temperature
    # column :minimum_humidity
    # column :maximum_humidity
    column :time_of_a_day
    column :amazon_tags
    actions
  end

  filter :hair_type, as: :select, collection: %w(straight wavy curly coily 1 2a 2b 2c 3a 3b 3c 4a 4b 4c)
  filter :minimum_temperature
  filter :maximum_temperature
  # filter :minimum_humidity
  # filter :maximum_humidity
  filter :time_of_a_day

  form do |f|
    f.inputs 'Push note details' do
      f.input :hair_type, as: :select, collection: ['straight', 'wavy', 'curly', 'coily', '1', '2a', '2b', '2c', '3a', '3b', '3c', '4a', '4b', '4c']
      f.input :minimum_temperature, hint: 'In Fahrenheit. Example: 40'
      f.input :maximum_temperature, hint: 'In Fahrenheit. Example: 150'
      # f.input :minimum_humidity, hint: 'Example: 30'
      # f.input :maximum_humidity, hint: 'Example: 70'
      # f.input :time_of_a_day, as: :select, collection: ['9am', '12pm', '6pm']
      f.input :time_of_a_day, as: :select, collection: ['9am', '6pm']
      f.input :amazon_tags, hint: 'moisturizer, normal skin, winter'
      f.has_many :push_texts, allow_destroy: true, heading: 'Push messages texts' do |pt|
        pt.input :text, hint: "Example: Hey %{user}, how's your skin looking today?"
      end
    end
    f.actions
  end

  show do
    # default_main_content
    attributes_table do
      row :hair_type
      row :minimum_temperature
      row :maximum_temperature
      row :amazon_tags
      row :time_of_a_day
      row :created_at
      row :updated_at
    end

    panel 'Push Texts' do
      table_for hair_condition.push_texts do
        column :text
      end
    end
  end
end
