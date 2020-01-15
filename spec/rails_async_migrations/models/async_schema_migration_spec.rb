RSpec.describe AsyncSchemaMigration, type: :model do
  subject { described_class.new(id: 1, version: 1, state: 'pending', direction: 'down') }

  describe 'Associations' do
    it { is_expected.to validate_presence_of(:version) }
    it { is_expected.to validate_inclusion_of(:state).in_array(%w[created pending processing done failed]) }
    it { is_expected.to validate_inclusion_of(:direction).in_array(%w[up down]) }
  end

  describe 'Associations' do
    it { is_expected.to validate_presence_of(:version) }
  end

  context 'when created' do
    it 'calls #trace' do
      allow(subject).to receive(:trace)

      subject.save

      expect(subject).to have_received(:trace)
    end
  end

  describe '#trace' do
    it 'prints current migration state' do
      expect_any_instance_of(RailsAsyncMigrations::Tracer).to receive(:verbose).with(
        "Asynchronous migration `1` is now `pending`"
      )

      subject.trace
    end
  end
end
