RSpec.describe RailsAsyncMigrations::Migration::FireMigration do
  let(:instance) { described_class.new(migration.id) }
  let(:migration) do
    AsyncSchemaMigration.create!(
      version: '00000',
      state: 'created',
      direction: 'up'
    )
  end

  context '#perform' do
    subject { instance.perform }

    before do
      allow(instance).to receive(:process!).and_call_original
      allow(instance).to receive(:run_migration)
      allow(instance).to receive(:done!).and_call_original
      allow(instance).to receive(:check_queue).and_call_original
    end

    context 'when the migration does not exists' do
      before { allow(instance).to receive(:run_migration).and_call_original }

      it { expect { subject }.to raise_error(RailsAsyncMigrations::Error) }
    end

    context 'when the migration has been already performed' do
      it 'returns' do
        allow(instance).to receive(:done?).and_return(true)

        subject

        expect(instance).to have_received(:done?)
        expect(instance).not_to have_received(:run_migration)
        expect(instance).not_to have_received(:done!)
        expect(instance).not_to have_received(:check_queue)
      end
    end

    context 'when the migration has not been performed' do
      before { allow(instance).to receive(:done?).and_return(false) }

      it 'updates the status to `done`' do
        allow(instance).to receive(:done!)

        expect { subject; migration.reload }.to change { migration.state }.from('created').to('processing')

        expect(instance).to have_received(:process!)
      end

      it 'runs the migration' do
        subject

        expect(instance).to have_received(:run_migration)
      end

      it 'updates the status to `done`' do
        expect { subject; migration.reload }.to change { migration.state }.from('created').to('done')

        expect(instance).to have_received(:done!)
      end

      it 'checks the queue to trigger the next async migrations' do
        subject

        expect(instance).to have_received(:check_queue)
      end
    end
  end
end
