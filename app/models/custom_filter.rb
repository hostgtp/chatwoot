# == Schema Information
#
# Table name: custom_filters
#
#  id          :bigint           not null, primary key
#  filter_type :integer          default("conversation"), not null
#  name        :string           not null
#  query       :jsonb            not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_custom_filters_on_account_id  (account_id)
#  index_custom_filters_on_user_id     (user_id)
#
class CustomFilter < ApplicationRecord
  belongs_to :user
  belongs_to :account

  enum filter_type: { conversation: 0, contact: 1, report: 2 }

  def records_count
    get_record_count_from_redis || set_record_count_in_redis
  end

  def filter_records
    Conversations::FilterService.new(query.with_indifferent_access, Current.user).perform
  end

  def set_record_count_in_redis
    records = filter_records
    Redis::Alfred.set(filter_count_key, records[:count][:all_count])
    get_record_count_from_redis
  end

  def fetch_record_count_from_redis
    Redis::Alfred.get(filter_count_key)
  end

  def filter_count_key
    format(::Redis::Alfred::CUSTOM_FILTER_RECORDS_COUNT_KEY, account_id: account_id, filter_id: id)
  end
end
