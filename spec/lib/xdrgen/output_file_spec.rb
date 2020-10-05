describe Xdrgen::OutputFile, "#balance_after" do
  subject(:file) { described_class.new(output_path) }

  let(:output_path) { "#{SPEC_ROOT}/../tmp/balanced.txt" }
  let(:unbalanced) do
    <<-EOS.strip_heredoc
    attribute :hello, XDR::UnsignedInt
    attribute :i_am_a_long_field, XDR::UnsignedInt
    attribute :s, XDR::UnsignedInt
    EOS
  end

  let(:actual) { IO.read(output_path) }
  let(:balanced) do
    <<-EOS.strip_heredoc
    attribute :hello,             XDR::UnsignedInt
    attribute :i_am_a_long_field, XDR::UnsignedInt
    attribute :s,                 XDR::UnsignedInt
    EOS
  end

  after { FileUtils.rm output_path }

  it "balanaces the input string on each line after splitting on the provided regex" do
    file.balance_after(/.+?,/) do
      file.puts unbalanced
    end
    file.close
    expect(actual).to eq(balanced)
  end
end
