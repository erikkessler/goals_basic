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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140524210943) do

  create_table "activities", force: true do |t|
    t.integer  "repeated"
    t.date     "due_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "name"
    t.text     "description"
    t.boolean  "complete"
    t.datetime "completed_date"
    t.integer  "user_id"
    t.string   "integration_info"
    t.string   "type"
    t.integer  "priority"
    t.integer  "role_id"
    t.decimal  "value",            precision: 8, scale: 2
    t.decimal  "weight",           precision: 8, scale: 2
    t.boolean  "goal"
  end

  add_index "activities", ["parent_id"], name: "index_activities_on_parent_id"

end
