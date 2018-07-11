require 'helper'

require_relative '../fixtures/bash_complete_fixtures'

NRSER::Log.setup_for_rspec! dest: Thor::ROOT.join( 'tmp', 'rspec.log' ), color: true

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
                "alpha",
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

          _when words: [ basename, 'al' ] do
            it "responds with the `alpha` subcommand" do
              is_expected.to eq [ 'alpha' ]
            end
          end
        
        end # CASE basics


        use_case(
          "matching command with dashed usage", 
          "(dashed-main-cmd)"
        ) do
          _when "`request.cur` includes neither dash nor underscore" do
            let( :request ) { build_request '$0', 'dashed' }

            it "responds with the usage format (dashed)" do
              is_expected.to eq ['dashed-main-cmd']
            end
          end

          _when "`request.cur` includes dash" do
            let( :request ) { build_request '$0', 'dashed-ma' }

            it "responds with the usage format (dashed)" do
              is_expected.to eq ['dashed-main-cmd']
            end
          end

          _when "`request.cur` includes underscore" do
            let( :request ) { build_request '$0', 'dashed_' }
            
            it "responds with the underscored format" do
              is_expected.to eq ['dashed_main_cmd']
            end
          end
        end # CASE "matching command with dashed usage" **********************


        use_case(
          "matching command with underscored usage",
          "(underscored_main_cmd)"
         ) do

          _when "`request.cur` includes neither dash nor underscore" do
            let( :request ) { build_request basename, 'underscored' }

            it "responds with the usage format (underscored)" do
              is_expected.to eq ['underscored_main_cmd']
            end
          end

          _when "`request.cur` includes a dash" do
            let( :request ) { build_request basename, 'underscored-' }
            
            it "responds with the dashed format" do
               is_expected.to eq ['underscored-main-cmd']
            end
          end

          _when "`request.cur` includes an underscore" do
            let( :request ) { build_request basename, 'underscored_m' }
            
            it "responds with the underscored format (usage in this case)" do
               is_expected.to eq ['underscored_main_cmd']
            end
          end
        end # CASE "matching command with underscored usage" *****************

      end # SETUP "sorted results when passed `request`"
    end # METHOD :bash_complete
  end # CLASS BashCompleteFixtures::Main
end # Spec File Description