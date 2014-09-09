module Engine
  module POS
    class TransactionsAPI < Grape::API
      helpers CoreEngineHelper
      helpers Engine::POS::PosUtils
      before do
        check_merchant! unless (request.request_method == 'PUT' || request.request_method == 'DELETE')
      end

      resources :transactions do
        params do
          requires :money_amount, type: Integer
          requires :plan_type, type: String
          requires :bank_card, type: String
        end
        post '/' do
          begin
            @transaction = current_merchant.new_transaction(
                money_amount: params[:money_amount].to_i,
                plan_type: params[:plan_type],
                media_num: params[:bank_card],
                media_type: Member::PaymentMedia::BANK_CARD
            )
            logger.info("transaction created with ref_id: #{@transaction.ref_id}")
            present @transaction, with: Engine::POS::Entities::Transaction
            status 200
          rescue Pay::NoPlanSelectedError => e
            logger.info("transaction failed: #{e}")
            print_pos_error(MessageProperties::MERCHANT_NOT_SUPPORTED)
          rescue Pay::PaymentPlanError => e
            logger.info("transaction failed: #{e}")
            print_pos_error(e.message)
          end
        end

        params do
          requires :status, type: Integer
          requires :trans_id, type: String
        end
        put '/:trans_id' do
          status = params[:status].to_i
          trans_id = params[:trans_id]
          #wrapped in transaction, ready for read/write separation
          transaction = Trade::Transaction.transaction do
            Trade::Transaction.where(ref_id: trans_id).first
          end
          if transaction.nil?
            logger.error("can not find transaction with id #{trans_id}")
            print_pos_error
          else
            transaction.confirmed = true
            transaction.status = status
            transaction.sequence_num = params[:sequence_num]
            transaction.terminal_num = params[:terminal_num]
            if not params[:transaction_datetime].blank?
              transaction.transaction_datetime = begin
                Time.zone.parse(params[:transaction_datetime])
              rescue StandardError
                nil
              end
            end
            transaction.merchant_amount = params[:merchant_amount]
            transaction.reason = params[:reason]
            transaction.save!
            finish_transaction(trans_id)
          end
        end

        params do
          requires :trans_id, type: String
        end
        delete '/:trans_id' do
          trans_id = params[:trans_id]
          if (Trade::Transaction.exists?(ref_id: trans_id) || Trade::TransactionLog.recent.exists?(ref_id: trans_id))
            roll_back_transaction = Trade::RollBackTransaction.new
            roll_back_transaction.confirmed = true
            roll_back_transaction.status = Trade::Transaction::SUCCESS
            roll_back_transaction.roll_back_ref = trans_id
            roll_back_transaction.save!
            begin
              finish_transaction(roll_back_transaction.ref_id)
            rescue Trade::TransactionAlreadyRevertedError
              #do nothing here
            end
          else
            logger.error("can not find transaction with id #{trans_id}, discard the request")
          end
        end
      end
    end
  end
end