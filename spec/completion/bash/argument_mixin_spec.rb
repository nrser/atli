require 'helper'

require_relative './bash_comp_spec_helpers'
require_relative './fixtures/bash_complete_fixtures'

describe_spec_file(
  spec_path:        __FILE__,
  module:           Thor::Completion::Bash::ArgumentMixin,
  class:            BashCompleteFixtures::Main,
  method:           :bash_complete,
) do

  include BashCompSpecHelpers

  describe "verify {ArgumentMixin} has been mixed in correctly" do
    describe_class Thor::Argument do
      it do
        is_expected.to include Thor::Completion::Bash::ArgumentMixin
      end
    end

    describe_class BashCompleteFixtures::Main do
      describe "dashed_main_cmd Command" do
        subject { super().all_commands[:dashed_main_cmd] }

        it { is_expected.to be_a Thor::Command }

        describe "str_comp_opt Option" do
          subject { super().options[:str_comp_opt] }

          it { is_expected.to be_a Thor::Option }

          describe_attr :complete do
            it do
              is_expected.to be_a( Proc ).and have_attributes( arity: 0)
            end
          end
        end
      end
    end
  end # describe "verify {ArgumentMixin} has been mixed in correctly"


  describe_setup "process `request` and sort results" do

    let( :request ) { build_request *words }

    subject { super().call( request: request, index: 1 ).sort }


    use_case "Provide dynamic completions for :complete options" do

      _when "just the option name part has been filled in" do

        let( :request ) {
          build_request \
            basename,
            'dashed-main',
            '--str-comp-opt=',
            cword: 2,
            split: true,
            cur: '',
            prev: '--str-comp-opt'
        }

        it "responds with the option's enum choices" do
          is_expected.to eq [ 'beijing', 'berkeley', 'xiamen' ].sort
        end
      end # WHEN


      _when "part of the option value has been typed" do

        let( :request ) {
          build_request \
            basename,
            'dashed-main',
            '--str-comp-opt=be',
            cword: 2,
            split: true,
            cur: 'be',
            prev: '--str-comp-opt'
        }

        it "responds with the matching enum choice" do
          is_expected.to eq [ 'beijing', 'berkeley' ].sort
        end
      end # WHEN

    end # CASE

  end # SETUP "sorted results when passed `request`"
end # Spec File Description