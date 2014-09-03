module Member
  module CreditAccountEngineConcern
    extend ActiveSupport::Concern
    included do
      delegate :external_id, to: :referer_account, allow_nil: true, prefix: true
    end

    def apply_consumption_credit!(credit, media_num)
      self.total_credit += credit
      self.usable_credit += credit
      self.consumption_credit += credit
      save!
      payment_media = Member::PaymentMedia.where(media_num: media_num).first
      unless payment_media.nil?
        payment_media.credit_earned += credit
        payment_media.save!
      end
    end


    def apply_referer_credit!(credit)
      referer_account = self.referer_account
      unless referer_account.nil?
        referer_account.total_credit += credit
        referer_account.usable_credit += credit
        referer_account.referer_credit += credit
        self.referee_credit += credit
        referer_account.save!
        save!
      end
    end
  end
end