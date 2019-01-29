# frozen_string_literal: true

describe 'GH-776', site: true do
  before do
    File.write('content/donkey.md', 'Donkey!')

    File.write('Rules', <<EOS)
  compile '/donkey.*' do
    filter :erb
    snapshot :secret, path: '/donkey-secret.html'
    write '/donkey.html'
  end

  layout '/foo.*', :erb
EOS
  end

  let(:site) { Nanoc::Int::SiteLoader.new.new_from_cwd }

  before do
    Nanoc::Int::Compiler.compile(site)
  end

  context 'without pruning' do
    it 'writes two files' do
      expect(File.read('output/donkey.html')).to eql('Donkey!')
      expect(File.read('output/donkey-secret.html')).to eql('Donkey!')
    end
  end

  context 'with pruning' do
    before do
      res = Nanoc::Int::Compiler.new_for(site).run_until_reps_built
      Nanoc::Pruner.new(site.config, res.fetch(:reps)).run
    end

    it 'does not prune written snapshots' do
      expect(File.read('output/donkey.html')).to eql('Donkey!')
      expect(File.read('output/donkey-secret.html')).to eql('Donkey!')
    end
  end
end
