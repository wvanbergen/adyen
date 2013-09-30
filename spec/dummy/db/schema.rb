# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130930141325) do

  create_table "adyen_notifications", :force => true do |t|
    t.boolean  "live",                                :default => false, :null => false
    t.string   "event_code",            :limit => 40,                    :null => false
    t.string   "psp_reference",         :limit => 50,                    :null => false
    t.string   "original_reference"
    t.string   "merchant_reference",                                     :null => false
    t.string   "merchant_account_code",                                  :null => false
    t.datetime "event_date",                                             :null => false
    t.boolean  "success",                             :default => false, :null => false
    t.string   "payment_method"
    t.string   "operations"
    t.text     "reason"
    t.string   "currency",              :limit => 3
    t.integer  "value"
    t.boolean  "processed",                           :default => false, :null => false
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

  add_index "adyen_notifications", ["psp_reference", "event_code", "success"], :name => "adyen_notification_uniqueness", :unique => true

end
