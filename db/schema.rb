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

ActiveRecord::Schema.define(version: 20150504090315) do

  create_table "load_profiles", force: true do |t|
    t.string   "key",                default: "",    null: false
    t.string   "name"
    t.boolean  "locked",             default: false, null: false
    t.string   "curve_file_name"
    t.string   "curve_content_type"
    t.integer  "curve_file_size"
    t.datetime "curve_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "load_profiles", ["key"], name: "index_load_profiles_on_key", unique: true, using: :btree

  create_table "technologies", force: true do |t|
    t.string "key",         limit: 100, null: false
    t.string "name",        limit: 100
    t.string "import_from", limit: 50
    t.string "export_to",   limit: 100
  end

  add_index "technologies", ["key"], name: "index_technologies_on_key", unique: true, using: :btree

  create_table "technology_profiles", force: true do |t|
    t.integer "load_profile_id",              null: false
    t.string  "technology",      default: "", null: false
  end

  add_index "technology_profiles", ["load_profile_id", "technology"], name: "index_technology_profiles_on_load_profile_id_and_technology", unique: true, using: :btree
  add_index "technology_profiles", ["load_profile_id"], name: "index_technology_profiles_on_load_profile_id", using: :btree

  create_table "testing_grounds", force: true do |t|
    t.text     "technologies",       limit: 16777215,              null: false
    t.text     "technology_profile"
    t.integer  "topology_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",               limit: 100,      default: "", null: false
    t.integer  "scenario_id"
    t.integer  "parent_scenario_id"
  end

  create_table "topologies", force: true do |t|
    t.text "graph", limit: 16777215, null: false
  end

  create_table "users", force: true do |t|
    t.string   "email",                              null: false
    t.string   "encrypted_password", default: "",    null: false
    t.boolean  "activated",          default: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

end
