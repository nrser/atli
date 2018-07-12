require 'helper'

require_relative '../fixtures/bash_complete_fixtures'

describe_spec_file(
  spec_path:        __FILE__,
  module:           Thor::Completion::Bash::ThorMixin,
  class:            BashCompleteFixtures::Main,
) do
  describe_class BashCompleteFixtures::Main do
    describe_method :bash_complete do

      def self.basename
        BashCompleteFixtures::Main.basename
      end

      def basename
        self.class.basename
      end

      def build_request *words, cword: -1, split: false
        words.map! { |word|
          if word == '$0'
            basename
          else
            word
          end
        }

        if cword < 0
          cword = words.length + cword
        end

        Thor::Completion::Bash::Request.new \
          words: words,
          cword: cword,
          cur: words[cword],
          prev: words[cword - 1],
          split: split
      end

      describe_setup "process `request` and sort results" do

        let( :request ) { build_request *words }

        subject { super().call( request: request, index: 1 ).sort }

        use_case "basics" do
          _when words: [ basename, '' ] do
            it "responds with Main's command and subcommand usage names" do
              is_expected.to eq [
                "help",
                "bash-complete",
                "dashed-main-cmd",
                "underscored_main_cmd",
                "my-alpha-sub",
                "my_beta_sub",
              ].sort
            end
          end # WHEN "only the program name has been typed"
          

          _when words: [ basename, 'bash' ] do
            it "responds with the bash-complete command itself!" do
              is_expected.to eq [ "bash-complete" ]
            end
          end
          
          _when words: [ basename, '-' ] do
            it "responds with the built-in help mappings" do
              is_expected.to eq Thor::HELP_MAPPINGS.sort
            end
          end

          _when words: [ basename, '--' ] do
            it "responds with the `--help` help mapping" do
              is_expected.to eq ['--help']
            end
          end

          _when words: [ basename, 'my-al' ] do
            it "responds with the `alpha-sub` subcommand" do
              is_expected.to eq [ 'my-alpha-sub' ]
            end
          end

          _when words: [ basename, 'my' ] do
            it "responds with both subcmds" do
              is_expected.to eq [ 'my-alpha-sub', 'my_beta_sub' ].sort
            end
          end
        
        end # CASE basics


        use_case(
          "matching command with dashed usage", 
          "(dashed-main-cmd)"
        ) do
          _when "`request.cur` includes neither dash nor underscore",
                words: [ basename, 'dashed' ] do
            it "responds with the usage format (dashed)" do
              is_expected.to eq ['dashed-main-cmd']
            end
          end

          _when "`request.cur` includes dash",
                words: [ basename, 'dashed-ma' ] do
            it "responds with the usage format (dashed)" do
              is_expected.to eq ['dashed-main-cmd']
            end
          end

          _when "`request.cur` includes underscore",
                words: [ basename, 'dashed_' ] do
            it "responds with the underscored format" do
              is_expected.to eq ['dashed_main_cmd']
            end
          end
        end # CASE "matching command with dashed usage" **********************


        use_case(
          "matching command with underscored usage",
          "(underscored_main_cmd)"
         ) do

          _when "`request.cur` includes neither dash nor underscore",
                words: [ basename, 'underscored' ] do
            it "responds with the usage format (underscored)" do
              is_expected.to eq ['underscored_main_cmd']
            end
          end

          _when "`request.cur` includes a dash",
                words: [ basename, 'underscored-' ] do
            it "responds with the dashed format" do
               is_expected.to eq ['underscored-main-cmd']
            end
          end

          _when "`request.cur` includes an underscore",
                words: [ basename, 'underscored_m' ] do
            it "responds with the underscored format (usage in this case)" do
               is_expected.to eq ['underscored_main_cmd']
            end
          end
        end # CASE "matching command with underscored usage" *****************


        setup "words = [#{ basename }, sub, cur]" do

          let( :words ) { [ basename, sub, cur ] }

          use_case "matches subcommand and passes on to it" do

            _when "`sub` is exact subcmd usage and `cur` is empty",
                  sub: 'my-alpha-sub',
                  cur: '' do
              it "responds with all the subcmd's commands" do
                is_expected.to eq [
                  "dashed-alpha-cmd",
                  "underscored_alpha_cmd",
                  "help",
                ].sort
              end
            end # WHEN


            _when "`sub` is a partial but unique match,",
                  "and `cur` is empty",
                  sub: 'my-alpha',
                  cur: '' do
              it "responds with all the subcmd's commands" do
                is_expected.to eq [
                  "dashed-alpha-cmd",
                  "underscored_alpha_cmd",
                  "help",
                ].sort
              end
            end # WHEN


            _when "`sub` is a partial but NOT unique match,",
                  "and `cur` is empty",
                  sub: 'my',
                  cur: '' do
              it "responds with no matches" do
                is_expected.to eq []
              end
            end # WHEN


            _when "`sub` is a underscored but usage is dashed,",
                  "and `cur` is empty",
                  sub: 'my_alpha_sub',
                  cur: '' do
              it "responds with all the subcmd's commands" do
                is_expected.to eq [
                  "dashed-alpha-cmd",
                  "underscored_alpha_cmd",
                  "help",
                ].sort
              end
            end # WHEN


            _when "`sub` is a dashed but usage is underscored,",
                  "and `cur` is empty",
                  sub: 'my-beta-sub',
                  cur: '' do
              it "responds with all the subcmd's commands" do
                is_expected.to eq [
                  "dashed-beta-cmd",
                  "underscored_beta_cmd",
                  "help",
                ].sort
              end
            end # WHEN

          end # CASE matches exact subcommand and passes on to it

        end # SETUP words = [basename, sub, cur]

      end # SETUP "sorted results when passed `request`"
    end # METHOD :bash_complete
  end # CLASS BashCompleteFixtures::Main
end # Spec File Description