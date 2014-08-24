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

ActiveRecord::Schema.define(version: 20140824130903) do

  create_table "acquirer_org", force: true do |t|
    t.string   "acquirer_name"
    t.string   "acquirer_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "activity_logs", force: true do |t|
    t.string   "user_name"
    t.string   "ip_address"
    t.string   "action"
    t.string   "note"
    t.string   "object"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "card_bins", force: true do |t|
    t.string   "card_code"
    t.string   "bank_name"
    t.integer  "length"
    t.string   "bank_bin"
    t.integer  "organization"
    t.integer  "card_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "card_bins", ["bank_bin"], name: "index_card_bins_on_bank_bin", using: :btree
  add_index "card_bins", ["bank_name"], name: "index_card_bins_on_bank_name", using: :btree

  create_table "configurations", force: true do |t|
    t.string "key"
    t.string "value"
  end

  create_table "credit_accounts", force: true do |t|
    t.string   "account_type"
    t.string   "name"
    t.string   "address"
    t.string   "mobile"
    t.string   "external_id",                    null: false
    t.integer  "total_credit",       default: 0, null: false
    t.integer  "usable_credit",      default: 0, null: false
    t.integer  "locked_credit",      default: 0, null: false
    t.integer  "cashed_credit",      default: 0, null: false
    t.integer  "referer_credit",     default: 0, null: false
    t.integer  "referee_credit",     default: 0, null: false
    t.integer  "consumption_credit", default: 0, null: false
    t.integer  "consumption_times",  default: 0, null: false
    t.integer  "referer_account_id"
    t.integer  "lock_version"
    t.integer  "status",             default: 1, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "tag"
  end

  add_index "credit_accounts", ["external_id"], name: "credit_account_external_id", unique: true, using: :btree
  add_index "credit_accounts", ["mobile"], name: "index_credit_accounts_on_mobile", unique: true, using: :btree
  add_index "credit_accounts", ["tag"], name: "index_credit_accounts_on_tag", using: :btree

  create_table "credit_cashing_applications", force: true do |t|
    t.string   "bank_card"
    t.string   "bank_name"
    t.string   "real_name"
    t.integer  "amount"
    t.integer  "status",            default: 101, null: false
    t.string   "comment"
    t.integer  "credit_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "credit_cashing_applications", ["credit_account_id"], name: "fk_cashing_application_credit_accounts", using: :btree

  create_table "marketing_rules", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "merchant_store_id"
    t.string   "rule_type"
    t.integer  "money_condition"
    t.integer  "accumulated_money_condition"
    t.integer  "accumulated_consumption_time_condition"
    t.datetime "valid_from"
    t.datetime "valid_till"
    t.integer  "status"
  end

  create_table "marketing_rules_payment_plans", force: true do |t|
    t.integer "marketing_rule_id"
    t.integer "payment_plan_id"
  end

  add_index "marketing_rules_payment_plans", ["marketing_rule_id"], name: "index_marketing_rules_payment_plans_on_marketing_rule_id", using: :btree
  add_index "marketing_rules_payment_plans", ["payment_plan_id"], name: "index_marketing_rules_payment_plans_on_payment_plan_id", using: :btree

  create_table "member_ships", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "member_group_id"
    t.string   "member_group_type"
    t.integer  "credit_account_id"
  end

  add_index "member_ships", ["credit_account_id"], name: "index_member_ships_on_credit_account_id", using: :btree
  add_index "member_ships", ["member_group_id", "member_group_type"], name: "index_member_ships_on_member_group_id_and_member_group_type", using: :btree

  create_table "merchant_group_ships", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "merchant_store_id"
    t.integer  "merchant_group_id"
  end

  add_index "merchant_group_ships", ["merchant_group_id"], name: "index_merchant_group_ships_on_merchant_group_id", using: :btree
  add_index "merchant_group_ships", ["merchant_store_id"], name: "index_merchant_group_ships_on_merchant_store_id", using: :btree

  create_table "merchant_groups", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "display_name"
  end

  add_index "merchant_groups", ["name"], name: "index_merchant_groups_on_name", unique: true, using: :btree

  create_table "merchant_stores", force: true do |t|
    t.string   "name",                                                            null: false
    t.string   "merchant_number",                                                 null: false
    t.string   "license_name"
    t.string   "license_num"
    t.string   "license_expire_date"
    t.string   "tax_number"
    t.string   "organization_code"
    t.string   "legal_person"
    t.string   "legal_person_ic"
    t.string   "register_address"
    t.string   "real_address"
    t.string   "business_scope"
    t.string   "real_business_scope"
    t.string   "contract_num"
    t.datetime "contract_active_date"
    t.string   "contractor"
    t.string   "file_num"
    t.string   "finance_contact_name"
    t.string   "finance_contact_phone"
    t.string   "public_account_name"
    t.string   "public_account_num"
    t.string   "public_account_bank"
    t.string   "clearance_account_name"
    t.string   "clearance_account_num"
    t.string   "clearance_account_bank"
    t.string   "deploy_contact_name"
    t.string   "deploy_contact_phone"
    t.string   "status"
    t.decimal  "standard_rate",          precision: 12, scale: 9,                 null: false
    t.integer  "credit_account_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "accquire_org_id"
    t.string   "tag"
    t.boolean  "accept_global_voucher",                                           null: false
    t.boolean  "accept_own_voucher",                              default: false, null: false
    t.string   "notification_mobile"
  end

  add_index "merchant_stores", ["merchant_number"], name: "index_merchant_stores_on_merchant_number", unique: true, using: :btree
  add_index "merchant_stores", ["tag"], name: "index_merchant_stores_on_tag", using: :btree

  create_table "payment_media", force: true do |t|
    t.string   "media_type"
    t.string   "media_num"
    t.string   "card_type"
    t.string   "bank_name"
    t.boolean  "cashing_card",      default: false, null: false
    t.integer  "credit_account_id"
    t.integer  "credit_earned",     default: 0,     null: false
    t.integer  "lock_version"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "payment_media", ["credit_account_id"], name: "fk_payment_media_accounts", using: :btree
  add_index "payment_media", ["media_num", "media_type"], name: "media_num", unique: true, using: :btree

  create_table "payment_plans", force: true do |t|
    t.string   "plan_type"
    t.decimal  "merchant_rate",        precision: 12, scale: 9
    t.decimal  "customer_rate",        precision: 12, scale: 9
    t.decimal  "referer_rate",         precision: 12, scale: 9
    t.integer  "discount_amount"
    t.decimal  "discount_rate",        precision: 12, scale: 9
    t.integer  "card_bin_id"
    t.integer  "merchant_store_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                                        default: 0, null: false
    t.datetime "valid_from"
    t.datetime "valid_till"
    t.string   "discount_type"
    t.string   "bank_name"
    t.integer  "minimal_money_amount",                          default: 0, null: false
    t.integer  "voucher_status"
    t.string   "user_tag"
    t.integer  "user_type",                                     default: 0, null: false
  end

  add_index "payment_plans", ["merchant_store_id"], name: "fk_store_payment_plan", using: :btree

  create_table "platform_accounts", force: true do |t|
    t.string   "account_name",  null: false
    t.string   "access_key",    null: false
    t.string   "access_target", null: false
    t.string   "remark"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
  end

  add_index "platform_accounts", ["account_name"], name: "platform_account_account_name", unique: true, using: :btree

  create_table "post_actions", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "marketing_rule_id"
    t.integer  "voucher_meta_id"
    t.string   "action_type"
    t.integer  "voucher_count"
  end

  create_table "sequence_numbers", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "number"
    t.boolean  "used",        default: false, null: false
    t.integer  "sequence_id"
  end

  add_index "sequence_numbers", ["number", "sequence_id"], name: "index_sequence_numbers_on_number_and_sequence_id", unique: true, using: :btree

  create_table "sequences", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
  end

  create_table "system_users", force: true do |t|
    t.string   "real_name"
    t.string   "name"
    t.string   "password_digest"
    t.string   "role_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "transaction_archives", force: true do |t|
    t.string   "transaction_type"
    t.integer  "money_amount"
    t.integer  "actual_money_amount"
    t.integer  "payment_plan_id"
    t.integer  "credit_account_id"
    t.integer  "merchant_store_id"
    t.integer  "consumer_credit"
    t.integer  "referer_credit"
    t.string   "mobile"
    t.string   "customer_name"
    t.string   "merchant_name"
    t.string   "media_num"
    t.string   "media_type"
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.string   "merchant_num"
    t.string   "plan_type"
    t.string   "matched_bank"
    t.string   "ref_id"
    t.boolean  "confirmed",                                     default: false, null: false
    t.string   "sequence_num"
    t.string   "transaction_datetime"
    t.string   "terminal_num"
    t.integer  "merchant_amount"
    t.integer  "status"
    t.string   "reason"
    t.string   "roll_back_ref"
    t.string   "acquirer_code"
    t.string   "merchant_tag"
    t.string   "user_tag"
    t.decimal  "merchant_rate",        precision: 12, scale: 9
    t.string   "voucher_info"
  end

  create_table "transaction_logs", id: false, force: true do |t|
    t.integer  "id",                                                              null: false
    t.integer  "log_type"
    t.datetime "transaction_datetime",                                            null: false
    t.string   "transaction_type"
    t.integer  "money_amount"
    t.integer  "actual_money_amount"
    t.integer  "payment_plan_id"
    t.integer  "credit_account_id"
    t.integer  "merchant_store_id"
    t.integer  "credit_delta"
    t.string   "mobile"
    t.string   "customer_name"
    t.string   "merchant_name"
    t.string   "terminal_num"
    t.string   "media_num"
    t.string   "media_type"
    t.string   "sequence_number"
    t.integer  "merchant_amount"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "merchant_num"
    t.string   "plan_type"
    t.string   "matched_bank"
    t.integer  "status",                                                          null: false
    t.string   "ref_id"
    t.integer  "internal_seq_num",                                    default: 0, null: false
    t.string   "acquirer_code"
    t.string   "merchant_tag"
    t.string   "user_tag"
    t.decimal  "merchant_rate",              precision: 12, scale: 9
    t.integer  "checked",                                             default: 0, null: false
    t.integer  "voucher_used_count",                                  default: 0, null: false
    t.integer  "voucher_deducted_amount",                             default: 0, null: false
    t.string   "referer_external_id"
    t.string   "referer_mobile"
    t.integer  "referer_id"
    t.string   "credit_account_external_id"
  end

  add_index "transaction_logs", ["acquirer_code"], name: "index_transaction_logs_on_acquirer_code", using: :btree
  add_index "transaction_logs", ["credit_account_id"], name: "index_transaction_logs_on_credit_account_id", using: :btree
  add_index "transaction_logs", ["merchant_num"], name: "index_transaction_logs_on_merchant_num", using: :btree
  add_index "transaction_logs", ["merchant_store_id"], name: "index_transaction_logs_on_merchant_store_id", using: :btree
  add_index "transaction_logs", ["merchant_tag"], name: "index_transaction_logs_on_merchant_tag", using: :btree
  add_index "transaction_logs", ["ref_id", "internal_seq_num", "status", "transaction_datetime"], name: "unique_log", unique: true, using: :btree
  add_index "transaction_logs", ["ref_id"], name: "index_transaction_logs_on_ref_id", using: :btree
  add_index "transaction_logs", ["terminal_num"], name: "index_transaction_logs_on_terminal_num", using: :btree
  add_index "transaction_logs", ["transaction_datetime"], name: "index_transaction_logs_on_transaction_datetime", using: :btree
  add_index "transaction_logs", ["user_tag"], name: "index_transaction_logs_on_user_tag", using: :btree

  create_table "transaction_post_actions", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "payment_plan_id"
    t.integer  "voucher_meta_id"
    t.string   "action_type"
    t.integer  "money_condition"
    t.integer  "accumulated_money_condition"
    t.integer  "accumulated_consumption_time_condition"
    t.datetime "valid_from"
    t.datetime "valid_till"
    t.integer  "status"
  end

  add_index "transaction_post_actions", ["payment_plan_id"], name: "index_transaction_post_actions_on_payment_plan_id", using: :btree
  add_index "transaction_post_actions", ["voucher_meta_id"], name: "index_transaction_post_actions_on_voucher_meta_id", using: :btree

  create_table "transactions", force: true do |t|
    t.string   "transaction_type"
    t.integer  "money_amount"
    t.integer  "actual_money_amount"
    t.integer  "payment_plan_id"
    t.integer  "credit_account_id"
    t.integer  "merchant_store_id"
    t.integer  "consumer_credit"
    t.integer  "referer_credit"
    t.string   "mobile"
    t.string   "customer_name"
    t.string   "merchant_name"
    t.string   "media_num"
    t.string   "media_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "merchant_num"
    t.string   "plan_type"
    t.string   "matched_bank"
    t.string   "ref_id"
    t.boolean  "confirmed",                                     default: false, null: false
    t.string   "sequence_num"
    t.datetime "transaction_datetime"
    t.string   "terminal_num"
    t.integer  "merchant_amount"
    t.integer  "status"
    t.string   "reason"
    t.string   "roll_back_ref"
    t.string   "acquirer_code"
    t.string   "merchant_tag"
    t.string   "user_tag"
    t.decimal  "merchant_rate",        precision: 12, scale: 9
    t.string   "voucher_info"
  end

  add_index "transactions", ["ref_id"], name: "index_transactions_on_ref_id", using: :btree

  create_table "voucher_meta", force: true do |t|
    t.datetime "valid_from"
    t.datetime "valid_till"
    t.string   "issuer_identifier"
    t.string   "issuer_name"
    t.integer  "issuer_type"
    t.string   "settler_identifier"
    t.string   "settler_name"
    t.integer  "settler_type"
    t.integer  "initial_amount",     default: -1, null: false
    t.integer  "amount_left",        default: -1, null: false
    t.integer  "denomination"
    t.integer  "limit_per_account",  default: -1, null: false
    t.string   "aliases",                         null: false
    t.string   "code",                            null: false
    t.string   "remark"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "merchant_group_id"
    t.integer  "merchant_store_id"
    t.integer  "applicable_type"
    t.integer  "sequence_id"
    t.integer  "money_condition",    default: 0,  null: false
    t.integer  "issued_count",       default: 0,  null: false
  end

  add_index "voucher_meta", ["aliases"], name: "index_voucher_meta_on_aliases", unique: true, using: :btree
  add_index "voucher_meta", ["code"], name: "index_voucher_meta_on_code", unique: true, using: :btree
  add_index "voucher_meta", ["issuer_identifier"], name: "index_voucher_meta_on_issuer_identifier", using: :btree
  add_index "voucher_meta", ["sequence_id"], name: "index_voucher_meta_on_sequence_id", unique: true, using: :btree
  add_index "voucher_meta", ["settler_identifier"], name: "index_voucher_meta_on_settler_identifier", using: :btree

  create_table "voucher_stores", force: true do |t|
    t.integer "merchant_store_id"
    t.integer "voucher_meta_id"
  end

  add_index "voucher_stores", ["merchant_store_id"], name: "index_voucher_stores_on_merchant_store_id", using: :btree
  add_index "voucher_stores", ["voucher_meta_id"], name: "index_voucher_stores_on_voucher_meta_id", using: :btree

  create_table "voucher_transaction_logs", id: false, force: true do |t|
    t.integer  "id",                                     null: false
    t.string   "mobile"
    t.integer  "credit_account_id"
    t.string   "transaction_type"
    t.datetime "transaction_datetime",                   null: false
    t.string   "issuer_identifier"
    t.string   "issuer_name"
    t.integer  "issuer_type"
    t.string   "settler_identifier"
    t.string   "settler_name"
    t.integer  "settler_type"
    t.integer  "denomination"
    t.integer  "deducted_amount"
    t.string   "voucher_meta_code"
    t.string   "voucher_unique_id"
    t.string   "ref_id"
    t.string   "primary_transaction_ref_id"
    t.string   "issue_event"
    t.string   "merchant_name"
    t.integer  "merchant_store_id"
    t.string   "merchant_num"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "checked",                    default: 0, null: false
    t.string   "voucher_sequence_number"
  end

  add_index "voucher_transaction_logs", ["credit_account_id"], name: "index_voucher_transaction_logs_on_credit_account_id", using: :btree
  add_index "voucher_transaction_logs", ["issuer_identifier"], name: "index_voucher_transaction_logs_on_issuer_identifier", using: :btree
  add_index "voucher_transaction_logs", ["merchant_store_id"], name: "index_voucher_transaction_logs_on_merchant_store_id", using: :btree
  add_index "voucher_transaction_logs", ["primary_transaction_ref_id"], name: "index_voucher_transaction_logs_on_primary_transaction_ref_id", using: :btree
  add_index "voucher_transaction_logs", ["ref_id"], name: "index_voucher_transaction_logs_on_ref_id", using: :btree
  add_index "voucher_transaction_logs", ["settler_identifier"], name: "index_voucher_transaction_logs_on_settler_identifier", using: :btree
  add_index "voucher_transaction_logs", ["voucher_unique_id"], name: "index_voucher_transaction_logs_on_voucher_unique_id", using: :btree

  create_table "vouchers", force: true do |t|
    t.integer  "credit_account_id"
    t.integer  "voucher_meta_id"
    t.string   "unique_id"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "used_datetime"
    t.string   "sequence_number"
  end

  add_index "vouchers", ["credit_account_id"], name: "index_vouchers_on_credit_account_id", using: :btree
  add_index "vouchers", ["sequence_number", "voucher_meta_id"], name: "index_vouchers_on_sequence_number_and_voucher_meta_id", unique: true, using: :btree
  add_index "vouchers", ["unique_id"], name: "index_vouchers_on_unique_id", unique: true, using: :btree
  add_index "vouchers", ["voucher_meta_id"], name: "index_vouchers_on_voucher_meta_id", using: :btree

  add_foreign_key "credit_cashing_applications", "credit_accounts", name: "fk_cashing_application_credit_accounts", dependent: :delete

  add_foreign_key "payment_media", "credit_accounts", name: "fk_payment_media_accounts", dependent: :delete

  add_foreign_key "payment_plans", "merchant_stores", name: "fk_store_payment_plan", dependent: :delete

end
