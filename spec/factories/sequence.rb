FactoryGirl.define do
  factory :sequence, class: Member::Sequence do
    ignore do
      numbers []
    end
    before :create do |sequence, evaluator|
      evaluator.numbers.each do |number|
        sequence.sequence_numbers << Member::SequenceNumber.new(number: number)
      end
    end
  end
end