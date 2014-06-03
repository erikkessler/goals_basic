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

ActiveRecord::Schema.define(version: 20140603145406) do

  create_table "activities", force: true do |t|
    t.integer  "repeated"
    t.date     "show_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "parent_id"
    t.string   "name"
    t.text     "description"
    t.datetime "completed_date"
    t.integer  "user_id"
    t.string   "integration_info"
    t.string   "type"
    t.integer  "priority"
    t.integer  "role_id"
    t.integer  "rep_parent_id"
    t.date     "expiration_date"
    t.integer  "state",            default: 0,    null: false
    t.integer  "goal_type"
    t.integer  "reward",           default: 0,    null: false
    t.integer  "penalty",          default: 0,    null: false
    t.integer  "count",            default: 0,    null: false
    t.integer  "count_goal"
    t.boolean  "is_root",          default: true, null: false
  end

  add_index "activities", ["parent_id"], name: "index_activities_on_parent_id"

  create_table "activity_handlers", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "type_groups", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "types", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "type_group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "type_id"
  end

  add_index "types", ["type_group_id"], name: "index_types_on_type_group_id"

end
