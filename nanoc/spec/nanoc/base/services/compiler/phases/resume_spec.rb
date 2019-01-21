# frozen_string_literal: true

describe Nanoc::Int::Compiler::Phases::Resume do
  subject(:phase) do
    described_class.new(
      wrapped: wrapped,
    )
  end

  let(:wrapped_class) do
    Class.new(Nanoc::Int::Compiler::Phases::Abstract) do
      attr_reader :count

      def self.to_s
        'MyPhaseClass'
      end

      def initialize(other_rep)
        super(wrapped: nil)

        @other_rep = other_rep
        @count = 0
      end

      def run(_rep, is_outdated:) # rubocop:disable Lint/UnusedMethodArgument
        @count += 1
        Fiber.yield(Nanoc::Int::Errors::UnmetDependency.new(@other_rep, :last))

        @count += 1
        Fiber.yield(Nanoc::Int::Errors::UnmetDependency.new(@other_rep, :last))

        @count += 1
      end
    end
  end

  let(:wrapped) { wrapped_class.new(other_rep) }

  let(:item) { Nanoc::Core::Item.new('item content', {}, '/donkey.md') }
  let(:rep) { Nanoc::Core::ItemRep.new(item, :latex) }

  let(:other_item) { Nanoc::Core::Item.new('other item content', {}, '/other.md') }
  let(:other_rep) { Nanoc::Core::ItemRep.new(other_item, :latex) }

  let(:config) { Nanoc::Core::Configuration.new(dir: Dir.getwd).with_defaults }

  describe '#call' do
    context 'one run' do
      subject do
        phase.call(rep, is_outdated: true)
      end

      it 'delegates to wrapped' do
        expect { subject rescue nil }.to change { wrapped.count }.from(0).to(1)
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Int::Errors::UnmetDependency)
      end

      it 'posts correct notifications' do
        begin
          msgs = []
          Nanoc::Int::NotificationCenter.on(:compilation_suspended, self) { msgs << :compilation_suspended }

          subject rescue nil
          Nanoc::Int::NotificationCenter.sync
          expect(msgs).to eq([:compilation_suspended])
        ensure
          Nanoc::Int::NotificationCenter.remove(:compilation_suspended, self)
        end
      end

      context 'wrapped in Notify' do
        let(:phase) do
          Nanoc::Int::Compiler::Phases::Notify.new(wrapped: super())
        end

        it 'posts correct notifications' do
          begin
            msgs = []
            Nanoc::Int::NotificationCenter.on(:compilation_started, self) { msgs << :compilation_started }
            Nanoc::Int::NotificationCenter.on(:compilation_suspended, self) { msgs << :compilation_suspended }
            Nanoc::Int::NotificationCenter.on(:compilation_ended, self) { msgs << :compilation_ended }

            subject rescue nil
            Nanoc::Int::NotificationCenter.sync
            expect(msgs).to eq(%i[compilation_started compilation_suspended])
          ensure
            Nanoc::Int::NotificationCenter.remove(:compilation_ended, self)
            Nanoc::Int::NotificationCenter.remove(:compilation_suspended, self)
            Nanoc::Int::NotificationCenter.remove(:compilation_started, self)
          end
        end
      end
    end

    context 'two runs' do
      subject do
        phase.call(rep, is_outdated: true) rescue nil
        phase.call(rep, is_outdated: true)
      end

      it 'delegates to wrapped' do
        expect { subject rescue nil }.to change { wrapped.count }.from(0).to(2)
      end

      it 'raises' do
        expect { subject }.to raise_error(Nanoc::Int::Errors::UnmetDependency)
      end

      it 'posts correct notifications' do
        begin
          msgs = []
          Nanoc::Int::NotificationCenter.on(:compilation_suspended, self) { msgs << :compilation_suspended }

          subject rescue nil
          Nanoc::Int::NotificationCenter.sync
          expect(msgs).to eq(%i[compilation_suspended compilation_suspended])
        ensure
          Nanoc::Int::NotificationCenter.remove(:compilation_suspended, self)
        end
      end

      context 'wrapped in Notify' do
        let(:phase) do
          Nanoc::Int::Compiler::Phases::Notify.new(wrapped: super())
        end

        it 'posts correct notifications' do
          begin
            msgs = []
            Nanoc::Int::NotificationCenter.on(:compilation_started, self) { msgs << :compilation_started }
            Nanoc::Int::NotificationCenter.on(:compilation_suspended, self) { msgs << :compilation_suspended }
            Nanoc::Int::NotificationCenter.on(:compilation_ended, self) { msgs << :compilation_ended }

            subject rescue nil
            Nanoc::Int::NotificationCenter.sync
            expect(msgs).to eq(%i[compilation_started compilation_suspended compilation_started compilation_suspended])
          ensure
            Nanoc::Int::NotificationCenter.remove(:compilation_ended, self)
            Nanoc::Int::NotificationCenter.remove(:compilation_suspended, self)
            Nanoc::Int::NotificationCenter.remove(:compilation_started, self)
          end
        end
      end
    end

    context 'three runs' do
      subject do
        phase.call(rep, is_outdated: true) rescue nil
        phase.call(rep, is_outdated: true) rescue nil
        phase.call(rep, is_outdated: true)
      end

      it 'delegates to wrapped' do
        expect { subject }.to change { wrapped.count }.from(0).to(3)
      end

      it 'does not raise' do
        expect { subject }.not_to raise_error
      end

      it 'posts correct notifications' do
        begin
          msgs = []
          Nanoc::Int::NotificationCenter.on(:compilation_suspended, self) { msgs << :compilation_suspended }

          subject
          Nanoc::Int::NotificationCenter.sync
          expect(msgs).to eq(%i[compilation_suspended compilation_suspended])
        ensure
          Nanoc::Int::NotificationCenter.remove(:compilation_suspended, self)
        end
      end

      context 'wrapped in Notify' do
        let(:phase) do
          Nanoc::Int::Compiler::Phases::Notify.new(wrapped: super())
        end

        it 'posts correct notifications' do
          begin
            msgs = []
            Nanoc::Int::NotificationCenter.on(:compilation_started, self) { msgs << :compilation_started }
            Nanoc::Int::NotificationCenter.on(:compilation_suspended, self) { msgs << :compilation_suspended }
            Nanoc::Int::NotificationCenter.on(:compilation_ended, self) { msgs << :compilation_ended }

            subject
            Nanoc::Int::NotificationCenter.sync
            expect(msgs).to eq(%i[compilation_started compilation_suspended compilation_started compilation_suspended compilation_started compilation_ended])
          ensure
            Nanoc::Int::NotificationCenter.remove(:compilation_ended, self)
            Nanoc::Int::NotificationCenter.remove(:compilation_suspended, self)
            Nanoc::Int::NotificationCenter.remove(:compilation_started, self)
          end
        end
      end
    end
  end
end
