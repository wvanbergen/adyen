 create_table :adyen_payment_notifications, :force => true do |t|      
  t.boolean  :live
  t.string   :event_code,            :null => false
  t.string   :psp_reference,         :null => false
  t.string   :original_reference,    :null => true
  t.string   :merchant_reference,    :null => false
  t.string   :merchant_account_code, :null => false
  t.datetime :event_date,            :null => false
  t.boolean  :success,               
  t.string   :payment_method,        :null => false
  t.string   :operations,            :null => false
  t.text     :reason
  t.string   :currency,              :null => false, :limit => 3
  t.decimal  :value,                 :null => false, :precision => 9, :scale => 2
  t.boolean  :processed,             :default => false      
  t.timestamps
end