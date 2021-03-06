class Admin::TasksController < ApplicationController
  before_action :authenticate_admin!

  before_action do
    @replace_payment_card = ReplacePaymentCard.new
    @undisburse_payment_card = UndisbursePaymentCard.new
    @import_payment_cards = ImportPaymentCards.new
  end

  def show
  end

  def replace_payment_card
    replace_payment_card_params = params.require(:replace_payment_card)
                                    .permit(
                                      :wrong_sequence_number,
                                      :correct_sequence_number
                                    )
    @replace_payment_card.assign_attributes(replace_payment_card_params)

    wrong_payment_card = PaymentCard.find_by(sequence_number: @replace_payment_card.wrong_sequence_number)
    correct_payment_card = PaymentCard.find_by(sequence_number: @replace_payment_card.correct_sequence_number)

    if wrong_payment_card.blank?
      @replace_payment_card.errors.add(:wrong_sequence_number, "Payment Card does not exist")
    elsif wrong_payment_card.aid_application.blank?
      @replace_payment_card.errors.add(:wrong_sequence_number, "Payment Card has not been disbursed")
    end

    if correct_payment_card.blank?
      @replace_payment_card.errors.add(:correct_sequence_number, "Payment Card does not exist")
    elsif correct_payment_card.aid_application.present?
      @replace_payment_card.errors.add(:correct_sequence_number, "Payment Card has already been disbursed to #{correct_payment_card.aid_application.application_number}")
    end

    if @replace_payment_card.errors.empty?
      wrong_payment_card.replace_with(correct_payment_card)
      redirect_to({ action: :show }, notice: "Replaced Sequence Number '#{@replace_payment_card.wrong_sequence_number}' with '#{@replace_payment_card.correct_sequence_number}' for #{correct_payment_card.aid_application.application_number}")
    else
      render :show
    end
  end

  def undisburse_payment_card
    undisburse_payment_card_params = params.require(:undisburse_payment_card).permit(:sequence_number)
    @undisburse_payment_card.assign_attributes(undisburse_payment_card_params)

    payment_card = PaymentCard.find_by(sequence_number: @undisburse_payment_card.sequence_number)
    if payment_card.blank?
      @undisburse_payment_card.errors.add(:sequence_number, "Payment Card does not exist")
    elsif payment_card.aid_application.blank?
      @undisburse_payment_card.errors.add(:sequence_number, "Payment Card has not been assigned to an Aid Application")
    end

    if @undisburse_payment_card.errors.empty?
      aid_application = payment_card.aid_application
      payment_card.update!(activation_code: nil, blackhawk_activation_code_assigned_at: nil, aid_application: nil)
      aid_application.update!(disbursed_at: nil, disburser: nil, payment_card: nil)

      redirect_to({ action: :show }, notice: "Undisbursed Sequence Number '#{@undisburse_payment_card.sequence_number}' for #{aid_application.application_number}")
    else
      render :show
    end
  end

  def import_payment_cards
    import_payment_cards_params = params.require(:import_payment_cards)
                                    .permit(
                                      :quote_number,
                                      :csv_text
                                    )

    @import_payment_cards.assign_attributes(import_payment_cards_params)

    begin
      result = PaymentCard.import(quote_number: @import_payment_cards.quote_number, csv_text: @import_payment_cards.csv_text)
    rescue => error
      @import_payment_cards.errors.add(:csv_text, error.message)
    end

    if @import_payment_cards.errors.empty?
      redirect_to({ action: :show }, notice: "Imported #{result&.rows.size} Payment Cards")
    else
      render :show
    end
  end


  class ReplacePaymentCard
    include ActiveModel::Model
    attr_accessor :wrong_sequence_number
    attr_accessor :correct_sequence_number

    def self.model_name
      ActiveModel::Name.new(self, nil, "ReplacePaymentCard")
    end
  end

  class UndisbursePaymentCard
    include ActiveModel::Model
    attr_accessor :sequence_number

    def self.model_name
      ActiveModel::Name.new(self, nil, "UndisbursePaymentCard")
    end
  end

  class ImportPaymentCards
    include ActiveModel::Model
    attr_accessor :quote_number
    attr_accessor :csv_text

    def self.model_name
      ActiveModel::Name.new(self, nil, "ImportPaymentCards")
    end
  end
end
