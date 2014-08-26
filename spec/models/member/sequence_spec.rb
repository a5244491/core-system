require 'spec_helper'

describe Member::Sequence do
  describe 'allocate sequence number' do
    before :each do
      @sequence = create(:sequence, numbers: %w(1234 1235))
    end

    it 'should successfully allocate sequence number' do
      @sequence.allocate_sequence_number.should be =='1234'
      Member::SequenceNumber.where(number: '1234').first.used.should be_true
      @sequence.allocate_sequence_number.should be =='1235'
      Member::SequenceNumber.where(number: '1235').first.used.should be_true
      @sequence.allocate_sequence_number.should be_nil
    end
  end
end
