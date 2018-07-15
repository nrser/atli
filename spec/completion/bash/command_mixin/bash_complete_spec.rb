require 'helper'

require_relative '../bash_comp_spec_helpers'
require_relative '../fixtures/bash_complete_fixtures'

describe_spec_file(
  spec_path:        __FILE__,
  module:           Thor::Completion::Bash::CommandMixin,
  class:            BashCompleteFixtures::Main,
  method:           :bash_complete,
) do

  include BashCompSpecHelpers

  describe_setup "process `request` and sort results" do

    let( :request ) { build_request *words }

    subject { super().call( request: request, index: 1 ).sort }

    use_case "complete :boolean options" do

      _when words: [ basename, 'dashed-main-cmd', '--bool' ] do
        it "compeltes to `--bool-opt`" do
          is_expected.to eq ['--bool-opt']
        end
      end # WHEN

      _when words: [ basename, 'dashed-main-cmd', '--no-b' ] do
        it "compeltes to `--no-bool-opt`" do
          is_expected.to eq ['--no-bool-opt']
        end
      end # WHEN

    end # CASE complete :boolean options


    use_case "complete :string options" do

      _when words: [ basename, 'dashed-main-cmd', '--str-o' ] do
        it "compeltes to `--str-opt=`" do
          is_expected.to eq ['--str-opt=']
        end
      end # WHEN

    end # CASE complete :string options


    use_case "list options" do

      _when words: [ basename, 'dashed-main-cmd', '--' ] do
        it "Lists all `--` options" do
          is_expected.to eq [
            '--bool-opt',
            '--no-bool-opt',
            '--str-opt=',
            '--help',
            '--str-enum-opt=',
            '--str-comp-opt=',
          ].sort
        end
      end # WHEN

    end # CASE complete :string options


    use_case "Provide value completions for :enum options" do

      _when "just the option name part has been filled in" do

        # A real one:
        # 
        #     :request => {
        #         :words => [
        #             [0] "locd",
        #             [1] "agent",
        #             [2] "add",
        #             [3] "--label="
        #         ],
        #         :cword => 3,
        #           :cur => "",
        #         :prev => "--label",
        #         :split => true
        #     },
        # 
        let( :request ) {
          build_request \
            basename,
            'dashed-main',
            '--str-enum-opt=',
            cword: 2,
            split: true,
            cur: '',
            prev: '--str-enum-opt'
        }

        it "responds with the option's enum choices" do
          is_expected.to eq [ 'one', 'two', 'three' ].sort
        end
      end # WHEN


      _when "unique part of the option value has been typed" do
        # Example:
        # 
        #     :request => {
        #         :cword => 3,
        #         :words => [
        #             [0] "locd",
        #             [1] "agent",
        #             [2] "add",
        #             [3] "--label=abc"
        #         ],
        #         :split => true,
        #         :prev => "--label",
        #           :cur => "abc"
        #     },
        # 
        let( :request ) {
          build_request \
            basename,
            'dashed-main',
            '--str-enum-opt=on',
            cword: 2,
            split: true,
            cur: 'on',
            prev: '--str-enum-opt'
        }

        it "responds with the unique matching enum" do
          is_expected.to eq [ 'one' ]
        end
      end # WHEN


      _when "non-unique part of the option value has been typed" do
        let( :request ) {
          build_request \
            basename,
            'dashed-main',
            '--str-enum-opt=t',
            cword: 2,
            split: true,
            cur: 't',
            prev: '--str-enum-opt'
        }

        it "responds with the matching enum choices" do
          is_expected.to eq [ 'two', 'three' ].sort
        end
      end # WHEN

    end # CASE


    use_case "Provide value completions for :complete options", focus: true do

      describe "verify {ArgumentMixin} has been mixed in correctly" do
        describe_class Thor::Argument do
          it do
            is_expected.to include Thor::Completion::Bash::ArgumentMixin
          end
        end

        describe_class BashCompleteFixtures::Main do
          describe 'dashed_main_cmd Command' do
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